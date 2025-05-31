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