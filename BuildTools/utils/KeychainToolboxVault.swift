import Foundation
import Security

protocol ToolboxVault {
    func stashLockers(_ data: [String: String])
    func stashRoutes(_ data: [String: String])
    func stashDock(url: String, mode: String)
    func stashConsent(armed: Bool, barred: Bool, at: Date?)
    func markPrimed()
    func defrost() -> ToolboxFrozen
}

final class KeychainToolboxVault: ToolboxVault {
    
    private let suiteVault: UserDefaults
    private let homeVault: UserDefaults
    
    init() {
        self.suiteVault = UserDefaults(suiteName: ToolboxConstants.suiteToolbox)!
        self.homeVault = UserDefaults.standard
    }
    
    // MARK: - Stash
    
    func stashLockers(_ data: [String: String]) {
        guard let encoded = encode(data) else { return }
        writeKeychain(account: ToolboxKey.lockers, value: encoded)
    }
    
    func stashRoutes(_ data: [String: String]) {
        guard let encoded = encode(data) else { return }
        let veiled = veil(encoded)
        writeKeychain(account: ToolboxKey.routes, value: veiled)
    }
    
    func stashDock(url: String, mode: String) {
        writeKeychain(account: ToolboxKey.dockURL, value: url)
        // Дублируем в UserDefaults для WebView compatibility
        suiteVault.set(url, forKey: ToolboxKey.dockURL)
        homeVault.set(url, forKey: ToolboxKey.dockURL)
        suiteVault.set(mode, forKey: ToolboxKey.dockMode)
    }
    
    func stashConsent(armed: Bool, barred: Bool, at: Date?) {
        suiteVault.set(armed, forKey: ToolboxKey.consentArmed)
        suiteVault.set(barred, forKey: ToolboxKey.consentBarred)
        if let when = at {
            let ms = when.timeIntervalSince1970 * 1000
            suiteVault.set(ms, forKey: ToolboxKey.consentClockedAt)
        }
    }
    
    func markPrimed() {
        suiteVault.set(true, forKey: ToolboxKey.primed)
        homeVault.set(true, forKey: ToolboxKey.primed)
    }
    
    // MARK: - Defrost
    
    func defrost() -> ToolboxFrozen {
        let lockersRaw = readKeychain(account: ToolboxKey.lockers) ?? ""
        let lockers = decode(lockersRaw) ?? [:]
        
        let routesVeiled = readKeychain(account: ToolboxKey.routes) ?? ""
        let routesRaw = unveil(routesVeiled) ?? ""
        let routes = decode(routesRaw) ?? [:]
        
        let dockURL = readKeychain(account: ToolboxKey.dockURL)
            ?? suiteVault.string(forKey: ToolboxKey.dockURL)
        let dockMode = suiteVault.string(forKey: ToolboxKey.dockMode)
        
        let primed = suiteVault.bool(forKey: ToolboxKey.primed)
        
        let armed = suiteVault.bool(forKey: ToolboxKey.consentArmed)
        let barred = suiteVault.bool(forKey: ToolboxKey.consentBarred)
        let atMs = suiteVault.double(forKey: ToolboxKey.consentClockedAt)
        let at = atMs > 0 ? Date(timeIntervalSince1970: atMs / 1000) : nil
        
        return ToolboxFrozen(
            lockers: lockers,
            routes: routes,
            dockURL: dockURL,
            dockMode: dockMode,
            untouched: !primed,
            consentArmed: armed,
            consentBarred: barred,
            consentClockedAt: at
        )
    }
    
    // MARK: - Keychain Services
    
    private func writeKeychain(account: String, value: String) {
        guard let data = value.data(using: .utf8) else { return }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: ToolboxConstants.keychainService,
            kSecAttrAccount as String: account
        ]
        
        // Delete existing first
        SecItemDelete(query as CFDictionary)
        
        // Add new
        var attributes = query
        attributes[kSecValueData as String] = data
        attributes[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        
        let status = SecItemAdd(attributes as CFDictionary, nil)
        if status != errSecSuccess {
        }
    }
    
    private func readKeychain(account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: ToolboxConstants.keychainService,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let text = String(data: data, encoding: .utf8) else {
            return nil
        }
        return text
    }
    
    private func encode(_ dict: [String: String]) -> String? {
        let any = dict.mapValues { $0 as Any }
        guard let data = try? JSONSerialization.data(withJSONObject: any),
              let text = String(data: data, encoding: .utf8) else {
            return nil
        }
        return text
    }
    
    private func decode(_ text: String) -> [String: String]? {
        guard let data = text.data(using: .utf8),
              let any = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        return any.mapValues { "\($0)" }
    }
    
    // MARK: - Veiling
    
    private func veil(_ input: String) -> String {
        let b64 = Data(input.utf8).base64EncodedString()
        return b64
            .replacingOccurrences(of: "=", with: "+")
            .replacingOccurrences(of: "/", with: "_")
    }
    
    private func unveil(_ input: String) -> String? {
        let b64 = input
            .replacingOccurrences(of: "+", with: "=")
            .replacingOccurrences(of: "_", with: "/")
        guard let data = Data(base64Encoded: b64),
              let text = String(data: data, encoding: .utf8) else {
            return nil
        }
        return text
    }
}
