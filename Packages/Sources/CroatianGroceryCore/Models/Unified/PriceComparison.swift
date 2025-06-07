import Foundation


/// Represents a price comparison between providers
public struct PriceComparison: Identifiable, Sendable {
    public let id = UUID()
    public let productName: String
    public let prices: [ShopProvider: UnifiedProduct]
    public let cheapestProvider: ShopProvider
    public let cheapestPrice: Float
    public let expensiveProvider: ShopProvider
    public let expensivePrice: Float
    public let priceDifference: Float
    
    public init?(products: [UnifiedProduct]) {
        guard !products.isEmpty else { return nil }
        
        // Group by normalized product name
        let productName = products.first?.name ?? ""
        self.productName = productName
        
        var priceMap: [ShopProvider: UnifiedProduct] = [:]
        for product in products {
            priceMap[product.provider] = product
        }
        self.prices = priceMap
        
        let sortedPrices = products.sorted { $0.unitPrice < $1.unitPrice }
        guard let cheapest = sortedPrices.first,
              let expensive = sortedPrices.last else { return nil }
        
        self.cheapestProvider = cheapest.provider
        self.cheapestPrice = cheapest.unitPrice
        self.expensiveProvider = expensive.provider
        self.expensivePrice = expensive.unitPrice
        self.priceDifference = expensive.unitPrice - cheapest.unitPrice
    }
}
