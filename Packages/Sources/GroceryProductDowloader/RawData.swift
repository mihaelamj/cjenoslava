import Foundation

public struct RawData: Sendable {
    public let content: Data
    public let url: URL
    public let contentType: String
    public let encoding: String.Encoding
    public let metadata: [String: String]
    
    public init(content: Data, url: URL, contentType: String = "application/octet-stream",
                encoding: String.Encoding = .utf8, metadata: [String: String] = [:]) {
        self.content = content
        self.url = url
        self.contentType = contentType
        self.encoding = encoding
        self.metadata = metadata
    }
    
    public var text: String? {
        return String(data: content, encoding: encoding)
    }
}
