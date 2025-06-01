import Foundation
// MARK: - Data Storage Protocol

public protocol DataStorage {
    func save(products: [UnifiedProduct]) async throws
    func load() async throws -> [UnifiedProduct]
    func save(session: DataCollectionSession) async throws
    func loadSessions() async throws -> [DataCollectionSession]
    func clear() async throws
}

// MARK: - File Storage Implementation

public class FileStorage: DataStorage {
    private let fileManager = FileManager.default
    private let documentsDirectory: URL
    private let productsFileName = "grocery_products.json"
    private let sessionsFileName = "collection_sessions.json"
    
    public init() throws {
        self.documentsDirectory = try fileManager.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
    }
    
    private var productsURL: URL {
        documentsDirectory.appendingPathComponent(productsFileName)
    }
    
    private var sessionsURL: URL {
        documentsDirectory.appendingPathComponent(sessionsFileName)
    }
    
    public func save(products: [UnifiedProduct]) async throws {
        let data = try JSONEncoder().encode(products)
        try data.write(to: productsURL)
    }
    
    public func load() async throws -> [UnifiedProduct] {
        guard fileManager.fileExists(atPath: productsURL.path) else {
            return []
        }
        
        let data = try Data(contentsOf: productsURL)
        return try JSONDecoder().decode([UnifiedProduct].self, from: data)
    }
    
    public func save(session: DataCollectionSession) async throws {
        var sessions = try await loadSessions()
        sessions.append(session)
        
        // Keep only the last 100 sessions
        if sessions.count > 100 {
            sessions = Array(sessions.suffix(100))
        }
        
        let data = try JSONEncoder().encode(sessions)
        try data.write(to: sessionsURL)
    }
    
    public func loadSessions() async throws -> [DataCollectionSession] {
        guard fileManager.fileExists(atPath: sessionsURL.path) else {
            return []
        }
        
        let data = try Data(contentsOf: sessionsURL)
        return try JSONDecoder().decode([DataCollectionSession].self, from: data)
    }
    
    public func clear() async throws {
        try? fileManager.removeItem(at: productsURL)
        try? fileManager.removeItem(at: sessionsURL)
    }
}

// MARK: - In-Memory Storage Implementation

public class InMemoryStorage: DataStorage {
    private var products: [UnifiedProduct] = []
    private var sessions: [DataCollectionSession] = []
    
    public init() {}
    
    public func save(products: [UnifiedProduct]) async throws {
        self.products = products
    }
    
    public func load() async throws -> [UnifiedProduct] {
        return products
    }
    
    public func save(session: DataCollectionSession) async throws {
        sessions.append(session)
        
        // Keep only the last 100 sessions
        if sessions.count > 100 {
            sessions = Array(sessions.suffix(100))
        }
    }
    
    public func loadSessions() async throws -> [DataCollectionSession] {
        return sessions
    }
    
    public func clear() async throws {
        products.removeAll()
        sessions.removeAll()
    }
}

// MARK: - Data Manager

public class DataManager {
    private let storage: DataStorage
    private let downloader: DataDownloader
    private let comparisonService: PriceComparisonService
    
    public init(
        storage: DataStorage,
        downloader: DataDownloader = DataDownloader(),
        comparisonService: PriceComparisonService = PriceComparisonService()
    ) {
        self.storage = storage
        self.downloader = downloader
        self.comparisonService = comparisonService
    }
    
    public func refreshData() async throws -> DataCollectionSession {
        let results = await downloader.downloadAllPrices()
        
        var allProducts: [UnifiedProduct] = []
        var successfulProviders: [GroceryProvider] = []
        var failedProviders: [GroceryProvider: String] = [:]
        
        for (provider, result) in results {
            switch result {
            case .success(let products):
                allProducts.append(contentsOf: products)
                successfulProviders.append(provider)
            case .failure(let error):
                failedProviders[provider] = error.localizedDescription
            }
        }
        
        try await storage.save(products: allProducts)
        
        let session = DataCollectionSession(
            startTime: Date(),
            endTime: Date(),
            providers: Array(results.keys),
            totalProducts: allProducts.count,
            successfulProviders: successfulProviders,
            failedProviders: failedProviders
        )
        
        try await storage.save(session: session)
        
        return session
    }
    
    public func loadProducts() async throws -> [UnifiedProduct] {
        return try await storage.load()
    }
    
    public func getComparisons() async throws -> [PriceComparison] {
        let products = try await loadProducts()
        return comparisonService.compareProducts(products)
    }
    
    public func searchProducts(query: String) async throws -> [UnifiedProduct] {
        let products = try await loadProducts()
        return comparisonService.searchProducts(products, query: query)
    }
    
    public func getProductsByProvider(_ provider: GroceryProvider) async throws -> [UnifiedProduct] {
        let products = try await loadProducts()
        return comparisonService.filterByProvider(products, providers: [provider])
    }
    
    public func getProductsByCategory(_ category: String) async throws -> [UnifiedProduct] {
        let products = try await loadProducts()
        return comparisonService.filterByCategory(products, category: category)
    }
    
    public func getBestDeals(limit: Int = 10) async throws -> [UnifiedProduct] {
        let products = try await loadProducts()
        return comparisonService.findBestDeals(from: products, limit: limit)
    }
    
    public func getSessions() async throws -> [DataCollectionSession] {
        return try await storage.loadSessions()
    }
}

// MARK: - Export Service

public class ExportService {
    
    public init() {}
    
    public func exportToCSV(products: [UnifiedProduct]) throws -> Data {
        var csv = "Provider,Name,Category,Brand,Unit,Price,Currency,Last Updated\n"
        
        for product in products {
            let row = [
                product.provider.displayName,
                csvEscape(product.name),
                csvEscape(product.category ?? ""),
                csvEscape(product.brand ?? ""),
                csvEscape(product.unit),
                product.unitPrice.description,
                product.currency,
                ISO8601DateFormatter().string(from: product.lastUpdated)
            ].joined(separator: ",")
            
            csv += row + "\n"
        }
        
        guard let data = csv.data(using: .utf8) else {
            throw ParserError.invalidData
        }
        
        return data
    }
    
    public func exportToJSON(products: [UnifiedProduct]) throws -> Data {
        return try JSONEncoder().encode(products)
    }
    
    public func exportComparisonsToCSV(comparisons: [PriceComparison]) throws -> Data {
        var csv = "Product,Cheapest Provider,Cheapest Price,Most Expensive Provider,Most Expensive Price,Difference,Savings Percentage\n"
        
        for comparison in comparisons {
            let savingsPercentage = (comparison.priceDifference / comparison.expensivePrice * 100).rounded()
            
            let row = [
                csvEscape(comparison.productName),
                comparison.cheapestProvider.displayName,
                comparison.cheapestPrice.description,
                comparison.expensiveProvider.displayName,
                comparison.expensivePrice.description,
                comparison.priceDifference.description,
                savingsPercentage.description + "%"
            ].joined(separator: ",")
            
            csv += row + "\n"
        }
        
        guard let data = csv.data(using: .utf8) else {
            throw ParserError.invalidData
        }
        
        return data
    }
    
    private func csvEscape(_ value: String) -> String {
        if value.contains(",") || value.contains("\"") || value.contains("\n") {
            return "\"" + value.replacingOccurrences(of: "\"", with: "\"\"") + "\""
        }
        return value
    }
}
