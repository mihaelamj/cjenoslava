import Foundation
// MARK: - Unified Data Models

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
    public let provider: GroceryProvider
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
        provider: GroceryProvider,
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

/// Represents a grocery store provider
public enum GroceryProvider: String, CaseIterable, Codable, Sendable {
    case plodine = "plodine"
    case tommy = "tommy"
    case lidl = "lidl"
    case spar = "spar"
    case studenac = "studenac"
    case dm = "dm"
    case eurospin = "eurospin"
    case konzum = "konzum"
    case kaufland = "kaufland"
    case ktc = "ktc"
//    case metro = "metro"
//    case ntl = "ntl"
//    case ribola = "ribola"
//    case spar = "spar"
//    case trgocentar = "trgocentar"
//    case vrutak = "vrutak"
//    case zabac = "zabac"
    
    public var displayName: String {
        switch self {
        case .plodine: return "Plodine"
        case .tommy: return "Tommy"
        case .lidl: return "Lidl"
        case .spar: return "Spar"
        case .studenac: return "Studenac"
        case .dm: return "dm"
        case .eurospin: return "Eurospin"
        case .konzum: return "Konzum"
        case .kaufland: return "Kaufland"
        case .ktc: return "KTC"
//        case .metro: return "Metro"
        }
    }
    
    public var websiteURL: URL? {
        switch self {
        case .plodine: return URL(string: "https://www.plodine.hr/info-o-cijenama")
        case .tommy: return URL(string: "https://www.tommy.hr/objava-cjenika")
        case .lidl: return URL(string: "https://tvrtka.lidl.hr/cijene")
        case .spar: return URL(string: "https://www.spar.hr/usluge/cjenici")
        case .studenac: return URL(string: "https://www.studenac.hr/popis-maloprodajnih-cijena")
        case .dm: return URL(string: "https://www.dm.hr/novo/promocije/nove-oznake-cijena-i-vazeci-cjenik-u-dm-u-2906632")
        case .eurospin: return URL(string: "https://www.eurospin.hr/cjenik/")
        case .konzum: return URL(string: "https://www.konzum.hr/cjenici")
        case .kaufland: return URL(string: "https://www.kaufland.hr/akcije-novosti/mpc-popis.html")
        case .ktc: return URL(string: "https://www.ktc.hr/cjenici")
//        case .metro: return URL(string: "https://metrocjenik.com.hr")
        
        }
    }
}

/// Represents a price comparison between providers
public struct PriceComparison: Identifiable, Sendable {
    public let id = UUID()
    public let productName: String
    public let prices: [GroceryProvider: UnifiedProduct]
    public let cheapestProvider: GroceryProvider
    public let cheapestPrice: Float
    public let expensiveProvider: GroceryProvider
    public let expensivePrice: Float
    public let priceDifference: Float
    
    public init?(products: [UnifiedProduct]) {
        guard !products.isEmpty else { return nil }
        
        // Group by normalized product name
        let productName = products.first?.name ?? ""
        self.productName = productName
        
        var priceMap: [GroceryProvider: UnifiedProduct] = [:]
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

/// Data collection session information
public struct DataCollectionSession: Codable, Identifiable, Sendable {
    public let id: UUID
    public let startTime: Date
    public let endTime: Date?
    public let providers: [GroceryProvider]
    public let totalProducts: Int
    public let successfulProviders: [GroceryProvider]
    public let failedProviders: [GroceryProvider: String] // Provider: Error message
    
    public init(
        id: UUID = UUID(),
        startTime: Date = Date(),
        endTime: Date? = nil,
        providers: [GroceryProvider],
        totalProducts: Int = 0,
        successfulProviders: [GroceryProvider] = [],
        failedProviders: [GroceryProvider: String] = [:]
    ) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.providers = providers
        self.totalProducts = totalProducts
        self.successfulProviders = successfulProviders
        self.failedProviders = failedProviders
    }
}
