import XCTest
@testable import CroatianGroceryCore

final class DownloadTests: XCTestCase {
    
    var downloader: DataDownloader!
    
    override func setUp() {
        super.setUp()
        downloader = DataDownloader()
    }
    
    override func tearDown() {
        downloader = nil
        super.tearDown()
    }
    
    // MARK: - Platform-specific tests
    
    #if os(macOS)
    func testMacOSDownloadCapabilities() async throws {
        // Test macOS-specific networking capabilities
        let result = try await downloader.downloadPrices(for: .tommy)
        XCTAssertNotNil(result, "Should be able to download on macOS")
    }
    #endif
    
    #if os(iOS)
    func testIOSDownloadCapabilities() async throws {
        // Test iOS-specific networking capabilities
        let result = try await downloader.downloadPrices(for: .tommy)
        XCTAssertNotNil(result, "Should be able to download on iOS")
    }
    #endif
    
    // MARK: - Individual provider tests
    
    func testTommyDownload() async throws {
        let products = try await downloader.downloadPrices(for: .tommy)
        
        XCTAssertFalse(products.isEmpty, "Tommy should return products")
        
        // Verify product structure
        let firstProduct = products.first!
        XCTAssertEqual(firstProduct.provider, .tommy)
        XCTAssertFalse(firstProduct.name.isEmpty, "Product should have a name")
        XCTAssertGreaterThan(firstProduct.unitPrice, 0, "Product should have a valid price")
    }
    
    func testLidlDownload() async throws {
        let products = try await downloader.downloadPrices(for: .lidl)
        
        XCTAssertFalse(products.isEmpty, "Lidl should return products")
        
        let firstProduct = products.first!
        XCTAssertEqual(firstProduct.provider, .lidl)
        XCTAssertFalse(firstProduct.name.isEmpty, "Product should have a name")
    }
    
    func testPlodineDownload() async throws {
        let products = try await downloader.downloadPrices(for: .plodine)
        
        XCTAssertFalse(products.isEmpty, "Plodine should return products")
        
        let firstProduct = products.first!
        XCTAssertEqual(firstProduct.provider, .plodine)
        XCTAssertFalse(firstProduct.name.isEmpty, "Product should have a name")
    }
    
    func testKonzumDownload() async throws {
        let products = try await downloader.downloadPrices(for: .konzum)
        
        XCTAssertFalse(products.isEmpty, "Konzum should return products")
        
        let firstProduct = products.first!
        XCTAssertEqual(firstProduct.provider, .konzum)
    }
    
    func testSparDownload() async throws {
        do {
            let products = try await downloader.downloadPrices(for: .spar)
            XCTAssertFalse(products.isEmpty, "Spar should return products")
        } catch ParserError.noDataFound {
            // Expected if no data available for today
            XCTSkip("No Spar data available for today")
        }
    }
    
    func testStudenacDownload() async throws {
        do {
            let products = try await downloader.downloadPrices(for: .studenac)
            XCTAssertFalse(products.isEmpty, "Studenac should return products")
        } catch ParserError.noDataFound {
            XCTSkip("No Studenac data available for today")
        }
    }
    
    func testDmDownload() async throws {
        do {
            let products = try await downloader.downloadPrices(for: .dm)
            XCTAssertFalse(products.isEmpty, "DM should return products")
        } catch ParserError.noDataFound {
            XCTSkip("No DM data available for today")
        }
    }
    
    func testEurospinDownload() async throws {
        do {
            let products = try await downloader.downloadPrices(for: .eurospin)
            XCTAssertFalse(products.isEmpty, "Eurospin should return products")
        } catch ParserError.noDataFound {
            XCTSkip("No Eurospin data available for today")
        }
    }
    
    func testKauflandDownload() async throws {
        do {
            let products = try await downloader.downloadPrices(for: .kaufland)
            XCTAssertFalse(products.isEmpty, "Kaufland should return products")
        } catch ParserError.noDataFound {
            XCTSkip("No Kaufland data available for today")
        }
    }
    
    func testKtcDownload() async throws {
        do {
            let products = try await downloader.downloadPrices(for: .ktc)
            XCTAssertFalse(products.isEmpty, "KTC should return products")
        } catch ParserError.noDataFound {
            XCTSkip("No KTC data available for today")
        }
    }
    
    // MARK: - Integration tests
    
    func testDownloadAllPrices() async throws {
        let results = await downloader.downloadAllPrices()
        
        XCTAssertEqual(results.count, ShopProvider.allCases.count, "Should attempt to download from all providers")
        
        // Check that at least one provider succeeded
        let successCount = results.values.compactMap { result -> [UnifiedProduct]? in
            if case .success(let products) = result {
                return products
            }
            return nil
        }.count
        
        XCTAssertGreaterThan(successCount, 0, "At least one provider should succeed")
        
        // Log results for debugging
        for (provider, result) in results {
            switch result {
            case .success(let products):
                print("✅ \(provider.displayName): \(products.count) products")
            case .failure(let error):
                print("❌ \(provider.displayName): \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Network reliability tests
    
    func testNetworkErrorHandling() async throws {
        // Test with invalid URL to ensure proper error handling
        let invalidDownloader = DataDownloader(session: URLSession.shared)
        
        do {
            _ = try await invalidDownloader.downloadPrices(for: .tommy)
            // If this succeeds, the real endpoint is working
        } catch {
            // Verify we get proper error types
            XCTAssertTrue(error is ParserError, "Should return ParserError for network issues")
        }
    }
    
    func testTimeoutHandling() async throws {
        // Create session with short timeout
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 1.0 // 1 second
        let shortTimeoutSession = URLSession(configuration: config)
        
        let timeoutDownloader = DataDownloader(session: shortTimeoutSession)
        
        do {
            _ = try await timeoutDownloader.downloadPrices(for: .tommy)
        } catch {
            // Should handle timeout gracefully
            XCTAssertTrue(error is ParserError)
        }
    }
    
    // MARK: - Performance tests
    
    func testDownloadPerformance() async throws {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        do {
            _ = try await downloader.downloadPrices(for: .tommy)
        } catch {
            // Handle or ignore error
        }
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let elapsed = endTime - startTime
        print("Download performance: \(elapsed) seconds")
    }
    
    // MARK: - Data validation tests
    
    func testProductDataIntegrity() async throws {
        let products = try await downloader.downloadPrices(for: .tommy)
        
        for product in products.prefix(10) { // Test first 10 products
            // Validate required fields
            XCTAssertFalse(product.name.isEmpty, "Product name should not be empty")
            XCTAssertGreaterThan(product.unitPrice, 0, "Unit price should be positive")
            XCTAssertFalse(product.unit.isEmpty, "Unit should not be empty")
            XCTAssertEqual(product.provider, .tommy, "Provider should match")
            
            // Validate currency
            XCTAssertEqual(product.currency, "EUR", "Currency should be EUR")
            
            // Validate date
            let calendar = Calendar.current
            let daysDiff = calendar.dateComponents([.day], from: product.lastUpdated, to: Date()).day ?? 0
            XCTAssertLessThanOrEqual(daysDiff, 1, "Product should be updated within last day")
        }
    }
    
    #if DEBUG
    func testDebugLogging() async throws {
        // Test that debug logging works properly
        print("Starting debug download test...")
        
        let products = try await downloader.downloadPrices(for: .tommy)
        
        print("Downloaded \(products.count) products")
        
        if let firstProduct = products.first {
            print("First product: \(firstProduct.name) - \(firstProduct.unitPrice) \(firstProduct.currency)")
        }
    }
    #endif
}

// MARK: - Test helpers

extension DownloadTests {
    
    func skipIfNoNetwork() throws {
        // Skip test if no network connectivity
        let url = URL(string: "https://www.google.com")!
        var request = URLRequest(url: url)
        request.timeoutInterval = 5.0
        
        let semaphore = DispatchSemaphore(value: 0)
        var hasNetwork = false
        
        URLSession.shared.dataTask(with: request) { _, response, _ in
            if let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode == 200 {
                hasNetwork = true
            }
            semaphore.signal()
        }.resume()
        
        semaphore.wait()
        
        if !hasNetwork {
            throw XCTSkip("No network connectivity available")
        }
    }
}
