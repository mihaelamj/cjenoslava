import Foundation
// MARK: - Parser Protocol

// swiftlint:disable all
public protocol DataParser {
    func parseProducts(from data: Data, provider: GroceryProvider) async throws -> [UnifiedProduct]
}

// MARK: - Parser Errors

public enum ParserError: Error, LocalizedError {
    case invalidData
    case unsupportedFormat
    case parsingFailed(String)
    case noDataFound
    case networkError(Error)
    
    public var errorDescription: String? {
        switch self {
        case .invalidData:
            return "Invalid data format"
        case .unsupportedFormat:
            return "Unsupported data format"
        case .parsingFailed(let details):
            return "Parsing failed: \(details)"
        case .noDataFound:
            return "No data found"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}

// MARK: - CSV Parser

public class CSVParser: DataParser {
    
    public init() {}
    
    public func parseProducts(from data: Data, provider: GroceryProvider) async throws -> [UnifiedProduct] {
        guard let content = String(data: data, encoding: .utf8) else {
            throw ParserError.invalidData
        }
        
        let lines = content.components(separatedBy: .newlines)
        guard lines.count > 1 else {
            throw ParserError.noDataFound
        }
        
        let headers = parseCSVLine(lines[0])
        var products: [UnifiedProduct] = []
        
        for lineIndex in 1..<lines.count {
            let line = lines[lineIndex].trimmingCharacters(in: .whitespacesAndNewlines)
            if line.isEmpty { continue }
            
            let values = parseCSVLine(line)
            if values.count != headers.count { continue }
            
            var dataDict: [String: String] = [:]
            for (index, header) in headers.enumerated() {
                if index < values.count {
                    dataDict[header] = values[index]
                }
            }
            
            do {
                let product = try await convertToUnifiedProduct(dataDict, provider: provider)
                products.append(product)
            } catch {
                // Log error but continue processing
                print("Failed to parse product at line \(lineIndex): \(error)")
            }
        }
        
        return products
    }
    
    private func parseCSVLine(_ line: String) -> [String] {
        var result: [String] = []
        var current = ""
        var inQuotes = false
        var i = line.startIndex
        
        while i < line.endIndex {
            let char = line[i]
            
            if char == "\"" {
                inQuotes.toggle()
            } else if char == "," && !inQuotes {
                result.append(current.trimmingCharacters(in: .whitespacesAndNewlines))
                current = ""
            } else {
                current.append(char)
            }
            
            i = line.index(after: i)
        }
        
        result.append(current.trimmingCharacters(in: .whitespacesAndNewlines))
        return result
    }
    
    private func convertToUnifiedProduct(_ data: [String: String], provider: GroceryProvider) async throws -> UnifiedProduct {
        switch provider {
        case .plodine:
            return try convertPlodineProduct(data)
        case .tommy:
            return try convertTommyProduct(data)
        case .lidl:
            return try convertLidlProduct(data)
        case .spar:
            return try convertSparProduct(data)
        case .studenac:
            return try convertStudenacProduct(data)
        case .dm:
            return try convertDMProduct(data)
        case .eurospin:
            return try convertEurospinProduct(data)
        case .konzum:
            return try convertKonzumProduct(data)
        case .kaufland:
            return try convertKauflandProduct(data)
        case .ktc:
            return try convertKTCProduct(data)
        }
    }
    
    // MARK: - Provider-specific converters
    
    private func convertPlodineProduct(_ data: [String: String]) throws -> UnifiedProduct {
        guard let name = data["naziv_artikla"] ?? data["product_name"],
              let priceStr = data["cijena"] ?? data["price"],
              let unit = data["jedinica_mjere"] ?? data["unit"] else {
            throw ParserError.parsingFailed("Missing required fields for Plodine product")
        }
        
        let price = parsePrice(priceStr)
        let pricePerUnit = data["cijena_po_jedinici"].flatMap { parsePrice($0) }
        
        return UnifiedProduct(
            name: name,
            category: data["kategorija"],
            brand: data["brend"],
            barcode: data["barkod"],
            unit: unit,
            unitPrice: price,
            pricePerUnit: pricePerUnit,
            originalData: data,
            provider: .plodine
        )
    }
    
    private func convertTommyProduct(_ data: [String: String]) throws -> UnifiedProduct {
        guard let name = data["product_name"] ?? data["naziv"],
              let priceStr = data["price"] ?? data["cijena"],
              let unit = data["unit"] ?? data["jedinica"] else {
            throw ParserError.parsingFailed("Missing required fields for Tommy product")
        }
        
        let price = parsePrice(priceStr)
        let pricePerUnit = data["unit_price"].flatMap { parsePrice($0) }
//        let promoPrice = data["promotional_price"].flatMap { parsePrice($0) }
        // Check for an empty string and set promoPrice to nil in that case
        let promoPrice = data["promotional_price"].flatMap { value in
            value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : parsePrice(value)
        }
        
        
        return UnifiedProduct(
            name: name,
            category: data["category"],
            brand: data["brand"],
            barcode: data["ean"],
            unit: unit,
            unitPrice: promoPrice ?? price,
            pricePerUnit: pricePerUnit,
            originalData: data,
            provider: .tommy,
            isOnSale: promoPrice != nil,
            originalPrice: promoPrice != nil ? price : nil
        )
    }
    
    private func convertLidlProduct(_ data: [String: String]) throws -> UnifiedProduct {
        guard let name = data["bezeichnung"] ?? data["name"],
              let priceStr = data["preis"] ?? data["price"],
              let unit = data["einheit"] ?? data["unit"] else {
            throw ParserError.parsingFailed("Missing required fields for Lidl product")
        }
        
        let price = parsePrice(priceStr)
        let pricePerUnit = data["grundpreis"].flatMap { parsePrice($0) }
        let promoPrice = data["angebotspreis"].flatMap { parsePrice($0) }
        
        return UnifiedProduct(
            name: name,
            category: data["warengruppe"],
            brand: data["marke"],
            barcode: data["gtin"],
            unit: unit,
            unitPrice: promoPrice ?? price,
            pricePerUnit: pricePerUnit,
            originalData: data,
            provider: .lidl,
            isOnSale: promoPrice != nil,
            originalPrice: promoPrice != nil ? price : nil
        )
    }
    
    private func convertSparProduct(_ data: [String: String]) throws -> UnifiedProduct {
        guard let name = data["item_name"] ?? data["naziv"],
              let priceStr = data["retail_price"] ?? data["cijena"],
              let unit = data["unit_type"] ?? data["jedinica"] else {
            throw ParserError.parsingFailed("Missing required fields for Spar product")
        }
        
        let price = parsePrice(priceStr)
        let pricePerUnit = data["price_per_unit"].flatMap { parsePrice($0) }
        let salePrice = data["sale_price"].flatMap { parsePrice($0) }
        
        return UnifiedProduct(
            name: name,
            category: data["category_name"],
            brand: data["brand_name"],
            barcode: data["barcode"],
            unit: unit,
            unitPrice: salePrice ?? price,
            pricePerUnit: pricePerUnit,
            originalData: data,
            provider: .spar,
            isOnSale: salePrice != nil,
            originalPrice: salePrice != nil ? price : nil
        )
    }
    
    private func convertStudenacProduct(_ data: [String: String]) throws -> UnifiedProduct {
        guard let name = data["naziv"] ?? data["product_name"],
              let priceStr = data["cijena_kn"] ?? data["price"],
              let unit = data["mjera"] ?? data["unit"] else {
            throw ParserError.parsingFailed("Missing required fields for Studenac product")
        }
        
        let price = parsePrice(priceStr)
        let pricePerUnit = data["cijena_mjera"].flatMap { parsePrice($0) }
        
        return UnifiedProduct(
            name: name,
            category: data["grupa"],
            brand: data["proizvodjac"],
            barcode: data["ean_kod"],
            unit: unit,
            unitPrice: price,
            pricePerUnit: pricePerUnit,
            originalData: data,
            provider: .studenac
        )
    }
    
    private func convertDMProduct(_ data: [String: String]) throws -> UnifiedProduct {
        guard let name = data["artikel_bezeichnung"] ?? data["name"],
              let priceStr = data["verkaufspreis"] ?? data["price"],
              let unit = data["verkaufseinheit"] ?? data["unit"] else {
            throw ParserError.parsingFailed("Missing required fields for DM product")
        }
        
        let price = parsePrice(priceStr)
        let pricePerUnit = data["grundpreis"].flatMap { parsePrice($0) }
        
        return UnifiedProduct(
            name: name,
            category: data["kategorie"],
            brand: data["hersteller"],
            barcode: data["ean"],
            unit: unit,
            unitPrice: price,
            pricePerUnit: pricePerUnit,
            originalData: data,
            provider: .dm
        )
    }
    
    private func convertEurospinProduct(_ data: [String: String]) throws -> UnifiedProduct {
        guard let name = data["denominazione"] ?? data["name"],
              let priceStr = data["prezzo"] ?? data["price"],
              let unit = data["unita"] ?? data["unit"] else {
            throw ParserError.parsingFailed("Missing required fields for Eurospin product")
        }
        
        let price = parsePrice(priceStr)
        let pricePerUnit = data["prezzo_unitario"].flatMap { parsePrice($0) }
        
        return UnifiedProduct(
            name: name,
            category: data["categoria"],
            brand: data["marca"],
            barcode: data["codice_barre"],
            unit: unit,
            unitPrice: price,
            pricePerUnit: pricePerUnit,
            originalData: data,
            provider: .eurospin
        )
    }
    
    private func convertKonzumProduct(_ data: [String: String]) throws -> UnifiedProduct {
        guard let name = data["naziv_proizvoda"] ?? data["name"],
              let priceStr = data["maloprodajna_cijena"] ?? data["price"],
              let unit = data["jedinica"] ?? data["unit"] else {
            throw ParserError.parsingFailed("Missing required fields for Konzum product")
        }
        
        let price = parsePrice(priceStr)
        let pricePerUnit = data["cijena_jedinice"].flatMap { parsePrice($0) }
        
        return UnifiedProduct(
            name: name,
            category: data["kategorija_proizvoda"],
            brand: data["marka"],
            barcode: data["bar_kod"],
            unit: unit,
            unitPrice: price,
            pricePerUnit: pricePerUnit,
            originalData: data,
            provider: .konzum
        )
    }
    
    private func convertKauflandProduct(_ data: [String: String]) throws -> UnifiedProduct {
        guard let name = data["artikel_name"] ?? data["name"],
              let priceStr = data["verkaufspreis"] ?? data["price"],
              let unit = data["mengeneinheit"] ?? data["unit"] else {
            throw ParserError.parsingFailed("Missing required fields for Kaufland product")
        }
        
        let price = parsePrice(priceStr)
        let pricePerUnit = data["grundpreis"].flatMap { parsePrice($0) }
        
        return UnifiedProduct(
            name: name,
            category: data["warengruppe"],
            brand: data["markenname"],
            barcode: data["ean_code"],
            unit: unit,
            unitPrice: price,
            pricePerUnit: pricePerUnit,
            originalData: data,
            provider: .kaufland
        )
    }
    
    private func convertKTCProduct(_ data: [String: String]) throws -> UnifiedProduct {
        guard let name = data["ime_artikla"] ?? data["name"],
              let priceStr = data["prodajna_cijena"] ?? data["price"],
              let unit = data["jedinica_mjere"] ?? data["unit"] else {
            throw ParserError.parsingFailed("Missing required fields for KTC product")
        }
        
        let price = parsePrice(priceStr)
        let pricePerUnit = data["cijena_po_kg_l"].flatMap { parsePrice($0) }
        
        return UnifiedProduct(
            name: name,
            category: data["grupa_artikla"],
            brand: data["brend"],
            barcode: data["ean13"],
            unit: unit,
            unitPrice: price,
            pricePerUnit: pricePerUnit,
            originalData: data,
            provider: .ktc
        )
    }
    
    // MARK: - Helper Methods
    
    private func parsePrice(_ priceString: String) -> Float {
        let cleaned = priceString
            .replacingOccurrences(of: ",", with: ".")
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "€", with: "")
            .replacingOccurrences(of: "kn", with: "")
            .replacingOccurrences(of: "HRK", with: "")
            .replacingOccurrences(of: "EUR", with: "")
        
        return Float(cleaned) ?? 0
    }
}
