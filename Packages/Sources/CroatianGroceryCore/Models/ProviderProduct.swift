import Foundation

public protocol ProviderProduct: Decodable {
    func toUnifiedProduct() -> UnifiedProduct
}
