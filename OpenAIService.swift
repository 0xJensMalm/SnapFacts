// OpenAIService.swift

import Foundation
import UIKit

/// A combined service for:
///   1) DALL·E “variations” (generateImageVariation)
///   2) Vision-Chat analysis (analyzeImageWithVisionChat)
///   3) DALL·E text-to-image (generateImageFromText)
///
/// Uses prompts from `OpenAIPrompts.shared` when no explicit prompt is provided.
/// All CPU work (cropping, resizing, compression, Base64) is offloaded via Task.detached(...)
/// so the main thread never blocks more than a few milliseconds.
final class OpenAIService {
    // ─────────────────────────────────────────────────────────────
    // MARK: – Errors
    
    enum OpenAIError: Error {
        case failedToCropImage
        case failedToEncodePNG
        case failedToEncodeJPEG
        case invalidResponse
        case httpError(code: Int, message: String?)
        case noImageReturned
        case unexpectedResponseFormat
        case visionChatDidNotReturnContent
    }
    
    // ─────────────────────────────────────────────────────────────
    // MARK: – Properties
    
    private let apiKey: String
    private let session: URLSession
    
    init(apiKey: String, session: URLSession = .shared) {
        self.apiKey = apiKey
        self.session = session
    }
    
    // ─────────────────────────────────────────────────────────────
    // MARK: – Public Methods
    
    /// 1) Crop+resize the input image to a PNG under 4 MB (off the main actor),
    /// 2) Send it to DALL·E’s variations endpoint,
    /// 3) Return the new image URL.
    func generateImageVariation(from image: UIImage) async throws -> URL {
        print("[OpenAIService] → generateImageVariation START")
        print("[OpenAIService]    apiKey (prefix): \(apiKey.prefix(5))…")

        // Maximum allowed PNG size (4 MB):
        let maxPNGBytes = 4 * 1_024 * 1_024

        // Candidate side lengths (in pixels), largest to smallest.
        let candidateSides: [CGFloat] = [1024, 512, 256, 128]

        // 1) Crop original UIImage to a square CGImage once (background thread)
        let squareCGImage: CGImage = try await Task.detached(priority: .userInitiated) {
            let side = min(image.size.width, image.size.height)
            let cropRect = CGRect(
                x: (image.size.width - side) / 2,
                y: (image.size.height - side) / 2,
                width: side,
                height: side
            )
            guard let cgCropped = image.cgImage?.cropping(to: cropRect) else {
                print("[OpenAIService]    FAILED: cropping returned nil")
                throw OpenAIError.failedToCropImage
            }
            return cgCropped
        }.value

        // 2) Find the smallest side whose PNG is under 4 MB
        var finalPNGData: Data? = nil
        var chosenSide: CGFloat = 0

        for side in candidateSides {
            let pngDataForSide: Data = try await Task.detached(priority: .userInitiated) {
                let squareImage = UIImage(cgImage: squareCGImage)
                let renderer = UIGraphicsImageRenderer(size: CGSize(width: side, height: side))
                let resizedImage = renderer.image { _ in
                    squareImage.draw(in: CGRect(origin: .zero, size: CGSize(width: side, height: side)))
                }
                guard let png = resizedImage.pngData() else {
                    print("[OpenAIService]    FAILED: pngData() returned nil at side \(side)")
                    throw OpenAIError.failedToEncodePNG
                }
                return png
            }.value

            print("[OpenAIService]    Trying side \(Int(side)) px → PNG is \(pngDataForSide.count / 1_024) KB")

            if pngDataForSide.count <= maxPNGBytes {
                finalPNGData = pngDataForSide
                chosenSide = side
                break
            }
        }

        guard let pngData = finalPNGData else {
            let errorMsg = "All resized PNGs (down to 128×128) exceed 4 MB."
            print("[OpenAIService]    ERROR: \(errorMsg)")
            throw OpenAIError.httpError(code: 400, message: errorMsg)
        }

        print("[OpenAIService]    Selected side \(Int(chosenSide)) px → final PNG byte-count: \(pngData.count) bytes")

        // 3) Build multipart/form-data request
        let endpoint = "https://api.openai.com/v1/images/variations"
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)",
                         forHTTPHeaderField: "Content-Type")

        var body = Data()

        func addFormField(
            name: String,
            filename: String? = nil,
            contentType: String? = nil,
            data: Data
        ) {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            var disposition = "Content-Disposition: form-data; name=\"\(name)\""
            if let fn = filename {
                disposition += "; filename=\"\(fn)\""
            }
            body.append((disposition + "\r\n").data(using: .utf8)!)
            if let ct = contentType {
                body.append(("Content-Type: \(ct)\r\n").data(using: .utf8)!)
            }
            body.append("\r\n".data(using: .utf8)!)
            body.append(data)
            body.append("\r\n".data(using: .utf8)!)
        }

        // “image” part: chosen PNG (< 4 MB)
        addFormField(
            name: "image",
            filename: "image.png",
            contentType: "image/png",
            data: pngData
        )

        // DALL·E parameters: n=1, size matches chosen side, model="dall-e-2"
        addFormField(name: "n",       data: Data("1".utf8))
        addFormField(name: "size",    data: Data("\(Int(chosenSide))x\(Int(chosenSide))".utf8))
        addFormField(name: "model",   data: Data("dall-e-2".utf8))

        // Close multipart
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body

        print("[OpenAIService]    POST \(endpoint)")
        print("[OpenAIService]    Body length: \(body.count) bytes")

        // 4) Send request and parse response
        let (responseData, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            print("[OpenAIService]    Response was not HTTPURLResponse")
            throw OpenAIError.invalidResponse
        }

        print("[OpenAIService]    HTTP Status Code: \(httpResponse.statusCode)")
        if httpResponse.statusCode != 200 {
            let serverText = String(data: responseData, encoding: .utf8) ?? "<unreadable data>"
            print("[OpenAIService]    ERROR \(httpResponse.statusCode): \(serverText)")
            throw OpenAIError.httpError(code: httpResponse.statusCode, message: serverText)
        }

        struct VariationReply: Decodable {
            struct Item: Decodable { let url: URL }
            let data: [Item]
        }

        let decoder = JSONDecoder()
        do {
            let reply = try decoder.decode(VariationReply.self, from: responseData)
            guard let firstURL = reply.data.first?.url else {
                print("[OpenAIService]    ERROR: no URL in data[]")
                throw OpenAIError.noImageReturned
            }
            print("[OpenAIService]    Success → image URL: \(firstURL.absoluteString)")
            return firstURL
        } catch {
            let raw = String(data: responseData, encoding: .utf8) ?? "<invalid UTF8>"
            print("[OpenAIService]    JSON decode error: \(error). Response was:\n\(raw)")
            throw error
        }
    }
    
    /// 1) JPEG → Base64 (background),
    /// 2) Send Vision-Chat prompt + Base64 image to Chat Completions,
    /// 3) Parse the assistant’s JSON‐only response into AnalysisResult.
    /// Uses `OpenAIPrompts.shared.defaultTextPrompt` if no prompt is provided.
    func analyzeImageWithVisionChat(
        _ image: UIImage,
        prompt: String? = nil
    ) async throws -> AnalysisResult {
        print("[OpenAIService] → analyzeImageWithVisionChat START")
        print("[OpenAIService]    apiKey (prefix): \(apiKey.prefix(5))…")
        
        // 1) JPEG → Base64 (background)
        let base64String: String = try await Task.detached(priority: .userInitiated) {
            guard let jpegData = image.jpegData(compressionQuality: 0.8) else {
                print("[OpenAIService]    FAILED: jpegData() returned nil")
                throw OpenAIError.failedToEncodeJPEG
            }
            print("[OpenAIService]    JPEG byte‐count: \(jpegData.count)")
            return jpegData.base64EncodedString()
        }.value
        
        // 2) Build the JSON payload
        let endpoint = "https://api.openai.com/v1/chat/completions"
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        struct VisionContent: Encodable {
            let type: String
            let text: String?
            let image_url: ImageURL?
            
            struct ImageURL: Encodable { let url: String }
            
            static func plainText(_ t: String) -> VisionContent {
                .init(type: "text", text: t, image_url: nil)
            }
            
            static func visionImage(base64: String) -> VisionContent {
                let uri = "data:image/jpeg;base64,\(base64)"
                return .init(type: "image_url", text: nil, image_url: .init(url: uri))
            }
        }
        
        struct Message: Encodable {
            let role: String
            let content: [VisionContent]
        }
        
        struct ChatPayload: Encodable {
            let model: String
            let temperature: Double
            let messages: [Message]
        }
        
        // Use provided prompt or default from OpenAIPrompts.shared
        let finalPrompt = prompt ?? OpenAIPrompts.shared.defaultTextPrompt
        let payload = ChatPayload(
            model: "gpt-4o-mini",
            temperature: 0.2,
            messages: [
                .init(
                    role: "system",
                    content: [
                        .plainText("You are a helpful assistant that returns JSON only.")
                    ]
                ),
                .init(
                    role: "user",
                    content: [
                        .plainText(finalPrompt),
                        .visionImage(base64: base64String)
                    ]
                )
            ]
        )
        
        let encodedPayload: Data
        do {
            encodedPayload = try JSONEncoder().encode(payload)
        } catch {
            print("[OpenAIService]    ERROR: Failed to JSON‐encode payload: \(error)")
            throw error
        }
        
        print("[OpenAIService]    POST \(endpoint)")
        print("[OpenAIService]    JSON payload byte‐count: \(encodedPayload.count)")
        request.httpBody = encodedPayload
        
        // 3) Send the request
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            print("[OpenAIService]    ERROR: Response was not HTTPURLResponse")
            throw OpenAIError.invalidResponse
        }
        
        print("[OpenAIService]    HTTP Status Code: \(httpResponse.statusCode)")
        if httpResponse.statusCode != 200 {
            let serverMsg = String(data: data, encoding: .utf8) ?? "<unreadable data>"
            print("[OpenAIService]    ERROR \(httpResponse.statusCode): \(serverMsg)")
            throw OpenAIError.httpError(code: httpResponse.statusCode, message: serverMsg)
        }
        
        // 4) Decode the chat reply
        struct ChatReply: Decodable {
            struct Choice: Decodable {
                struct Message: Decodable { let content: String }
                let message: Message
            }
            let choices: [Choice]
        }
        
        let decoder = JSONDecoder()
        let chatReply: ChatReply
        do {
            chatReply = try decoder.decode(ChatReply.self, from: data)
        } catch {
            let raw = String(data: data, encoding: .utf8) ?? "<invalid UTF8>"
            print("[OpenAIService]    JSON decode error: \(error). Response:\n\(raw)")
            throw error
        }
        
        guard var rawContent = chatReply.choices.first?.message.content else {
            print("[OpenAIService]    ERROR: No “content” field in choices[0].message")
            throw OpenAIError.visionChatDidNotReturnContent
        }

        // ── STRIP POSSIBLE MARKDOWN FENCING: remove leading/trailing ```json … ```
        rawContent = rawContent.trimmingCharacters(in: .whitespacesAndNewlines)
        if rawContent.hasPrefix("```") {
            // Remove the first line of backticks (``` or ```json) and the trailing ```
            // Find first newline, then find last occurrence of ```
            if let firstNewline = rawContent.firstIndex(of: "\n"),
               let lastFenceRange = rawContent.range(of: "```", options: .backwards) {
                // Extract substring between them
                let innerRange = rawContent.index(after: firstNewline)..<lastFenceRange.lowerBound
                let stripped = rawContent[innerRange]
                rawContent = String(stripped).trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }

        print("[OpenAIService]    Raw assistant JSON:\n\(rawContent)")

        // 5) Convert to Data, then decode AnalysisResult
        guard let jsonData = rawContent.data(using: .utf8) else {
            print("[OpenAIService]    ERROR: Failed to convert assistant’s content to UTF‐8 Data")
            throw OpenAIError.unexpectedResponseFormat
        }
        
        do {
            let analysis = try decoder.decode(AnalysisResult.self, from: jsonData)
            print("[OpenAIService]    Success → AnalysisResult(title: \(analysis.title))")
            return analysis
        } catch {
            let raw = String(data: jsonData, encoding: .utf8) ?? "<invalid UTF8>"
            print("[OpenAIService]    ERROR: Failed to decode AnalysisResult: \(error). JSON was:\n\(raw)")
            throw error
        }
    }
    
    /// Generates a brand-new image from a pure text prompt using DALL·E.
    /// Uses `OpenAIPrompts.shared.defaultImagePrompt` if no prompt is provided.
    /// Returns the URL of the generated image.
    func generateImageFromText(
        prompt: String? = nil,
        size: Int = 256
    ) async throws -> URL {
        // 1) Build JSON payload for /v1/images/generations
        //    { "model": "dall-e-2", "prompt": "...", "n": 1, "size": "256x256" }
        let endpoint = "https://api.openai.com/v1/images/generations"
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        struct Payload: Encodable {
            let model: String
            let prompt: String
            let n: Int
            let size: String
        }
        
        // Use provided prompt or default from OpenAIPrompts.shared
        let finalPrompt = prompt ?? OpenAIPrompts.shared.defaultImagePrompt
        let sizeString = "\(size)x\(size)"
        let payload = Payload(model: "dall-e-2", prompt: finalPrompt, n: 1, size: sizeString)
        
        let encodedPayload: Data
        do {
            encodedPayload = try JSONEncoder().encode(payload)
        } catch {
            print("[OpenAIService]    ERROR: Failed to JSON‐encode text‐to‐image payload: \(error)")
            throw error
        }
        
        print("[OpenAIService] → generateImageFromText START")
        print("[OpenAIService]    apiKey (prefix): \(apiKey.prefix(5))…")
        print("[OpenAIService]    POST \(endpoint)")
        print("[OpenAIService]    Prompt length: \(finalPrompt.count) chars, size: \(sizeString)")
        print("[OpenAIService]    JSON payload byte‐count: \(encodedPayload.count)")
        
        request.httpBody = encodedPayload
        
        // 2) Send the request
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            print("[OpenAIService]    Response was not HTTPURLResponse")
            throw OpenAIError.invalidResponse
        }
        
        print("[OpenAIService]    HTTP Status Code: \(httpResponse.statusCode)")
        if httpResponse.statusCode != 200 {
            let serverMsg = String(data: data, encoding: .utf8) ?? "<unreadable data>"
            print("[OpenAIService]    ERROR \(httpResponse.statusCode): \(serverMsg)")
            throw OpenAIError.httpError(code: httpResponse.statusCode, message: serverMsg)
        }
        
        // 3) Decode the JSON reply
        struct GenerationReply: Decodable {
            struct Item: Decodable { let url: URL }
            let data: [Item]
        }
        
        do {
            let reply = try JSONDecoder().decode(GenerationReply.self, from: data)
            guard let outURL = reply.data.first?.url else {
                print("[OpenAIService]    ERROR: no URL returned from text-to-image")
                throw OpenAIError.noImageReturned
            }
            print("[OpenAIService]    Success → generated image URL: \(outURL.absoluteString)")
            return outURL
        } catch {
            let raw = String(data: data, encoding: .utf8) ?? "<invalid UTF8>"
            print("[OpenAIService]    JSON decode error (text-to-image): \(error). Response:\n\(raw)")
            throw error
        }
    }
}
