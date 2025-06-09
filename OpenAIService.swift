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
//  API key is now fetched internally from Info.plist.
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
        case jsonDecodingError(Error, String)
        case apiKeyNotFound // New error case
    }
    
    // ─────────────────────────────────────────────────────────────
    // MARK: – Properties
    
    private let apiKey: String
    private let session: URLSession
    
    /// Model to use for chat/vision calls (e.g. “gpt-4o”, “gpt-4o-mini”)
    private let chatModel: String
    
    /// Model to use for image-generation calls (e.g. “dall-e-3”, “dall-e-2”)
    private let imageModel: String

    // Static function to retrieve the API key from Info.plist
    private static func getOpenAIAPIKey() throws -> String {
        let apiKey = APIKeys.openAI

        // Ensure the key isn't an unresolved placeholder or empty
        if apiKey.isEmpty || apiKey.contains("YOUR_API_KEY") || apiKey.contains("PLACEHOLDER") {
            let errorMessage = """
            [OpenAIService] CRITICAL ERROR: API Key in APIKey.swift is a placeholder, empty, or invalid.
            Value found: '\(apiKey)'.
            Please ensure APIKey.swift contains your valid OpenAI API key.
            """
            print(errorMessage)
            // Consider logging this error to your analytics if you have one
            throw OpenAIError.apiKeyNotFound // Or a more specific error like .apiKeyInvalid
        }
        return apiKey
    }
    
    /// Initialize with dynamic model IDs. If you do not explicitly pass models, defaults are:
    ///   - chatModel: “gpt-4o-mini”
    ///   - imageModel: “dall-e-3”
    /// API key is now fetched internally.
    init(
        chatModel: String = "gpt-4o-mini", // Sensible default
        imageModel: String = "dall-e-3",   // Sensible default
        session: URLSession = .shared
    ) throws { // Changed to throwing init in case API key retrieval fails
        // Fetch the API key. If it fails, the initializer throws.
        // This ensures an OpenAIService instance is only created if an API key is available.
        self.apiKey = try OpenAIService.getOpenAIAPIKey()
        
        self.chatModel = chatModel
        self.imageModel = imageModel
        self.session = session
        
        print("[OpenAIService] Initialized. API Key loaded (prefix: \(self.apiKey.prefix(5))...), Chat Model: \(self.chatModel), Image Model: \(self.imageModel)")
    }
    
    // ─────────────────────────────────────────────────────────────
    // MARK: – Public Methods
    
    /// 1) Crop+resize the input image to a PNG under 4 MB,
    /// 2) Send it to DALL·E’s Variations endpoint (currently “dall-e-2” only),
    /// 3) Return the new image URL.
    /// Note: This function is specific to DALL·E 2's variation endpoint.
    func generateImageVariation(from image: UIImage) async throws -> URL {
        print("[OpenAIService] → generateImageVariation START (Using DALL·E 2 for variations)")
        // apiKey is now an instance property, no need to log prefix again if done in init

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
        let endpoint = "https://api.openai.com/v1/images/variations"
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(self.apiKey)", forHTTPHeaderField: "Authorization") // Use instance apiKey

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

        addFormField(
            name: "image",
            filename: "image.png",
            contentType: "image/png",
            data: pngData
        )
        addFormField(name: "n",       data: Data("1".utf8))
        addFormField(name: "size",    data: Data("\(Int(chosenSide))x\(Int(chosenSide))".utf8))
        addFormField(name: "model",   data: Data("dall-e-2".utf8))

        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body

        print("[OpenAIService]     POST \(endpoint)")
        print("[OpenAIService]     Body length: \(body.count) bytes")

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
    
    // MARK: - New Pokémon-Style Card Data Generation Pipeline

    /// New orchestrator method for the Pokémon-style card generation.
    /// 1. Analyzes image for base details (subject, type, stats) using vision.
    /// 2. Generates a title using a text prompt.
    /// 3. Generates a stats JSON string using a text prompt.
    /// 4. Renders an art prompt string locally.
    public func generateCardDataFromImage(image: UIImage) async throws -> (title: String, statsJSON: String, artPrompt: String, analysisData: InitialAnalysisData) {
        print("[OpenAIService] → generateCardDataFromImage START")

        // Step 1: Analyze image for base details
        print("[OpenAIService]     Step 1: Analyzing image for initial data...")
        let initialAnalysis = try await analyzeImageForInitialData(image)
        print("[OpenAIService]     Step 1: DONE. Subject: \(initialAnalysis.subject), Type: \(initialAnalysis.type)")

        // Prepare payload for prompt rendering - converting InitialAnalysisData to [String: Any]
        // This is needed because CardRecipe.render expects [String: Any]
        let analysisPayload: [String: Any] = [
            "subject": initialAnalysis.subject,
            "visualTraits": initialAnalysis.visualTraits,
            "type": initialAnalysis.type,
            "strength": initialAnalysis.strength,
            "stamina": initialAnalysis.stamina,
            "agility": initialAnalysis.agility
        ]

        // Step 2: Generate Title
        print("[OpenAIService]     Step 2: Generating title...")
        let titleSystemPrompt = OpenAIPrompts.shared.cardPrompt(.title, with: analysisPayload)
        let generatedTitle = try await generateTextFromPrompt(titleSystemPrompt)
        print("[OpenAIService]     Step 2: DONE. Title: \(generatedTitle)")

        // Step 3: Generate Stats JSON
        print("[OpenAIService]     Step 3: Generating stats JSON...")
        let statsSystemPrompt = OpenAIPrompts.shared.cardPrompt(.statsJSON, with: analysisPayload)
        let generatedStatsJSON = try await generateTextFromPrompt(statsSystemPrompt)
        print("[OpenAIService]     Step 3: DONE. Stats JSON: \(generatedStatsJSON.prefix(100))...")

        // Step 4: Render Art Prompt
        print("[OpenAIService]     Step 4: Rendering art prompt...")
        let artPromptString = OpenAIPrompts.shared.cardPrompt(.artPrompt, with: analysisPayload)
        print("[OpenAIService]     Step 4: DONE. Art Prompt: \(artPromptString.prefix(100))...")

        print("[OpenAIService] → generateCardDataFromImage END")
        return (title: generatedTitle, statsJSON: generatedStatsJSON, artPrompt: artPromptString, analysisData: initialAnalysis)
    }

    /// Renamed and repurposed from analyzeImageWithVisionChat.
    /// This method now specifically uses OpenAIPrompts.shared.analysePrompt
    /// and decodes the result into InitialAnalysisData.
    private func analyzeImageForInitialData(
        _ image: UIImage
    ) async throws -> InitialAnalysisData {
        print("[OpenAIService] → analyzeImageForInitialData START (model: \(self.chatModel))")
        
        let base64String: String = try await Task.detached(priority: .userInitiated) {
            guard let jpegData = image.jpegData(compressionQuality: 0.7) else {
                print("[OpenAIService]     FAILED: jpegData() returned nil")
                throw OpenAIError.failedToEncodeJPEG
            }
            print("[OpenAIService]     JPEG byte-count: \(jpegData.count)")
            return jpegData.base64EncodedString()
        }.value
        
        let endpoint = "https://api.openai.com/v1/chat/completions"
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(self.apiKey)", forHTTPHeaderField: "Authorization") // Use instance apiKey
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Define parts for the multimodal message content
        struct TextContentPart: Encodable {
            let type: String = "text"
            let text: String
        }

        struct ImageURLContentPart: Encodable {
            let type: String = "image_url"
            struct ImageURLData: Encodable {
                let url: String
                let detail: String?
            }
            let image_url: ImageURLData
        }

        // Enum to hold different content part types
        enum MessageContentPart: Encodable {
            case text(TextContentPart)
            case imageUrl(ImageURLContentPart)

            func encode(to encoder: Encoder) throws {
                var container = encoder.singleValueContainer()
                switch self {
                case .text(let textPart):
                    try container.encode(textPart)
                case .imageUrl(let imageUrlPart):
                    try container.encode(imageUrlPart)
                }
            }
        }
        
        struct Message: Encodable {
            let role: String
            let content: [MessageContentPart]
        }

        struct ResponseFormat: Encodable { let type: String }
        struct ChatPayload: Encodable {
            let model: String
            let temperature: Double
            let messages: [Message]
            let response_format: ResponseFormat? // Make optional if not always used
            let max_tokens: Int?
        }
        
        let systemMessageText = "You are an expert assistant that analyzes images and ALWAYS returns a response in valid, minified JSON format as specified by the user. Do not include any markdown fences like ```json or ``` around the JSON output."
        let userPromptText = OpenAIPrompts.shared.analysePrompt

        let payload = ChatPayload(
            model: self.chatModel,
            temperature: 0.2, // Low temperature for predictable JSON
            messages: [
                Message(role: "system", content: [
                    .text(TextContentPart(text: systemMessageText))
                ]),
                Message(role: "user", content: [
                    .text(TextContentPart(text: userPromptText)),
                    .imageUrl(ImageURLContentPart(image_url: .init(url: "data:image/jpeg;base64,\(base64String)", detail: "auto")))
                ])
            ],
            response_format: ResponseFormat(type: "json_object"),
            max_tokens: 2048 // Adjust as needed
        )
        
        let encodedPayload = try JSONEncoder().encode(payload)
        print("[OpenAIService]     POST \(endpoint)  (model: \(self.chatModel))")
        print("[OpenAIService]     JSON payload byte-count: \(encodedPayload.count)")
        request.httpBody = encodedPayload
        
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
        
        struct ChatReply: Decodable {
            struct Choice: Decodable { struct Message: Decodable { let content: String? }; let message: Message }
            let choices: [Choice]
        }
        
        let decoder = JSONDecoder()
        let chatReply = try decoder.decode(ChatReply.self, from: data)
        
        guard var rawContent = chatReply.choices.first?.message.content else {
            let raw = String(data: data, encoding: .utf8) ?? "<invalid UTF8>"
            print("[OpenAIService]     ERROR: No “content” field or content is null. Response:\n\(raw)")
            throw OpenAIError.visionChatDidNotReturnContent
        }

        rawContent = rawContent.trimmingCharacters(in: .whitespacesAndNewlines)
        if rawContent.hasPrefix("```json") {
            rawContent = String(rawContent.dropFirst(7).reversed().drop(while: { $0 == "`" }).reversed())
        } else if rawContent.hasPrefix("```") && rawContent.hasSuffix("```") {
             if let firstNewline = rawContent.firstIndex(of: "\n"), let lastFenceRange = rawContent.range(of: "```", options: .backwards) {
                 if firstNewline < lastFenceRange.lowerBound {
                     let innerRange = rawContent.index(after: firstNewline)..<lastFenceRange.lowerBound
                     rawContent = String(rawContent[innerRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                 } else { // Only one line of ```, likely just the fence itself
                    rawContent = String(rawContent.dropFirst(3).reversed().drop(while: { $0 == "`" }).reversed())
                 }
             } else { // Fallback if structure is unexpected
                 rawContent = rawContent.replacingOccurrences(of: "```json", with: "").replacingOccurrences(of: "```", with: "")
             }
        }
        rawContent = rawContent.trimmingCharacters(in: .whitespacesAndNewlines)

        print("[OpenAIService]     Raw assistant JSON (after stripping):\n\(rawContent)")

        guard let jsonData = rawContent.data(using: .utf8) else {
            print("[OpenAIService]     ERROR: Failed to convert assistant’s content to UTF-8 Data. Content: \(rawContent)")
            throw OpenAIError.unexpectedResponseFormat
        }
        
        do {
            let decodedResult = try decoder.decode(InitialAnalysisData.self, from: jsonData)
            print("[OpenAIService]     Successfully decoded JSON into InitialAnalysisData.")
            return decodedResult
        } catch {
            let raw = String(data: jsonData, encoding: .utf8) ?? "<invalid UTF8>"
            print("[OpenAIService]     ERROR: Failed to decode AnalysisResult: \(error). JSON was:\n\(raw)")
            throw OpenAIError.jsonDecodingError(error, raw)
        }
    }

    /// Private helper to make a text-only chat completion request to OpenAI.
    private func generateTextFromPrompt(_ systemPrompt: String) async throws -> String {
        print("[OpenAIService] → generateTextFromPrompt START (model: \(self.chatModel))")
        print("[OpenAIService]     System Prompt: \(systemPrompt.prefix(200))...")

        let endpoint = "https://api.openai.com/v1/chat/completions"
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(self.apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload: [String: Any] = [
            "model": self.chatModel,
            "messages": [
                ["role": "system", "content": systemPrompt]
            ],
            "max_tokens": 500 // Adjust as needed for title/stats generation
        ]

        let jsonData = try JSONSerialization.data(withJSONObject: payload)
        request.httpBody = jsonData

        let (responseData, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            print("[OpenAIService]     ERROR: Invalid response from server (not HTTPURLResponse)")
            throw OpenAIError.invalidResponse
        }

        print("[OpenAIService]     HTTP Status Code: \(httpResponse.statusCode)")

        if httpResponse.statusCode != 200 {
            let serverText = String(data: responseData, encoding: .utf8) ?? "<unreadable data>"
            print("[OpenAIService]     ERROR \(httpResponse.statusCode): \(serverText)")
            throw OpenAIError.httpError(code: httpResponse.statusCode, message: serverText)
        }

        // Parse the response JSON to extract the text content
        struct OpenAICompletionResponse: Decodable {
            struct Choice: Decodable {
                struct Message: Decodable {
                    let role: String?
                    let content: String
                }
                let message: Message
            }
            let choices: [Choice]
        }

        do {
            let openAIResponse = try JSONDecoder().decode(OpenAICompletionResponse.self, from: responseData)
            guard let firstChoiceContent = openAIResponse.choices.first?.message.content else {
                print("[OpenAIService]     ERROR: No content found in OpenAI response choices.")
                throw OpenAIError.visionChatDidNotReturnContent
            }
            print("[OpenAIService]     Successfully extracted text content: \(firstChoiceContent.prefix(100))...")
            print("[OpenAIService] → generateTextFromPrompt END")
            return firstChoiceContent.trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            let rawResponseString = String(data: responseData, encoding: .utf8) ?? "<unreadable data>"
            print("[OpenAIService]     ERROR: Failed to decode OpenAI response JSON or extract content. Error: \(error.localizedDescription). Raw response: \(rawResponseString.prefix(500))")
            throw OpenAIError.jsonDecodingError(error, rawResponseString)
        }
    }
    
    func generateImageFromText(
        prompt: String,
        size: Int = 1024,
        quality: String = "standard",
        style: String? = nil
    ) async throws -> URL {
        print("[OpenAIService] → generateImageFromText START (model: \(self.imageModel))")

        let endpoint = "https://api.openai.com/v1/images/generations"
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(self.apiKey)", forHTTPHeaderField: "Authorization") // Use instance apiKey
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        struct Payload: Encodable {
            let model: String
            let prompt: String
            let n: Int
            let size: String
            let quality: String?
            let style: String?
        }
        
        let sizeString: String
        switch self.imageModel {
        case "dall-e-3": sizeString = "1024x1024"
        case "dall-e-2":
            let validSizes = [256, 512, 1024]; let clampedSize = validSizes.contains(size) ? size : 1024
            sizeString = "\(clampedSize)x\(clampedSize)"
        default: sizeString = "\(size)x\(size)"
        }
        
        let payloadObject = Payload(
            model: self.imageModel, prompt: prompt, n: 1, size: sizeString,
            quality: self.imageModel == "dall-e-3" ? quality : nil,
            style: self.imageModel == "dall-e-3" ? style : nil
        )
        
        let encodedPayload = try JSONEncoder().encode(payloadObject)
        print("[OpenAIService]     POST \(endpoint)")
        print("[OpenAIService]     Using model: \(self.imageModel), Prompt: \"\(prompt.prefix(50))...\", Size: \(sizeString), Quality: \(quality), Style: \(style ?? "default")")
        print("[OpenAIService]     JSON payload byte-count: \(encodedPayload.count)")
        request.httpBody = encodedPayload
        
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
        
        struct GenerationReply: Decodable { struct Item: Decodable { let url: URL }; let data: [Item] }
        
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
