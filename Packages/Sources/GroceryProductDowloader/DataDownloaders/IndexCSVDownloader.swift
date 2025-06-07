import Foundation

/// For stores like Konzum, Kaufland that list CSV files on index pages
public actor IndexCSVDownloader: IndexBasedDownloader {
    private let httpDownloader: HTTPDataDownloader
    
    public init() {
        self.httpDownloader = HTTPDataDownloader()
    }
    
    public func findDataURLs(for request: StoreDataRequest) async throws -> [URL] {
        let indexURL = buildIndexURL(for: request)
        let html = try await httpDownloader.downloadText(from: indexURL)
        return extractCSVURLs(from: html, date: request.date, provider: request.provider)
    }
    
    public func downloadFromIndex(for request: StoreDataRequest) async throws -> [RawData] {
        let urls = try await findDataURLs(for: request)
        var results: [RawData] = []
        
        for url in urls {
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
    
    private func buildIndexURL(for request: StoreDataRequest) -> URL {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: request.date)
        
        switch request.provider {
        case .konzum:
            return URL(string: "https://www.konzum.hr/cjenici?date=\(dateString)")!
        case .kaufland:
            return URL(string: "https://www.kaufland.hr/akcije-novosti/popis-mpc.html")!
        case .ktc:
            return URL(string: "https://www.ktc.hr/cjenici")!
        case .eurospin:
            return URL(string: "https://www.eurospin.hr/cjenik/")!
        case .metro:
            return URL(string: "https://metrocjenik.com.hr")!
        case .ntl:
            return URL(string: "https://www.ntl.hr/cjenici-za-ntl-supermarkete")!
        case .zabac:
            return URL(string: "https://zabacfoodoutlet.hr/cjenik/")!
        default:
            fatalError("Provider \(request.provider) not supported by IndexCSVDownloader")
        }
    }
    
    private func extractCSVURLs(from html: String, date: Date, provider: GroceryProductProvider) -> [URL] {
        let dateFormatter = DateFormatter()
        
        switch provider {
        case .konzum:
            dateFormatter.dateFormat = "dd.MM.yyyy"
        case .kaufland:
            dateFormatter.dateFormat = "dd_MM_yyyy"
        case .metro:
            dateFormatter.dateFormat = "yyyyMMdd"
        default:
            dateFormatter.dateFormat = "yyyy-MM-dd"
        }
        
        let dateString = dateFormatter.string(from: date)
        
        // Parse HTML using regex to find CSV links
        let pattern = #"href="([^"]*\.csv[^"]*)"#
        let regex = try! NSRegularExpression(pattern: pattern)
        let range = NSRange(html.startIndex..<html.endIndex, in: html)
        
        var urls: [URL] = []
        regex.enumerateMatches(in: html, range: range) { match, _, _ in
            if let range = Range(match!.range(at: 1), in: html) {
                let urlString = String(html[range])
                if urlString.contains(dateString) {
                    if let url = URL(string: urlString) {
                        urls.append(url)
                    }
                }
            }
        }
        
        return urls
    }
}
