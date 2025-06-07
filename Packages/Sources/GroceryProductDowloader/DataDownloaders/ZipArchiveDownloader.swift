import Foundation

/// For stores like Lidl, Plodine that package data in ZIP files
public actor ZipArchiveDownloader: ArchiveBasedDownloader {
    private let httpDownloader: HTTPDataDownloader
    private let zipExtractor: ZipExtractor
    
    public init() {
        self.httpDownloader = HTTPDataDownloader()
        self.zipExtractor = ZipExtractor()
    }
    
    public func downloadAndExtractArchive(from url: URL, fileExtension: String = ".csv") async throws -> [RawData] {
        let zipData = try await httpDownloader.downloadBinary(from: url)
        
        // Clean up file extension (remove dot if present)
        let cleanExtension = fileExtension.replacingOccurrences(of: ".", with: "")
        
        return try await zipExtractor.extractToRawData(
            from: zipData,
            sourceURL: url,
            fileExtensions: [cleanExtension]
        )
    }
    
    public func downloadForDate(_ date: Date, provider: GroceryProductProvider) async throws -> [RawData] {
        let zipURL = buildZipURL(for: date, provider: provider)
        return try await downloadAndExtractArchive(from: zipURL)
    }
    
    private func buildZipURL(for date: Date, provider: GroceryProductProvider) -> URL {
        let dateFormatter = DateFormatter()
        
        switch provider {
        case .lidl:
            dateFormatter.dateFormat = "d_M_yyyy"
            let dateString = dateFormatter.string(from: date)
            return URL(string: "https://tvrtka.lidl.hr/cijene/Popis_cijena_po_trgovinama_na_dan_\(dateString).zip")!
            
        case .plodine:
            dateFormatter.dateFormat = "dd_MM_yyyy"
            let dateString = dateFormatter.string(from: date)
            return URL(string: "https://www.plodine.hr/info-o-cijenama/cjenici/cjenici_\(dateString)_*.zip")!
            
        case .studenac:
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let dateString = dateFormatter.string(from: date)
            return URL(string: "https://www.studenac.hr/cjenici/PROIZVODI-\(dateString).zip")!
            
        default:
            fatalError("Provider \(provider) not supported by ZipArchiveDownloader")
        }
    }
}
