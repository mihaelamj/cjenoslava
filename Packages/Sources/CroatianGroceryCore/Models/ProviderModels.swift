import Foundation
// MARK: - Provider-Specific Models

/// Plodine specific data structure
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

/// Tommy specific data structure
public struct TommyProduct: Codable {
    public let product_code: String?
    public let product_name: String
    public let category: String?
    public let unit: String
    public let price: String
    public let unit_price: String?
    public let ean: String?
    public let brand: String?
    public let last_updated: String?
    public let promotional_price: String?
    
    public init(product_code: String?, product_name: String, category: String?, unit: String, price: String, unit_price: String?, ean: String?, brand: String?, last_updated: String?, promotional_price: String?) {
        self.product_code = product_code
        self.product_name = product_name
        self.category = category
        self.unit = unit
        self.price = price
        self.unit_price = unit_price
        self.ean = ean
        self.brand = brand
        self.last_updated = last_updated
        self.promotional_price = promotional_price
    }
}

/// Lidl specific data structure
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

/// Spar specific data structure
public struct SparProduct: Codable {
    public let item_id: String?
    public let item_name: String
    public let category_name: String?
    public let unit_type: String
    public let retail_price: String
    public let price_per_unit: String?
    public let barcode: String?
    public let brand_name: String?
    public let updated_date: String?
    public let sale_price: String?
    
    public init(item_id: String?, item_name: String, category_name: String?, unit_type: String, retail_price: String, price_per_unit: String?, barcode: String?, brand_name: String?, updated_date: String?, sale_price: String?) {
        self.item_id = item_id
        self.item_name = item_name
        self.category_name = category_name
        self.unit_type = unit_type
        self.retail_price = retail_price
        self.price_per_unit = price_per_unit
        self.barcode = barcode
        self.brand_name = brand_name
        self.updated_date = updated_date
        self.sale_price = sale_price
    }
}

/// Studenac specific data structure
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

/// dm specific data structure
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

/// Eurospin specific data structure
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

/// Konzum specific data structure
public struct KonzumProduct: Codable {
    public let sifra: String?
    public let naziv_proizvoda: String
    public let kategorija_proizvoda: String?
    public let jedinica: String
    public let maloprodajna_cijena: String
    public let cijena_jedinice: String?
    public let bar_kod: String?
    public let marka: String?
    public let datum_update: String?
    
    public init(sifra: String?, naziv_proizvoda: String, kategorija_proizvoda: String?, jedinica: String, maloprodajna_cijena: String, cijena_jedinice: String?, bar_kod: String?, marka: String?, datum_update: String?) {
        self.sifra = sifra
        self.naziv_proizvoda = naziv_proizvoda
        self.kategorija_proizvoda = kategorija_proizvoda
        self.jedinica = jedinica
        self.maloprodajna_cijena = maloprodajna_cijena
        self.cijena_jedinice = cijena_jedinice
        self.bar_kod = bar_kod
        self.marka = marka
        self.datum_update = datum_update
    }
}

/// Kaufland specific data structure
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

/// KTC specific data structure
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
