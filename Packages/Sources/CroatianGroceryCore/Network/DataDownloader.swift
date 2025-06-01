import Foundation

// MARK: - Data Downloader

public class DataDownloader {
    private let session: URLSession
    let parser: DataParser

    public init(session: URLSession = .shared, parser: DataParser = CSVParser()) {
        self.session = session
        self.parser = parser
    }

    public func downloadAllPrices() async -> [GroceryProvider: Result<[UnifiedProduct], Error>] {
        var results: [GroceryProvider: Result<[UnifiedProduct], Error>] = [:]

        // Sequential download to avoid overwhelming servers
        for provider in GroceryProvider.allCases {
            do {
                let products = try await downloadPrices(for: provider)
                results[provider] = .success(products)
                print("✅ Successfully downloaded \(products.count) products from \(provider.displayName)")
            } catch {
                results[provider] = .failure(error)
                print("❌ Failed to download from \(provider.displayName): \(error.localizedDescription)")
            }
        }

        return results
    }

    public func downloadPrices(for provider: GroceryProvider) async throws -> [UnifiedProduct] {
        print("🔍 Starting download for \(provider.displayName)...")

        let downloader = StoreDownloaderFactory.createDownloader(for: provider, session: session, parser: parser)
        return try await downloader.downloadProducts(for: Date())
    }

    // MARK: - Helper methods

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

// MARK: - Extensions

extension DateFormatter {
    func apply(_ closure: (DateFormatter) -> Void) -> DateFormatter {
        closure(self)
        return self
    }
}
