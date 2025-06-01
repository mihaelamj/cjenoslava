import Foundation

// swiftlint:disable all

public struct SparProduct: Codable {
    public let item_id: String?
    public let item_name: String
    public let category_name: String?
    public let unit_type: String
    public let retail_price: String
    public let price_per_unit: String?
    public let barcode: String?
    public let brand_name: String?
    public let updated_date: String?
    public let sale_price: String?
    
    public init(item_id: String?, item_name: String, category_name: String?, unit_type: String, retail_price: String, price_per_unit: String?, barcode: String?, brand_name: String?, updated_date: String?, sale_price: String?) {
        self.item_id = item_id
        self.item_name = item_name
        self.category_name = category_name
        self.unit_type = unit_type
        self.retail_price = retail_price
        self.price_per_unit = price_per_unit
        self.barcode = barcode
        self.brand_name = brand_name
        self.updated_date = updated_date
        self.sale_price = sale_price
    }
}
