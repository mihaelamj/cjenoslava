import Foundation
import GroceryProduct

public actor GroceryDataDownloader {
    
    public init() {}
    
    public func downloadData(for request: StoreDataRequest) async throws -> [RawData] {
        let downloader = DownloaderFactory.createDownloader(for: request.provider)
        
        switch downloader {
        case let indexDownloader as IndexCSVDownloader:
            return try await indexDownloader.downloadFromIndex(for: request)
            
        case let apiDownloader as JSONAPIDownloader:
            return try await apiDownloader.fetchFromAPI(for: request)
            
        case let specialDownloader as SpecialDMDownloader:
            return try await specialDownloader.downloadSpecialFormat(for: request)
            
        case let xmlDownloader as XMLDownloader:
            return try await xmlDownloader.downloadSpecialFormat(for: request)
            
        case let archiveDownloader as ZipArchiveDownloader:
            return try await archiveDownloader.downloadForDate(request.date, provider: request.provider)
            
        default:
            throw DownloadError.dataNotFound
        }
    }
}

