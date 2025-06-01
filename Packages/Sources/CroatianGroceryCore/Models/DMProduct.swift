import Foundation

// swiftlint:disable all

public struct DMProduct: Codable {
    public let artikel_nr: String?
    public let artikel_bezeichnung: String
    public let kategorie: String?
    public let verkaufseinheit: String
    public let verkaufspreis: String
    public let grundpreis: String?
    public let ean: String?
    public let hersteller: String?
    public let datum: String?
    
    public init(artikel_nr: String?, artikel_bezeichnung: String, kategorie: String?, verkaufseinheit: String, verkaufspreis: String, grundpreis: String?, ean: String?, hersteller: String?, datum: String?) {
        self.artikel_nr = artikel_nr
        self.artikel_bezeichnung = artikel_bezeichnung
        self.kategorie = kategorie
        self.verkaufseinheit = verkaufseinheit
        self.verkaufspreis = verkaufspreis
        self.grundpreis = grundpreis
        self.ean = ean
        self.hersteller = hersteller
        self.datum = datum
    }
}
