import Foundation

// MARK: - Store-Specific Downloader Protocols

protocol StoreDownloader {
    func downloadProducts(for date: Date) async throws -> [UnifiedProduct]
}

// MARK: - Tommy Downloader

class TommyDownloader: StoreDownloader {
    private let session: URLSession
    private let parser: DataParser
    
    init(session: URLSession, parser: DataParser) {
        self.session = session
        self.parser = parser
    }
    
    func downloadProducts(for date: Date) async throws -> [UnifiedProduct] {
        // Based on tommy.py implementation
        let dateString = ISO8601DateFormatter().string(from: date).prefix(10) // YYYY-MM-DD
        let apiURL = URL(string: "https://spiza.tommy.hr/api/v2/shop/store-prices-tables?date=\(dateString)&page=1&itemsPerPage=200&channelCode=general")!
        
        let (data, _) = try await session.data(from: apiURL)
        
        // Parse JSON response to get store data
        let storeData = try parseStoresList(data)
        
        var allProducts: [UnifiedProduct] = []
        
        for store in storeData {
            let csvURL = URL(string: "https://spiza.tommy.hr\(store.csvPath)")!
            let (csvData, _) = try await session.data(from: csvURL)
            
            let products = try await parser.parseProducts(from: csvData, provider: .tommy)
            allProducts.append(contentsOf: products)
        }
        
        return allProducts
    }
    
    private func parseStoresList(_ data: Data) throws -> [TommyStoreInfo] {
        struct APIResponse: Codable {
            let hydraMember: [TommyStoreInfo]
            
            enum CodingKeys: String, CodingKey {
                case hydraMember = "hydra:member"
            }
        }
        
        let response = try JSONDecoder().decode(APIResponse.self, from: data)
        return response.hydraMember
    }
}

struct TommyStoreInfo: Codable {
    let id: String
    let fileName: String
    
    var csvPath: String {
        return id.hasPrefix("/api/v2") ? id : "/api/v2\(id)"
    }
    
    enum CodingKeys: String, CodingKey {
        case id = "@id"
        case fileName
    }
}

// MARK: - Lidl Downloader

class LidlDownloader: StoreDownloader {
    private let session: URLSession
    private let parser: DataParser
    
    init(session: URLSession, parser: DataParser) {
        self.session = session
        self.parser = parser
    }
    
    func downloadProducts(for date: Date) async throws -> [UnifiedProduct] {
        // Based on lidl.py implementation
        let indexURL = URL(string: "https://tvrtka.lidl.hr/cijene")!
        let (htmlData, _) = try await session.data(from: indexURL)
        let html = String(data: htmlData, encoding: .utf8) ?? ""
        
        // Find ZIP file URL for the specified date
        let zipURL = try findZipURL(in: html, for: date, pattern: "Popis_cijena_po_trgovinama_na_dan_(\\d{1,2})_(\\d{1,2})_(\\d{4})\\.zip")
        
        // Download ZIP file
        let (zipData, _) = try await session.data(from: zipURL)
        
        // Parse ZIP file contents
        let zipParser = ZipFileParser()
        let csvFiles = try zipParser.extractCSVFiles(from: zipData)
        
        var allProducts: [UnifiedProduct] = []
        
        for (_, csvData) in csvFiles {
            let products = try await parser.parseProducts(from: csvData, provider: .lidl)
            allProducts.append(contentsOf: products)
        }
        
        return allProducts
    }
    
    private func findZipURL(in html: String, for date: Date, pattern: String) throws -> URL {
        let formatter = DateFormatter()
        formatter.dateFormat = "d_M_yyyy"
        let dateString = formatter.string(from: date)
        
        // Use regex to find ZIP URL with the specific date
        let regex = try NSRegularExpression(pattern: pattern, options: [])
        let range = NSRange(html.startIndex..<html.endIndex, in: html)
        
        let matches = regex.matches(in: html, options: [], range: range)
        
        for match in matches {
            if let urlRange = Range(match.range, in: html) {
                let urlString = String(html[urlRange])
                if urlString.contains(dateString), let url = URL(string: urlString) {
                    return url
                }
            }
        }
        
        throw ParserError.noDataFound
    }
}

// MARK: - Plodine Downloader

class PlodineDownloader: StoreDownloader {
    private let session: URLSession
    private let parser: DataParser
    
    init(session: URLSession, parser: DataParser) {
        self.session = session
        self.parser = parser
    }
    
    func downloadProducts(for date: Date) async throws -> [UnifiedProduct] {
        // Based on plodine.py implementation
        let indexURL = URL(string: "https://www.plodine.hr/info-o-cijenama")!
        let (htmlData, _) = try await session.data(from: indexURL)
        let html = String(data: htmlData, encoding: .utf8) ?? ""
        
        // Find ZIP file URL for the specified date
        let zipURL = try findZipURL(in: html, for: date, pattern: "cjenici_(\\d{2})_(\\d{2})_(\\d{4})_.*\\.zip")
        
        // Download ZIP file
        let (zipData, _) = try await session.data(from: zipURL)
        
        // Parse ZIP file contents
        let zipParser = ZipFileParser()
        let csvFiles = try zipParser.extractCSVFiles(from: zipData)
        
        var allProducts: [UnifiedProduct] = []
        
        for (_, csvData) in csvFiles {
            let products = try await parser.parseProducts(from: csvData, provider: .plodine)
            allProducts.append(contentsOf: products)
        }
        
        return allProducts
    }
    
    private func findZipURL(in html: String, for date: Date, pattern: String) throws -> URL {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd_MM_yyyy"
        let dateString = formatter.string(from: date)
        
        let regex = try NSRegularExpression(pattern: pattern, options: [])
        let range = NSRange(html.startIndex..<html.endIndex, in: html)
        
        let matches = regex.matches(in: html, options: [], range: range)
        
        for match in matches {
            if let urlRange = Range(match.range, in: html) {
                let urlString = String(html[urlRange])
                if urlString.contains(dateString), let url = URL(string: urlString) {
                    return url
                }
            }
        }
        
        throw ParserError.noDataFound
    }
}

// MARK: - Konzum Downloader

class KonzumDownloader: StoreDownloader {
    private let session: URLSession
    private let parser: DataParser
    
    init(session: URLSession, parser: DataParser) {
        self.session = session
        self.parser = parser
    }
    
    func downloadProducts(for date: Date) async throws -> [UnifiedProduct] {
        // Based on konzum.py implementation
        let dateString = DateFormatter().apply { $0.dateFormat = "yyyy-MM-dd" }.string(from: date)
        var allProducts: [UnifiedProduct] = []
        
        // Konzum has paginated CSV listings
        for page in 1...10 { // Reasonable limit to prevent infinite loops
            let pageURL = URL(string: "https://www.konzum.hr/cjenici?date=\(dateString)&page=\(page)")!
            let (htmlData, _) = try await session.data(from: pageURL)
            let html = String(data: htmlData, encoding: .utf8) ?? ""
            
            let csvURLs = extractCSVURLs(from: html)
            if csvURLs.isEmpty { break } // No more pages
            
            for csvURL in csvURLs {
                let (csvData, _) = try await session.data(from: csvURL)
                let products = try await parser.parseProducts(from: csvData, provider: .konzum)
                allProducts.append(contentsOf: products)
            }
        }
        
        return allProducts
    }
    
    private func extractCSVURLs(from html: String) -> [URL] {
        // Extract CSV URLs from HTML page
        // Look for links with format='csv' attribute
        var urls: [URL] = []
        
        let pattern = #"<a[^>]*format=["\']csv["\'][^>]*href=["\']([^"\']*)["\']"#
        
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            let range = NSRange(html.startIndex..<html.endIndex, in: html)
            
            let matches = regex.matches(in: html, options: [], range: range)
            
            for match in matches {
                if let urlRange = Range(match.range(at: 1), in: html) {
                    let urlString = String(html[urlRange])
                    if let url = URL(string: "https://www.konzum.hr\(urlString)") {
                        urls.append(url)
                    }
                }
            }
        } catch {
            print("Failed to parse CSV URLs: \(error)")
        }
        
        return urls
    }
}

// MARK: - Factory

class StoreDownloaderFactory {
    static func createDownloader(for provider: GroceryProvider, session: URLSession, parser: DataParser) -> StoreDownloader {
        switch provider {
        case .tommy:
            return TommyDownloader(session: session, parser: parser)
        case .lidl:
            return LidlDownloader(session: session, parser: parser)
        case .plodine:
            return PlodineDownloader(session: session, parser: parser)
        case .konzum:
            return KonzumDownloader(session: session, parser: parser)
        default:
            // Return a default implementation for other stores
            return DefaultStoreDownloader(provider: provider, session: session, parser: parser)
        }
    }
}

// MARK: - Default Implementation

class DefaultStoreDownloader: StoreDownloader {
    private let provider: GroceryProvider
    private let session: URLSession
    private let parser: DataParser
    
    init(provider: GroceryProvider, session: URLSession, parser: DataParser) {
        self.provider = provider
        self.session = session
        self.parser = parser
    }
    
    func downloadProducts(for date: Date) async throws -> [UnifiedProduct] {
        // Generic implementation for stores that haven't been specifically implemented yet
        throw ParserError.noDataFound
    }
}