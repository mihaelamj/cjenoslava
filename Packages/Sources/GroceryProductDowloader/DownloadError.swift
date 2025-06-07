import Foundation

public enum DownloadError: Error, LocalizedError {
    case invalidResponse
    case httpError(Int)
    case encodingError
    case invalidJSON
    case dataNotFound
    
    public var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid HTTP response"
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .encodingError:
            return "Text encoding error"
        case .invalidJSON:
            return "Invalid JSON format"
        case .dataNotFound:
            return "Requested data not found"
        }
    }
}
