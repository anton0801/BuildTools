import UIKit
import FirebaseCore
import FirebaseMessaging
import AppTrackingTransparency
import UserNotifications
import AdjustSdk
import AdSupport

final class AppDelegate: UIResponder, UIApplicationDelegate {
    
    private var observers: [BusObserver] = []
    private let lockerWeaver = LockerWeaver()
    private let pushScribe = PushScribe()
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {

        observers = [
            FirebaseObserver(),
            MessagingObserver(messagingDelegate: self, notificationDelegate: self),
            // AdjustObserver(delegate: self),
            BroadcastObserver()
        ]
        
        for observer in observers {
            observer.subscribe()
        }
        
        NotificationCenter.default.post(name: BusEvent.didActivate, object: nil)
        
        if let remote = launchOptions?[.remoteNotification] as? [AnyHashable: Any] {
            pushScribe.scribe(remote)
        }
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onActivation),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        
        return true
    }
    
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        Messaging.messaging().apnsToken = deviceToken
        Adjust.setPushToken(deviceToken)
    }
    
    @objc private func onActivation() {
        AdjustStarter.begin(delegate: self)
    }
}

extension AppDelegate: MessagingDelegate {
    func messaging(
        _ messaging: Messaging,
        didReceiveRegistrationToken fcmToken: String?
    ) {
        messaging.token { token, err in
            guard err == nil, let t = token else { return }
            UserDefaults.standard.set(t, forKey: ToolboxKey.fcm)
            UserDefaults.standard.set(t, forKey: ToolboxKey.push)
            UserDefaults(suiteName: ToolboxConstants.suiteToolbox)?.set(t, forKey: "shared_fcm")
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        pushScribe.scribe(notification.request.content.userInfo)
        completionHandler([.banner, .sound, .badge])
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        pushScribe.scribe(response.notification.request.content.userInfo)
        completionHandler()
    }
    
    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        pushScribe.scribe(userInfo)
        completionHandler(.newData)
    }
}

extension AppDelegate: AdjustDelegate {
    
    func adjustAttributionChanged(_ attribution: ADJAttribution?) {
        guard let attribution else { return }
        
        var data: [AnyHashable: Any] = [:]
        if let network      = attribution.network      { data["network"]       = network }
        if let campaign     = attribution.campaign     { data["campaign"]      = campaign }
        if let adgroup      = attribution.adgroup      { data["adgroup"]       = adgroup }
        if let creative     = attribution.creative     { data["creative"]      = creative }
        if let clickLabel   = attribution.clickLabel   { data["click_label"]   = clickLabel }
        if let trackerName  = attribution.trackerName  { data["tracker_name"]  = trackerName }
        if let trackerToken = attribution.trackerToken { data["tracker_token"] = trackerToken }
        if let costType     = attribution.costType     { data["cost_type"]     = costType }
        data["is_organic"] = attribution.network == nil
        
        lockerWeaver.acceptLockers(data)
    }
    
    func adjustSessionTrackingFailed(_ sessionFailureResponseData: ADJSessionFailure?) {
        let desc = sessionFailureResponseData?.message ?? "unknown"
        let errData: [AnyHashable: Any] = ["error": true, "error_desc": desc]
        lockerWeaver.acceptLockers(errData)
    }
    
    func adjustDeeplinkResponse(_ deeplink: URL?) -> Bool {
        guard let deeplink else { return false }
        
        let data: [AnyHashable: Any] = [
            "deeplink_url":    deeplink.absoluteString,
            "deeplink_scheme": deeplink.scheme ?? "",
            "deeplink_host":   deeplink.host ?? "",
            "deeplink_path":   deeplink.path
        ]
        
        lockerWeaver.acceptRoutes(data)
        NotificationCenter.default.post(
            name: BusEvent.routesReceived,
            object: nil,
            userInfo: ["data": data]
        )
        return true
    }
}

protocol BusObserver {
    var label: String { get }
    func subscribe()
}

final class FirebaseObserver: BusObserver {
    let label = "firebase"
    private var token: NSObjectProtocol?
    
    func subscribe() {
        token = NotificationCenter.default.addObserver(
            forName: BusEvent.didActivate,
            object: nil,
            queue: .main
        ) { _ in
            FirebaseApp.configure()
        }
    }
}

final class MessagingObserver: BusObserver {
    let label = "messaging"
    private weak var messagingDelegate: MessagingDelegate?
    private weak var notificationDelegate: UNUserNotificationCenterDelegate?
    private var token: NSObjectProtocol?
    
    init(messagingDelegate: MessagingDelegate, notificationDelegate: UNUserNotificationCenterDelegate) {
        self.messagingDelegate = messagingDelegate
        self.notificationDelegate = notificationDelegate
    }
    
    func subscribe() {
        token = NotificationCenter.default.addObserver(
            forName: BusEvent.didActivate,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self = self else { return }
            Messaging.messaging().delegate = self.messagingDelegate
            UNUserNotificationCenter.current().delegate = self.notificationDelegate
            UIApplication.shared.registerForRemoteNotifications()
        }
    }
}

final class BroadcastObserver: BusObserver {
    let label = "broadcast"
    private var tokens: [NSObjectProtocol] = []
    
    func subscribe() {
        let t1 = NotificationCenter.default.addObserver(
            forName: BusEvent.lockersReceived,
            object: nil,
            queue: .main
        ) { note in
            guard let data = note.userInfo?["data"] as? [AnyHashable: Any] else { return }
            NotificationCenter.default.post(
                name: .init("ConversionDataReceived"),
                object: nil,
                userInfo: ["conversionData": data]
            )
        }
        
        let t2 = NotificationCenter.default.addObserver(
            forName: BusEvent.routesReceived,
            object: nil,
            queue: .main
        ) { note in
            guard let data = note.userInfo?["data"] as? [AnyHashable: Any] else { return }
            NotificationCenter.default.post(
                name: .init("deeplink_values"),
                object: nil,
                userInfo: ["deeplinksData": data]
            )
        }
        
        let t3 = NotificationCenter.default.addObserver(
            forName: BusEvent.pushPayloadFound,
            object: nil,
            queue: .main
        ) { note in
            guard let url = note.userInfo?["url"] as? String else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                NotificationCenter.default.post(
                    name: .init("LoadTempURL"),
                    object: nil,
                    userInfo: ["temp_url": url]
                )
            }
        }
        
        tokens = [t1, t2, t3]
    }
}

enum AdjustStarter {
    
    private static var initialized = false

    static func begin(delegate: NSObject & AdjustDelegate) {
        guard !initialized else { return }
        
        if #available(iOS 14, *) {
            ATTrackingManager.requestTrackingAuthorization { status in
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    guard !AdjustStarter.initialized else { return }
                    AdjustStarter.initialized = true
                    UserDefaults.standard.set(status.rawValue, forKey: "att_status")
                    initAdjust(delegate: delegate)
                    NotificationCenter.default.post(name: .init("ATTConsentDone"), object: nil)
                }
            }
        } else {
            AdjustStarter.initialized = true
            initAdjust(delegate: delegate)
            NotificationCenter.default.post(name: .init("ATTConsentDone"), object: nil)
        }
    }
    
    private static func initAdjust(delegate: NSObject & AdjustDelegate) {
        guard let config = ADJConfig(
            appToken: ToolboxConstants.adjustAppToken,
            environment: ADJEnvironmentProduction
        ) else {
            print("\(ToolboxConstants.logHammer) ADJConfig init failed")
            return
        }
        config.delegate = delegate
        config.logLevel = ADJLogLevel.suppress
        
        Adjust.initSdk(config)
    }
}

final class LockerWeaver: NSObject {
    
    private var lockersBuffer: [AnyHashable: Any] = [:]
    private var routesBuffer: [AnyHashable: Any] = [:]
    private var fuseTimer: Timer?
    
    func acceptLockers(_ data: [AnyHashable: Any]) {
        lockersBuffer = data
        scheduleFuse()
        if !routesBuffer.isEmpty { performFuse() }
    }
    
    func acceptRoutes(_ data: [AnyHashable: Any]) {
        guard !UserDefaults.standard.bool(forKey: ToolboxKey.primed) else { return }
        routesBuffer = data
        fuseTimer?.invalidate()
        if !lockersBuffer.isEmpty { performFuse() }
    }
    
    private func scheduleFuse() {
        fuseTimer?.invalidate()
        fuseTimer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: false) { [weak self] _ in
            self?.performFuse()
        }
    }
    
    private func performFuse() {
        var combined = lockersBuffer
        for (k, v) in routesBuffer {
            let prefixed = "deep_\(k)"
            if combined[prefixed] == nil {
                combined[prefixed] = v
            }
        }
        NotificationCenter.default.post(
            name: BusEvent.lockersReceived,
            object: nil,
            userInfo: ["data": combined]
        )
    }
}

final class PushScribe: NSObject {
    
    func scribe(_ payload: [AnyHashable: Any]) {
        guard let url = chisel(payload) else { return }
        UserDefaults.standard.set(url, forKey: ToolboxKey.pushURL)
        NotificationCenter.default.post(
            name: BusEvent.pushPayloadFound,
            object: nil,
            userInfo: ["url": url]
        )
    }
    
    private func chisel(_ payload: [AnyHashable: Any]) -> String? {
        if let direct = payload["url"] as? String { return direct }
        if let nested = payload["data"] as? [String: Any],
           let url = nested["url"] as? String { return url }
        if let aps = payload["aps"] as? [String: Any],
           let nested = aps["data"] as? [String: Any],
           let url = nested["url"] as? String { return url }
        if let custom = payload["custom"] as? [String: Any],
           let url = custom["target_url"] as? String { return url }
        return nil
    }
}
