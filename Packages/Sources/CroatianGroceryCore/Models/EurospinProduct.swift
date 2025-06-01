import Foundation

// swiftlint:disable all

public struct EurospinProduct: Codable {
    public let codice: String?
    public let denominazione: String
    public let categoria: String?
    public let unita: String
    public let prezzo: String
    public let prezzo_unitario: String?
    public let codice_barre: String?
    public let marca: String?
    public let aggiornato: String?
    
    public init(codice: String?, denominazione: String, categoria: String?, unita: String, prezzo: String, prezzo_unitario: String?, codice_barre: String?, marca: String?, aggiornato: String?) {
        self.codice = codice
        self.denominazione = denominazione
        self.categoria = categoria
        self.unita = unita
        self.prezzo = prezzo
        self.prezzo_unitario = prezzo_unitario
        self.codice_barre = codice_barre
        self.marca = marca
        self.aggiornato = aggiornato
    }
}
