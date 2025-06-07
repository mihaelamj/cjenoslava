import Foundation


/// Represents a grocery store provider
public enum ShopProvider: String, CaseIterable, Codable, Sendable {
    case plodine = "plodine"
    case tommy = "tommy"
    case lidl = "lidl"
    case spar = "spar"
    case studenac = "studenac"
    case dm = "dm"
    case eurospin = "eurospin"
    case konzum = "konzum"
    case kaufland = "kaufland"
    case ktc = "ktc"
//    case metro = "metro"
//    case ntl = "ntl"
//    case ribola = "ribola"
//    case trgocentar = "trgocentar"
//    case vrutak = "vrutak"
//    case zabac = "zabac"
    
    public var displayName: String {
        switch self {
        case .plodine: return "Plodine"
        case .tommy: return "Tommy"
        case .lidl: return "Lidl"
        case .spar: return "Spar"
        case .studenac: return "Studenac"
        case .dm: return "dm"
        case .eurospin: return "Eurospin"
        case .konzum: return "Konzum"
        case .kaufland: return "Kaufland"
        case .ktc: return "KTC"
//        case .metro: return "Metro"
        }
    }
    
    public var websiteURL: URL? {
        switch self {
        case .plodine: return URL(string: "https://www.plodine.hr/info-o-cijenama")
        case .tommy: return URL(string: "https://www.tommy.hr/objava-cjenika")
        case .lidl: return URL(string: "https://tvrtka.lidl.hr/cijene")
        case .spar: return URL(string: "https://www.spar.hr/usluge/cjenici")
        case .studenac: return URL(string: "https://www.studenac.hr/popis-maloprodajnih-cijena")
        case .dm: return URL(string: "https://www.dm.hr/novo/promocije/nove-oznake-cijena-i-vazeci-cjenik-u-dm-u-2906632")
        case .eurospin: return URL(string: "https://www.eurospin.hr/cjenik/")
        case .konzum: return URL(string: "https://www.konzum.hr/cjenici")
        case .kaufland: return URL(string: "https://www.kaufland.hr/akcije-novosti/mpc-popis.html")
        case .ktc: return URL(string: "https://www.ktc.hr/cjenici")
//        case .metro: return URL(string: "https://metrocjenik.com.hr")
        
        }
    }
}
