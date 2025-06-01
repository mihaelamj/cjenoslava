import Foundation

// swiftlint:disable all

public struct KTCProduct: Codable {
    public let id_artikla: String?
    public let ime_artikla: String
    public let grupa_artikla: String?
    public let jedinica_mjere: String
    public let prodajna_cijena: String
    public let cijena_po_kg_l: String?
    public let ean13: String?
    public let brend: String?
    public let zadnji_update: String?
    
    public init(id_artikla: String?, ime_artikla: String, grupa_artikla: String?, jedinica_mjere: String, prodajna_cijena: String, cijena_po_kg_l: String?, ean13: String?, brend: String?, zadnji_update: String?) {
        self.id_artikla = id_artikla
        self.ime_artikla = ime_artikla
        self.grupa_artikla = grupa_artikla
        self.jedinica_mjere = jedinica_mjere
        self.prodajna_cijena = prodajna_cijena
        self.cijena_po_kg_l = cijena_po_kg_l
        self.ean13 = ean13
        self.brend = brend
        self.zadnji_update = zadnji_update
    }
}
