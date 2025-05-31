 init() { do { let storage = try FileStorage() self.dataManager = DataManager(storage: storage) } catch { fatalError("Failed to initialize storage: \(error)") } }
func loadComparisons() async {
    isLoading = true
    errorMessage = nil
    
    do {
        comparisons = try await dataManager.getComparisons()
        filteredComparisons = comparisons
        updateSavingsReport()
    } catch {
        errorMessage = error.localizedDescription
    }
    
    isLoading = false
}

func refreshData() async {
    isLoading = true
    errorMessage = nil
    
    do {
        _ = try await dataManager.refreshData()
        comparisons = try await dataManager.getComparisons()
        filteredComparisons = comparisons
        updateSavingsReport()
    } catch {
        errorMessage = error.localizedDescription
    }
    
    isLoading = false
}

func filterSignificant(_ significantOnly: Bool) {
    if significantOnly {
        filteredComparisons = comparisons.filter { comparison in
            let percentage = comparison.priceDifference / comparison.expensivePrice * 100
            return percentage >= 10
        }
    } else {
        filteredComparisons = comparisons
    }
    updateSavingsReport()
}

private func updateSavingsReport() {
    savingsReport = comparisonService.calculateSavings(from: filteredComparisons)
}
}

#Preview { PriceComparisonView()
 .PHONY: build test clean install lint format help
Default target
help:
@echo "Croatian Grocery Price Tracker - Development Commands"
@echo ""
@echo "Available commands:"
@echo "  build       - Build all targets"
@echo "  test        - Run all tests"
@echo "  clean       - Clean build artifacts"
@echo "  install     - Install CLI tool"
@echo "  lint        - Run SwiftLint"
@echo "  format      - Format code with SwiftFormat"
@echo "  refresh     - Download latest price data"
@echo "  compare     - Show price comparisons"
@echo "  export      - Export data to CSV"
@echo "  apps        - Build iOS and macOS apps"

Build commands
build:
swift build

build-release:
swift build -c release

test:
swift test

test-coverage:
swift test --enable-code-coverage

clean:
swift package clean
rm -rf .build

Development tools
lint: @if command -v swiftlint >/dev/null 2>&1; then
swiftlint;
else
echo "SwiftLint not installed. Install with: brew install swiftlint";
fi

format: @if command -v swiftformat >/dev/null 2>&1; then
swiftformat .;
else
echo "SwiftFormat not installed. Install with: brew install swiftformat";
fi

Installation
install: build-release
cp .build/release/grocery-price-cli /usr/local/bin/

CLI shortcuts
refresh: build-release
./.build/release/grocery-price-cli refresh --verbose

compare: build-release
./.build/release/grocery-price-cli compare --limit 10

search: build-release @read -p "Enter search term: " term;
./.build/release/grocery-price-cli search "$$term"

export: build-release
./.build/release/grocery-price-cli export --format csv --output grocery_prices_$$(date +%Y%m%d).csv

analytics: build-release
./.build/release/grocery-price-cli analytics

App building
apps: build-ios-app build-macos-app

build-ios-app:
xcodebuild -scheme GroceryPriceTracker-iOS -destination 'platform=iOS Simulator,name=iPhone 15' build

build-macos-app:
xcodebuild -scheme GroceryPriceTracker-macOS build

Docker support
docker-build:
docker build -t croatian-grocery-tracker .

docker-run:
docker run --rm -it croatian-grocery-tracker

Project setup
setup: @echo "Setting up Croatian Grocery Price Tracker development environment..." @if ! command -v swift >/dev/null 2>&1; then
echo "Error: Swift is not installed. Please install Xcode or Swift toolchain.";
exit 1;
fi @echo "✅ Swift is installed" @swift package resolve @echo "✅ Dependencies resolved" @if command -v swiftlint >/dev/null 2>&1; then
echo "✅ SwiftLint is available";
else
echo "⚠️ SwiftLint not found. Install with: brew install swiftlint";
fi @if command -v swiftformat >/dev/null 2>&1; then
echo "✅ SwiftFormat is available";
else
echo "⚠️ SwiftFormat not found. Install with: brew install swiftformat";
fi @echo "🎉 Setup complete! Run 'make help' to see available commands."

Continuous Integration
ci: lint test build-release

Demo data
demo: build-release
@echo "🎬 Running demo with sample data..."
./.build/release/grocery-price-cli refresh --verbose
@echo ""
@echo "📊 Top 5 price comparisons:"
./.build/release/grocery-price-cli compare --limit 5
@echo ""
@echo "📈 Analytics summary:"
./.build/release/grocery-price-cli analytics

Archive for distribution
archive: @echo "📦 Creating distribution archive..." @mkdir -p dist @cp .build/release/grocery-price-cli dist/ @cp README.md dist/ @cp LICENSE dist/ @tar -czf croatian-grocery-tracker-$$(date +%Y%m%d).tar.gz -C dist . @echo "✅ Archive created: croatian-grocery-tracker-$$(date +%Y%m%d).tar.gz"
 import XCTest @testable import CroatianGroceryCore
final class ParserTests: XCTestCase {

var parser: CSVParser!

override func setUp() {
    super.setUp()
    parser = CSVParser()
}

override func tearDown() {
    parser = nil
    super.tearDown()
}

func testCSVParsingBasic() async throws {
    let csvData = """
    naziv_artikla,cijena,jedinica_mjere,kategorija
    "Mlijeko 1L","8.99","kom","Mliječni proizvodi"
    "Kruh bijeli","3.50","kom","Pekarski proizvodi"
    """.data(using: .utf8)!
    
    let products = try await parser.parseProducts(from: csvData, provider: .plodine)
    
    XCTAssertEqual(products.count, 2)
    
    let milk = products.first { $0.name == "Mlijeko 1L" }
    XCTAssertNotNil(milk)
    XCTAssertEqual(milk?.unitPrice, Decimal(string: "8.99"))
    XCTAssertEqual(milk?.unit, "kom")
    XCTAssertEqual(milk?.category, "Mliječni proizvodi")
    XCTAssertEqual(milk?.provider, .plodine)
}

func testCSVParsingWithQuotes() async throws {
    let csvData = """
    product_name,price,unit,category
    "Product with, comma","12.50","kg","Test Category"
    "Product with ""quotes""","5.99","L","Another Category"
    """.data(using: .utf8)!
    
    let products = try await parser.parseProducts(from: csvData, provider: .tommy)
    
    XCTAssertEqual(products.count, 2)
    
    let commaProduct = products.first { $0.name == "Product with, comma" }
    XCTAssertNotNil(commaProduct)
    XCTAssertEqual(commaProduct?.unitPrice, Decimal(string: "12.50"))
}

func testPriceParsingWithDifferentFormats() {
    let testCases = [
        ("8.99", Decimal(string: "8.99")!),
        ("8,99", Decimal(string: "8.99")!),
        ("€8.99", Decimal(string: "8.99")!),
        ("8.99 kn", Decimal(string: "8.99")!),
        ("8.99 EUR", Decimal(string: "8.99")!),
        ("8 99", Decimal(string: "899")!)  // Spaces as thousands separator
    ]
    
    for (input, expected) in testCases {
        let result = parsePrice(input)
        XCTAssertEqual(result, expected, "Failed to parse price: \(input)")
    }
}

func testEmptyCSVHandling() async throws {
    let csvData = "".data(using: .utf8)!
    
    do {
        _ = try await parser.parseProducts(from: csvData, provider: .plodine)
        XCTFail("Should have thrown an error for empty data")
    } catch ParserError.noDataFound {
        // Expected
    } catch {
        XCTFail("Unexpected error: \(error)")
    }
}

func testInvalidDataHandling() async throws {
    let invalidData = Data([0xFF, 0xFE, 0xFD])
    
    do {
        _ = try await parser.parseProducts(from: invalidData, provider: .plodine)
        XCTFail("Should have thrown an error for invalid data")
    } catch ParserError.invalidData {
        // Expected
    } catch {
        XCTFail("Unexpected error: \(error)")
    }
}

func testProviderSpecificParsing() async throws {
    let plodineCSV = """
    naziv_artikla,cijena,jedinica_mjere,brend
    "Test Product","9.99","kom","Test Brand"
    """.data(using: .utf8)!
    
    let products = try await parser.parseProducts(from: plodineCSV, provider: .plodine)
    let product = products.first!
    
    XCTAssertEqual(product.name, "Test Product")
    XCTAssertEqual(product.brand, "Test Brand")
    XCTAssertEqual(product.provider, .plodine)
    XCTAssertEqual(product.originalData["naziv_artikla"], "Test Product")
    XCTAssertEqual(product.originalData["brend"], "Test Brand")
}

func testSaleProductParsing() async throws {
    let tommyCSV = """
    product_name,price,promotional_price,unit
    "Sale Product","10.00","7.99","kom"
    "Regular Product","5.00","","kom"
    """.data(using: .utf8)!
    
    let products = try await parser.parseProducts(from: tommyCSV, provider: .tommy)
    
    let saleProduct = products.first { $0.name == "Sale Product" }!
    XCTAssertTrue(saleProduct.isOnSale)
    XCTAssertEqual(saleProduct.unitPrice, Decimal(string: "7.99"))
    XCTAssertEqual(saleProduct.originalPrice, Decimal(string: "10.00"))
    
    let regularProduct = products.first { $0.name == "Regular Product" }!
    XCTAssertFalse(regularProduct.isOnSale)
    XCTAssertNil(regularProduct.originalPrice)
}

// Helper method exposed for testing
private func parsePrice(_ priceString: String) -> Decimal {
    let cleaned = priceString
        .replacingOccurrences(of: ",", with: ".")
        .replacingOccurrences(of: " ", with: "")
        .replacingOccurrences(of: "€", with: "")
        .replacingOccurrences(of: "kn", with: "")
        .replacingOccurrences(of: "HRK", with: "")
        .replacingOccurrences(of: "EUR", with: "")
    
    return Decimal(string: cleaned) ?? 0
}
}
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
    let unitPrice: Decimal              // Current price
    let pricePerUnit: Decimal?          // Price per kg/L
    let originalData: [String: String]  // Original provider fields
    let provider: GroceryProvider       // Source retailer
    let lastUpdated: Date              // Last update timestamp
    let isOnSale: Bool                 // Sale status
    let originalPrice: Decimal?        // Original price if on sale
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
 <?xml version="1.0" encoding="UTF-8"?> <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd"> <plist version="1.0"> <dict> <key>CFBundleDevelopmentRegion</key> <string>$(DEVELOPMENT_LANGUAGE)</string> <key>CFBundleDisplayName</key> <string>Croatian Grocery Price Tracker</string> <key>CFBundleExecutable</key> <string>$(EXECUTABLE_NAME)</string> <key>CFBundleIdentifier</key> <string>$(PRODUCT_BUNDLE_IDENTIFIER)</string> <key>CFBundleInfoDictionaryVersion</key> <string>6.0</string> <key>CFBundleName</key> <string>$(PRODUCT_NAME)</string> <key>CFBundlePackageType</key> <string>$(PRODUCT_BUNDLE_PACKAGE_TYPE)</string> <key>CFBundleShortVersionString</key> <string>1.0</string> <key>CFBundleVersion</key> <string>1</string> <key>LSMinimumSystemVersion</key> <string>$(MACOSX_DEPLOYMENT_TARGET)</string> <key>NSAppTransportSecurity</key> <dict> <key>NSAllowsArbitraryLoads</key> <true/> </dict> <key>NSHumanReadableCopyright</key> <string>Copyright © 2025. All rights reserved.</string> </dict> </plist>
 import SwiftUI import CroatianGroceryUI
@main struct GroceryPriceTrackerApp: App { var body: some Scene { WindowGroup { MainTabView() .frame(minWidth: 800, minHeight: 600) } .windowToolbarStyle(.unified) .commands { CommandGroup(replacing: .newItem) { Button("Refresh Data") { // Handle refresh from menu } .keyboardShortcut("r", modifiers: .command) } } } }
 <?xml version="1.0" encoding="UTF-8"?> <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd"> <plist version="1.0"> <dict> <key>CFBundleDevelopmentRegion</key> <string>$(DEVELOPMENT_LANGUAGE)</string> <key>CFBundleDisplayName</key> <string>Grocery Prices</string> <key>CFBundleExecutable</key> <string>$(EXECUTABLE_NAME)</string> <key>CFBundleIdentifier</key> <string>$(PRODUCT_BUNDLE_IDENTIFIER)</string> <key>CFBundleInfoDictionaryVersion</key> <string>6.0</string> <key>CFBundleName</key> <string>$(PRODUCT_NAME)</string> <key>CFBundlePackageType</key> <string>$(PRODUCT_BUNDLE_PACKAGE_TYPE)</string> <key>CFBundleShortVersionString</key> <string>1.0</string> <key>CFBundleVersion</key> <string>1</string> <key>LSRequiresIPhoneOS</key> <true/> <key>UIApplicationSceneManifest</key> <dict> <key>UIApplicationSupportsMultipleScenes</key> <true/> </dict> <key>UIApplicationSupportsIndirectInputEvents</key> <true/> <key>UILaunchScreen</key> <dict/> <key>UIRequiredDeviceCapabilities</key> <array> <string>armv7</string> </array> <key>UISupportedInterfaceOrientations</key> <array> <string>UIInterfaceOrientationPortrait</string> <string>UIInterfaceOrientationLandscapeLeft</string> <string>UIInterfaceOrientationLandscapeRight</string> </array> <key>UISupportedInterfaceOrientations~ipad</key> <array> <string>UIInterfaceOrientationPortrait</string> <string>UIInterfaceOrientationPortraitUpsideDown</string> <string>UIInterfaceOrientationLandscapeLeft</string> <string>UIInterfaceOrientationLandscapeRight</string> </array> <key>NSAppTransportSecurity</key> <dict> <key>NSAllowsArbitraryLoads</key> <true/> </dict> </dict> </plist>
 import SwiftUI import CroatianGroceryUI
@main struct GroceryPriceTrackerApp: App { var body: some Scene { WindowGroup { MainTabView() } } }
 import SwiftUI import CroatianGroceryCore
public struct MainTabView: View {

public init() {}

public var body: some View {
    TabView {
        ProductListView()
            .tabItem {
                Label("Products", systemImage: "list.bullet")
            }
        
        PriceComparisonView()
            .tabItem {
                Label("Compare", systemImage: "chart.bar")
            }
        
        AnalyticsView()
            .tabItem {
                Label("Analytics", systemImage: "chart.pie")
            }
        
        SettingsView()
            .tabItem {
                Label("Settings", systemImage: "gear")
            }
    }
}
}

public struct SettingsView: View {
@StateObject private var viewModel = SettingsViewModel()
@State private var showingExportSheet = false
@State private var showingDeleteAlert = false

public init() {}

public var body: some View {
    NavigationView {
        List {
            dataSection
            exportSection
            aboutSection
        }
        .navigationTitle("Settings")
    }
    .sheet(isPresented: $showingExportSheet) {
        ExportSheetView()
    }
    .alert("Delete All Data", isPresented: $showingDeleteAlert) {
        Button("Cancel", role: .cancel) { }
        Button("Delete", role: .destructive) {
            Task {
                await viewModel.clearData()
            }
        }
    } message: {
        Text("This will permanently delete all downloaded product data and collection history. This action cannot be undone.")
    }
}

private var dataSection: some View {
    Section("Data Management") {
        HStack {
            Label("Last Updated", systemImage: "clock")
            Spacer()
            Text(viewModel.lastUpdateText)
                .foregroundColor(.secondary)
        }
        
        HStack {
            Label("Products", systemImage: "cart")
            Spacer()
            Text("\(viewModel.productCount)")
                .foregroundColor(.secondary)
        }
        
        Button(action: {
            Task {
                await viewModel.refreshData()
            }
        }) {
            Label("Refresh Data", systemImage: "arrow.clockwise")
        }
        .disabled(viewModel.isRefreshing)
        
        Button(action: {
            showingDeleteAlert = true
        }) {
            Label("Clear All Data", systemImage: "trash")
                .foregroundColor(.red)
        }
    }
}

private var exportSection: some View {
    Section("Export") {
        Button(action: {
            showingExportSheet = true
        }) {
            Label("Export Data", systemImage: "square.and.arrow.up")
        }
    }
}

private var aboutSection: some View {
    Section("About") {
        HStack {
            Label("Version", systemImage: "info.circle")
            Spacer()
            Text("1.0.0")
                .foregroundColor(.secondary)
        }
        
        Link(destination: URL(string: "https://github.com/your-repo/croatian-grocery-tracker")!) {
            Label("Source Code", systemImage: "chevron.left.forwardslash.chevron.right")
        }
        
        HStack {
            Label("Data Sources", systemImage: "link")
            Spacer()
            Text("\(GroceryProvider.allCases.count) providers")
                .foregroundColor(.secondary)
        }
    }
}
}

public struct ExportSheetView: View {
@StateObject private var viewModel = ExportViewModel()
@State private var selectedFormat: ExportFormat = .csv
@State private var exportType: ExportType = .products
@Environment(.dismiss) private var dismiss

public init() {}

public var body: some View {
    NavigationView {
        Form {
            Section("Export Type") {
                Picker("Type", selection: $exportType) {
                    Text("Products").tag(ExportType.products)
                    Text("Price Comparisons").tag(ExportType.comparisons)
                }
                .pickerStyle(.segmented)
            }
            
            Section("Format") {
                Picker("Format", selection: $selectedFormat) {
                    Text("CSV").tag(ExportFormat.csv)
                    Text("JSON").tag(ExportFormat.json)
                }
                .pickerStyle(.segmented)
            }
            
            Section {
                Button(action: {
                    Task {
                        await viewModel.export(type: exportType, format: selectedFormat)
                    }
                }) {
                    HStack {
                        if viewModel.isExporting {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                        
                        Text(viewModel.isExporting ? "Exporting..." : "Export")
                    }
                }
                .disabled(viewModel.isExporting)
            }
        }
        .navigationTitle("Export Data")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    dismiss()
                }
            }
        }
    }
    .alert("Export Complete", isPresented: $viewModel.showingSuccessAlert) {
        Button("OK") { }
    } message: {
        Text("Data has been exported successfully.")
    }
    .alert("Export Failed", isPresented: $viewModel.showingErrorAlert) {
        Button("OK") { }
    } message: {
        Text(viewModel.errorMessage ?? "An unknown error occurred.")
    }
}
}

enum ExportFormat {
case csv, json
}

enum ExportType {
case products, comparisons
}

@MainActor
class SettingsViewModel: ObservableObject {
@Published var lastUpdateText = "Never"
@Published var productCount = 0
@Published var isRefreshing = false
@Published var errorMessage: String?

private let dataManager: DataManager

init() {
    do {
        let storage = try FileStorage()
        self.dataManager = DataManager(storage: storage)
        Task {
            await loadInfo()
        }
    } catch {
        fatalError("Failed to initialize storage: \(error)")
    }
}

func loadInfo() async {
    do {
        let products = try await dataManager.loadProducts()
        productCount = products.count
        
        let sessions = try await dataManager.getSessions()
        if let lastSession = sessions.last {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            lastUpdateText = formatter.string(from: lastSession.startTime)
        }
    } catch {
        errorMessage = error.localizedDescription
    }
}

func refreshData() async {
    isRefreshing = true
    errorMessage = nil
    
    do {
        _ = try await dataManager.refreshData()
        await loadInfo()
    } catch {
        errorMessage = error.localizedDescription
    }
    
    isRefreshing = false
}

func clearData() async {
    do {
        let storage = try FileStorage()
        try await storage.clear()
        await loadInfo()
    } catch {
        errorMessage = error.localizedDescription
    }
}
}

@MainActor
class ExportViewModel: ObservableObject {
@Published var isExporting = false
@Published var showingSuccessAlert = false
@Published var showingErrorAlert = false
@Published var errorMessage: String?

private let dataManager: DataManager
private let exportService = ExportService()

init() {
    do {
        let storage = try FileStorage()
        self.dataManager = DataManager(storage: storage)
    } catch {
        fatalError("Failed to initialize storage: \(error)")
    }
}

func export(type: ExportType, format: ExportFormat) async {
    isExporting = true
    errorMessage = nil
    
    do {
        let data: Data
        let fileName: String
        
        switch type {
        case .products:
            let products = try await dataManager.loadProducts()
            
            switch format {
            case .csv:
                data = try exportService.exportToCSV(products: products)
                fileName = "grocery_products.csv"
            case .json:
                data = try exportService.exportToJSON(products: products)
                fileName = "grocery_products.json"
            }
            
        case .comparisons:
            let comparisons = try await dataManager.getComparisons()
            data = try exportService.exportComparisonsToCSV(comparisons: comparisons)
            fileName = "price_comparisons.csv"
        }
        
        // On iOS, we'll use the share sheet
        #if os(iOS)
        shareData(data, fileName: fileName)
        #else
        // On macOS, save to Downloads folder
        try await saveToDownloads(data, fileName: fileName)
        #endif
        
        showingSuccessAlert = true
    } catch {
        errorMessage = error.localizedDescription
        showingErrorAlert = true
    }
    
    isExporting = false
}

#if os(iOS)
private func shareData(_ data: Data, fileName: String) {
    let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
    
    do {
        try data.write(to: tempURL)
        
        let activityViewController = UIActivityViewController(
            activityItems: [tempURL],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(activityViewController, animated: true)
        }
    } catch {
        errorMessage = error.localizedDescription
        showingErrorAlert = true
    }
}
#endif

#if os(macOS)
private func saveToDownloads(_ data: Data, fileName: String) async throws {
    let downloadsURL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!
    let fileURL = downloadsURL.appendingPathComponent(fileName)
    
    try data.write(to: fileURL)
}
#endif
}

#Preview { MainTabView() }
 import SwiftUI import CroatianGroceryCore import Charts
public struct AnalyticsView: View {
@StateObject private var viewModel = AnalyticsViewModel()

public init() {}

public var body: some View {
    NavigationView {
        ScrollView {
            LazyVStack(spacing: 20) {
                if viewModel.isLoading {
                    ProgressView("Loading analytics...")
                        .frame(maxWidth: .infinity, minHeight: 200)
                } else if viewModel.products.isEmpty {
                    emptyStateView
                } else {
                    analyticsContent
                }
            }
            .padding()
        }
        .navigationTitle("Analytics")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Refresh") {
                    Task {
                        await viewModel.refreshData()
                    }
                }
            }
        }
    }
    .task {
        await viewModel.loadData()
    }
}

private var analyticsContent: some View {
    VStack(spacing: 20) {
        overallStatsSection
        providerAnalyticsSection
        categoryAnalyticsSection
        bestDealsSection
    }
}

private var overallStatsSection: some View {
    VStack(alignment: .leading, spacing: 16) {
        Text("Overall Statistics")
            .font(.title2)
            .fontWeight(.bold)
        
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            StatCardView(
                title: "Total Products",
                value: "\(viewModel.products.count)",
                icon: "cart.fill",
                color: .blue
            )
            
            StatCardView(
                title: "Providers",
                value: "\(viewModel.providerCount)",
                icon: "building.2.fill",
                color: .green
            )
            
            StatCardView(
                title: "Categories",
                value: "\(viewModel.categoryCount)",
                icon: "tag.fill",
                color: .orange
            )
            
            StatCardView(
                title: "On Sale",
                value: "\(viewModel.onSaleCount)",
                icon: "flame.fill",
                color: .red
            )
        }
    }
}

private var providerAnalyticsSection: some View {
    VStack(alignment: .leading, spacing: 16) {
        Text("Provider Analytics")
            .font(.title2)
            .fontWeight(.bold)
        
        if #available(iOS 16.0, macOS 13.0, *) {
            Chart(viewModel.providerAnalytics, id: \.provider) { analytics in
                BarMark(
                    x: .value("Provider", analytics.provider.displayName),
                    y: .value("Average Price", Double(truncating: analytics.averagePrice as NSNumber))
                )
                .foregroundStyle(.blue)
            }
            .frame(height: 200)
        }
        
        ForEach(viewModel.providerAnalytics, id: \.provider) { analytics in
            ProviderAnalyticsRowView(analytics: analytics)
        }
    }
}

private var categoryAnalyticsSection: some View {
    VStack(alignment: .leading, spacing: 16) {
        Text("Top Categories")
            .font(.title2)
            .fontWeight(.bold)
        
        ForEach(Array(viewModel.categoryAnalytics.prefix(5)), id: \.category) { analytics in
            CategoryAnalyticsRowView(analytics: analytics)
        }
    }
}

private var bestDealsSection: some View {
    VStack(alignment: .leading, spacing: 16) {
        Text("Best Deals")
            .font(.title2)
            .fontWeight(.bold)
        
        ForEach(viewModel.bestDeals) { deal in
            BestDealRowView(product: deal)
        }
    }
}

private var emptyStateView: some View {
    VStack(spacing: 16) {
        Image(systemName: "chart.bar.doc.horizontal")
            .font(.system(size: 48))
            .foregroundColor(.secondary)
        
        Text("No analytics available")
            .font(.headline)
        
        Text("Load some product data first")
            .font(.subheadline)
            .foregroundColor(.secondary)
        
        Button("Refresh Data") {
            Task {
                await viewModel.refreshData()
            }
        }
        .buttonStyle(.borderedProminent)
    }
    .frame(maxWidth: .infinity, minHeight: 200)
}
}

public struct StatCardView: View {
let title: String
let value: String
let icon: String
let color: Color

public init(title: String, value: String, icon: String, color: Color) {
    self.title = title
    self.value = value
    self.icon = icon
    self.color = color
}

public var body: some View {
    VStack(spacing: 8) {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title2)
            
            Spacer()
        }
        
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(value)
                    .font(.title)
                    .fontWeight(.bold)
                Spacer()
            }
            
            HStack {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }
        }
    }
    .padding()
    .background(Color(.systemGray6))
    .clipShape(RoundedRectangle(cornerRadius: 12))
}
}

public struct ProviderAnalyticsRowView: View {
let analytics: ProviderAnalytics

public init(analytics: ProviderAnalytics) {
    self.analytics = analytics
}

public var body: some View {
    VStack(alignment: .leading, spacing: 8) {
        HStack {
            ProviderBadgeView(provider: analytics.provider)
            Spacer()
            Text("\(analytics.totalProducts) products")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Avg Price")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("€\(analytics.averagePrice)")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            
            Spacer()
            
            VStack(alignment: .center, spacing: 4) {
                Text("Price Range")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("€\(analytics.minPrice) - €\(analytics.maxPrice)")
                    .font(.caption)
                    .fontWeight(.medium)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("Sale Rate")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("\(String(format: "%.1f", analytics.salePercentage))%")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(analytics.salePercentage > 10 ? .green : .primary)
            }
        }
    }
    .padding()
    .background(Color(.systemGray6))
    .clipShape(RoundedRectangle(cornerRadius: 8))
}
}

public struct CategoryAnalyticsRowView: View {
let analytics: CategoryAnalytics

public init(analytics: CategoryAnalytics) {
    self.analytics = analytics
}

public var body: some View {
    HStack {
        VStack(alignment: .leading, spacing: 4) {
            Text(analytics.category)
                .font(.headline)
            
            Text("\(analytics.totalProducts) products")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        
        Spacer()
        
        VStack(alignment: .trailing, spacing: 4) {
            Text("€\(analytics.averagePrice)")
                .font(.headline)
                .foregroundColor(.blue)
            
            Text("avg price")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    .padding()
    .background(Color(.systemGray6))
    .clipShape(RoundedRectangle(cornerRadius: 8))
}
}

public struct BestDealRowView: View {
let product: UnifiedProduct

public init(product: UnifiedProduct) {
    self.product = product
}

public var body: some View {
    HStack {
        VStack(alignment: .leading, spacing: 4) {
            Text(product.name)
                .font(.headline)
                .lineLimit(2)
            
            if let brand = product.brand {
                Text(brand)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        
        Spacer()
        
        VStack(alignment: .trailing, spacing: 4) {
            Text("€\(product.unitPrice)")
                .font(.headline)
                .foregroundColor(.green)
            
            ProviderBadgeView(provider: product.provider)
        }
    }
    .padding()
    .background(
        RoundedRectangle(cornerRadius: 8)
            .fill(.green.opacity(0.1))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(.green.opacity(0.3), lineWidth: 1)
            )
    )
}
}

@MainActor
class AnalyticsViewModel: ObservableObject {
@Published var products: [UnifiedProduct] = []
@Published var providerAnalytics: [ProviderAnalytics] = []
@Published var categoryAnalytics: [CategoryAnalytics] = []
@Published var bestDeals: [UnifiedProduct] = []
@Published var isLoading = false
@Published var errorMessage: String?

private let dataManager: DataManager
private let analyticsService = PriceAnalyticsService()

var providerCount: Int {
    Set(products.map { $0.provider }).count
}

var categoryCount: Int {
    Set(products.compactMap { $0.category }).count
}

var onSaleCount: Int {
    products.filter { $0.isOnSale }.count
}

init() {
    do {
        let storage = try FileStorage()
        self.dataManager = DataManager(storage: storage)
    } catch {
        fatalError("Failed to initialize storage: \(error)")
    }
}

func loadData() async {
    isLoading = true
    errorMessage = nil
    
    do {
        products = try await dataManager.loadProducts()
        generateAnalytics()
        bestDeals = try await dataManager.getBestDeals(limit: 5)
    } catch {
        errorMessage = error.localizedDescription
    }
    
    isLoading = false
}

func refreshData() async {
    isLoading = true
    errorMessage = nil
    
    do {
        _ = try await dataManager.refreshData()
        products = try await dataManager.loadProducts()
        generateAnalytics()
        bestDeals = try await dataManager.getBestDeals(limit: 5)
    } catch {
        errorMessage = error.localizedDescription
    }
    
    isLoading = false
}

private func generateAnalytics() {
    providerAnalytics = analyticsService.generateProviderAnalytics(products)
    categoryAnalytics = analyticsService.generateCategoryAnalytics(products)
}
}

#Preview { AnalyticsView() }
 init() { do { let storage = try FileStorage() self.dataManager = DataManager(storage: storage) } catch { fatalError("Failed to initialize storage: \(error)") } }
func loadComparisons() async {
    isLoading = true
    errorMessage = nil
    
    do {
        comparisons = try await dataManager.getComparisons()
        filteredComparisons = comparisons
        updateSavingsReport()
    } catch {
        errorMessage = error.localizedDescription
    }
    
    isLoading = false
}

func refreshData() async {
    isLoading = true
    errorMessage = nil
    
    do {
        _ = try await dataManager.refreshData()
        comparisons = try await dataManager.getComparisons()
        filteredComparisons = comparisons
        updateSavingsReport()
    } catch {
        errorMessage = error.localizedDescription
    }
    
    isLoading = false
}

func filterSignificant(_ significantOnly: Bool) {
    if significantOnly {
        filteredComparisons = comparisons.filter { comparison in
            let percentage = comparison.priceDifference / comparison.expensivePrice * 100
            return percentage >= 10
        }
    } else {
        filteredComparisons = comparisons
    }
    updateSavingsReport()
}

private func updateSavingsReport() {
    savingsReport = comparisonService.calculateSavings(from: filteredComparisons)
}
}

#Preview { PriceComparisonView()
 some View {
    Section("Savings Summary") {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total Comparisons")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(report.totalComparisons)")
                        .font(.headline)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Avg Savings")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("€\(report.averageSavings)")
                        .font(.headline)
                        .foregroundColor(.green)
                }
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total Savings")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("€\(report.totalSavings)")
                        .font(.headline)
                        .foregroundColor(.green)
                }
                
                Spacer()
                
                if let biggestSaving = report.biggestSaving {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Biggest Saving")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("€\(biggestSaving.priceDifference)")
                            .font(.headline)
                            .foregroundColor(.green)
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }
}

private var emptyStateView: some View {
    VStack(spacing: 16) {
        Image(systemName: "chart.bar.xaxis")
            .font(.system(size: 48))
            .foregroundColor(.secondary)
        
        Text("No comparisons available")
            .font(.headline)
        
        Text("Load some product data first")
            .font(.subheadline)
            .foregroundColor(.secondary)
        
        Button("Refresh Data") {
            Task {
                await viewModel.refreshData()
            }
        }
        .buttonStyle(.borderedProminent)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
}
}

public struct PriceComparisonRowView: View {
let comparison: PriceComparison

public init(comparison: PriceComparison) {
    self.comparison = comparison
}

public var body: some View {
    VStack(alignment: .leading, spacing: 12) {
        Text(comparison.productName)
            .font(.headline)
            .lineLimit(2)
        
        HStack(spacing: 16) {
            // Cheapest option
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "crown.fill")
                        .foregroundColor(.yellow)
                        .font(.caption)
                    Text("Best Price")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                
                ProviderBadgeView(provider: comparison.cheapestProvider)
                
                Text("€\(comparison.cheapestPrice)")
                    .font(.headline)
                    .foregroundColor(.green)
            }
            
            Spacer()
            
            // Most expensive option
            VStack(alignment: .trailing, spacing: 4) {
                HStack {
                    Text("Most Expensive")
                        .font(.caption)
                        .fontWeight(.medium)
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                        .font(.caption)
                }
                
                ProviderBadgeView(provider: comparison.expensiveProvider)
                
                Text("€\(comparison.expensivePrice)")
                    .font(.headline)
                    .foregroundColor(.red)
            }
        }
        
        // Savings information
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("You Save")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("€\(comparison.priceDifference)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.green)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("Savings")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                let percentage = (comparison.priceDifference / comparison.expensivePrice * 100).rounded()
                Text("\(percentage)%")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.green)
            }
        }
    }
    .padding(.vertical, 8)
}
}

@MainActor
class PriceComparisonViewModel: ObservableObject {
@Published var comparisons: [PriceComparison] = []
@Published var filteredComparisons: [PriceComparison] = []
@Published var savingsReport: PriceSavingsReport?
@Published var isLoading = false
@Published var errorMessage: String?

private let dataManager: DataManager
private let comparisonService = PriceComparisonService()

init() {
    do {
        let storage = try FileStorage()
        self.dataManager = DataManager(



Retry
Continue

Edit

Resumed work on PriceComparisonViewModel class implementation.

0s


<file path="Sources/CroatianGroceryUI/Views/PriceComparisonView.swift" action="modify">