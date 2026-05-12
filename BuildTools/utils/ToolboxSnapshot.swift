import Foundation

struct ToolboxSnapshot {
    let lockers: [String: String]
    let routes: [String: String]
    let dockURL: String?
    let dockMode: String?
    let untouched: Bool
    let docked: Bool
    let organicProbed: Bool
    let consentArmed: Bool
    let consentBarred: Bool
    let consentClockedAt: Date?
    
    static let pristine = ToolboxSnapshot(
        lockers: [:],
        routes: [:],
        dockURL: nil,
        dockMode: nil,
        untouched: true,
        docked: false,
        organicProbed: false,
        consentArmed: false,
        consentBarred: false,
        consentClockedAt: nil
    )
    
    var lockersFilled: Bool { !lockers.isEmpty }
    var organicLane: Bool { lockers["af_status"] == "Organic" }
    
    var consentRipe: Bool {
        guard !consentArmed && !consentBarred else { return false }
        if let date = consentClockedAt {
            let elapsed = Date().timeIntervalSince(date) / 86400
            return elapsed >= 3
        }
        return true
    }
    
    func with(
        lockers: [String: String]? = nil,
        routes: [String: String]? = nil,
        dockURL: String?? = nil,
        dockMode: String?? = nil,
        untouched: Bool? = nil,
        docked: Bool? = nil,
        organicProbed: Bool? = nil,
        consentArmed: Bool? = nil,
        consentBarred: Bool? = nil,
        consentClockedAt: Date?? = nil
    ) -> ToolboxSnapshot {
        ToolboxSnapshot(
            lockers: lockers ?? self.lockers,
            routes: routes ?? self.routes,
            dockURL: dockURL ?? self.dockURL,
            dockMode: dockMode ?? self.dockMode,
            untouched: untouched ?? self.untouched,
            docked: docked ?? self.docked,
            organicProbed: organicProbed ?? self.organicProbed,
            consentArmed: consentArmed ?? self.consentArmed,
            consentBarred: consentBarred ?? self.consentBarred,
            consentClockedAt: consentClockedAt ?? self.consentClockedAt
        )
    }
    
    static func hydrate(from frozen: ToolboxFrozen) -> ToolboxSnapshot {
        ToolboxSnapshot(
            lockers: frozen.lockers,
            routes: frozen.routes,
            dockURL: frozen.dockURL,
            dockMode: frozen.dockMode,
            untouched: frozen.untouched,
            docked: false,
            organicProbed: false,
            consentArmed: frozen.consentArmed,
            consentBarred: frozen.consentBarred,
            consentClockedAt: frozen.consentClockedAt
        )
    }
}

@MainActor
final class SnapshotManager {
    
    private(set) var current: ToolboxSnapshot = .pristine
    
    func replace(with newSnapshot: ToolboxSnapshot) {
        current = newSnapshot
    }
    
    func mutate(_ transform: (ToolboxSnapshot) -> ToolboxSnapshot) {
        current = transform(current)
    }
}
