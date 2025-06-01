import Foundation

// swiftlint:disable all

public struct LidlProduct: Codable {
    public let artikelnummer: String?
    public let bezeichnung: String
    public let warengruppe: String?
    public let einheit: String
    public let preis: String
    public let grundpreis: String?
    public let gtin: String?
    public let marke: String?
    public let aktualisiert: String?
    public let angebotspreis: String?
    
    public init(artikelnummer: String?, bezeichnung: String, warengruppe: String?, einheit: String, preis: String, grundpreis: String?, gtin: String?, marke: String?, aktualisiert: String?, angebotspreis: String?) {
        self.artikelnummer = artikelnummer
        self.bezeichnung = bezeichnung
        self.warengruppe = warengruppe
        self.einheit = einheit
        self.preis = preis
        self.grundpreis = grundpreis
        self.gtin = gtin
        self.marke = marke
        self.aktualisiert = aktualisiert
        self.angebotspreis = angebotspreis
    }
}
