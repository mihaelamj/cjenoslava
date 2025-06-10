import Foundation
import GroceryProduct

public struct DownloaderFactory {
    
    public static func createDownloader(for provider: GroceryProductProvider) -> any Sendable {
        switch provider {
            // Index-based CSV downloaders
        case .konzum, .kaufland, .ktc, .eurospin, .metro, .ntl, .zabac:
            return IndexCSVDownloader()
            
            // ZIP archive downloaders
        case .lidl, .plodine, .studenac:
            return ZipArchiveDownloader()
            
            // JSON API downloaders
        case .tommy, .spar:
            return JSONAPIDownloader()
            
            // XML downloaders
        case .ribola, .trgocentar, .vrutak:
            return XMLDownloader()
            
            // Special cases
        case .dm:
            return SpecialDMDownloader()
        }
    }
}
