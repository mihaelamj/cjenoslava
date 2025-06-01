import Foundation
// MARK: - Data Downloader

public class DataDownloader {
    private let session: URLSession
    private let parser: DataParser

    public init(session: URLSession = .shared, parser: DataParser = CSVParser()) {
        self.session = session
        self.parser = parser
    }

    public func downloadAllPrices() async -> [GroceryProvider: Result<[UnifiedProduct], Error>] {
        var results: [GroceryProvider: Result<[UnifiedProduct], Error>] = [:]

        // Sequential download to avoid concurrency issues
        for provider in GroceryProvider.allCases {
            do {
                let products = try await downloadPrices(for: provider)
                results[provider] = .success(products)
            } catch {
                results[provider] = .failure(error)
            }
        }

        return results
    }

    public func downloadPrices(for provider: GroceryProvider) async throws -> [UnifiedProduct] {
        print("🔍 Starting download for \(provider.displayName)...")

        guard let websiteURL = provider.websiteURL else {
            throw ParserError.networkError(URLError(.badURL))
        }

        // First, scrape the website to find CSV download links
        let csvURLs = try await findCSVDownloadLinks(for: provider, at: websiteURL)

        print("📋 Found \(csvURLs.count) potential CSV links for \(provider.displayName)")

        var allProducts: [UnifiedProduct] = []
        var lastError: Error?

        // Try each CSV URL until we find valid data
        for url in csvURLs {
            do {
                print("⬇️ Trying to download from: \(url)")
                let data = try await downloadData(from: url)
                let products = try await parser.parseProducts(from: data, provider: provider)

                allProducts.append(contentsOf: products)

                // If we got products from this URL, log success
                if !products.isEmpty {
                    print("✅ Successfully downloaded \(products.count) products from \(provider.displayName)")
                    break // Success, no need to try other URLs
                }
            } catch {
                lastError = error
                print("⚠️ Failed to download from \(url): \(error.localizedDescription)")
                continue
            }
        }

        // If we didn't get any products, throw the last error
        if allProducts.isEmpty {
            print("❌ No products found for \(provider.displayName)")
            throw lastError ?? ParserError.noDataFound
        }

        return allProducts
    }

    // MARK: - CSV Link Discovery

    private func findCSVDownloadLinks(for provider: GroceryProvider, at url: URL) async throws -> [URL] {
        let html = try await downloadHTML(from: url)
        var csvURLs: [URL] = []

        // Look for CSV download links in the HTML
        csvURLs.append(contentsOf: extractCSVLinks(from: html, baseURL: url))

        // Add provider-specific fallback URLs as backup
        csvURLs.append(contentsOf: getProviderFallbackURLs(for: provider))

        return csvURLs
    }

    private func downloadHTML(from url: URL) async throws -> String {
        let data = try await downloadData(from: url)
        guard let html = String(data: data, encoding: .utf8) else {
            throw ParserError.invalidData
        }
        return html
    }

    private func extractCSVLinks(from html: String, baseURL: URL) -> [URL] {
        var urls: [URL] = []

        // Patterns to find CSV download links
        let patterns = [
            // Direct CSV file links
            #"href=[\"']([^\"']*\.csv[^\"']*)[\"']"#,
            // Links containing "csv" text
            #"href=[\"']([^\"']*)[\"'][^>]*>[^<]*csv[^<]*</a>"#,
            #"href=[\"']([^\"']*)[\"'][^>]*>[^<]*CSV[^<]*</a>"#,
            // Links with cjenik (price list in Croatian)
            #"href=[\"']([^\"']*cjenik[^\"']*)[\"']"#,
            #"href=[\"']([^\"']*price[^\"']*)[\"']"#,
            // Common Croatian pricing terms
            #"href=[\"']([^\"']*cijena[^\"']*)[\"']"#,
            #"href=[\"']([^\"']*lista[^\"']*)[\"']"#
        ]

        for pattern in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { continue }
            let range = NSRange(html.startIndex..<html.endIndex, in: html)
            let matches = regex.matches(in: html, options: [], range: range)

            for match in matches {
                if let linkRange = Range(match.range(at: 1), in: html) {
                    let linkString = String(html[linkRange])
                    if let url = URL(string: linkString, relativeTo: baseURL) {
                        urls.append(url)
                    }
                }
            }
        }

        // Remove duplicates and sort by relevance
        urls = Array(Set(urls))
        urls.sort { url1, url2 in
            let s1 = url1.absoluteString.lowercased()
            let s2 = url2.absoluteString.lowercased()
            let isCsv1 = s1.contains(".csv")
            let isCsv2 = s2.contains(".csv")
            if isCsv1 && !isCsv2 { return true }
            if !isCsv1 && isCsv2 { return false }
            return s1 < s2
        }

        return urls
    }

    private func getProviderFallbackURLs(for provider: GroceryProvider) -> [URL] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let today = dateFormatter.string(from: Date())

        dateFormatter.dateFormat = "yyyyMMdd"
        let todayCompact = dateFormatter.string(from: Date())

        var fallbackURLs: [URL] = []

        switch provider {
        case .tommy:
            let baseURL = "https://www.tommy.hr/"
            let patterns = [
                "\(baseURL)download/cjenik.csv",
                "\(baseURL)cjenik.csv",
                "\(baseURL)files/cjenik-\(today).csv",
                "\(baseURL)objava-cjenika/download.csv"
            ]
            fallbackURLs = patterns.compactMap { URL(string: $0) }

        case .konzum:
            let baseURL = "https://www.konzum.hr/"
            let patterns = [
                "\(baseURL)download/cjenik-\(today).csv",
                "\(baseURL)cjenici/cjenik-\(today).csv",
                "\(baseURL)files/cjenik.csv"
            ]
            fallbackURLs = patterns.compactMap { URL(string: $0) }

        case .plodine:
            let baseURL = "https://www.plodine.hr/"
            let patterns = [
                "\(baseURL)download/cjenik-\(today).csv",
                "\(baseURL)info-o-cijenama/cjenik.csv",
                "\(baseURL)files/cjenik.csv"
            ]
            fallbackURLs = patterns.compactMap { URL(string: $0) }

        case .lidl:
            let baseURL = "https://tvrtka.lidl.hr/"
            let patterns = [
                "\(baseURL)download/preisliste-\(today).csv",
                "\(baseURL)cijene/preisliste.csv",
                "\(baseURL)files/cjenik.csv"
            ]
            fallbackURLs = patterns.compactMap { URL(string: $0) }

        default:
            if let base = provider.websiteURL?.absoluteString {
                let patterns = [
                    "\(base)/download/cjenik.csv",
                    "\(base)/cjenik.csv",
                    "\(base)/files/cjenik-\(today).csv"
                ]
                fallbackURLs = patterns.compactMap { URL(string: $0) }
            }
        }

        return fallbackURLs
    }

    // Keep existing downloadData method
    private func downloadData(from url: URL) async throws -> Data {
        do {
            let (data, response) = try await session.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw ParserError.networkError(URLError(.badServerResponse))
            }
            guard httpResponse.statusCode == 200 else {
                throw ParserError.networkError(URLError(.badServerResponse))
            }
            return data
        } catch {
            throw ParserError.networkError(error)
        }
    }
}

// MARK: - Batch Data Manager

public class BatchDataManager {
    private let downloader: DataDownloader

    public init(downloader: DataDownloader = DataDownloader()) {
        self.downloader = downloader
    }

    public func collectAllData() async -> DataCollectionSession {
        let session = DataCollectionSession(
            startTime: Date(),
            providers: GroceryProvider.allCases
        )

        let results = await downloader.downloadAllPrices()

        var successfulProviders: [GroceryProvider] = []
        var failedProviders: [GroceryProvider: String] = [:]
        var totalProducts = 0

        for (provider, result) in results {
            switch result {
            case .success(let products):
                successfulProviders.append(provider)
                totalProducts += products.count
            case .failure(let error):
                failedProviders[provider] = error.localizedDescription
            }
        }

        return DataCollectionSession(
            id: session.id,
            startTime: session.startTime,
            endTime: Date(),
            providers: session.providers,
            totalProducts: totalProducts,
            successfulProviders: successfulProviders,
            failedProviders: failedProviders
        )
    }
}