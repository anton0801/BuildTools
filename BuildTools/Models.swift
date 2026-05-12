import Foundation
import SwiftUI

// MARK: - Tool Status
enum ToolStatus: String, CaseIterable, Codable {
    case available = "Available"
    case inUse = "In Use"
    case broken = "Broken"
    case lost = "Lost"

    var color: Color {
        switch self {
        case .available: return Color(hex: "#22C55E")
        case .inUse:     return Color(hex: "#3B82F6")
        case .broken:    return Color(hex: "#EF4444")
        case .lost:      return Color(hex: "#991B1B")
        }
    }

    var icon: String {
        switch self {
        case .available: return "checkmark.circle.fill"
        case .inUse:     return "person.fill"
        case .broken:    return "wrench.fill"
        case .lost:      return "questionmark.circle.fill"
        }
    }
}

// MARK: - Tool Category
enum ToolCategory: String, CaseIterable, Codable {
    case power = "Power Tools"
    case hand = "Hand Tools"
    case measuring = "Measuring"
    case safety = "Safety"
    case electrical = "Electrical"
    case plumbing = "Plumbing"
    case other = "Other"

    var icon: String {
        switch self {
        case .power:      return "bolt.fill"
        case .hand:       return "hammer.fill"
        case .measuring:  return "ruler.fill"
        case .safety:     return "shield.fill"
        case .electrical: return "cable.connector.horizontal"
        case .plumbing:   return "drop.fill"
        case .other:      return "wrench.and.screwdriver.fill"
        }
    }
}

// MARK: - Location
enum ToolLocation: String, CaseIterable, Codable {
    case home    = "Home"
    case garage  = "Garage"
    case site    = "Site"
    case storage = "Storage"
    case vehicle = "Vehicle"

    var icon: String {
        switch self {
        case .home:    return "house.fill"
        case .garage:  return "car.fill"
        case .site:    return "building.2.fill"
        case .storage: return "archivebox.fill"
        case .vehicle: return "truck.box.fill"
        }
    }
}

// MARK: - Tool Model
struct Tool: Identifiable, Codable {
    var id: UUID = UUID()
    var name: String
    var category: ToolCategory
    var status: ToolStatus
    var location: ToolLocation
    var assignedTo: String?
    var notes: String
    var serialNumber: String
    var purchaseDate: Date?
    var lastUsedDate: Date?
    var createdAt: Date = Date()

    static var sampleData: [Tool] {
        [
            Tool(name: "DeWalt Drill", category: .power, status: .available, location: .garage,
                 assignedTo: nil, notes: "18V, two batteries", serialNumber: "DW-001"),
            Tool(name: "Angle Grinder", category: .power, status: .inUse, location: .site,
                 assignedTo: "Mike Johnson", notes: "230mm blade", serialNumber: "AG-002"),
            Tool(name: "Tape Measure 5m", category: .measuring, status: .available, location: .home,
                 assignedTo: nil, notes: "", serialNumber: "TM-003"),
            Tool(name: "Circular Saw", category: .power, status: .broken, location: .garage,
                 assignedTo: nil, notes: "Needs new blade", serialNumber: "CS-004"),
            Tool(name: "Safety Helmet", category: .safety, status: .available, location: .site,
                 assignedTo: nil, notes: "White, standard", serialNumber: "SH-005"),
            Tool(name: "Level 60cm", category: .measuring, status: .inUse, location: .site,
                 assignedTo: "Alex Smith", notes: "", serialNumber: "LV-006"),
            Tool(name: "Screwdriver Set", category: .hand, status: .lost, location: .home,
                 assignedTo: nil, notes: "Phillips + flat, 12pcs", serialNumber: "SS-007"),
            Tool(name: "Multimeter", category: .electrical, status: .available, location: .storage,
                 assignedTo: nil, notes: "Digital, auto-range", serialNumber: "MM-008"),
        ]
    }
}

// MARK: - Consumable
struct Consumable: Identifiable, Codable {
    var id: UUID = UUID()
    var name: String
    var quantity: Double
    var unit: String
    var minimumStock: Double
    var location: ToolLocation
    var notes: String
    var createdAt: Date = Date()

    var isLowStock: Bool { quantity <= minimumStock }

    static var sampleData: [Consumable] {
        [
            Consumable(name: "Drill Bits Set", quantity: 3, unit: "pcs", minimumStock: 5,
                      location: .garage, notes: "HSS, assorted"),
            Consumable(name: "Sandpaper 120", quantity: 12, unit: "sheets", minimumStock: 10,
                      location: .storage, notes: ""),
            Consumable(name: "Screws M6x50", quantity: 45, unit: "pcs", minimumStock: 50,
                      location: .garage, notes: "Zinc coated"),
            Consumable(name: "Masking Tape", quantity: 2, unit: "rolls", minimumStock: 3,
                      location: .home, notes: "50mm wide"),
            Consumable(name: "Wire 2.5mm²", quantity: 8, unit: "m", minimumStock: 20,
                      location: .site, notes: "Copper, flexible"),
            Consumable(name: "Safety Gloves", quantity: 6, unit: "pairs", minimumStock: 4,
                      location: .site, notes: "Size L"),
            Consumable(name: "Concrete Nails", quantity: 200, unit: "pcs", minimumStock: 100,
                      location: .garage, notes: "60mm"),
            Consumable(name: "Grease", quantity: 1, unit: "tube", minimumStock: 2,
                      location: .garage, notes: "Lithium, 400g"),
        ]
    }
}

// MARK: - Worker
struct Worker: Identifiable, Codable {
    var id: UUID = UUID()
    var name: String
    var role: String
    var phone: String
    var createdAt: Date = Date()

    static var sampleData: [Worker] {
        [
            Worker(name: "Mike Johnson", role: "Foreman", phone: "+1 555-0101"),
            Worker(name: "Alex Smith", role: "Electrician", phone: "+1 555-0102"),
            Worker(name: "Chris Lee", role: "Plumber", phone: "+1 555-0103"),
            Worker(name: "Sam Wilson", role: "General Worker", phone: "+1 555-0104"),
        ]
    }
}

// MARK: - Task
struct AppTask: Identifiable, Codable {
    var id: UUID = UUID()
    var title: String
    var notes: String
    var isCompleted: Bool = false
    var priority: TaskPriority
    var createdAt: Date = Date()

    static var sampleData: [AppTask] {
        [
            AppTask(title: "Buy new drill bits", notes: "HSS, 6mm and 10mm", priority: .high),
            AppTask(title: "Repair circular saw", notes: "Replace blade + check guard", priority: .urgent),
            AppTask(title: "Restock screws M6", notes: "Buy 200 pcs minimum", priority: .medium),
            AppTask(title: "Return tape measure", notes: "Mike borrowed it last week", priority: .low),
        ]
    }
}

enum TaskPriority: String, CaseIterable, Codable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case urgent = "Urgent"

    var color: Color {
        switch self {
        case .low:    return Color(hex: "#64748B")
        case .medium: return Color(hex: "#3B82F6")
        case .high:   return Color(hex: "#F97316")
        case .urgent: return Color(hex: "#EF4444")
        }
    }
}

// MARK: - Activity
struct Activity: Identifiable, Codable {
    var id: UUID = UUID()
    var description: String
    var toolName: String?
    var date: Date = Date()
    var type: ActivityType

    enum ActivityType: String, Codable {
        case added, updated, assigned, returned, broken, lost, taskCompleted
    }
}

// MARK: - User
struct AppUser: Codable {
    var name: String
    var role: String
    var email: String
}

struct ToolboxFrozen {
    let lockers: [String: String]
    let routes: [String: String]
    let dockURL: String?
    let dockMode: String?
    let untouched: Bool
    let consentArmed: Bool
    let consentBarred: Bool
    let consentClockedAt: Date?
}

// MARK: - Outcomes

enum ToolboxOutcome {
    case stillIdle
    case askForConsent
    case openDock
    case fallbackHome
}

// MARK: - Error Context

struct ErrorTag {
    let key: String
    let value: String
}

@resultBuilder
struct ErrorContextBuilder {
    static func buildBlock(_ tags: ErrorTag...) -> [ErrorTag] { Array(tags) }
    static func buildOptional(_ tags: [ErrorTag]?) -> [ErrorTag] { tags ?? [] }
    static func buildEither(first tags: [ErrorTag]) -> [ErrorTag] { tags }
    static func buildEither(second tags: [ErrorTag]) -> [ErrorTag] { tags }
}

// MARK: - ToolboxError

struct ToolboxError: Error {
    
    enum Kind: String {
        case emptyLockers
        case voltageInspectionFailed
        case dockRefused
        case payloadGarbled
        case wireSnapped
        case throttled
        case watchdogExpired
        case bootInterrupted
    }
    
    let kind: Kind
    let tags: [ErrorTag]
    
    init(_ kind: Kind, @ErrorContextBuilder tags: () -> [ErrorTag] = { [] }) {
        self.kind = kind
        self.tags = tags()
    }
    
    var humanLabel: String {
        let tagList = tags.map { "\($0.key)=\($0.value)" }.joined(separator: ", ")
        return tagList.isEmpty ? kind.rawValue : "\(kind.rawValue) {\(tagList)}"
    }
}

struct ToolboxKey {
    static let lockers           = "bt2_lockers"
    static let routes            = "bt2_routes"
    static let dockURL           = "bt2_dock_url"
    static let dockMode          = "bt2_dock_mode"
    static let primed            = "bt2_primed"
    static let consentArmed      = "bt2_consent_armed"
    static let consentBarred     = "bt2_consent_barred"
    static let consentClockedAt  = "bt2_consent_clocked_at"
    
    // Legacy
    static let pushURL = "temp_url"
    static let fcm     = "fcm_token"
    static let push    = "push_token"
}

// MARK: - Internal Event Bus Names

struct BusEvent {
    static let lockersReceived  = Notification.Name("bt2_internal_lockers")
    static let routesReceived   = Notification.Name("bt2_internal_routes")
    static let pushPayloadFound = Notification.Name("bt2_internal_push")
    static let didActivate      = Notification.Name("bt2_internal_activate")
}
