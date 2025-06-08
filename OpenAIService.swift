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

    
    func analyzeImageWithVisionChat(
        _ image: UIImage,
        prompt: String? = nil
    ) async throws -> AnalysisResult {
        print("[OpenAIService] → analyzeImageWithVisionChat START (model: \(self.chatModel))")
        
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
        
        struct VisionContent: Encodable {
            let type: String
            let text: String?
            let image_url: ImageURL?
            
            struct ImageURL: Encodable {
                let url: String
                let detail: String?
                init(url: String, detail: String? = "auto") {
                    self.url = url
                    self.detail = detail
                }
            }
            
            static func plainText(_ t: String) -> VisionContent { .init(type: "text", text: t, image_url: nil) }
            static func visionImage(base64: String, detail: String = "auto") -> VisionContent {
                .init(type: "image_url", text: nil, image_url: .init(url: "data:image/jpeg;base64,\(base64)", detail: detail))
            }
        }
        
        struct Message: Encodable { let role: String; let content: [VisionContent] }
        struct ResponseFormat: Encodable { let type: String }
        struct ChatPayload: Encodable {
            let model: String
            let temperature: Double
            let messages: [Message]
            let response_format: ResponseFormat?
            let max_tokens: Int?
        }
        
        let finalPrompt = prompt ?? OpenAIPrompts.shared.defaultTextPrompt
        let payload = ChatPayload(
            model: self.chatModel,
            temperature: 0.2,
            messages: [
                .init(role: "system", content: [.plainText("You are an expert assistant that analyzes images and ALWAYS returns a response in valid, minified JSON format as specified by the user. Do not include any markdown fences like ```json or ``` around the JSON output.")]),
                .init(role: "user", content: [.plainText(finalPrompt), .visionImage(base64: base64String, detail: "auto")])
            ],
            response_format: .init(type: "json_object"),
            max_tokens: 2048
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
            let analysis = try decoder.decode(AnalysisResult.self, from: jsonData)
            print("[OpenAIService]     Success → AnalysisResult(title: \(analysis.title))")
            return analysis
        } catch {
            let raw = String(data: jsonData, encoding: .utf8) ?? "<invalid UTF8>"
            print("[OpenAIService]     ERROR: Failed to decode AnalysisResult: \(error). JSON was:\n\(raw)")
            throw OpenAIError.jsonDecodingError(error, raw)
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
