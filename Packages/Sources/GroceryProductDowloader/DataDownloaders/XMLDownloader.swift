import Foundation

/// For stores like Ribola, Trgocentar, Vrutak that use XML format
public actor XMLDownloader: SpecialFormatDownloader {
    private let httpDownloader: HTTPDataDownloader
    
    public init() {
        self.httpDownloader = HTTPDataDownloader()
    }
    
    public func downloadSpecialFormat(for request: StoreDataRequest) async throws -> [RawData] {
        let xmlURLs = try await findXMLURLs(for: request)
        
        var results: [RawData] = []
        for url in xmlURLs {
            do {
                let data = try await httpDownloader.download(from: url)
                results.append(data)
            } catch {
                print("Failed to download XML from \(url): \(error)")
                continue
            }
        }
        
        return results
    }
    
    private func findXMLURLs(for request: StoreDataRequest) async throws -> [URL] {
        let indexURL = buildXMLIndexURL(for: request)
        let html = try await httpDownloader.downloadText(from: indexURL)
        return extractXMLURLs(from: html, provider: request.provider)
    }
    
    private func buildXMLIndexURL(for request: StoreDataRequest) -> URL {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "d.M.yyyy"
        let dateString = dateFormatter.string(from: request.date)
        
        switch request.provider {
        case .ribola:
            return URL(string: "https://ribola.hr/ribola-cjenici/?date=\(dateString)")!
        case .trgocentar:
            return URL(string: "https://trgocentar.com/Trgovine-cjenik/")!
        case .vrutak:
            return URL(string: "https://www.vrutak.hr/cjenik-svih-artikala")!
        default:
            fatalError("Provider \(request.provider) not supported by XMLDownloader")
        }
    }
    
    private func extractXMLURLs(from html: String, provider: GroceryProductProvider) -> [URL] {
        // Parse HTML to find XML file URLs
        let pattern = #"href="([^"]*\.xml)"#
        let regex = try! NSRegularExpression(pattern: pattern)
        let range = NSRange(html.startIndex..<html.endIndex, in: html)
        
        var urls: [URL] = []
        regex.enumerateMatches(in: html, range: range) { match, _, _ in
            if let range = Range(match!.range(at: 1), in: html) {
                let urlString = String(html[range])
                if let url = URL(string: urlString) {
                    urls.append(url)
                }
            }
        }
        
        return urls
    }
}
