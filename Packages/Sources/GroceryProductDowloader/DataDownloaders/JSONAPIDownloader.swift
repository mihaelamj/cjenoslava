import Foundation
import GroceryProduct

/// For stores like Tommy, Spar that use JSON APIs
public actor JSONAPIDownloader: APIBasedDownloader {
    private let httpDownloader: HTTPDataDownloader
    
    public init() {
        self.httpDownloader = HTTPDataDownloader()
    }
    
    public func fetchFromAPI(for request: StoreDataRequest) async throws -> [RawData] {
        let apiURL = buildAPIURL(for: request)
        let jsonData = try await httpDownloader.download(from: apiURL)
        
        // Parse JSON to find data URLs
        let dataURLs = try parseDataURLs(from: jsonData, provider: request.provider)
        
        // Download all data files
        var results: [RawData] = []
        for url in dataURLs {
            do {
                let data = try await httpDownloader.download(from: url)
                results.append(data)
            } catch {
                print("Failed to download \(url): \(error)")
                continue
            }
        }
        
        return results
    }
    
    private func buildAPIURL(for request: StoreDataRequest) -> URL {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: request.date)
        
        switch request.provider {
        case .tommy:
            return URL(string: "https://spiza.tommy.hr/api/v2/shop/store-prices-tables?date=\(dateString)&page=1&itemsPerPage=200&channelCode=general")!
            
        case .spar:
            dateFormatter.dateFormat = "yyyyMMdd"
            let sparDateString = dateFormatter.string(from: request.date)
            return URL(string: "https://www.spar.hr/datoteke_cjenici/Cjenik\(sparDateString).json")!
            
        default:
            fatalError("Provider \(request.provider) not supported by JSONAPIDownloader")
        }
    }
    
    private func parseDataURLs(from rawData: RawData, provider: GroceryProductProvider) throws -> [URL] {
        guard let json = try JSONSerialization.jsonObject(with: rawData.content) as? [String: Any] else {
            throw DownloadError.invalidJSON
        }
        
        var urls: [URL] = []
        
        switch provider {
        case .tommy:
            if let members = json["hydra:member"] as? [[String: Any]] {
                for member in members {
                    if let idPath = member["@id"] as? String {
                        let fullURL = "https://spiza.tommy.hr/api/v2" + idPath
                        if let url = URL(string: fullURL) {
                            urls.append(url)
                        }
                    }
                }
            }
            
        case .spar:
            if let files = json["files"] as? [[String: Any]] {
                for file in files {
                    if let urlString = file["URL"] as? String, let url = URL(string: urlString) {
                        urls.append(url)
                    }
                }
            }
            
        default:
            break
        }
        
        return urls
    }
}
