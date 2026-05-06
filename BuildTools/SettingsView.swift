import SwiftUI
import UserNotifications

// MARK: - Settings View
struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var notificationsManager: NotificationsManager
    @EnvironmentObject var toolsVM: ToolsViewModel
    @EnvironmentObject var consumablesVM: ConsumablesViewModel
    @State private var showDeleteConfirm = false
    @State private var showLogoutConfirm = false
    @State private var showWorkers = false
    @State private var showReports = false
    @State private var showNotifications = false
    @State private var savedBanner = false

    var body: some View {
        NavigationView {
            ZStack {
                DS.bg0.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Profile Card
                        VStack(spacing: 16) {
                            ZStack {
                                Circle().fill(
                                    LinearGradient(colors: [DS.yellow, DS.orange],
                                                   startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .frame(width: 72, height: 72)
                                Text(String(appState.userName.prefix(1)).uppercased())
                                    .font(.system(size: 30, weight: .black)).foregroundColor(DS.bg0)
                            }
                            VStack(spacing: 4) {
                                Text(appState.userName.isEmpty ? "User" : appState.userName)
                                    .font(.system(size: 20, weight: .bold)).foregroundColor(DS.textPrimary)
                                Text(appState.userEmail)
                                    .font(.system(size: 13)).foregroundColor(DS.textMuted)
                                if !appState.userRole.isEmpty {
                                    Text(appState.userRole)
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(DS.yellow)
                                        .padding(.horizontal, 10).padding(.vertical, 4)
                                        .background(DS.yellow.opacity(0.15)).cornerRadius(8)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(20)
                        .background(DS.card)
                        .cornerRadius(16)

                        // Appearance
                        VStack(spacing: 0) {
                            SettingsSectionHeader(title: "Appearance")
                            VStack(spacing: 1) {
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("Theme")
                                        .font(.system(size: 14)).foregroundColor(DS.textSecondary)
                                    HStack(spacing: 8) {
                                        ForEach([("sun.max.fill", "Light", "light"),
                                                 ("moon.fill", "Dark", "dark"),
                                                 ("gearshape.fill", "System", "system")], id: \.2) { item in
                                            Button(action: {
                                                withAnimation(DS.spring) { appState.appThemeRaw = item.2 }
                                            }) {
                                                HStack(spacing: 6) {
                                                    Image(systemName: item.0).font(.system(size: 12))
                                                    Text(item.1).font(.system(size: 13, weight: .semibold))
                                                }
                                                .foregroundColor(appState.appThemeRaw == item.2 ? DS.bg0 : DS.textSecondary)
                                                .frame(maxWidth: .infinity).padding(.vertical, 9)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 10)
                                                        .fill(appState.appThemeRaw == item.2 ? DS.yellow : DS.card)
                                                        .overlay(RoundedRectangle(cornerRadius: 10)
                                                            .stroke(appState.appThemeRaw == item.2 ? DS.yellow : DS.divider, lineWidth: 1))
                                                )
                                            }
                                        }
                                    }
                                }
                                .padding(14)
                            }
                            .background(DS.card)
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(DS.divider, lineWidth: 1))
                        }

                        // Notifications
                        VStack(spacing: 0) {
                            SettingsSectionHeader(title: "Notifications")
                            VStack(spacing: 1) {
                                SettingsToggleRow(
                                    icon: "bell.fill",
                                    iconColor: DS.blue,
                                    title: "Enable Notifications",
                                    subtitle: "Allow Build Tools to send alerts",
                                    isOn: Binding(
                                        get: { notificationsManager.notificationsEnabled },
                                        set: { newVal in
                                            if newVal {
                                                notificationsManager.requestPermission { granted in
                                                    if !granted {
                                                        // show system settings note
                                                    }
                                                }
                                            } else {
                                                notificationsManager.notificationsEnabled = false
                                                notificationsManager.cancelAll()
                                            }
                                        }
                                    )
                                )
                                Divider().background(DS.divider).padding(.leading, 52)

                                SettingsToggleRow(
                                    icon: "exclamationmark.triangle.fill",
                                    iconColor: DS.orange,
                                    title: "Low Stock Alerts",
                                    subtitle: "Notify when consumables run low",
                                    isOn: $notificationsManager.lowStockAlerts
                                )
                                .disabled(!notificationsManager.notificationsEnabled)
                                .opacity(notificationsManager.notificationsEnabled ? 1 : 0.4)

                                Divider().background(DS.divider).padding(.leading, 52)

                                SettingsToggleRow(
                                    icon: "clock.fill",
                                    iconColor: DS.yellow,
                                    title: "Daily Reminder",
                                    subtitle: "Morning check-in notification",
                                    isOn: Binding(
                                        get: { notificationsManager.dailyReminder },
                                        set: { newVal in
                                            notificationsManager.dailyReminder = newVal
                                            notificationsManager.scheduleDailyReminder()
                                        }
                                    )
                                )
                                .disabled(!notificationsManager.notificationsEnabled)
                                .opacity(notificationsManager.notificationsEnabled ? 1 : 0.4)

                                if notificationsManager.dailyReminder && notificationsManager.notificationsEnabled {
                                    Divider().background(DS.divider).padding(.leading, 52)
                                    HStack {
                                        Text("Reminder Time")
                                            .font(.system(size: 14)).foregroundColor(DS.textSecondary)
                                        Spacer()
                                        Picker("Hour", selection: Binding(
                                            get: { notificationsManager.dailyReminderHour },
                                            set: { newVal in
                                                notificationsManager.dailyReminderHour = newVal
                                                notificationsManager.scheduleDailyReminder()
                                            }
                                        )) {
                                            ForEach(6..<22, id: \.self) { h in
                                                Text("\(h):00").tag(h)
                                            }
                                        }
                                        .pickerStyle(.menu).tint(DS.yellow)
                                    }
                                    .padding(14)
                                }
                            }
                            .background(DS.card)
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(DS.divider, lineWidth: 1))
                        }

                        // Data
                        VStack(spacing: 0) {
                            SettingsSectionHeader(title: "Data")
                            VStack(spacing: 1) {
                                SettingsNavRow(icon: "person.3.fill", iconColor: DS.blue,
                                               title: "Manage Workers", subtitle: "Add or remove workers") {
                                    showWorkers = true
                                }
                                Divider().background(DS.divider).padding(.leading, 52)
                                SettingsNavRow(icon: "chart.bar.fill", iconColor: Color(hex: "#22C55E"),
                                               title: "Reports & History", subtitle: "View analytics and logs") {
                                    showReports = true
                                }
                                Divider().background(DS.divider).padding(.leading, 52)
                                SettingsInfoRow(icon: "hammer.fill", iconColor: DS.yellow,
                                                title: "Total Tools", value: "\(toolsVM.tools.count)")
                                Divider().background(DS.divider).padding(.leading, 52)
                                SettingsInfoRow(icon: "cube.box.fill", iconColor: DS.orange,
                                                title: "Total Consumables", value: "\(consumablesVM.consumables.count)")
                            }
                            .background(DS.card)
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(DS.divider, lineWidth: 1))
                        }

                        // Account
                        VStack(spacing: 0) {
                            SettingsSectionHeader(title: "Account")
                            VStack(spacing: 1) {
                                Button(action: { showLogoutConfirm = true }) {
                                    HStack(spacing: 14) {
                                        Image(systemName: "rectangle.portrait.and.arrow.right")
                                            .font(.system(size: 15)).foregroundColor(DS.orange)
                                            .frame(width: 32, height: 32)
                                            .background(DS.orange.opacity(0.12)).cornerRadius(8)
                                        Text("Log Out")
                                            .font(.system(size: 15, weight: .medium)).foregroundColor(DS.orange)
                                        Spacer()
                                    }
                                    .padding(14)
                                }

                                Divider().background(DS.divider).padding(.leading, 52)

                                Button(action: { showDeleteConfirm = true }) {
                                    HStack(spacing: 14) {
                                        Image(systemName: "trash.fill")
                                            .font(.system(size: 15)).foregroundColor(Color(hex: "#EF4444"))
                                            .frame(width: 32, height: 32)
                                            .background(Color(hex: "#EF4444").opacity(0.12)).cornerRadius(8)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Delete Account")
                                                .font(.system(size: 15, weight: .medium)).foregroundColor(Color(hex: "#EF4444"))
                                            Text("Permanently removes all data")
                                                .font(.system(size: 11)).foregroundColor(DS.textMuted)
                                        }
                                        Spacer()
                                    }
                                    .padding(14)
                                }
                            }
                            .background(DS.card)
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(DS.divider, lineWidth: 1))
                        }

                        Text("Build Tools v1.0.0")
                            .font(.system(size: 12)).foregroundColor(DS.textMuted)
                            .padding(.bottom, 100)
                    }
                    .padding(.horizontal, 20).padding(.top, 16)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showWorkers) { WorkersView() }
            .sheet(isPresented: $showReports) { ReportsView() }
            .alert("Log Out?", isPresented: $showLogoutConfirm) {
                Button("Log Out", role: .destructive) { appState.logout() }
                Button("Cancel", role: .cancel) {}
            } message: { Text("You'll need to log in again to access your data.") }
            .alert("Delete Account?", isPresented: $showDeleteConfirm) {
                Button("Delete Everything", role: .destructive) {
                    clearAllData()
                    appState.deleteAccount()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently delete your account and all data. This cannot be undone.")
            }
        }
    }

    private func clearAllData() {
        UserDefaults.standard.removeObject(forKey: "bt_tools")
        UserDefaults.standard.removeObject(forKey: "bt_consumables")
        UserDefaults.standard.removeObject(forKey: "bt_workers")
        UserDefaults.standard.removeObject(forKey: "bt_tasks")
        UserDefaults.standard.removeObject(forKey: "bt_activities")
    }
}

// MARK: - Settings Components
struct SettingsSectionHeader: View {
    let title: String
    var body: some View {
        Text(title)
            .font(.system(size: 12, weight: .semibold)).foregroundColor(DS.textMuted)
            .textCase(.uppercase).tracking(1.2)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, 8).padding(.top, 4)
    }
}

struct SettingsToggleRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 15)).foregroundColor(iconColor)
                .frame(width: 32, height: 32)
                .background(iconColor.opacity(0.12)).cornerRadius(8)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 15, weight: .medium)).foregroundColor(DS.textPrimary)
                Text(subtitle).font(.system(size: 11)).foregroundColor(DS.textMuted)
            }
            Spacer()
            Toggle("", isOn: $isOn)
                .tint(DS.yellow)
                .labelsHidden()
        }
        .padding(14)
        .animation(DS.spring, value: isOn)
    }
}

struct SettingsNavRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 15)).foregroundColor(iconColor)
                    .frame(width: 32, height: 32)
                    .background(iconColor.opacity(0.12)).cornerRadius(8)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.system(size: 15, weight: .medium)).foregroundColor(DS.textPrimary)
                    Text(subtitle).font(.system(size: 11)).foregroundColor(DS.textMuted)
                }
                Spacer()
                Image(systemName: "chevron.right").font(.system(size: 12)).foregroundColor(DS.textMuted)
            }
            .padding(14)
        }
    }
}

struct SettingsInfoRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 15)).foregroundColor(iconColor)
                .frame(width: 32, height: 32)
                .background(iconColor.opacity(0.12)).cornerRadius(8)
            Text(title).font(.system(size: 15, weight: .medium)).foregroundColor(DS.textSecondary)
            Spacer()
            Text(value).font(.system(size: 14, weight: .bold)).foregroundColor(DS.textPrimary)
        }
        .padding(14)
    }
}
