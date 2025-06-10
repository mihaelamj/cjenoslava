import Foundation

public enum GroceryProductProvider: String, Codable, CaseIterable, Sendable {
    case dm = "dm"
    case eurospin = "eurospin"
    case kaufland = "kaufland"
    case konzum = "konzum"
    case ktc = "ktc"
    case lidl = "lidl"
    case metro = "metro"
    case ntl = "ntl"
    case plodine = "plodine"
    case ribola = "ribola"
    case spar = "spar"
    case studenac = "studenac"
    case tommy = "tommy"
    case trgocentar = "trgocentar"
    case vrutak = "vrutak"
    case zabac = "zabac"
    
    public var displayName: String {
        switch self {
        case .dm: return "DM"
        case .eurospin: return "Eurospin"
        case .kaufland: return "Kaufland"
        case .konzum: return "Konzum"
        case .ktc: return "KTC"
        case .lidl: return "Lidl"
        case .metro: return "Metro"
        case .ntl: return "NTL"
        case .plodine: return "Plodine"
        case .ribola: return "Ribola"
        case .spar: return "Spar"
        case .studenac: return "Studenac"
        case .tommy: return "Tommy"
        case .trgocentar: return "Trgocentar"
        case .vrutak: return "Vrutak"
        case .zabac: return "Žabac"
        }
    }
}

public enum Currency: String, Codable, Sendable {
    case eur = "EUR"
    case hrk = "HRK"
    
    public var symbol: String {
        switch self {
        case .eur: return "€"
        case .hrk: return "kn"
        }
    }
}
