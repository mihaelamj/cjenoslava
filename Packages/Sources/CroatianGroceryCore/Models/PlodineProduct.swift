import Foundation

// swiftlint:disable all
public struct PlodineProduct: Codable {
    public let sifra_artikla: String?
    public let naziv_artikla: String
    public let kategorija: String?
    public let jedinica_mjere: String
    public let cijena: String
    public let cijena_po_jedinici: String?
    public let barkod: String?
    public let brend: String?
    public let datum_azuriranja: String?
    
    public init(sifra_artikla: String?, naziv_artikla: String, kategorija: String?, jedinica_mjere: String, cijena: String, cijena_po_jedinici: String?, barkod: String?, brend: String?, datum_azuriranja: String?) {
        self.sifra_artikla = sifra_artikla
        self.naziv_artikla = naziv_artikla
        self.kategorija = kategorija
        self.jedinica_mjere = jedinica_mjere
        self.cijena = cijena
        self.cijena_po_jedinici = cijena_po_jedinici
        self.barkod = barkod
        self.brend = brend
        self.datum_azuriranja = datum_azuriranja
    }
}
