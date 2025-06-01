import Foundation

// swiftlint:disable all

public struct KauflandProduct: Codable {
    public let artikel_id: String?
    public let artikel_name: String
    public let warengruppe: String?
    public let mengeneinheit: String
    public let verkaufspreis: String
    public let grundpreis: String?
    public let ean_code: String?
    public let markenname: String?
    public let letzte_aktualisierung: String?
    
    public init(artikel_id: String?, artikel_name: String, warengruppe: String?, mengeneinheit: String, verkaufspreis: String, grundpreis: String?, ean_code: String?, markenname: String?, letzte_aktualisierung: String?) {
        self.artikel_id = artikel_id
        self.artikel_name = artikel_name
        self.warengruppe = warengruppe
        self.mengeneinheit = mengeneinheit
        self.verkaufspreis = verkaufspreis
        self.grundpreis = grundpreis
        self.ean_code = ean_code
        self.markenname = markenname
        self.letzte_aktualisierung = letzte_aktualisierung
    }
}
