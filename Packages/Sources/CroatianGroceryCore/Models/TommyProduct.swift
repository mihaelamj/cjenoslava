import Foundation

// swiftlint:disable all

public struct TommyProduct: Codable {
    public let product_code: String?
    public let product_name: String
    public let category: String?
    public let unit: String
    public let price: String
    public let unit_price: String?
    public let ean: String?
    public let brand: String?
    public let last_updated: String?
    public let promotional_price: String?
    
    public init(product_code: String?, product_name: String, category: String?, unit: String, price: String, unit_price: String?, ean: String?, brand: String?, last_updated: String?, promotional_price: String?) {
        self.product_code = product_code
        self.product_name = product_name
        self.category = category
        self.unit = unit
        self.price = price
        self.unit_price = unit_price
        self.ean = ean
        self.brand = brand
        self.last_updated = last_updated
        self.promotional_price = promotional_price
    }
}
