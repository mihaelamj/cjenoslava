import Foundation

public enum GroceryProductProvider: String, Codable, CaseIterable, Sendable {
    case konzum = "konzum"
    case lidl = "lidl"
    case spar = "spar"
    case kaufland = "kaufland"
    case plodine = "plodine"
    case dm = "dm"
    case eurospin = "eurospin"
    case ktc = "ktc"
    case studenac = "studenac"
    case ribola = "ribola"
    case tommy = "tommy"
    case vrutak = "vrutak"
    case trgocentar = "trgocentar"
    case metro = "metro"
    case ntl = "ntl"
    case zabac = "zabac"
    
    public var displayName: String {
        switch self {
        case .konzum: return "Konzum"
        case .lidl: return "Lidl"
        case .spar: return "Spar"
        case .kaufland: return "Kaufland"
        case .plodine: return "Plodine"
        case .dm: return "DM"
        case .eurospin: return "Eurospin"
        case .ktc: return "KTC"
        case .studenac: return "Studenac"
        case .ribola: return "Ribola"
        case .tommy: return "Tommy"
        case .vrutak: return "Vrutak"
        case .trgocentar: return "Trgocentar"
        case .metro: return "Metro"
        case .ntl: return "NTL"
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
