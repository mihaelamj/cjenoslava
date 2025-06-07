import Foundation

public struct StoreDataRequest: Sendable {
    public let provider: GroceryProductProvider
    public let date: Date
    public let storeId: String?
    public let additionalParameters: [String: String]
    
    public init(provider: GroceryProductProvider,
                date: Date,
                storeId: String? = nil,
                additionalParameters: [String: String] = [:]) {
        self.provider = provider
        self.date = date
        self.storeId = storeId
        self.additionalParameters = additionalParameters
    }
}
