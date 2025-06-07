import Foundation

public protocol DataDownloader: Sendable {
    func download(from url: URL) async throws -> RawData
    func downloadText(from url: URL, encoding: String.Encoding) async throws -> String
    func downloadBinary(from url: URL) async throws -> Data
}


public protocol IndexBasedDownloader: Sendable {
    func findDataURLs(for request: StoreDataRequest) async throws -> [URL]
    func downloadFromIndex(for request: StoreDataRequest) async throws -> [RawData]
}

/// Protocol for providers that serve data through APIs
public protocol APIBasedDownloader: Sendable {
    func fetchFromAPI(for request: StoreDataRequest) async throws -> [RawData]
}

/// Protocol for providers that package data in archives
public protocol ArchiveBasedDownloader: Sendable {
    func downloadAndExtractArchive(from url: URL, fileExtension: String) async throws -> [RawData]
}

/// Protocol for providers with special data formats
public protocol SpecialFormatDownloader: Sendable {
    func downloadSpecialFormat(for request: StoreDataRequest) async throws -> [RawData]
}
