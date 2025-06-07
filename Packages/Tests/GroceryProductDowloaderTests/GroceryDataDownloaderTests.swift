import XCTest
@testable import SharedGroceryProduct

final class GroceryDataDownloaderTests: XCTestCase {
    
    var downloader: GroceryDataDownloader!
    
    override func setUp() {
        super.setUp()
        downloader = GroceryDataDownloader()
    }
    
    override func tearDown() {
        downloader = nil
        super.tearDown()
    }
    
    // MARK: - StoreDataRequest Tests
    
    func testStoreDataRequestCreation() {
        let date = Date()
        let request = StoreDataRequest(
            provider: .konzum,
            date: date,
            storeId: "001",
            additionalParameters: ["test": "value"]
        )
        
        XCTAssertEqual(request.provider, .konzum)
        XCTAssertEqual(request.date, date)
        XCTAssertEqual(request.storeId, "001")
        XCTAssertEqual(request.additionalParameters["test"], "value")
    }
    
    func testStoreDataRequestDefaults() {
        let date = Date()
        let request = StoreDataRequest(provider: .lidl, date: date)
        
        XCTAssertEqual(request.provider, .lidl)
        XCTAssertEqual(request.date, date)
        XCTAssertNil(request.storeId)
        XCTAssertTrue(request.additionalParameters.isEmpty)
    }
    
    // MARK: - RawData Tests
    
    func testRawDataCreation() {
        let testData = "test,data,csv".data(using: .utf8)!
        let testURL = URL(string: "https://example.com/test.csv")!
        
        let rawData = RawData(
            content: testData,
            url: testURL,
            contentType: "text/csv",
            encoding: .utf8,
            metadata: ["fileName": "test.csv"]
        )
        
        XCTAssertEqual(rawData.content, testData)
        XCTAssertEqual(rawData.url, testURL)
        XCTAssertEqual(rawData.contentType, "text/csv")
        XCTAssertEqual(rawData.encoding, .utf8)
        XCTAssertEqual(rawData.metadata["fileName"], "test.csv")
        XCTAssertEqual(rawData.text, "test,data,csv")
    }
    
    func testRawDataTextExtraction() {
        let testData = "test,data,csv".data(using: .utf8)!
        let testURL = URL(string: "https://example.com/test.csv")!
        
        let rawData = RawData(content: testData, url: testURL)
        XCTAssertEqual(rawData.text, "test,data,csv")
    }
    
    func testRawDataTextExtractionWithWrongEncoding() {
        let testData = "test,data,csv".data(using: .utf8)!
        let testURL = URL(string: "https://example.com/test.csv")!
        
        let rawData = RawData(
            content: testData,
            url: testURL,
            encoding: .ascii // Wrong encoding
        )
        
        // Should still work for simple ASCII text
        XCTAssertNotNil(rawData.text)
    }
    
    // MARK: - DownloaderFactory Tests
    
    func testDownloaderFactoryIndexBasedProviders() {
        let indexProviders: [GroceryProductProvider] = [
            .konzum, .kaufland, .ktc, .eurospin, .metro, .ntl, .zabac
        ]
        
        for provider in indexProviders {
            let downloader = DownloaderFactory.createDownloader(for: provider)
            XCTAssertTrue(downloader is IndexCSVDownloader, "Provider \(provider) should use IndexCSVDownloader")
        }
    }
    
    func testDownloaderFactoryZipBasedProviders() {
        let zipProviders: [GroceryProductProvider] = [.lidl, .plodine, .studenac]
        
        for provider in zipProviders {
            let downloader = DownloaderFactory.createDownloader(for: provider)
            XCTAssertTrue(downloader is ZipArchiveDownloader, "Provider \(provider) should use ZipArchiveDownloader")
        }
    }
    
    func testDownloaderFactoryAPIBasedProviders() {
        let apiProviders: [GroceryProductProvider] = [.tommy, .spar]
        
        for provider in apiProviders {
            let downloader = DownloaderFactory.createDownloader(for: provider)
            XCTAssertTrue(downloader is JSONAPIDownloader, "Provider \(provider) should use JSONAPIDownloader")
        }
    }
    
    func testDownloaderFactoryXMLBasedProviders() {
        let xmlProviders: [GroceryProductProvider] = [.ribola, .trgocentar, .vrutak]
        
        for provider in xmlProviders {
            let downloader = DownloaderFactory.createDownloader(for: provider)
            XCTAssertTrue(downloader is XMLDownloader, "Provider \(provider) should use XMLDownloader")
        }
    }
    
    func testDownloaderFactorySpecialProviders() {
        let dmDownloader = DownloaderFactory.createDownloader(for: .dm)
        XCTAssertTrue(dmDownloader is SpecialDMDownloader, "DM should use SpecialDMDownloader")
    }
    
    // MARK: - Error Handling Tests
    
    func testDownloadErrorDescriptions() {
        let errors: [DownloadError] = [
            .invalidResponse,
            .httpError(404),
            .encodingError,
            .invalidJSON,
            .dataNotFound
        ]
        
        for error in errors {
            XCTAssertNotNil(error.errorDescription)
            XCTAssertFalse(error.errorDescription!.isEmpty)
        }
    }
    
    func testDownloadErrorHTTPCode() {
        let httpError = DownloadError.httpError(404)
        XCTAssertEqual(httpError.errorDescription, "HTTP error: 404")
    }
    
    // MARK: - HTTPDataDownloader Tests
    
    func testHTTPDataDownloaderEncodingDetection() async throws {
        let downloader = HTTPDataDownloader()
        
        // Test with a mock server would be ideal, but for now test initialization
        XCTAssertNotNil(downloader)
    }
    
    // MARK: - Mock Data Tests
    
    func testMockCSVData() {
        let csvContent = """
        product_id,product,brand,price,unit_price
        12345,Mlijek,Dukat,6.99,6.99
        67890,Kruh,Klara,3.49,6.98
        """
        
        let testData = csvContent.data(using: .utf8)!
        let testURL = URL(string: "https://example.com/test.csv")!
        
        let rawData = RawData(
            content: testData,
            url: testURL,
            contentType: "text/csv"
        )
        
        XCTAssertEqual(rawData.text, csvContent)
        XCTAssertTrue(rawData.text!.contains("Mlijek"))
        XCTAssertTrue(rawData.text!.contains("Dukat"))
    }
    
    func testMockXMLData() {
        let xmlContent = """
        <?xml version="1.0" encoding="UTF-8"?>
        <products>
            <product>
                <name>Mlijek</name>
                <brand>Dukat</brand>
                <price>6.99</price>
            </product>
        </products>
        """
        
        let testData = xmlContent.data(using: .utf8)!
        let testURL = URL(string: "https://example.com/test.xml")!
        
        let rawData = RawData(
            content: testData,
            url: testURL,
            contentType: "application/xml"
        )
        
        XCTAssertEqual(rawData.text, xmlContent)
        XCTAssertTrue(rawData.text!.contains("<?xml"))
        XCTAssertTrue(rawData.text!.contains("<products>"))
    }
    
    // MARK: - Integration Tests
    
    func testDownloadDataInvalidProvider() async {
        // This would test with a mock network layer in a real scenario
        let request = StoreDataRequest(provider: .konzum, date: Date())
        
        do {
            _ = try await downloader.downloadData(for: request)
            // In a real test with mocks, we'd expect this to succeed or fail predictably
        } catch {
            // Expected to fail without real network/mocks
            XCTAssertTrue(error is DownloadError)
        }
    }
    
    // MARK: - Performance Tests
    
    func testDownloaderFactoryPerformance() {
        measure {
            for provider in GroceryProductProvider.allCases {
                _ = DownloaderFactory.createDownloader(for: provider)
            }
        }
    }
    
    func testStoreDataRequestCreationPerformance() {
        let date = Date()
        
        measure {
            for i in 0..<1000 {
                _ = StoreDataRequest(
                    provider: .konzum,
                    date: date,
                    storeId: "\(i)",
                    additionalParameters: ["test": "value\(i)"]
                )
            }
        }
    }
    
    // MARK: - Edge Cases
    
    func testEmptyRawData() {
        let emptyData = Data()
        let testURL = URL(string: "https://example.com/empty.csv")!
        
        let rawData = RawData(content: emptyData, url: testURL)
        
        XCTAssertEqual(rawData.content.count, 0)
        XCTAssertEqual(rawData.text, "")
    }
    
    func testRawDataWithSpecialCharacters() {
        let specialContent = "čćžšđ,ČĆŽŠĐ,Žabac"
        let testData = specialContent.data(using: .utf8)!
        let testURL = URL(string: "https://example.com/special.csv")!
        
        let rawData = RawData(content: testData, url: testURL)
        
        XCTAssertEqual(rawData.text, specialContent)
        XCTAssertTrue(rawData.text!.contains("Žabac"))
    }
    
    func testLargeMetadataDictionary() {
        let testData = "test".data(using: .utf8)!
        let testURL = URL(string: "https://example.com/test.csv")!
        
        var largeMetadata: [String: String] = [:]
        for i in 0..<100 {
            largeMetadata["key\(i)"] = "value\(i)"
        }
        
        let rawData = RawData(
            content: testData,
            url: testURL,
            metadata: largeMetadata
        )
        
        XCTAssertEqual(rawData.metadata.count, 100)
        XCTAssertEqual(rawData.metadata["key50"], "value50")
    }
}

// MARK: - Test Extensions

extension GroceryDataDownloaderTests {
    
    func createTestRequest(for provider: GroceryProductProvider) -> StoreDataRequest {
        return StoreDataRequest(
            provider: provider,
            date: Date(),
            storeId: "TEST_001"
        )
    }
    
    func createTestRawData(content: String, url: String = "https://test.com/data.csv") -> RawData {
        return RawData(
            content: content.data(using: .utf8)!,
            url: URL(string: url)!,
            contentType: "text/csv"
        )
    }
}
