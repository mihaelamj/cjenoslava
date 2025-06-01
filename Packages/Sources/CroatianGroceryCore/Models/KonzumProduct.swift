import Foundation

// swiftlint:disable all

/// Konzum specific data structure
//public struct KonzumProduct: Codable {
//    public let sifra: String?
//    public let naziv_proizvoda: String
//    public let kategorija_proizvoda: String?
//    public let jedinica: String
//    public let maloprodajna_cijena: String
//    public let cijena_jedinice: String?
//    public let bar_kod: String?
//    public let marka: String?
//    public let datum_update: String?
//
//    public init(sifra: String?, naziv_proizvoda: String, kategorija_proizvoda: String?, jedinica: String, maloprodajna_cijena: String, cijena_jedinice: String?, bar_kod: String?, marka: String?, datum_update: String?) {
//        self.sifra = sifra
//        self.naziv_proizvoda = naziv_proizvoda
//        self.kategorija_proizvoda = kategorija_proizvoda
//        self.jedinica = jedinica
//        self.maloprodajna_cijena = maloprodajna_cijena
//        self.cijena_jedinice = cijena_jedinice
//        self.bar_kod = bar_kod
//        self.marka = marka
//        self.datum_update = datum_update
//    }
//}

/**
 Printing description of data:
 ▿ 12 elements
   ▿ 0 : 2 elements
     - key : "ŠIFRA PROIZVODA"
     - value : "90735104"
   ▿ 1 : 2 elements
     - key : "NAZIV PROIZVODA"
     - value : "MLIJEKO TIJ OLEA MEDIT SMILJE 250ml"
   ▿ 2 : 2 elements
     - key : "MPC ZA VRIJEME POSEBNOG OBLIKA PRODAJE"
     - value : ""
   ▿ 3 : 2 elements
     - key : "NETO KOLIČINA"
     - value : "0.25 l"
   ▿ 4 : 2 elements
     - key : "CIJENA ZA JEDINICU MJERE"
     - value : "10.76"
   ▿ 5 : 2 elements
     - key : "MALOPRODAJNA CIJENA"
     - value : "2.69"
   ▿ 6 : 2 elements
     - key : "SIDRENA CIJENA NA 2.5.2025"
     - value : "2.69"
   ▿ 7 : 2 elements
     - key : "NAJNIŽA CIJENA U POSLJEDNIH 30 DANA"
     - value : "2.15"
   ▿ 8 : 2 elements
     - key : "JEDINICA MJERE"
     - value : "ko"
   ▿ 9 : 2 elements
     - key : "KATEGORIJA PROIZVODA"
     - value : "KOZMETIKA"
   ▿ 10 : 2 elements
     - key : "MARKA PROIZVODA"
     - value : "OLEA"
   ▿ 11 : 2 elements
     - key : "BARKOD"
     - value : "3850334099662"
 */
public struct KonzumProduct: Codable {
    public let sifra: String?
    public let nazivProizvoda: String
    public let kategorijaProizvoda: String?
    public let jedinica: String
    public let maloprodajnaCijena: String
    public let cijenaJedinice: String?
    public let barkod: String?
    public let marka: String?
    public let datumUpdate: String?

    public init(
        sifra: String?,
        nazivProizvoda: String,
        kategorijaProizvoda: String?,
        jedinica: String,
        maloprodajnaCijena: String,
        cijenaJedinice: String?,
        barkod: String?,
        marka: String?,
        datumUpdate: String?
    ) {
        self.sifra = sifra
        self.nazivProizvoda = nazivProizvoda
        self.kategorijaProizvoda = kategorijaProizvoda
        self.jedinica = jedinica
        self.maloprodajnaCijena = maloprodajnaCijena
        self.cijenaJedinice = cijenaJedinice
        self.barkod = barkod
        self.marka = marka
        self.datumUpdate = datumUpdate
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DynamicCodingKeys.self)
        
        func decodeValue(for key: String) throws -> String? {
            if let match = container.allKeys.first(where: { $0.stringValue.caseInsensitiveCompare(key) == .orderedSame }) {
                return try container.decodeIfPresent(String.self, forKey: match)
            }
            return nil
        }
        
        self.sifra = try decodeValue(for: Constants.Keys.sifra)
        self.nazivProizvoda = try decodeValue(for: Constants.Keys.nazivProizvoda) ?? ""
        self.kategorijaProizvoda = try decodeValue(for: Constants.Keys.kategorijaProizvoda)
        self.jedinica = try decodeValue(for: Constants.Keys.jedinica) ?? ""
        self.maloprodajnaCijena = try decodeValue(for: Constants.Keys.maloprodajnaCijena) ?? ""
        self.cijenaJedinice = try decodeValue(for: Constants.Keys.cijenaJedinice)
        self.barkod = try decodeValue(for: Constants.Keys.barkod)
        self.marka = try decodeValue(for: Constants.Keys.marka)

        if let sidrenaKey = container.allKeys.first(where: { $0.stringValue.lowercased().hasPrefix(Constants.Keys.sidrenaPrefix) }) {
            self.datumUpdate = try container.decodeIfPresent(String.self, forKey: sidrenaKey)
        } else {
            self.datumUpdate = nil
        }
    }

    private struct DynamicCodingKeys: CodingKey {
        var stringValue: String
        init?(stringValue: String) { self.stringValue = stringValue }
        var intValue: Int? { nil }
        init?(intValue: Int) { nil }
    }

    public struct Constants {
        public struct Keys {
            static let sifra = "šifra proizvoda"
            static let nazivProizvoda = "naziv proizvoda"
            static let kategorijaProizvoda = "kategorija proizvoda"
            static let jedinica = "jedinica mjere"
            static let maloprodajnaCijena = "maloprodajna cijena"
            static let cijenaJedinice = "cijena za jedinicu mjere"
            static let barkod = "barkod"
            static let marka = "marka proizvoda"
            static let sidrenaPrefix = "sidrena cijena na"
        }
    }
}
