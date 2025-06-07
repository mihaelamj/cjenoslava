 import Foundation
// MARK: - Price Comparison Service

public class PriceComparisonService {

public init() {}

public func compareProducts(_ products: [UnifiedProduct]) -> [PriceComparison] {
    // Group products by normalized name
    let grouped = Dictionary(grouping: products) { product in
        normalizeProductName(product.name)
    }
    
    var comparisons: [PriceComparison] = []
    
    for (_, productGroup) in grouped {
        // Only compare if we have products from multiple providers
        let uniqueProviders = Set(productGroup.map { $0.provider })
        if uniqueProviders.count > 1,
           let comparison = PriceComparison(products: productGroup) {
            comparisons.append(comparison)
        }
    }
    
    return comparisons.sorted { $0.priceDifference > $1.priceDifference }
}

public func findBestDeals(from products: [UnifiedProduct], limit: Int = 10) -> [UnifiedProduct] {
    let comparisons = compareProducts(products)
    
    return comparisons
        .prefix(limit)
        .compactMap { comparison in
            comparison.prices[comparison.cheapestProvider]
        }
}

public func calculateSavings(from comparisons: [PriceComparison]) -> PriceSavingsReport {
    let totalComparisons = comparisons.count
    let totalSavings = comparisons.reduce(0) { $0 + $1.priceDifference }
    let averageSavings = totalComparisons > 0 ? totalSavings / Float(totalComparisons) : 0
    
    let maxSaving = comparisons.max { $0.priceDifference < $1.priceDifference }
    
    return PriceSavingsReport(
        totalComparisons: totalComparisons,
        totalSavings: totalSavings,
        averageSavings: averageSavings,
        biggestSaving: maxSaving
    )
}

public func searchProducts(_ products: [UnifiedProduct], query: String) -> [UnifiedProduct] {
    let lowercaseQuery = query.lowercased()
    
    return products.filter { product in
        product.name.lowercased().contains(lowercaseQuery) ||
        product.brand?.lowercased().contains(lowercaseQuery) == true ||
        product.category?.lowercased().contains(lowercaseQuery) == true
    }
}

public func filterByProvider(_ products: [UnifiedProduct], providers: Set<ShopProvider>) -> [UnifiedProduct] {
    return products.filter { providers.contains($0.provider) }
}

public func filterByCategory(_ products: [UnifiedProduct], category: String) -> [UnifiedProduct] {
    return products.filter { product in
        product.category?.lowercased() == category.lowercased()
    }
}

public func filterByPriceRange(_ products: [UnifiedProduct], min: Float, max: Float) -> [UnifiedProduct] {
    return products.filter { product in
        product.unitPrice >= min && product.unitPrice <= max
    }
}

private func normalizeProductName(_ name: String) -> String {
    return name
        .lowercased()
        .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        .trimmingCharacters(in: .whitespacesAndNewlines)
        .replacingOccurrences(of: "[^a-z0-9\\s]", with: "", options: .regularExpression)
}
}

// MARK: - Supporting Models

public struct PriceSavingsReport {
public let totalComparisons: Int
public let totalSavings: Float
public let averageSavings: Float
public let biggestSaving: PriceComparison?

public init(totalComparisons: Int, totalSavings: Float, averageSavings: Float, biggestSaving: PriceComparison?) {
    self.totalComparisons = totalComparisons
    self.totalSavings = totalSavings
    self.averageSavings = averageSavings
    self.biggestSaving = biggestSaving
}
}

// MARK: - Analytics Service

public class PriceAnalyticsService {

public init() {}

public func generateProviderAnalytics(_ products: [UnifiedProduct]) -> [ProviderAnalytics] {
    let grouped = Dictionary(grouping: products) { $0.provider }
    
    return grouped.map { provider, products in
        let prices = products.map { $0.unitPrice }
        let averagePrice = prices.reduce(0, +) / Float(prices.count)
        let minPrice = prices.min() ?? 0
        let maxPrice = prices.max() ?? 0
        
        let onSaleCount = products.filter { $0.isOnSale }.count
        let onSalePercentage = Double(onSaleCount) / Double(products.count) * 100
        
        return ProviderAnalytics(
            provider: provider,
            totalProducts: products.count,
            averagePrice: averagePrice,
            minPrice: minPrice,
            maxPrice: maxPrice,
            productsOnSale: onSaleCount,
            salePercentage: onSalePercentage
        )
    }.sorted { $0.averagePrice < $1.averagePrice }
}

public func generateCategoryAnalytics(_ products: [UnifiedProduct]) -> [CategoryAnalytics] {
    let grouped = Dictionary(grouping: products) { $0.category ?? "Unknown" }
    
    return grouped.map { category, products in
        let prices = products.map { $0.unitPrice }
        let averagePrice = prices.reduce(0, +) / Float(prices.count)
        
        let providerCounts = Dictionary(grouping: products) { $0.provider }
            .mapValues { $0.count }
        
        return CategoryAnalytics(
            category: category,
            totalProducts: products.count,
            averagePrice: averagePrice,
            providerCounts: providerCounts
        )
    }.sorted { $0.totalProducts > $1.totalProducts }
}
}

public struct ProviderAnalytics {
public let provider: ShopProvider
public let totalProducts: Int
public let averagePrice: Float
public let minPrice: Float
public let maxPrice: Float
public let productsOnSale: Int
public let salePercentage: Double

public init(provider: ShopProvider, totalProducts: Int, averagePrice: Float, minPrice: Float, maxPrice: Float, productsOnSale: Int, salePercentage: Double) {
    self.provider = provider
    self.totalProducts = totalProducts
    self.averagePrice = averagePrice
    self.minPrice = minPrice
    self.maxPrice = maxPrice
    self.productsOnSale = productsOnSale
    self.salePercentage = salePercentage
}
}

public struct CategoryAnalytics {
public let category: String
public let totalProducts: Int
public let averagePrice: Float
public let providerCounts: [ShopProvider: Int]

public init(category: String, totalProducts: Int, averagePrice: Float, providerCounts: [ShopProvider: Int]) {
    self.category = category
    self.totalProducts = totalProducts
    self.averagePrice = averagePrice
    self.providerCounts = providerCounts
}
}
