import Foundation

public struct GroceryProduct: Codable, Identifiable, Hashable, Sendable {
    
    // MARK: - Core Identity
    public let id: UUID
    public let storeId: String?
    public let barcode: String?
    public let name: String
    public let brand: String?
    public let category: String?
    
    // MARK: - Pricing (using Decimal for precision)
    public let price: Decimal
    public let unitPrice: Decimal?
    public let specialPrice: Decimal?  // Sale/promotional price
    public let bestPrice30Days: Decimal?  // Lowest price in last 30 days
    public let anchorPrice: Decimal?  // Reference price (often from specific date)
    public let currency: Currency
    
    // MARK: - Product Details
    public let quantity: String?  // "500g", "1L", etc.
    public let unit: String?  // "kg", "L", "kom", etc.
    
    // MARK: - Sale Information
    public var isOnSale: Bool {
        return specialPrice != nil && specialPrice! < price
    }
    
    public var effectivePrice: Decimal {
        return specialPrice ?? price
    }
    
    // MARK: - Metadata
    public let provider: GroceryProductProvider
    public let lastUpdated: Date
    public let anchorPriceDate: Date?  // When anchor price was set
    public let dateAdded: Date?  // When product was first added
    
    // MARK: - Raw Data Preservation
    public let originalData: [String: String] // Preserves all original fields
    
    // MARK: - Initializer
    public init(
        id: UUID = UUID(),
        storeId: String? = nil,
        barcode: String? = nil,
        name: String,
        brand: String? = nil,
        category: String? = nil,
        price: Decimal,
        unitPrice: Decimal? = nil,
        specialPrice: Decimal? = nil,
        bestPrice30Days: Decimal? = nil,
        anchorPrice: Decimal? = nil,
        currency: Currency = .eur,
        quantity: String? = nil,
        unit: String? = nil,
        provider: GroceryProductProvider,
        lastUpdated: Date = Date(),
        anchorPriceDate: Date? = nil,
        dateAdded: Date? = nil,
        originalData: [String: String] = [:]
    ) {
        self.id = id
        self.storeId = storeId
        self.barcode = barcode
        self.name = name
        self.brand = brand
        self.category = category
        self.price = price
        self.unitPrice = unitPrice
        self.specialPrice = specialPrice
        self.bestPrice30Days = bestPrice30Days
        self.anchorPrice = anchorPrice
        self.currency = currency
        self.quantity = quantity
        self.unit = unit
        self.provider = provider
        self.lastUpdated = lastUpdated
        self.anchorPriceDate = anchorPriceDate
        self.dateAdded = dateAdded
        self.originalData = originalData
    }
}

// MARK: - Convenience Extensions

public extension GroceryProduct {
    
    /// Formatted price string with currency symbol
    var formattedPrice: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency.rawValue
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSDecimalNumber(decimal: effectivePrice)) ?? "\(currency.symbol)\(effectivePrice)"
    }
    
    /// Formatted unit price if available
    var formattedUnitPrice: String? {
        guard let unitPrice = unitPrice, let unit = unit else { return nil }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency.rawValue
        formatter.maximumFractionDigits = 2
        let priceString = formatter.string(from: NSDecimalNumber(decimal: unitPrice)) ?? "\(currency.symbol)\(unitPrice)"
        return "\(priceString)/\(unit)"
    }
    
    /// Discount percentage if on sale
    var discountPercentage: Double? {
        guard let specialPrice = specialPrice else { return nil }
        let discount = (price - specialPrice) / price
        return Double(truncating: NSDecimalNumber(decimal: discount * 100))
    }
    
    /// Full display name with brand
    var displayName: String {
        if let brand = brand, !brand.isEmpty {
            return "\(brand) \(name)"
        }
        return name
    }
    
    /// Search-friendly text for filtering
    var searchableText: String {
        return [displayName, category, barcode]
            .compactMap { $0 }
            .joined(separator: " ")
            .lowercased()
    }
}

// MARK: - Factory Methods

public extension GroceryProduct {
    
    /// Create from Python crawler data
    static func fromCrawlerData(
        productData: [String: Any],
        provider: GroceryProductProvider,
        storeId: String
    ) -> GroceryProduct? {
        
        guard let storeid = productData["product_id"] as? String,
              let name = productData["product"] as? String,
              let priceValue = productData["price"] else {
            return nil
        }
        print(storeid)
        
        // Convert price (handle both Decimal and String from Python)
        let price: Decimal
        if let decimalPrice = priceValue as? Decimal {
            price = decimalPrice
        } else if let stringPrice = priceValue as? String {
            price = Decimal(string: stringPrice) ?? 0
        } else if let doublePrice = priceValue as? Double {
            price = Decimal(doublePrice)
        } else {
            return nil
        }
        
        // Extract optional fields
        let unitPrice = extractDecimal(from: productData["unit_price"])
        let specialPrice = extractDecimal(from: productData["special_price"])
        let bestPrice30 = extractDecimal(from: productData["best_price_30"])
        let anchorPrice = extractDecimal(from: productData["anchor_price"])
        
        // Convert original data to string dictionary
        let originalData = productData.compactMapValues { value in
            if let stringValue = value as? String {
                return stringValue
            } else {
                return String(describing: value)
            }
        }
        
        return GroceryProduct(
            storeId: "001",
            barcode: productData["barcode"] as? String,
            name: name,
            brand: productData["brand"] as? String,
            category: productData["category"] as? String,
            price: price,
            unitPrice: unitPrice,
            specialPrice: specialPrice,
            bestPrice30Days: bestPrice30,
            anchorPrice: anchorPrice,
            quantity: productData["quantity"] as? String,
            unit: productData["unit"] as? String,
            provider: provider,
            originalData: originalData
        )
    }
    
    private static func extractDecimal(from value: Any?) -> Decimal? {
        guard let value = value else { return nil }
        
        if let decimal = value as? Decimal {
            return decimal
        } else if let string = value as? String, !string.isEmpty {
            return Decimal(string: string)
        } else if let double = value as? Double {
            return Decimal(double)
        }
        return nil
    }
}

// MARK: - Sample Data for Testing

public extension GroceryProduct {
    static let sampleData: [GroceryProduct] = [
        GroceryProduct(
            storeId: "001",
            barcode: "3850104130090",
            name: "Mlijek 2.8% m.m.",
            brand: "Dukat",
            category: "Mliječni proizvodi",
            price: Decimal(string: "6.99")!,
            unitPrice: Decimal(string: "6.99")!,
            specialPrice: Decimal(string: "5.99")!,
            currency: .eur,
            quantity: "1L",
            unit: "L",
            provider: .konzum,
            originalData: ["original_field": "original_value"]
        ),
        GroceryProduct(
            storeId: "002",
            name: "Kruh bijeli",
            brand: "Klara",
            category: "Pekarnički proizvodi",
            price: Decimal(string: "3.49")!,
            unitPrice: Decimal(string: "6.98")!,
            currency: .eur,
            quantity: "500g",
            unit: "kg",
            provider: .lidl
        )
    ]
}
