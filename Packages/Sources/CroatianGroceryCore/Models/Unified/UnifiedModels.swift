import Foundation

/// Unified product representation across all grocery stores
public struct UnifiedProduct: Codable, Identifiable, Hashable, Sendable {
    public let id: UUID
    public let name: String
    public let category: String?
    public let brand: String?
    public let barcode: String?
    public let unit: String
    public let unitPrice: Float
    public let packageSize: String?
    public let pricePerUnit: Float?
    public let originalData: [String: String] // Preserves original field names
    public let provider: ShopProvider
    public let lastUpdated: Date
    public let isOnSale: Bool
    public let originalPrice: Float?
    public let currency: String
    
    public init(
        id: UUID = UUID(),
        name: String,
        category: String? = nil,
        brand: String? = nil,
        barcode: String? = nil,
        unit: String,
        unitPrice: Float,
        packageSize: String? = nil,
        pricePerUnit: Float? = nil,
        originalData: [String: String],
        provider: ShopProvider,
        lastUpdated: Date = Date(),
        isOnSale: Bool = false,
        originalPrice: Float? = nil,
        currency: String = "EUR"
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.brand = brand
        self.barcode = barcode
        self.unit = unit
        self.unitPrice = unitPrice
        self.packageSize = packageSize
        self.pricePerUnit = pricePerUnit
        self.originalData = originalData
        self.provider = provider
        self.lastUpdated = lastUpdated
        self.isOnSale = isOnSale
        self.originalPrice = originalPrice
        self.currency = currency
    }
}

