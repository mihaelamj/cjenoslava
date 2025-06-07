import XCTest
import ZIPFoundation
@testable import SharedGroceryProduct

final class ZipExtractorTests: XCTestCase {
    
    var zipExtractor: ZipExtractor!
    var tempDirectory: URL!
    
    override func setUp() async throws {
        try await super.setUp()
        zipExtractor = ZipExtractor()
        
        // Create temporary directory for tests
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("ZipExtractorTests")
            .appendingPathComponent(UUID().uuidString)
        
        try FileManager.default.createDirectory(
            at: tempDirectory,
            withIntermediateDirectories: true
        )
    }
    
    override func tearDown() async throws {
        zipExtractor = nil
        
        // Clean up temporary directory
        if let tempDirectory = tempDirectory {
            try? FileManager.default.removeItem(at: tempDirectory)
        }
        
        try await super.tearDown()
    }
    
    // MARK: - Test ZIP Creation Helper
    
    private func createTestZIP(files: [String: String]) throws -> Data {
        let zipURL = tempDirectory.appendingPathComponent("test.zip")
        
        guard let archive = Archive(url: zipURL, accessMode: .create) else {
            throw ZipExtractionError.extractionFailed
        }
        
        for (fileName, content) in files {
            let data = content.data(using: .utf8)!
            try archive.addEntry(
                with: fileName,
                type: .file,
                uncompressedSize: UInt64(data.count)
            ) { position, size in
                let rangeStart = Int(position)
                let rangeEnd = min(rangeStart + size, data.count)
                return data.subdata(in: rangeStart..<rangeEnd)
            }
        }
        
        return try Data(contentsOf: zipURL)
    }
    
    // MARK: - Basic Extraction Tests
    
    func testExtractCSVFiles() async throws {
        let testFiles = [
            "prices.csv": "product_id,name,price\n123,Milk,6.99\n456,Bread,3.49",
            "stores.csv": "store_id,name,city\n001,Store1,Zagreb\n002,Store2,Split",
            "readme.txt": "This is a readme file"
        ]
        
        let zipData = try createTestZIP(files: testFiles)
        let extractedFiles = try await zipExtractor.extractCSVFiles(from: zipData)
        
        XCTAssertEqual(extractedFiles.count, 2)
        
        let pricesFile = extractedFiles.first { $0.name == "prices.csv" }
        XCTAssertNotNil(pricesFile)
        XCTAssertEqual(pricesFile?.contentType, "text/csv")
        XCTAssertTrue(pricesFile?.textContent?.contains("Milk") ?? false)
        
        let storesFile = extractedFiles.first { $0.name == "stores.csv" }
        XCTAssertNotNil(storesFile)
        XCTAssertTrue(storesFile?.textContent?.contains("Zagreb") ?? false)
    }
    
    func testExtractXMLFiles() async throws {
        let testFiles = [
            "products.xml": """
                <?xml version="1.0" encoding="UTF-8"?>
                <products>
                    <product id="123">
                        <name>Milk</name>
                        <price>6.99</price>
                    </product>
                </products>
                """,
            "config.xml": """
                <?xml version="1.0"?>
                <config>
                    <setting>value</setting>
                </config>
                """,
            "data.csv": "id,name\n1,test"
        ]
        
        let zipData = try createTestZIP(files: testFiles)
        let extractedFiles = try await zipExtractor.extractXMLFiles(from: zipData)
        
        XCTAssertEqual(extractedFiles.count, 2)
        
        let productsFile = extractedFiles.first { $0.name == "products.xml" }
        XCTAssertNotNil(productsFile)
        XCTAssertEqual(productsFile?.contentType, "application/xml")
        XCTAssertTrue(productsFile?.textContent?.contains("<products>") ?? false)
    }
    
    func testExtractAllFiles() async throws {
        let testFiles = [
            "data.csv": "id,name\n1,Product1",
            "config.xml": "<?xml version=\"1.0\"?><config></config>",
            "readme.txt": "Instructions",
            "report.json": "{\"status\": \"ok\"}"
        ]
        
        let zipData = try createTestZIP(files: testFiles)
        let extractedFiles = try await zipExtractor.extractFiles(from: zipData)
        
        XCTAssertEqual(extractedFiles.count, 4)
        
        let fileExtensions = Set(extractedFiles.map { $0.fileExtension })
        XCTAssertTrue(fileExtensions.contains("csv"))
        XCTAssertTrue(fileExtensions.contains("xml"))
        XCTAssertTrue(fileExtensions.contains("txt"))
        XCTAssertTrue(fileExtensions.contains("json"))
    }
    
    // MARK: - File Filtering Tests
    
    func testExtractSpecificExtensions() async throws {
        let testFiles = [
            "data1.csv": "csv content 1",
            "data2.csv": "csv content 2",
            "config.xml": "xml content",
            "readme.txt": "text content",
            "info.json": "json content"
        ]
        
        let zipData = try createTestZIP(files: testFiles)
        let csvFiles = try await zipExtractor.extractFiles(
            from: zipData,
            fileExtensions: ["csv"]
        )
        
        XCTAssertEqual(csvFiles.count, 2)
        XCTAssertTrue(csvFiles.allSatisfy { $0.fileExtension == "csv" })
    }
    
    func testExtractMultipleExtensions() async throws {
        let testFiles = [
            "data.csv": "csv,content",
            "config.xml": "<?xml version=\"1.0\"?><root/>",
            "readme.txt": "text content",
            "script.js": "console.log('test')"
        ]
        
        let zipData = try createTestZIP(files: testFiles)
        let files = try await zipExtractor.extractFiles(
            from: zipData,
            fileExtensions: ["csv", "xml"]
        )
        
        XCTAssertEqual(files.count, 2)
        let extensions = Set(files.map { $0.fileExtension })
        XCTAssertEqual(extensions, Set(["csv", "xml"]))
    }
    
    // MARK: - Content Type Detection Tests
    
    func testContentTypeDetectionByExtension() async throws {
        let testFiles = [
            "data.csv": "id,name\n1,test",
            "config.xml": "<?xml version=\"1.0\"?><root/>",
            "document.pdf": "PDF content here",
            "page.html": "<html><body>Hello</body></html>",
            "data.json": "{\"key\": \"value\"}",
            "readme.txt": "Plain text content"
        ]
        
        let zipData = try createTestZIP(files: testFiles)
        let extractedFiles = try await zipExtractor.extractFiles(from: zipData)
        
        let contentTypes = Dictionary(
            uniqueKeysWithValues: extractedFiles.map { ($0.name, $0.contentType) }
        )
        
        XCTAssertEqual(contentTypes["data.csv"], "text/csv")
        XCTAssertEqual(contentTypes["config.xml"], "application/xml")
        XCTAssertEqual(contentTypes["document.pdf"], "application/pdf")
        XCTAssertEqual(contentTypes["page.html"], "text/html")
        XCTAssertEqual(contentTypes["data.json"], "application/json")
        XCTAssertEqual(contentTypes["readme.txt"], "text/plain")
    }
    
    func testContentTypeDetectionByContent() async throws {
        let testFiles = [
            "noext1": "<?xml version=\"1.0\"?><root/>",
            "noext2": "id,name,price\n1,Product,9.99",
            "noext3": "<html><head></head><body></body></html>",
            "unknown": "some random binary content"
        ]
        
        let zipData = try createTestZIP(files: testFiles)
        let extractedFiles = try await zipExtractor.extractFiles(from: zipData)
        
        let contentTypes = Dictionary(
            uniqueKeysWithValues: extractedFiles.map { ($0.name, $0.contentType) }
        )
        
        XCTAssertEqual(contentTypes["noext1"], "application/xml")
        XCTAssertEqual(contentTypes["noext2"], "text/csv")
        XCTAssertEqual(contentTypes["noext3"], "text/html")
        XCTAssertEqual(contentTypes["unknown"], "application/octet-stream")
    }
    
    // MARK: - Single File Extraction Tests
    
    func testExtractSingleFile() async throws {
        let testFiles = [
            "target.csv": "id,name,price\n1,Product1,9.99\n2,Product2,12.99",
            "other.csv": "different,content",
            "config.xml": "<?xml version=\"1.0\"?><config/>"
        ]
        
        let zipData = try createTestZIP(files: testFiles)
        let extractedFile = try await zipExtractor.extractFile(
            named: "target.csv",
            from: zipData
        )
        
        XCTAssertNotNil(extractedFile)
        XCTAssertEqual(extractedFile?.name, "target.csv")
        XCTAssertEqual(extractedFile?.contentType, "text/csv")
        XCTAssertTrue(extractedFile?.textContent?.contains("Product1") ?? false)
    }
    
    func testExtractNonExistentFile() async throws {
        let testFiles = [
            "existing.csv": "some,data"
        ]
        
        let zipData = try createTestZIP(files: testFiles)
        let extractedFile = try await zipExtractor.extractFile(
            named: "nonexistent.csv",
            from: zipData
        )
        
        XCTAssertNil(extractedFile)
    }
    
    // MARK: - Archive Info Tests
    
    func testGetArchiveInfo() async throws {
        let testFiles = [
            "file1.csv": "a,b,c\n1,2,3",
            "file2.xml": "<?xml version=\"1.0\"?><root><item>test</item></root>",
            "file3.txt": "Some text content here"
        ]
        
        let zipData = try createTestZIP(files: testFiles)
        let archiveInfo = try await zipExtractor.getArchiveInfo(from: zipData)
        
        XCTAssertEqual(archiveInfo.fileCount, 3)
        XCTAssertTrue(archiveInfo.totalUncompressedSize > 0)
        XCTAssertTrue(archiveInfo.fileExtensions.contains("csv"))
        XCTAssertTrue(archiveInfo.fileExtensions.contains("xml"))
        XCTAssertTrue(archiveInfo.fileExtensions.contains("txt"))
        XCTAssertTrue(archiveInfo.compressionRatio > 0)
        XCTAssertNotNil(archiveInfo.formattedSize)
    }
    
    func testListFiles() async throws {
        let testFiles = [
            "prices.csv": "product,price\nMilk,6.99",
            "stores.xml": "<?xml version=\"1.0\"?><stores></stores>",
            "readme.txt": "Instructions file"
        ]
        
        let zipData = try createTestZIP(files: testFiles)
        let fileList = try await zipExtractor.listFiles(in: zipData)
        
        XCTAssertEqual(fileList.count, 3)
        
        let fileNames = fileList.map { $0.path }
        XCTAssertTrue(fileNames.contains("prices.csv"))
        XCTAssertTrue(fileNames.contains("stores.xml"))
        XCTAssertTrue(fileNames.contains("readme.txt"))
        
        // All should be files, not directories
        XCTAssertTrue(fileList.allSatisfy { $0.type == "file" })
    }
    
    // MARK: - RawData Conversion Tests
    
    func testExtractToRawData() async throws {
        let testFiles = [
            "prices.csv": "product_id,name,price\n123,Milk,6.99",
            "config.xml": "<?xml version=\"1.0\"?><config></config>"
        ]
        
        let zipData = try createTestZIP(files: testFiles)
        let sourceURL = URL(string: "https://example.com/data.zip")!
        
        let rawDataArray = try await zipExtractor.extractToRawData(
            from: zipData,
            sourceURL: sourceURL,
            fileExtensions: ["csv"]
        )
        
        XCTAssertEqual(rawDataArray.count, 1)
        
        let csvRawData = rawDataArray[0]
        XCTAssertEqual(csvRawData.contentType, "text/csv")
        XCTAssertTrue(csvRawData.url.absoluteString.contains("prices.csv"))
        XCTAssertEqual(csvRawData.metadata["fileName"], "prices.csv")
        XCTAssertTrue(csvRawData.text?.contains("Milk") ?? false)
    }
    
    func testRawDataEncoding() async throws {
        // Test with Croatian characters
        let croatianText = "šifra,naziv,cijena\n123,Mlijeko,6.99\n456,Kruh,3.49"
        let testFiles = [
            "croatian.csv": croatianText
        ]
        
        let zipData = try createTestZIP(files: testFiles)
        let sourceURL = URL(string: "https://example.com/data.zip")!
        
        let rawDataArray = try await zipExtractor.extractToRawData(
            from: zipData,
            sourceURL: sourceURL
        )
        
        XCTAssertEqual(rawDataArray.count, 1)
        let rawData = rawDataArray[0]
        
        // Should handle Croatian characters properly
        XCTAssertTrue(rawData.text?.contains("šifra") ?? false)
        XCTAssertTrue(rawData.text?.contains("Mlijeko") ?? false)
    }
    
    // MARK: - Error Handling Tests
    
    func testInvalidZipData() async {
        let invalidData = "This is not a ZIP file".data(using: .utf8)!
        
        do {
            _ = try await zipExtractor.extractFiles(from: invalidData)
            XCTFail("Should have thrown an error for invalid ZIP data")
        } catch {
            XCTAssertTrue(error is ZipExtractionError)
        }
    }
    
    func testEmptyZipData() async {
        let emptyData = Data()
        
        do {
            _ = try await zipExtractor.extractFiles(from: emptyData)
            XCTFail("Should have thrown an error for empty data")
        } catch {
            XCTAssertTrue(error is ZipExtractionError)
        }
    }
    
    func testZipExtractionErrorDescriptions() {
        let errors: [ZipExtractionError] = [
            .extractionFailed,
            .invalidZipData,
            .fileNotFound,
            .permissionDenied,
            .unsupportedFormat
        ]
        
        for error in errors {
            XCTAssertNotNil(error.errorDescription)
            XCTAssertFalse(error.errorDescription!.isEmpty)
        }
    }
    
    // MARK: - Performance Tests
    
    func testExtractionPerformance() async throws {
        // Create a larger ZIP for performance testing
        var largeFiles: [String: String] = [:]
        for i in 0..<50 {
            largeFiles["file\(i).csv"] = String(repeating: "data,row\(i)\n", count: 100)
        }
        
        let zipData = try createTestZIP(files: largeFiles)
        
        measure {
            Task {
                do {
                    _ = try await zipExtractor.extractFiles(from: zipData)
                } catch {
                    XCTFail("Performance test failed: \(error)")
                }
            }
        }
    }
    
    func testArchiveInfoPerformance() async throws {
        var manyFiles: [String: String] = [:]
        for i in 0..<100 {
            manyFiles["file\(i).txt"] = "Content of file \(i)"
        }
        
        let zipData = try createTestZIP(files: manyFiles)
        
        measure {
            Task {
                do {
                    _ = try await zipExtractor.getArchiveInfo(from: zipData)
                } catch {
                    XCTFail("Performance test failed: \(error)")
                }
            }
        }
    }
    
    // MARK: - Edge Cases
    
    func testExtractFilesWithDirectoryStructure() async throws {
        let testFiles = [
            "root.csv": "root,data",
            "subdir/file.csv": "sub,data",
            "deep/nested/file.csv": "deep,data"
        ]
        
        let zipData = try createTestZIP(files: testFiles)
        let extractedFiles = try await zipExtractor.extractFiles(
            from: zipData,
            preserveDirectoryStructure: true
        )
        
        let nestedFile = extractedFiles.first { $0.originalPath.contains("deep/nested") }
        XCTAssertNotNil(nestedFile)
        XCTAssertTrue(nestedFile?.originalPath.contains("deep/nested/file.csv") ?? false)
    }
    
    func testExtractLargeFile() async throws {
        let largeContent = String(repeating: "line,data,content\n", count: 10000)
        let testFiles = [
            "large.csv": largeContent
        ]
        
        let zipData = try createTestZIP(files: testFiles)
        let extractedFiles = try await zipExtractor.extractCSVFiles(from: zipData)
        
        XCTAssertEqual(extractedFiles.count, 1)
        XCTAssertTrue(extractedFiles[0].data.count > 100000) // Should be quite large
    }
    
    func testValidateZipData() async {
        let validTestFiles = ["test.csv": "data"]
        let validZipData = try! createTestZIP(files: validTestFiles)
        let invalidZipData = "invalid".data(using: .utf8)!
        
        let validResult = await zipExtractor.validateZipData(validZipData)
        let invalidResult = await zipExtractor.validateZipData(invalidZipData)
        
        XCTAssertTrue(validResult)
        XCTAssertFalse(invalidResult)
    }
}

// MARK: - Test Extensions

extension ZipExtractorTests {
    
    func createSampleGroceryCSV() -> String {
        return """
        product_id,barcode,name,brand,category,price,unit_price,quantity,unit
        12345,3850104130090,Mlijek 2.8%,Dukat,Mliječni proizvodi,6.99,6.99,1L,L
        67890,3850104567890,Kruh bijeli,Klara,Pekarnički proizvodi,3.49,6.98,500g,kg
        54321,3850104543210,Jogurt,Vindija,Mliječni proizvodi,2.99,5.98,500g,kg
        """
    }
    
    func createSampleGroceryXML() -> String {
        return """
        <?xml version="1.0" encoding="UTF-8"?>
        <products>
            <product>
                <product_id>12345</product_id>
                <barcode>3850104130090</barcode>
                <name>Mlijek 2.8%</name>
                <brand>Dukat</brand>
                <price>6.99</price>
            </product>
        </products>
        """
    }
    
    func testRealWorldGroceryData() async throws {
        let testFiles = [
            "prices.csv": createSampleGroceryCSV(),
            "products.xml": createSampleGroceryXML(),
            "stores.csv": "store_id,name,city\n001,Konzum Zagreb,Zagreb"
        ]
        
        let zipData = try createTestZIP(files: testFiles)
        let sourceURL = URL(string: "https://konzum.hr/prices.zip")!
        
        let rawDataArray = try await zipExtractor.extractToRawData(
            from: zipData,
            sourceURL: sourceURL,
            fileExtensions: ["csv"]
        )
        
        XCTAssertEqual(rawDataArray.count, 2) // prices.csv and stores.csv
        
        let pricesData = rawDataArray.first { $0.url.lastPathComponent == "prices.csv" }
        XCTAssertNotNil(pricesData)
        XCTAssertTrue(pricesData?.text?.contains("Dukat") ?? false)
        XCTAssertTrue(pricesData?.text?.contains("3850104130090") ?? false)
    }
}
