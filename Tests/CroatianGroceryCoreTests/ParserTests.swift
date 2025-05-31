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