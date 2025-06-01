//
//  OpenAIService.swift
//  YourAppTarget
//
//  A combined service for:
//    1) DALL·E “variations” (generateImageVariation) - Note: DALL-E 2 only for this endpoint
//    2) Vision-Chat analysis (analyzeImageWithVisionChat)
//    3) DALL·E text-to-image (generateImageFromText)
//
//  Now supports injecting dynamic model IDs for both chat/vision and image generation.
//
//  References:
//    • GPT-4 Series (chat/vision): e.g., "gpt-4o", "gpt-4o-mini", "gpt-4-turbo"
//    • DALL·E Series (image): "dall-e-3", "dall-e-2"
//

import Foundation
import UIKit

/// Service wrapper around OpenAI API for:
/// 1) DALL·E “variations” (DALL·E 2 only)
/// 2) Vision-Chat analysis
/// 3) DALL·E / GPT-Image text-to-image
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
        case jsonDecodingError(Error, String) // Added for better debugging
    }
    
    // ─────────────────────────────────────────────────────────────
    // MARK: – Properties
    
    private let apiKey: String
    private let session: URLSession
    
    /// Model to use for chat/vision calls (e.g. “gpt-4o”, “gpt-4o-mini”)
    private let chatModel: String
    
    /// Model to use for image-generation calls (e.g. “dall-e-3”, “dall-e-2”)
    private let imageModel: String
    
    /// Initialize with dynamic model IDs. If you do not explicitly pass models, defaults are:
    ///   - chatModel: “gpt-4o-mini”
    ///   - imageModel: “dall-e-3”
    init(
        apiKey: String,
        chatModel: String = "gpt-4o-mini", // Sensible default
        imageModel: String = "dall-e-3",   // Sensible default
        session: URLSession = .shared
    ) {
        self.apiKey = apiKey
        self.chatModel = chatModel
        self.imageModel = imageModel
        self.session = session
    }
    
    // ─────────────────────────────────────────────────────────────
    // MARK: – Public Methods
    
    /// 1) Crop+resize the input image to a PNG under 4 MB,
    /// 2) Send it to DALL·E’s Variations endpoint (currently “dall-e-2” only),
    /// 3) Return the new image URL.
    /// Note: This function is specific to DALL·E 2's variation endpoint.
    func generateImageVariation(from image: UIImage) async throws -> URL {
        print("[OpenAIService] → generateImageVariation START (Using DALL·E 2 for variations)")
        print("[OpenAIService]     apiKey (prefix): \(apiKey.prefix(5))…")

        // Maximum allowed PNG size (4 MB):
        let maxPNGBytes = 4 * 1_024 * 1_024

        // Candidate side lengths (in pixels), largest to smallest.
        let candidateSides: [CGFloat] = [1024, 512, 256, 128]

        // 1) Crop original UIImage to a square CGImage once
        let squareCGImage: CGImage = try await Task.detached(priority: .userInitiated) {
            let side = min(image.size.width, image.size.height)
            let cropRect = CGRect(
                x: (image.size.width - side) / 2,
                y: (image.size.height - side) / 2,
                width: side,
                height: side
            )
            guard let cgCropped = image.cgImage?.cropping(to: cropRect) else {
                print("[OpenAIService]     FAILED: cropping returned nil")
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
                    print("[OpenAIService]     FAILED: pngData() returned nil at side \(side)")
                    throw OpenAIError.failedToEncodePNG
                }
                return png
            }.value

            print("[OpenAIService]     Trying side \(Int(side)) px → PNG is \(pngDataForSide.count / 1_024) KB")

            if pngDataForSide.count <= maxPNGBytes {
                finalPNGData = pngDataForSide
                chosenSide = side
                break
            }
        }

        guard let pngData = finalPNGData else {
            let errorMsg = "All resized PNGs (down to 128×128) exceed 4 MB."
            print("[OpenAIService]     ERROR: \(errorMsg)")
            throw OpenAIError.httpError(code: 400, message: errorMsg) // Simulate client error
        }

        print("[OpenAIService]     Selected side \(Int(chosenSide)) px → final PNG byte-count: \(pngData.count) bytes")

        // 3) Build multipart/form-data request
        // Note: Variations endpoint only supports “dall-e-2” on the server side.
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
        addFormField(name: "model",   data: Data("dall-e-2".utf8)) // Hardcoded for variations API

        // Close multipart
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body

        print("[OpenAIService]     POST \(endpoint)")
        print("[OpenAIService]     Body length: \(body.count) bytes")

        // 4) Send request and parse response
        let (responseData, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            print("[OpenAIService]     Response was not HTTPURLResponse")
            throw OpenAIError.invalidResponse
        }

        print("[OpenAIService]     HTTP Status Code: \(httpResponse.statusCode)")
        if httpResponse.statusCode != 200 {
            let serverText = String(data: responseData, encoding: .utf8) ?? "<unreadable data>"
            print("[OpenAIService]     ERROR \(httpResponse.statusCode): \(serverText)")
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
                print("[OpenAIService]     ERROR: no URL in data[]")
                throw OpenAIError.noImageReturned
            }
            print("[OpenAIService]     Success → image URL: \(firstURL.absoluteString)")
            return firstURL
        } catch {
            let raw = String(data: responseData, encoding: .utf8) ?? "<invalid UTF8>"
            print("[OpenAIService]     JSON decode error: \(error). Response was:\n\(raw)")
            throw OpenAIError.jsonDecodingError(error, raw)
        }
    }
    
    /// 1) JPEG → Base64 (background),
    /// 2) Send Vision-Chat prompt + Base64 image to Chat Completions,
    /// 3) Parse the assistant’s JSON-only response into AnalysisResult.
    /// Uses `OpenAIPrompts.shared.defaultTextPrompt` if no prompt is provided.
    func analyzeImageWithVisionChat(
        _ image: UIImage,
        prompt: String? = nil // This will be the body of the textPrompt from OpenAIPrompts
    ) async throws -> AnalysisResult {
        print("[OpenAIService] → analyzeImageWithVisionChat START (model: \(chatModel))")
        print("[OpenAIService]     apiKey (prefix): \(apiKey.prefix(5))…")
        
        // 1) JPEG → Base64 (background)
        let base64String: String = try await Task.detached(priority: .userInitiated) {
            guard let jpegData = image.jpegData(compressionQuality: 0.7) else { // Slightly lower quality for faster upload
                print("[OpenAIService]     FAILED: jpegData() returned nil")
                throw OpenAIError.failedToEncodeJPEG
            }
            print("[OpenAIService]     JPEG byte-count: \(jpegData.count)")
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
            
            struct ImageURL: Encodable {
                let url: String
                let detail: String? // Added for image detail control
                
                init(url: String, detail: String? = "auto") { // Default to auto, can be high/low
                    self.url = url
                    self.detail = detail
                }
            }
            
            static func plainText(_ t: String) -> VisionContent {
                .init(type: "text", text: t, image_url: nil)
            }
            
            static func visionImage(base64: String, detail: String = "auto") -> VisionContent {
                let uri = "data:image/jpeg;base64,\(base64)"
                return .init(type: "image_url", text: nil, image_url: .init(url: uri, detail: detail))
            }
        }
        
        struct Message: Encodable {
            let role: String
            let content: [VisionContent] // Can be array of text and image parts
        }
        
        // For GPT-4 Vision, we need to specify that the response should be JSON
        struct ResponseFormat: Encodable {
            let type: String // "json_object"
        }
        
        struct ChatPayload: Encodable {
            let model: String
            let temperature: Double
            let messages: [Message]
            let response_format: ResponseFormat? // For forcing JSON output
            let max_tokens: Int? // Good to set for JSON to avoid truncation
        }
        
        // Use provided prompt or default from OpenAIPrompts.shared
        let finalPrompt = prompt ?? OpenAIPrompts.shared.defaultTextPrompt
        let payload = ChatPayload(
            model: chatModel,        // ← dynamic chat model
            temperature: 0.2,
            messages: [
                .init(
                    role: "system",
                    content: [
                        // Instructing it to return JSON. The main prompt also specifies this.
                        .plainText("You are an expert assistant that analyzes images and ALWAYS returns a response in valid, minified JSON format as specified by the user. Do not include any markdown fences like ```json or ``` around the JSON output.")
                    ]
                ),
                .init(
                    role: "user",
                    content: [
                        .plainText(finalPrompt), // This prompt should clearly ask for JSON structure
                        .visionImage(base64: base64String, detail: "auto") // Use "high" for more detail if needed, but costs more
                    ]
                )
            ],
            response_format: .init(type: "json_object"), // Ensure JSON mode
            max_tokens: 2048 // Increased to ensure full JSON can be returned
        )
        
        let encodedPayload: Data
        do {
            encodedPayload = try JSONEncoder().encode(payload)
        } catch {
            print("[OpenAIService]     ERROR: Failed to JSON-encode payload: \(error)")
            throw error
        }
        
        print("[OpenAIService]     POST \(endpoint)  (model: \(chatModel))")
        // print("[OpenAIService]     JSON payload: \(String(data: encodedPayload, encoding: .utf8) ?? "Non-UTF8 payload")") // For debugging
        print("[OpenAIService]     JSON payload byte-count: \(encodedPayload.count)")
        request.httpBody = encodedPayload
        
        // 3) Send the request
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            print("[OpenAIService]     ERROR: Response was not HTTPURLResponse")
            throw OpenAIError.invalidResponse
        }
        
        print("[OpenAIService]     HTTP Status Code: \(httpResponse.statusCode)")
        if httpResponse.statusCode != 200 {
            let serverMsg = String(data: data, encoding: .utf8) ?? "<unreadable data>"
            print("[OpenAIService]     ERROR \(httpResponse.statusCode): \(serverMsg)")
            throw OpenAIError.httpError(code: httpResponse.statusCode, message: serverMsg)
        }
        
        // 4) Decode the chat reply
        struct ChatReply: Decodable {
            struct Choice: Decodable {
                struct Message: Decodable { let content: String? } // Content can be null
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
            print("[OpenAIService]     JSON decode error (ChatReply): \(error). Response:\n\(raw)")
            throw OpenAIError.jsonDecodingError(error, raw)
        }
        
        guard var rawContent = chatReply.choices.first?.message.content else {
            let raw = String(data: data, encoding: .utf8) ?? "<invalid UTF8>"
            print("[OpenAIService]     ERROR: No “content” field or content is null in choices[0].message. Response:\n\(raw)")
            throw OpenAIError.visionChatDidNotReturnContent
        }

        // OpenAI might still wrap with ```json ... ``` even with response_format.
        rawContent = rawContent.trimmingCharacters(in: .whitespacesAndNewlines)
        if rawContent.hasPrefix("```json") {
            rawContent = String(rawContent.dropFirst(7)) // Remove ```json
            if rawContent.hasSuffix("```") {
                rawContent = String(rawContent.dropLast(3)) // Remove ```
            }
        } else if rawContent.hasPrefix("```") {
             if let firstNewline = rawContent.firstIndex(of: "\n"),
                let lastFenceRange = rawContent.range(of: "```", options: .backwards) {
                 let innerRange = rawContent.index(after: firstNewline)..<lastFenceRange.lowerBound
                 let stripped = rawContent[innerRange]
                 rawContent = String(stripped).trimmingCharacters(in: .whitespacesAndNewlines)
             }
        }
        rawContent = rawContent.trimmingCharacters(in: .whitespacesAndNewlines)


        print("[OpenAIService]     Raw assistant JSON (after potential stripping):\n\(rawContent)")

        // 5) Convert to Data, then decode AnalysisResult
        guard let jsonData = rawContent.data(using: .utf8) else {
            print("[OpenAIService]     ERROR: Failed to convert assistant’s content to UTF-8 Data. Content was: \(rawContent)")
            throw OpenAIError.unexpectedResponseFormat
        }
        
        do {
            let analysis = try decoder.decode(AnalysisResult.self, from: jsonData)
            print("[OpenAIService]     Success → AnalysisResult(title: \(analysis.title))")
            return analysis
        } catch {
            let raw = String(data: jsonData, encoding: .utf8) ?? "<invalid UTF8>"
            print("[OpenAIService]     ERROR: Failed to decode AnalysisResult: \(error). JSON was:\n\(raw)")
            throw OpenAIError.jsonDecodingError(error, raw)
        }
    }
    
    /// Generates a brand-new image from a pure text prompt using the injected `imageModel`.
    /// Returns the URL of the generated image.
    func generateImageFromText(
        prompt: String, // Made non-optional, as it's crucial
        size: Int = 1024, // Default to DALL-E 3 common size
        quality: String = "standard", // "standard" or "hd" for DALL-E 3
        style: String? = nil // "vivid" or "natural" for DALL-E 3
    ) async throws -> URL {
        print("[OpenAIService] → generateImageFromText START (model: \(imageModel))")
        print("[OpenAIService]     apiKey (prefix): \(apiKey.prefix(5))…")

        // 1) Build JSON payload for /v1/images/generations
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
            let quality: String? // Optional: "standard" or "hd" (for DALL·E 3)
            let style: String?   // Optional: "vivid" or "natural" (for DALL·E 3)
        }
        
        let sizeString: String
        switch imageModel {
        case "dall-e-3":
            // DALL·E 3 accepts 1024x1024, 1792x1024, or 1024x1792
            // Forcing square for simplicity in this app
            sizeString = "1024x1024" // Or make this adaptable based on `size` input
        case "dall-e-2":
            // DALL·E 2 accepts 256x256, 512x512, or 1024x1024
            let validSizes = [256, 512, 1024]
            let clampedSize = validSizes.contains(size) ? size : 1024 // Default to 1024 if invalid
            sizeString = "\(clampedSize)x\(clampedSize)"
        default: // Assuming "gpt-image-1" or others might have own conventions or use OpenAI defaults
            sizeString = "\(size)x\(size)"
        }
        
        let payloadObject = Payload(
            model: imageModel,    // ← dynamic image model
            prompt: prompt,
            n: 1,
            size: sizeString,
            quality: imageModel == "dall-e-3" ? quality : nil, // Quality only for DALL·E 3
            style: imageModel == "dall-e-3" ? style : nil      // Style only for DALL·E 3
        )
        
        let encodedPayload: Data
        do {
            encodedPayload = try JSONEncoder().encode(payloadObject)
        } catch {
            print("[OpenAIService]     ERROR: Failed to JSON-encode text-to-image payload: \(error)")
            throw error
        }
        
        print("[OpenAIService]     POST \(endpoint)")
        print("[OpenAIService]     Using model: \(imageModel)")
        print("[OpenAIService]     Prompt length: \(prompt.count) chars, size: \(sizeString), quality: \(quality), style: \(style ?? "default")")
        // print("[OpenAIService]     JSON payload: \(String(data: encodedPayload, encoding: .utf8) ?? "Non-UTF8 payload")") // For debugging
        print("[OpenAIService]     JSON payload byte-count: \(encodedPayload.count)")
        request.httpBody = encodedPayload
        
        // 2) Send the request
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            print("[OpenAIService]     Response was not HTTPURLResponse")
            throw OpenAIError.invalidResponse
        }
        
        print("[OpenAIService]     HTTP Status Code: \(httpResponse.statusCode)")
        if httpResponse.statusCode != 200 {
            let serverMsg = String(data: data, encoding: .utf8) ?? "<unreadable data>"
            print("[OpenAIService]     ERROR \(httpResponse.statusCode): \(serverMsg)")
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
                print("[OpenAIService]     ERROR: no URL returned from text-to-image")
                throw OpenAIError.noImageReturned
            }
            print("[OpenAIService]     Success → generated image URL: \(outURL.absoluteString)")
            return outURL
        } catch {
            let raw = String(data: data, encoding: .utf8) ?? "<invalid UTF8>"
            print("[OpenAIService]     JSON decode error (text-to-image): \(error). Response:\n\(raw)")
            throw OpenAIError.jsonDecodingError(error, raw)
        }
    }
}
