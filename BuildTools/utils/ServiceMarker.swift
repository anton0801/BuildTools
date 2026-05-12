import Foundation

protocol ServiceMarker {
    associatedtype Provided
}

enum VaultMarker: ServiceMarker { typealias Provided = ToolboxVault }
enum InspectorMarker: ServiceMarker { typealias Provided = VoltageInspector }
enum RefetcherMarker: ServiceMarker { typealias Provided = LockerRefetcher }
enum ChartMarker: ServiceMarker { typealias Provided = DockCharter }
enum ConsentMarker: ServiceMarker { typealias Provided = ConsentRequester }

final class PhantomRegistry {
    
    static let shared = PhantomRegistry()
    
    private var storage: [ObjectIdentifier: Any] = [:]
    private let lock = NSLock()
    
    private init() {
        registerDefaults()
    }
    
    func register<M: ServiceMarker>(_ marker: M.Type, provider: () -> M.Provided) {
        lock.lock()
        defer { lock.unlock() }
        storage[ObjectIdentifier(marker)] = provider()
    }
    
    func resolve<M: ServiceMarker>(_ marker: M.Type) -> M.Provided {
        lock.lock()
        defer { lock.unlock() }
        guard let raw = storage[ObjectIdentifier(marker)],
              let typed = raw as? M.Provided else {
            fatalError("\(ToolboxConstants.logHammer) PhantomRegistry: no provider for \(marker)")
        }
        return typed
    }
    
    // MARK: - Default registrations
    
    private func registerDefaults() {
        storage[ObjectIdentifier(VaultMarker.self)]     = KeychainToolboxVault()
        storage[ObjectIdentifier(InspectorMarker.self)] = SupabaseVoltageInspector()
        storage[ObjectIdentifier(RefetcherMarker.self)] = AdjustLockerRefetcher()  // ← заменили
        storage[ObjectIdentifier(ChartMarker.self)]     = HTTPDockCharter()
        storage[ObjectIdentifier(ConsentMarker.self)]   = NotificationConsentRequester()
    }
}
