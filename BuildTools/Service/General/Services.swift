import Foundation
import FirebaseCore
import FirebaseMessaging
import WebKit
import UIKit
import UserNotifications
import AdjustSdk

protocol VoltageInspector {
    func makeInspectionSequence() -> InspectionSequence
}

protocol LockerRefetcher {
    func refetch(deviceID: String) async throws -> [String: Any]
}

protocol DockCharter {
    func chart(seed: [String: Any]) async throws -> String
}

protocol ConsentRequester {
    func request(deferred: @escaping (Bool) -> Void)
    func arm()
}

// MARK: - Custom AsyncSequence для validation

/// Inspection events — что генерирует sequence
enum InspectionEvent {
    case probing
    case landed(Bool)
}

/// Custom AsyncSequence — даёт back-pressure через AsyncIterator
struct InspectionSequence: AsyncSequence {
    typealias Element = InspectionEvent
    
    let runner: () async throws -> Bool
    
    struct AsyncIterator: AsyncIteratorProtocol {
        var runner: (() async throws -> Bool)?
        var emittedProbing = false
        
        mutating func next() async throws -> InspectionEvent? {
            // Сначала emit .probing
            if !emittedProbing {
                emittedProbing = true
                return .probing
            }
            
            // Потом запускаем runner и emit .landed
            guard let r = runner else { return nil }
            runner = nil
            
            let result = try await r()
            return .landed(result)
        }
    }
    
    func makeAsyncIterator() -> AsyncIterator {
        AsyncIterator(runner: runner)
    }
}

// MARK: - Supabase Voltage Inspector

final class SupabaseVoltageInspector: VoltageInspector {
    
    func makeInspectionSequence() -> InspectionSequence {
        return InspectionSequence { [weak self] in
            return true
        }
    }
}

final class AdjustLockerRefetcher: LockerRefetcher {
    
    private let session: URLSession
    
    init() {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 90
        config.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        config.urlCache = nil
        self.session = URLSession(configuration: config)
    }
    
    func refetch(deviceID: String) async throws -> [String: Any] {
        var components = URLComponents(string: "https://api4.adjust.com/attribution")
        components?.queryItems = [
            URLQueryItem(name: "app_token",  value: ToolboxConstants.adjustAppToken),
            URLQueryItem(name: "device_id",  value: deviceID),
            URLQueryItem(name: "type",       value: "adid")
        ]
        
        guard let url = components?.url else {
            throw ToolboxError(.payloadGarbled) {
                ErrorTag(key: "stage", value: "URL build")
            }
        }
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await session.data(for: request)
        
        guard let http = response as? HTTPURLResponse,
              (200...299).contains(http.statusCode) else {
            throw ToolboxError(.wireSnapped) {
                ErrorTag(key: "stage", value: "attribution refetch")
            }
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw ToolboxError(.payloadGarbled) {
                ErrorTag(key: "stage", value: "JSON decode")
            }
        }
        
        // Нормализуем Adjust attribution response в формат совместимый с остальным кодом
        return normalizeAttribution(json)
    }
    
    /// Приводит Adjust attribution response к формату [String: Any] совместимому с AF
    private func normalizeAttribution(_ json: [String: Any]) -> [String: Any] {
        var result = json
        
        // Adjust возвращает "Attribution" объект внутри "data" — разворачиваем
        if let attribution = json["Attribution"] as? [String: Any] {
            for (k, v) in attribution {
                result[k] = v
            }
        }
        
        // Маппинг Adjust полей → внутренние ключи
        if let network = json["tracker_name"] as? String {
            result["network"] = network
        }
        if json["network"] == nil {
            result["af_status"] = "Organic"
        } else {
            result["af_status"] = "Non-organic"
        }
        
        return result
    }
}

final class HTTPDockCharter: DockCharter {
    
    private let session: URLSession
    private let intervals: [Double] = [64.0, 128.0, 256.0]
    
    init() {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 90
        config.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        config.urlCache = nil
        self.session = URLSession(configuration: config)
    }
    
    private var browserAgent: String = WKWebView().value(forKey: "userAgent") as? String ?? ""
    
    func chart(seed: [String: Any]) async throws -> String {
        guard let endpoint = URL(string: ToolboxConstants.backendDepot) else {
            throw ToolboxError(.payloadGarbled) {
                ErrorTag(key: "stage", value: "endpoint URL")
            }
        }
        
        var body: [String: Any] = seed
        body["os"] = "iOS"
        // Adjust device ID вместо AppsFlyer UID (af_id)
        body["af_id"] = await Adjust.adid() ?? ""
        body["bundle_id"] = Bundle.main.bundleIdentifier ?? ""
        body["firebase_project_id"] = FirebaseApp.app()?.options.gcmSenderID
        body["store_id"] = "id\(ToolboxConstants.appCode)"
        body["push_token"] = UserDefaults.standard.string(forKey: ToolboxKey.push)
            ?? Messaging.messaging().fcmToken
        body["locale"] = Locale.preferredLanguages.first?.prefix(2).uppercased() ?? "EN"
        
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(browserAgent, forHTTPHeaderField: "User-Agent")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        var lastError: Error?
        
        for (idx, interval) in intervals.enumerated() {
            do {
                return try await singleShot(request)
            } catch let err as ToolboxError where err.kind == .dockRefused {
                throw err
            } catch let err as ToolboxError where err.kind == .throttled {
                let waitTime = interval * Double(idx + 1)
                try await Task.sleep(nanoseconds: UInt64(waitTime * 1_000_000_000))
                continue
            } catch {
                lastError = error
                if idx < intervals.count - 1 {
                    try await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
                }
            }
        }
        
        if let lastError = lastError { throw lastError }
        throw ToolboxError(.wireSnapped) {
            ErrorTag(key: "reason", value: "all retries exhausted")
        }
    }
    
    private func singleShot(_ request: URLRequest) async throws -> String {
        let (data, response) = try await session.data(for: request)
        
        guard let http = response as? HTTPURLResponse else {
            throw ToolboxError(.wireSnapped) {
                ErrorTag(key: "reason", value: "non-HTTP response")
            }
        }
        
        if http.statusCode == 404 {
            throw ToolboxError(.dockRefused) {
                ErrorTag(key: "httpCode", value: "404")
            }
        }
        
        if http.statusCode == 429 {
            throw ToolboxError(.throttled) {
                ErrorTag(key: "httpCode", value: "429")
            }
        }
        
        guard (200...299).contains(http.statusCode) else {
            throw ToolboxError(.wireSnapped) {
                ErrorTag(key: "httpCode", value: "\(http.statusCode)")
            }
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw ToolboxError(.payloadGarbled) {
                ErrorTag(key: "stage", value: "JSON parse")
            }
        }
        
        guard let ok = json["ok"] as? Bool else {
            throw ToolboxError(.payloadGarbled) {
                ErrorTag(key: "stage", value: "missing 'ok'")
            }
        }
        
        if !ok {
            throw ToolboxError(.dockRefused) {
                ErrorTag(key: "reason", value: "server ok:false")
            }
        }
        
        guard let url = json["url"] as? String else {
            throw ToolboxError(.payloadGarbled) {
                ErrorTag(key: "stage", value: "missing 'url'")
            }
        }
        
        return url
    }
}

final class NotificationConsentRequester: ConsentRequester {
    
    /// Closure-based — completion вызывается deferred на main queue
    func request(deferred: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge]
        ) { granted, error in
            if let error = error {
            }
            Task { @MainActor in
                deferred(granted)
            }
        }
    }
    
    func arm() {
        Task { @MainActor in
            UIApplication.shared.registerForRemoteNotifications()
        }
    }
}

