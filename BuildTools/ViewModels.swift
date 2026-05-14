import Foundation
import SwiftUI
import Combine
import UserNotifications

// MARK: - AppState (EnvironmentObject)
class AppState: ObservableObject {
    @AppStorage("appTheme") var appThemeRaw: String = "dark"
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false
    @AppStorage("isLoggedIn") var isLoggedIn: Bool = false
    @AppStorage("userName") var userName: String = ""
    @AppStorage("userEmail") var userEmail: String = ""
    @AppStorage("userRole") var userRole: String = ""
    
    init() {
        userName = "User"
        userEmail = "user@mail.com"
        userRole = "User Manager"
        isLoggedIn = true
    }

    var colorScheme: ColorScheme? {
        switch appThemeRaw {
        case "light": return .light
        case "dark":  return .dark
        default:      return nil
        }
    }

    func logout() {
        isLoggedIn = false
        userName = ""
        userEmail = ""
        userRole = ""
    }

    func deleteAccount() {
        logout()
        hasCompletedOnboarding = false
    }
}

// MARK: - ToolsViewModel
class ToolsViewModel: ObservableObject {
    @Published var tools: [Tool] = []
    @Published var searchText: String = ""
    @Published var selectedCategory: ToolCategory? = nil
    @Published var selectedStatus: ToolStatus? = nil

    private let storageKey = "bt_tools"

    init() { load() }

    var filteredTools: [Tool] {
        tools.filter { tool in
            let matchSearch = searchText.isEmpty ||
                tool.name.localizedCaseInsensitiveContains(searchText)
            let matchCat = selectedCategory == nil || tool.category == selectedCategory
            let matchStatus = selectedStatus == nil || tool.status == selectedStatus
            return matchSearch && matchCat && matchStatus
        }
    }

    var availableCount: Int { tools.filter { $0.status == .available }.count }
    var inUseCount: Int     { tools.filter { $0.status == .inUse }.count }
    var brokenCount: Int    { tools.filter { $0.status == .broken }.count }
    var lostCount: Int      { tools.filter { $0.status == .lost }.count }
    var missingCount: Int   { tools.filter { $0.status == .lost || $0.status == .broken }.count }

    func add(_ tool: Tool) {
        tools.insert(tool, at: 0)
        save()
        ActivityLog.shared.log("Added tool: \(tool.name)", toolName: tool.name, type: .added)
    }

    func update(_ tool: Tool) {
        if let idx = tools.firstIndex(where: { $0.id == tool.id }) {
            tools[idx] = tool
            save()
            ActivityLog.shared.log("Updated tool: \(tool.name)", toolName: tool.name, type: .updated)
        }
    }

    func delete(at offsets: IndexSet) {
        let names = offsets.map { filteredTools[$0].name }
        tools.removeAll { tool in
            offsets.contains(filteredTools.firstIndex(where: { $0.id == tool.id }) ?? -1)
        }
        save()
        names.forEach { ActivityLog.shared.log("Deleted tool: \($0)", toolName: $0, type: .updated) }
    }

    func delete(_ tool: Tool) {
        tools.removeAll { $0.id == tool.id }
        save()
        ActivityLog.shared.log("Deleted tool: \(tool.name)", toolName: tool.name, type: .updated)
    }

    private func save() {
        if let data = try? JSONEncoder().encode(tools) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([Tool].self, from: data) {
            tools = decoded
        } else {
            tools = Tool.sampleData
            save()
        }
    }
}

// MARK: - ConsumablesViewModel
class ConsumablesViewModel: ObservableObject {
    @Published var consumables: [Consumable] = []
    @Published var searchText: String = ""

    private let storageKey = "bt_consumables"

    init() { load() }

    var filteredConsumables: [Consumable] {
        consumables.filter {
            searchText.isEmpty || $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }

    var lowStockItems: [Consumable] { consumables.filter { $0.isLowStock } }

    func add(_ item: Consumable) {
        consumables.insert(item, at: 0)
        save()
        ActivityLog.shared.log("Added consumable: \(item.name)", toolName: item.name, type: .added)
    }

    func update(_ item: Consumable) {
        if let idx = consumables.firstIndex(where: { $0.id == item.id }) {
            consumables[idx] = item
            save()
        }
    }

    func delete(_ item: Consumable) {
        consumables.removeAll { $0.id == item.id }
        save()
    }

    private func save() {
        if let data = try? JSONEncoder().encode(consumables) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([Consumable].self, from: data) {
            consumables = decoded
        } else {
            consumables = Consumable.sampleData
            save()
        }
    }
}

// MARK: - WorkersViewModel
class WorkersViewModel: ObservableObject {
    @Published var workers: [Worker] = []

    private let storageKey = "bt_workers"

    init() { load() }

    func add(_ worker: Worker) {
        workers.insert(worker, at: 0)
        save()
    }

    func update(_ worker: Worker) {
        if let idx = workers.firstIndex(where: { $0.id == worker.id }) {
            workers[idx] = worker
            save()
        }
    }

    func delete(_ worker: Worker) {
        workers.removeAll { $0.id == worker.id }
        save()
    }

    private func save() {
        if let data = try? JSONEncoder().encode(workers) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([Worker].self, from: data) {
            workers = decoded
        } else {
            workers = Worker.sampleData
            save()
        }
    }
}

// MARK: - TasksViewModel
class TasksViewModel: ObservableObject {
    @Published var tasks: [AppTask] = []

    private let storageKey = "bt_tasks"

    init() { load() }

    var pendingTasks: [AppTask]   { tasks.filter { !$0.isCompleted } }
    var completedTasks: [AppTask] { tasks.filter { $0.isCompleted } }

    func add(_ task: AppTask) {
        tasks.insert(task, at: 0)
        save()
        ActivityLog.shared.log("Added task: \(task.title)", type: .added)
    }

    func toggle(_ task: AppTask) {
        if let idx = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[idx].isCompleted.toggle()
            save()
            if tasks[idx].isCompleted {
                ActivityLog.shared.log("Completed task: \(task.title)", type: .taskCompleted)
            }
        }
    }

    func delete(_ task: AppTask) {
        tasks.removeAll { $0.id == task.id }
        save()
    }

    private func save() {
        if let data = try? JSONEncoder().encode(tasks) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([AppTask].self, from: data) {
            tasks = decoded
        } else {
            tasks = AppTask.sampleData
            save()
        }
    }
}

// MARK: - ActivityLog (Singleton)
class ActivityLog: ObservableObject {
    static let shared = ActivityLog()
    @Published var activities: [Activity] = []
    private let storageKey = "bt_activities"

    private init() { load() }

    func log(_ description: String, toolName: String? = nil, type: Activity.ActivityType) {
        let activity = Activity(description: description, toolName: toolName, date: Date(), type: type)
        activities.insert(activity, at: 0)
        if activities.count > 200 { activities = Array(activities.prefix(200)) }
        save()
    }

    private func save() {
        if let data = try? JSONEncoder().encode(activities) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([Activity].self, from: data) {
            activities = decoded
        }
    }
}

// MARK: - NotificationsManager
class NotificationsManager: ObservableObject {
    @AppStorage("notificationsEnabled") var notificationsEnabled: Bool = false
    @AppStorage("lowStockAlerts") var lowStockAlerts: Bool = true
    @AppStorage("dailyReminder") var dailyReminder: Bool = false
    @AppStorage("dailyReminderHour") var dailyReminderHour: Int = 9

    func requestPermission(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            DispatchQueue.main.async {
                self.notificationsEnabled = granted
                completion(granted)
            }
        }
    }

    func scheduleLowStockAlert(itemName: String) {
        guard notificationsEnabled && lowStockAlerts else { return }
        let content = UNMutableNotificationContent()
        content.title = "Low Stock Alert"
        content.body = "\(itemName) is running low. Consider restocking."
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let req = UNNotificationRequest(identifier: "lowstock_\(itemName)", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(req)
    }

    func scheduleDailyReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["daily_reminder"])
        guard notificationsEnabled && dailyReminder else { return }
        let content = UNMutableNotificationContent()
        content.title = "Build Tools"
        content.body = "Check your tools and consumables status today."
        content.sound = .default
        var components = DateComponents()
        components.hour = dailyReminderHour
        components.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let req = UNNotificationRequest(identifier: "daily_reminder", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(req)
    }

    func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}


@MainActor
final class BuildToolsViewModel: ObservableObject {
    
    @Published var navigateToMain = false {
        didSet {
            if navigateToMain {
                deadlineTask?.cancel()
                uiLocked = true
            }
        }
    }
    
    @Published var navigateToWeb = false {
        didSet {
            if navigateToWeb {
                deadlineTask?.cancel()
                uiLocked = true
            }
        }
    }
    
    @Published var showPermissionPrompt = false
    @Published var showOfflineView = false
    
    private let engine: CPSEngine
    private var cancellables = Set<AnyCancellable>()
    private var deadlineTask: Task<Void, Never>?
    private var cachedDataTask: Task<Void, Never>?
    private var attObserver: NSObjectProtocol?
    
    private var uiLocked: Bool = false
    private var adjustAttributionReceived = false
    
    init() {
        _ = PhantomRegistry.shared
        
        self.engine = CPSEngine()
        wireUp()
    }
    
    deinit {
        deadlineTask?.cancel()
        cachedDataTask?.cancel()
    }
    
    private func wireUp() {
        engine.outcomePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] outcome in
                self?.handleOutcome(outcome)
            }
            .store(in: &cancellables)
    }
    
    func boot() {
        engine.warmUp()
        armDeadline()
        
        attObserver = NotificationCenter.default.addObserver(
            forName: .init("ATTConsentDone"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self = self else { return }
            guard !self.uiLocked else { return }
            self.armCachedDataFallback()
        }
    }
    
    func ingestAttribution(_ data: [String: Any]) {
        adjustAttributionReceived = true
        cachedDataTask?.cancel()
        cachedDataTask = nil
        engine.ingestLockers(data)
        engine.ignite()
    }
    
    func ingestDeeplinks(_ data: [String: Any]) {
        engine.ingestRoutes(data)
    }
    
    func acceptConsent() {
        engine.acceptConsent {
            self.showPermissionPrompt = false
        }
    }
    
    func skipConsent() {
        engine.deferConsent()
        showPermissionPrompt = false
    }
    
    func networkConnectivityChanged(_ connected: Bool) {
        showOfflineView = !connected
    }
    
    private func handleOutcome(_ outcome: ToolboxOutcome) {
        guard !uiLocked else {
            return
        }
        
        switch outcome {
        case .stillIdle:
            break
        case .askForConsent:
            showPermissionPrompt = true
        case .openDock:
            navigateToWeb = true
        case .fallbackHome:
            navigateToMain = true
        }
    }
    
    private func armCachedDataFallback() {
        // Если данных нет — нечего постить, ждём Adjust
        guard engine.snapshots.current.lockersFilled else {
            return
        }
    
        guard !adjustAttributionReceived else {
            return
        }
        
        cachedDataTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 5_000_000_000)
            
            guard let self = self else { return }
            guard !Task.isCancelled else { return }
            guard !self.uiLocked else { return }
            
            let cached = self.engine.snapshots.current.lockers
            
            NotificationCenter.default.post(
                name: .init("ConversionDataReceived"),
                object: nil,
                userInfo: ["conversionData": cached]
            )
        }
    }
    
    
    private func armDeadline() {
        deadlineTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 30_000_000_000)
            
            guard let self = self else { return }
            
            let shouldFire = self.engine.reportDeadlineHit()
            if shouldFire {
                self.handleOutcome(.fallbackHome)
            }
        }
    }
}
