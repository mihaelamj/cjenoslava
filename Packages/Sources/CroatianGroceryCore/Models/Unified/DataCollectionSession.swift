import Foundation

/// Data collection session information
public struct DataCollectionSession: Codable, Identifiable, Sendable {
    public let id: UUID
    public let startTime: Date
    public let endTime: Date?
    public let providers: [ShopProvider]
    public let totalProducts: Int
    public let successfulProviders: [ShopProvider]
    public let failedProviders: [ShopProvider: String] // Provider: Error message
    
    public init(
        id: UUID = UUID(),
        startTime: Date = Date(),
        endTime: Date? = nil,
        providers: [ShopProvider],
        totalProducts: Int = 0,
        successfulProviders: [ShopProvider] = [],
        failedProviders: [ShopProvider: String] = [:]
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
