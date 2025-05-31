 # Croatian Grocery Price Tracker
A comprehensive Swift package and application suite for tracking and comparing grocery prices across major Croatian retailers.

🏪 Supported Retailers
Plodine - https://www.plodine.hr/info-o-cijenama
Tommy - https://www.tommy.hr/objava-cjenika
Lidl - https://tvrtka.lidl.hr/cijene
Spar - https://www.spar.hr/usluge/cjenici
Studenac - https://www.studenac.hr/popis-maloprodajnih-cijena
dm - https://www.dm.hr/novo/promocije/nove-oznake-cijena-i-vazeci-cjenik-u-dm-u-2906632
Eurospin - https://www.eurospin.hr/cjenik/
Konzum - https://www.konzum.hr/cjenici
Kaufland - https://www.kaufland.hr/akcije-novosti/mpc-popis.html
KTC - https://www.ktc.hr/cjenici
📋 Features
Core Features
Automated Data Collection: Download price lists from all major Croatian grocery retailers
Unified Data Model: Standardized representation while preserving original field names
Price Comparison: Compare prices across different providers for the same products
Real-time Updates: Leverage Croatia's new daily price reporting regulation (NN 75/2025)
Multiple Export Formats: CSV and JSON export capabilities
Platform Support
iOS App: Native iOS application with SwiftUI interface
macOS App: Native macOS application optimized for desktop use
Command Line Tool: Automated data collection and analysis via CLI
Swift Package: Reusable core components for custom implementations
Analytics & Insights
Provider performance analytics
Category-based price analysis
Best deals identification
Savings calculations
Historical trend tracking
🏗️ Architecture
CroatianGroceryPriceTracker/
├── Sources/
│   ├── CroatianGroceryCore/          # Core business logic
│   │   ├── Models/                   # Data models (unified & provider-specific)
│   │   ├── Parsers/                  # Data parsing implementations
│   │   ├── Network/                  # Download and web scraping
│   │   ├── Services/                 # Business logic services
│   │   └── Storage/                  # Data persistence
│   ├── CroatianGroceryUI/            # SwiftUI components
│   │   └── Views/                    # UI views and view models
│   └── GroceryPriceCLI/              # Command line interface
├── Apps/
│   ├── iOS/                          # iOS application
│   └── macOS/                        # macOS application
└── Tests/                            # Unit and integration tests
🚀 Quick Start
Command Line Usage
bash
# Install the CLI tool
swift build -c release
./.build/release/grocery-price-cli --help

# Download latest prices from all providers
./.build/release/grocery-price-cli refresh

# List products from a specific provider
./.build/release/grocery-price-cli list --provider tommy --limit 10

# Compare prices across providers
./.build/release/grocery-price-cli compare --limit 5

# Search for specific products
./.build/release/grocery-price-cli search "mlijeko"

# Export data
./.build/release/grocery-price-cli export --format csv --output prices.csv

# View analytics
./.build/release/grocery-price-cli analytics
Swift Package Integration
Add to your Package.swift:

swift
dependencies: [
    .package(url: "https://github.com/your-username/CroatianGroceryPriceTracker", from: "1.0.0")
]
Basic usage:

swift
import CroatianGroceryCore

// Initialize data manager
let storage = try FileStorage()
let dataManager = DataManager(storage: storage)

// Download latest prices
let session = try await dataManager.refreshData()
print("Downloaded \(session.totalProducts) products")

// Get price comparisons
let comparisons = try await dataManager.getComparisons()
for comparison in comparisons.prefix(5) {
    print("💰 \(comparison.productName)")
    print("   Best: €\(comparison.cheapestPrice) at \(comparison.cheapestProvider.displayName)")
    print("   Savings: €\(comparison.priceDifference)")
}

// Search products
let products = try await dataManager.searchProducts(query: "kruh")
iOS/macOS App Usage
The apps provide intuitive interfaces for:

Browsing products by provider
Comparing prices across stores
Viewing analytics and trends
Exporting data for analysis
Real-time price tracking
🗃️ Data Structure
Unified Product Model
swift
struct UnifiedProduct {
    let name: String                    // Product name
    let category: String?               // Product category
    let brand: String?                  // Brand name
    let barcode: String?                // EAN/UPC code
    let unit: String                    // Unit of measure
    let unitPrice: Float              // Current price
    let pricePerUnit: Float?          // Price per kg/L
    let originalData: [String: String]  // Original provider fields
    let provider: GroceryProvider       // Source retailer
    let lastUpdated: Date              // Last update timestamp
    let isOnSale: Bool                 // Sale status
    let originalPrice: Float?        // Original price if on sale
}
Provider-Specific Models
Each retailer has its own model preserving original field names:

swift
// Plodine
struct PlodineProduct {
    let sifra_artikla: String?
    let naziv_artikla: String
    let kategorija: String?
    let jedinica_mjere: String
    let cijena: String
    // ... other fields
}

// Tommy
struct TommyProduct {
    let product_code: String?
    let product_name: String
    let category: String?
    let unit: String
    let price: String
    // ... other fields
}
🔧 Technical Implementation
Data Collection Process
Web Scraping: Automated discovery of CSV/data download links
Format Detection: Support for CSV, JSON, and XML formats
Data Parsing: Provider-specific parsers with fallback mechanisms
Unification: Conversion to standardized format while preserving originals
Storage: Persistent local storage with session tracking
Parsing Strategy
swift
// Provider-agnostic parsing with graceful fallbacks
private func convertToUnifiedProduct(_ data: [String: String], provider: GroceryProvider) async throws -> UnifiedProduct {
    switch provider {
    case .plodine:
        return try convertPlodineProduct(data)
    case .tommy:
        return try convertTommyProduct(data)
    // ... other providers
    }
}
Error Handling & Resilience
Graceful handling of provider downtime
Partial data collection when some providers fail
Automatic retry mechanisms
Comprehensive error reporting
📊 Analytics Features
Provider Analytics
Average prices by retailer
Product count comparisons
Sale frequency analysis
Price range analysis
Category Analytics
Price trends by product category
Provider coverage per category
Category-specific best deals
Savings Analysis
Total potential savings
Biggest price differences
Percentage savings calculations
Historical savings trends
🛠️ Development
Requirements
Xcode 15+
Swift 5.9+
iOS 16+ / macOS 13+
Building
bash
# Build all targets
swift build

# Run tests
swift test

# Build release
swift build -c release

# Generate Xcode project
swift package generate-xcodeproj
Adding New Providers
Add provider to GroceryProvider enum
Create provider-specific model in ProviderModels.swift
Implement parser in DataParser.swift
Add URL scraping logic in DataDownloader.swift
Update tests and documentation
Testing
bash
# Run all tests
swift test

# Run specific test suite
swift test --filter CroatianGroceryCoreTests

# Generate test coverage
swift test --enable-code-coverage
📱 App Store Submission
The iOS and macOS apps are designed for App Store distribution:

Privacy-compliant data collection
No personal data tracking
Offline-capable with local storage
Accessibility support
Multiple language support (Croatian/English)
🌍 Regulatory Compliance
This project leverages Croatia's new price transparency regulations:

NN 75/2025: Government mandate for daily price list publication
Machine-readable formats: Compliance with automated processing requirements
Real-time data: Daily updates as required by law
Consumer protection: Supporting price comparison and market transparency
🤝 Contributing
Fork the repository
Create a feature branch (git checkout -b feature/amazing-feature)
Commit your changes (git commit -m 'Add amazing feature')
Push to the branch (git push origin feature/amazing-feature)
Open a Pull Request
Contribution Guidelines
Follow Swift API Design Guidelines
Add tests for new features
Update documentation
Ensure compatibility across all platforms
Test with real data from providers
📄 License
This project is licensed under the MIT License - see the LICENSE file for details.

🙏 Acknowledgments
Croatian government for implementing price transparency regulations
All grocery retailers for providing public price data
Swift community for excellent tooling and libraries
📞 Support
📧 Email: support@example.com
🐛 Issues: GitHub Issues
💬 Discussions: GitHub Discussions
Note: This tool is designed to help consumers make informed purchasing decisions. Price data is collected from publicly available sources and may not always reflect in-store pricing. Always verify prices before making purchases.
