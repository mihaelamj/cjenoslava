import Foundation
// MARK: - Parser Protocol

// swiftlint:disable all
public protocol DataParser {
    func parseProducts(from data: Data, provider: ShopProvider) async throws -> [UnifiedProduct]
}

// MARK: - Parser Errors

public enum ParserError: Error, LocalizedError {
    case invalidData
    case unsupportedFormat
    case parsingFailed(String)
    case noDataFound
    case networkError(Error)
    
    public var errorDescription: String? {
        switch self {
        case .invalidData:
            return "Invalid data format"
        case .unsupportedFormat:
            return "Unsupported data format"
        case .parsingFailed(let details):
            return "Parsing failed: \(details)"
        case .noDataFound:
            return "No data found"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}
