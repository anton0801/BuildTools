import SwiftUI

// MARK: - Main Tab View
struct MainTabView: View {
    @EnvironmentObject var appState: AppState
    @StateObject var toolsVM = ToolsViewModel()
    @StateObject var consumablesVM = ConsumablesViewModel()
    @StateObject var workersVM = WorkersViewModel()
    @StateObject var tasksVM = TasksViewModel()
    @StateObject var activityLog = ActivityLog.shared
    @StateObject var notificationsManager = NotificationsManager()
    @State private var selectedTab = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            DS.bg0.ignoresSafeArea()

            TabView(selection: $selectedTab) {
                DashboardView()
                    .tag(0)
                ToolsListView()
                    .tag(1)
                ConsumablesView()
                    .tag(2)
                TasksView()
                    .tag(3)
                SettingsView()
                    .tag(4)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            // Custom Tab Bar
            CustomTabBar(selectedTab: $selectedTab,
                         missingCount: toolsVM.missingCount,
                         lowStockCount: consumablesVM.lowStockItems.count,
                         pendingTasksCount: tasksVM.pendingTasks.count)
        }
        .environmentObject(toolsVM)
        .environmentObject(consumablesVM)
        .environmentObject(workersVM)
        .environmentObject(tasksVM)
        .environmentObject(activityLog)
        .environmentObject(notificationsManager)
        .preferredColorScheme(appState.colorScheme)
    }
}

// MARK: - Custom Tab Bar
struct CustomTabBar: View {
    @Binding var selectedTab: Int
    let missingCount: Int
    let lowStockCount: Int
    let pendingTasksCount: Int

    private let tabs: [(icon: String, label: String)] = [
        ("square.grid.2x2.fill", "Dashboard"),
        ("wrench.and.screwdriver.fill", "Tools"),
        ("cube.box.fill", "Supplies"),
        ("checklist", "Tasks"),
        ("gearshape.fill", "Settings"),
    ]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<tabs.count, id: \.self) { idx in
                Button(action: {
                    withAnimation(DS.spring) { selectedTab = idx }
                }) {
                    VStack(spacing: 4) {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: tabs[idx].icon)
                                .font(.system(size: 20, weight: selectedTab == idx ? .bold : .regular))
                                .foregroundColor(selectedTab == idx ? DS.yellow : DS.textMuted)
                                .scaleEffect(selectedTab == idx ? 1.1 : 1.0)
                                .animation(DS.spring, value: selectedTab)

                            if badgeCount(for: idx) > 0 {
                                Text("\(badgeCount(for: idx))")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(3)
                                    .background(Color(hex: "#EF4444"))
                                    .clipShape(Circle())
                                    .offset(x: 8, y: -6)
                            }
                        }
                        Text(tabs[idx].label)
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(selectedTab == idx ? DS.yellow : DS.textMuted)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
            }
        }
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 0)
                .fill(DS.bg1)
                .overlay(
                    Rectangle()
                        .fill(DS.divider)
                        .frame(height: 1),
                    alignment: .top
                )
        )
        .padding(.bottom, 8)
    }

    private func badgeCount(for tab: Int) -> Int {
        switch tab {
        case 1: return missingCount
        case 2: return lowStockCount
        case 3: return pendingTasksCount
        default: return 0
        }
    }
}

// MARK: - Dashboard View
struct DashboardView: View {
    @EnvironmentObject var toolsVM: ToolsViewModel
    @EnvironmentObject var consumablesVM: ConsumablesViewModel
    @EnvironmentObject var tasksVM: TasksViewModel
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var activityLog: ActivityLog
    @State private var appeared = false

    var body: some View {
        NavigationView {
            ZStack {
                DS.bg0.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Header
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Good day,")
                                    .font(.system(size: 14))
                                    .foregroundColor(DS.textMuted)
                                Text(appState.userName.isEmpty ? "Manager" : appState.userName)
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(DS.textPrimary)
                            }
                            Spacer()
                            ZStack {
                                Circle()
                                    .fill(DS.yellow)
                                    .frame(width: 44, height: 44)
                                Text(String(appState.userName.prefix(1)).uppercased())
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(DS.bg0)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : -20)

                        // Alert banner if any issues
                        if toolsVM.missingCount > 0 || consumablesVM.lowStockItems.count > 0 {
                            HStack(spacing: 12) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(DS.orange)
                                Text("\(toolsVM.missingCount) tools missing · \(consumablesVM.lowStockItems.count) items low on stock")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(DS.textPrimary)
                                Spacer()
                            }
                            .padding(14)
                            .background(DS.orange.opacity(0.15))
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(DS.orange.opacity(0.3), lineWidth: 1))
                            .padding(.horizontal, 20)
                            .opacity(appeared ? 1 : 0)
                        }

                        // Stats grid
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            StatCard(title: "Total Tools", value: "\(toolsVM.tools.count)",
                                     icon: "wrench.fill", color: DS.yellow)
                            StatCard(title: "In Use", value: "\(toolsVM.inUseCount)",
                                     icon: "person.fill", color: DS.blue)
                            StatCard(title: "Missing", value: "\(toolsVM.missingCount)",
                                     icon: "exclamationmark.circle.fill", color: Color(hex: "#EF4444"))
                            StatCard(title: "Low Stock", value: "\(consumablesVM.lowStockItems.count)",
                                     icon: "cube.box.fill", color: DS.orange)
                        }
                        .padding(.horizontal, 20)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 20)

                        // Tool status overview
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader(title: "Tool Status")
                            HStack(spacing: 0) {
                                StatusBarSegment(label: "Available", count: toolsVM.availableCount,
                                                  total: toolsVM.tools.count, color: Color(hex: "#22C55E"))
                                StatusBarSegment(label: "In Use", count: toolsVM.inUseCount,
                                                  total: toolsVM.tools.count, color: DS.blue)
                                StatusBarSegment(label: "Broken", count: toolsVM.brokenCount,
                                                  total: toolsVM.tools.count, color: Color(hex: "#EF4444"))
                                StatusBarSegment(label: "Lost", count: toolsVM.lostCount,
                                                  total: toolsVM.tools.count, color: Color(hex: "#991B1B"))
                            }
                            .frame(height: 8)
                            .clipShape(RoundedRectangle(cornerRadius: 4))

                            HStack(spacing: 16) {
                                ForEach([
                                    ("Available", toolsVM.availableCount, Color(hex: "#22C55E")),
                                    ("In Use", toolsVM.inUseCount, DS.blue),
                                    ("Broken", toolsVM.brokenCount, Color(hex: "#EF4444")),
                                    ("Lost", toolsVM.lostCount, Color(hex: "#991B1B")),
                                ], id: \.0) { item in
                                    HStack(spacing: 4) {
                                        Circle().fill(item.2).frame(width: 6, height: 6)
                                        Text("\(item.1) \(item.0)")
                                            .font(.system(size: 11))
                                            .foregroundColor(DS.textMuted)
                                    }
                                }
                            }
                        }
                        .padding(16)
                        .background(DS.card)
                        .cornerRadius(16)
                        .padding(.horizontal, 20)
                        .opacity(appeared ? 1 : 0)

                        // Pending tasks
                        if !tasksVM.pendingTasks.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                SectionHeader(title: "Pending Tasks")
                                ForEach(tasksVM.pendingTasks.prefix(3)) { task in
                                    DashboardTaskRow(task: task)
                                }
                            }
                            .padding(.horizontal, 20)
                            .opacity(appeared ? 1 : 0)
                        }

                        // Recent activity
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader(title: "Recent Activity")
                            if activityLog.activities.isEmpty {
                                Text("No activity yet")
                                    .font(.system(size: 14))
                                    .foregroundColor(DS.textMuted)
                                    .padding()
                            } else {
                                ForEach(activityLog.activities.prefix(5)) { activity in
                                    ActivityRow(activity: activity)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .opacity(appeared ? 1 : 0)

                        Spacer().frame(height: 100)
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) { appeared = true }
        }
    }
}

struct StatusBarSegment: View {
    let label: String
    let count: Int
    let total: Int
    let color: Color
    var proportion: CGFloat { total > 0 ? CGFloat(count) / CGFloat(total) : 0 }
    var body: some View {
        color.frame(maxWidth: .infinity * proportion)
    }
}

struct DashboardTaskRow: View {
    @EnvironmentObject var tasksVM: TasksViewModel
    let task: AppTask
    var body: some View {
        HStack(spacing: 12) {
            Button(action: { tasksVM.toggle(task) }) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(task.isCompleted ? DS.yellow : DS.textMuted)
                    .font(.system(size: 20))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(DS.textPrimary)
                    .strikethrough(task.isCompleted)
                if !task.notes.isEmpty {
                    Text(task.notes)
                        .font(.system(size: 12))
                        .foregroundColor(DS.textMuted)
                }
            }
            Spacer()
            Text(task.priority.rawValue)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(task.priority.color)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(task.priority.color.opacity(0.15))
                .cornerRadius(8)
        }
        .padding(12)
        .background(DS.card)
        .cornerRadius(12)
    }
}

struct ActivityRow: View {
    let activity: Activity
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: activityIcon)
                .font(.system(size: 13))
                .foregroundColor(activityColor)
                .frame(width: 30, height: 30)
                .background(activityColor.opacity(0.15))
                .cornerRadius(8)
            VStack(alignment: .leading, spacing: 2) {
                Text(activity.description)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(DS.textPrimary)
                Text(activity.date, style: .relative)
                    .font(.system(size: 11))
                    .foregroundColor(DS.textMuted)
            }
            Spacer()
        }
        .padding(.vertical, 6)
    }

    var activityIcon: String {
        switch activity.type {
        case .added:         return "plus.circle.fill"
        case .updated:       return "pencil.circle.fill"
        case .assigned:      return "person.fill"
        case .returned:      return "arrow.uturn.left.circle.fill"
        case .broken:        return "exclamationmark.circle.fill"
        case .lost:          return "questionmark.circle.fill"
        case .taskCompleted: return "checkmark.circle.fill"
        }
    }

    var activityColor: Color {
        switch activity.type {
        case .added:         return DS.yellow
        case .updated:       return DS.blue
        case .assigned:      return DS.orange
        case .returned:      return Color(hex: "#22C55E")
        case .broken:        return Color(hex: "#EF4444")
        case .lost:          return Color(hex: "#991B1B")
        case .taskCompleted: return Color(hex: "#22C55E")
        }
    }
}
