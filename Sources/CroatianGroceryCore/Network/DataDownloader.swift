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
        
        await withTaskGroup(of: (GroceryProvider, Result<[UnifiedProduct], Error>).self) { group in
            let service = self // DataDownloader, non-Sendable
            for provider in GroceryProvider.allCases {
                group.addTask { @Sendable in
                    do {
                        let products = try await service.downloadPrices(for: provider)
                        return (provider, .success(products))
                    } catch {
                        return (provider, .failure(error))
                    }
                }
            }
            
            for await (provider, result) in group {
                results[provider] = result
            }
        }
        
        return results
    }
    
    public func downloadAllPricesEx() async -> [GroceryProvider: Result<[UnifiedProduct], Error>] {
        var results: [GroceryProvider: Result<[UnifiedProduct], Error>] = [:]
        
        await withTaskGroup(of: (GroceryProvider, Result<[UnifiedProduct], Error>).self) { group in
            for provider in GroceryProvider.allCases {
                group.addTask {
                    do {
                        let products = try await self.downloadPrices(for: provider)
                        return (provider, .success(products))
                    } catch {
                        return (provider, .failure(error))
                    }
                }
            }
            
            for await (provider, result) in group {
                results[provider] = result
            }
        }
        
        return results
    }
    
    
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
    
    private func findDataURLs(for provider: GroceryProvider, baseURL: URL) async throws -> [URL] {
        // This method would need to scrape the webpage to find CSV/data download links
        // For now, we'll return some common patterns based on the provider
        
        switch provider {
        case .tommy:
            // Tommy provides CSV download links
            return try await scrapeTommyDataURLs(baseURL: baseURL)
        case .plodine:
            return try await scrapePlodineDataURLs(baseURL: baseURL)
        case .lidl:
            return try await scrapeLidlDataURLs(baseURL: baseURL)
        case .spar:
            return try await scrapeSparDataURLs(baseURL: baseURL)
        case .studenac:
            return try await scrapeStudenacDataURLs(baseURL: baseURL)
        case .dm:
            return try await scrapeDMDataURLs(baseURL: baseURL)
        case .eurospin:
            return try await scrapeEurospinDataURLs(baseURL: baseURL)
        case .konzum:
            return try await scrapeKonzumDataURLs(baseURL: baseURL)
        case .kaufland:
            return try await scrapeKauflandDataURLs(baseURL: baseURL)
        case .ktc:
            return try await scrapeKTCDataURLs(baseURL: baseURL)
        }
    }
    
    // MARK: - Provider-specific URL scrapers
    
    private func scrapeTommyDataURLs(baseURL: URL) async throws -> [URL] {
        let html = try await downloadHTML(from: baseURL)
        return extractCSVLinks(from: html, baseURL: baseURL)
    }
    
    private func scrapePlodineDataURLs(baseURL: URL) async throws -> [URL] {
        let html = try await downloadHTML(from: baseURL)
        return extractCSVLinks(from: html, baseURL: baseURL)
    }
    
    private func scrapeLidlDataURLs(baseURL: URL) async throws -> [URL] {
        let html = try await downloadHTML(from: baseURL)
        return extractCSVLinks(from: html, baseURL: baseURL)
    }
    
    private func scrapeSparDataURLs(baseURL: URL) async throws -> [URL] {
        let html = try await downloadHTML(from: baseURL)
        return extractCSVLinks(from: html, baseURL: baseURL)
    }
    
    private func scrapeStudenacDataURLs(baseURL: URL) async throws -> [URL] {
        let html = try await downloadHTML(from: baseURL)
        return extractCSVLinks(from: html, baseURL: baseURL)
    }
    
    private func scrapeDMDataURLs(baseURL: URL) async throws -> [URL] {
        let html = try await downloadHTML(from: baseURL)
        return extractCSVLinks(from: html, baseURL: baseURL)
    }
    
    private func scrapeEurospinDataURLs(baseURL: URL) async throws -> [URL] {
        let html = try await downloadHTML(from: baseURL)
        return extractCSVLinks(from: html, baseURL: baseURL)
    }
    
    private func scrapeKonzumDataURLs(baseURL: URL) async throws -> [URL] {
        let html = try await downloadHTML(from: baseURL)
        return extractCSVLinks(from: html, baseURL: baseURL)
    }
    
    private func scrapeKauflandDataURLs(baseURL: URL) async throws -> [URL] {
        let html = try await downloadHTML(from: baseURL)
        return extractCSVLinks(from: html, baseURL: baseURL)
    }
    
    private func scrapeKTCDataURLs(baseURL: URL) async throws -> [URL] {
        let html = try await downloadHTML(from: baseURL)
        return extractCSVLinks(from: html, baseURL: baseURL)
    }
    
    // MARK: - Helper methods
    
    private func downloadHTML(from url: URL) async throws -> String {
        let data = try await downloadData(from: url)
        guard let html = String(data: data, encoding: .utf8) else {
            throw ParserError.invalidData
        }
        return html
    }
    
    private func extractCSVLinks(from html: String, baseURL: URL) -> [URL] {
        var urls: [URL] = []
        
        // Look for common CSV file patterns
        let patterns = [
            #"href=["\']([^"\']*\.csv[^"\']*)["\']"#,
            #"href=["\']([^"\']*cjenik[^"\']*)["\']"#,
            #"href=["\']([^"\']*price[^"\']*)["\']"#,
            #"href=["\']([^"\']*lista[^"\']*)["\']"#
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
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
        }
        
        // If no CSV links found, return the base URL (might be a direct CSV endpoint)
        if urls.isEmpty {
            urls.append(baseURL)
        }
        
        return urls
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
