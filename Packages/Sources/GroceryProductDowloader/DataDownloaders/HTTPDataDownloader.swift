import Foundation

public actor HTTPDataDownloader: DataDownloader {
    private let session: URLSession
    private let timeout: TimeInterval
    
    public init(timeout: TimeInterval = 30.0) {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = timeout
        config.timeoutIntervalForResource = timeout * 2
        self.session = URLSession(configuration: config)
        self.timeout = timeout
    }
    
    public func download(from url: URL) async throws -> RawData {
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw DownloadError.invalidResponse
        }
        
        guard 200...299 ~= httpResponse.statusCode else {
            throw DownloadError.httpError(httpResponse.statusCode)
        }
        
        let contentType = httpResponse.value(forHTTPHeaderField: "Content-Type") ?? "application/octet-stream"
        let encoding = extractEncoding(from: contentType)
        
        // Convert HTTP headers to [String: String]
        let stringHeaders = httpResponse.allHeaderFields.compactMap { (key, value) -> (String, String)? in
            guard let stringKey = key as? String, let stringValue = value as? String else {
                return nil
            }
            return (stringKey, stringValue)
        }
        let metadata = Dictionary(uniqueKeysWithValues: stringHeaders)
        
        return RawData(
            content: data,
            url: url,
            contentType: contentType,
            encoding: encoding,
            metadata: metadata
        )
    }
    
    public func downloadText(from url: URL, encoding: String.Encoding = .utf8) async throws -> String {
        let rawData = try await download(from: url)
        guard let text = String(data: rawData.content, encoding: encoding) else {
            throw DownloadError.encodingError
        }
        return text
    }
    
    public func downloadBinary(from url: URL) async throws -> Data {
        let rawData = try await download(from: url)
        return rawData.content
    }
    
    private func extractEncoding(from contentType: String) -> String.Encoding {
        if contentType.contains("charset=utf-8") {
            return .utf8
        } else if contentType.contains("charset=windows-1250") {
            return .windowsCP1250
        } else if contentType.contains("charset=iso-8859-2") {
            return .isoLatin2
        }
        return .utf8
    }
}
