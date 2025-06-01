import Foundation
import ArgumentParser
import CroatianGroceryCore

//@main
struct GroceryPriceCLI: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "grocery-price-cli",
        abstract: "Croatian Grocery Price Tracker - Download and compare grocery prices",
        subcommands: [
            RefreshCommand.self,
            ListCommand.self,
            CompareCommand.self,
            SearchCommand.self,
            ExportCommand.self,
            AnalyticsCommand.self
        ]
    )
}

// MARK: - Refresh Command

struct RefreshCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "refresh",
        abstract: "Download the latest prices from all providers"
    )
    
    @Option(name: .shortAndLong, help: "Specific provider to refresh (optional)")
    var provider: String?
    
    @Flag(name: .shortAndLong, help: "Show verbose output")
    var verbose = false
    
    func run() async throws {
        let storage = try FileStorage()
        let dataManager = DataManager(storage: storage)
        
        if verbose {
            print("🚀 Starting price data collection...")
        }
        
        let session = try await dataManager.refreshData()
        
        print("✅ Data collection completed!")
        print("📊 Total products collected: \(session.totalProducts)")
        print("✅ Successful providers: \(session.successfulProviders.map { $0.displayName }.joined(separator: ", "))")
        
        if !session.failedProviders.isEmpty {
            print("❌ Failed providers:")
            for (provider, error) in session.failedProviders {
                print("   • \(provider.displayName): \(error)")
            }
        }
        
        let duration = session.endTime?.timeIntervalSince(session.startTime) ?? 0
        print("⏱️  Duration: \(String(format: "%.1f", duration)) seconds")
    }
}

// MARK: - List Command

struct ListCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List products from providers"
    )
    
    @Option(name: .shortAndLong, help: "Filter by provider")
    var provider: String?
    
    @Option(name: .shortAndLong, help: "Filter by category")
    var category: String?
    
    @Option(name: .shortAndLong, help: "Limit number of results")
    var limit: Int = 20
    
    func run() async throws {
        let storage = try FileStorage()
        let dataManager = DataManager(storage: storage)
        
        var products = try await dataManager.loadProducts()
        
        if let providerName = provider,
           let groceryProvider = GroceryProvider.allCases.first(where: { $0.rawValue == providerName.lowercased() }) {
            products = try await dataManager.getProductsByProvider(groceryProvider)
        }
        
        if let categoryName = category {
            products = try await dataManager.getProductsByCategory(categoryName)
        }
        
        products = Array(products.prefix(limit))
        
        if products.isEmpty {
            print("No products found.")
            return
        }
        
        print("📦 Found \(products.count) products:\n")
        
        for product in products {
            print("🏪 \(product.provider.displayName)")
            print("   📋 \(product.name)")
            if let category = product.category {
                print("   🏷️  Category: \(category)")
            }
            if let brand = product.brand {
                print("   🔖 Brand: \(brand)")
            }
            print("   💰 Price: €\(product.unitPrice) per \(product.unit)")
            if product.isOnSale, let originalPrice = product.originalPrice {
                print("   🔥 On Sale! Original: €\(originalPrice)")
            }
            print()
        }
    }
}

// MARK: - Compare Command

struct CompareCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "compare",
        abstract: "Compare prices across providers"
    )
    
    @Option(name: .shortAndLong, help: "Limit number of comparisons")
    var limit: Int = 10
    
    @Flag(name: .shortAndLong, help: "Show only significant differences (>10%)")
    var significant = false
    
    func run() async throws {
        let storage = try FileStorage()
        let dataManager = DataManager(storage: storage)
        
        var comparisons = try await dataManager.getComparisons()
        
        if significant {
            comparisons = comparisons.filter { comparison in
                let percentage = comparison.priceDifference / comparison.expensivePrice * 100
                return percentage >= 10
            }
        }
        
        comparisons = Array(comparisons.prefix(limit))
        
        if comparisons.isEmpty {
            print("No price comparisons found.")
            return
        }
        
        print("💰 Price Comparisons (Top \(comparisons.count)):\n")
        
        for (index, comparison) in comparisons.enumerated() {
            let savingsPercentage = (comparison.priceDifference / comparison.expensivePrice * 100).rounded()
            
            print("\(index + 1). \(comparison.productName)")
            print("   🥇 Cheapest: \(comparison.cheapestProvider.displayName) - €\(comparison.cheapestPrice)")
            print("   🥉 Most Expensive: \(comparison.expensiveProvider.displayName) - €\(comparison.expensivePrice)")
            print("   💸 Difference: €\(comparison.priceDifference) (\(savingsPercentage)% savings)")
            print()
        }
    }
}

// MARK: - Search Command

struct SearchCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "search",
        abstract: "Search for products"
    )
    
    @Argument(help: "Search query")
    var query: String
    
    @Option(name: .shortAndLong, help: "Limit number of results")
    var limit: Int = 10
    
    func run() async throws {
        let storage = try FileStorage()
        let dataManager = DataManager(storage: storage)
        
        let products = try await dataManager.searchProducts(query: query)
        let limitedProducts = Array(products.prefix(limit))
        
        if limitedProducts.isEmpty {
            print("No products found for query: '\(query)'")
            return
        }
        
        print("🔍 Search results for '\(query)' (\(limitedProducts.count) found):\n")
        
        for product in limitedProducts {
            print("🏪 \(product.provider.displayName) - €\(product.unitPrice)")
            print("   📋 \(product.name)")
            if let brand = product.brand {
                print("   🔖 \(brand)")
            }
            print()
        }
    }
}

// MARK: - Export Command

struct ExportCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "export",
        abstract: "Export data to CSV or JSON"
    )
    
    @Option(name: .shortAndLong, help: "Output format (csv, json)")
    var format: String = "csv"
    
    @Option(name: .shortAndLong, help: "Output file path")
    var output: String?
    
    @Flag(name: .shortAndLong, help: "Export comparisons instead of products")
    var comparisons = false
    
    func run() async throws {
        let storage = try FileStorage()
        let dataManager = DataManager(storage: storage)
        let exportService = ExportService()
        
        let data: Data
        let defaultFileName: String
        
        if comparisons {
            let comparisonData = try await dataManager.getComparisons()
            data = try exportService.exportComparisonsToCSV(comparisons: comparisonData)
            defaultFileName = "price_comparisons.csv"
        } else {
            let products = try await dataManager.loadProducts()
            
            switch format.lowercased() {
            case "json":
                data = try exportService.exportToJSON(products: products)
                defaultFileName = "grocery_products.json"
            default:
                data = try exportService.exportToCSV(products: products)
                defaultFileName = "grocery_products.csv"
            }
        }
        
        let outputPath = output ?? defaultFileName
        let outputURL = URL(fileURLWithPath: outputPath)
        
        try data.write(to: outputURL)
        print("✅ Data exported to: \(outputURL.path)")
        print("📊 File size: \(ByteCountFormatter.string(fromByteCount: Int64(data.count), countStyle: .file))")
    }
}

// MARK: - Analytics Command

struct AnalyticsCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "analytics",
        abstract: "Show analytics and statistics"
    )
    
    func run() async throws {
        let storage = try FileStorage()
        let dataManager = DataManager(storage: storage)
        let analyticsService = PriceAnalyticsService()
        
        let products = try await dataManager.loadProducts()
        
        if products.isEmpty {
            print("No products available. Run 'grocery-price-cli refresh' first.")
            return
        }
        
        print("📊 Grocery Price Analytics\n")
        
        // Overall statistics
        print("📈 Overall Statistics:")
        print("   Total products: \(products.count)")
        print("   Providers: \(Set(products.map { $0.provider }).count)")
        print("   Categories: \(Set(products.compactMap { $0.category }).count)")
        print("   Products on sale: \(products.filter { $0.isOnSale }.count)")
        print()
        
        // Provider analytics
        let providerAnalytics = analyticsService.generateProviderAnalytics(products)
        print("🏪 Provider Analytics:")
        for analytics in providerAnalytics {
            print("   \(analytics.provider.displayName):")
            print("      Products: \(analytics.totalProducts)")
            print("      Avg Price: €\(analytics.averagePrice)")
            print("      Price Range: €\(analytics.minPrice) - €\(analytics.maxPrice)")
            print("      Sale Rate: \(String(format: "%.1f", analytics.salePercentage))%")
        }
        print()
        
        // Category analytics
        let categoryAnalytics = analyticsService.generateCategoryAnalytics(products)
        print("🏷️  Top Categories:")
        for analytics in Array(categoryAnalytics.prefix(5)) {
            print("   \(analytics.category): \(analytics.totalProducts) products (avg €\(analytics.averagePrice))")
        }
        print()
        
        // Best deals
        let bestDeals = try await dataManager.getBestDeals(limit: 5)
        print("🔥 Best Deals:")
        for deal in bestDeals {
            print("   \(deal.name) - €\(deal.unitPrice) at \(deal.provider.displayName)")
        }
    }
}
