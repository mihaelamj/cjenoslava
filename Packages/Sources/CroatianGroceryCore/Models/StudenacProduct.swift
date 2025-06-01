import Foundation

// swiftlint:disable all

public struct StudenacProduct: Codable {
    public let kod_proizvoda: String?
    public let naziv: String
    public let grupa: String?
    public let mjera: String
    public let cijena_kn: String
    public let cijena_mjera: String?
    public let ean_kod: String?
    public let proizvodjac: String?
    public let datum_promjene: String?
    
    public init(kod_proizvoda: String?, naziv: String, grupa: String?, mjera: String, cijena_kn: String, cijena_mjera: String?, ean_kod: String?, proizvodjac: String?, datum_promjene: String?) {
        self.kod_proizvoda = kod_proizvoda
        self.naziv = naziv
        self.grupa = grupa
        self.mjera = mjera
        self.cijena_kn = cijena_kn
        self.cijena_mjera = cijena_mjera
        self.ean_kod = ean_kod
        self.proizvodjac = proizvodjac
        self.datum_promjene = datum_promjene
    }
}
