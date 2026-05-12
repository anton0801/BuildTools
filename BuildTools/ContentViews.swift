import SwiftUI
import WebKit

// MARK: - Consumables View
struct ConsumablesView: View {
    @EnvironmentObject var consumablesVM: ConsumablesViewModel
    @EnvironmentObject var notificationsManager: NotificationsManager
    @State private var showAdd = false
    @State private var showLowStock = false

    var body: some View {
        NavigationView {
            ZStack {
                DS.bg0.ignoresSafeArea()
                VStack(spacing: 0) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Consumables")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(DS.textPrimary)
                            Text("\(consumablesVM.consumables.count) items")
                                .font(.system(size: 13))
                                .foregroundColor(DS.textMuted)
                        }
                        Spacer()
                        HStack(spacing: 10) {
                            if !consumablesVM.lowStockItems.isEmpty {
                                Button(action: { showLowStock = true }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .font(.system(size: 12))
                                        Text("\(consumablesVM.lowStockItems.count)")
                                            .font(.system(size: 12, weight: .bold))
                                    }
                                    .foregroundColor(DS.bg0)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 7)
                                    .background(DS.orange)
                                    .cornerRadius(10)
                                }
                            }
                            Button(action: { showAdd = true }) {
                                Image(systemName: "plus")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(DS.bg0)
                                    .frame(width: 36, height: 36)
                                    .background(DS.yellow)
                                    .cornerRadius(10)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 12)

                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(DS.textMuted).font(.system(size: 14))
                        TextField("Search consumables...", text: $consumablesVM.searchText)
                            .foregroundColor(DS.textPrimary).font(.system(size: 15))
                    }
                    .padding(12)
                    .background(DS.card)
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(DS.divider, lineWidth: 1))
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)

                    if consumablesVM.filteredConsumables.isEmpty {
                        Spacer()
                        VStack(spacing: 16) {
                            Image(systemName: "cube.box").font(.system(size: 48)).foregroundColor(DS.textMuted)
                            Text("No consumables yet").font(.system(size: 16, weight: .medium)).foregroundColor(DS.textMuted)
                        }
                        Spacer()
                    } else {
                        ScrollView(showsIndicators: false) {
                            LazyVStack(spacing: 8) {
                                ForEach(consumablesVM.filteredConsumables) { item in
                                    ConsumableRow(item: item)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 100)
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showAdd) { AddConsumableView() }
            .sheet(isPresented: $showLowStock) { LowStockView() }
        }
    }
}

struct BuildToolsWebView: View {
    @State private var targetURL: String? = ""
    @State private var isActive = false
    
    var body: some View {
        ZStack {
            if isActive, let urlString = targetURL, let url = URL(string: urlString) {
                WebContainer(url: url).ignoresSafeArea(.keyboard, edges: .bottom)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear { initialize() }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("LoadTempURL"))) { _ in reload() }
    }
    
    private func initialize() {
        let temp = UserDefaults.standard.string(forKey: ToolboxKey.pushURL)
        let stored = UserDefaults.standard.string(forKey: ToolboxKey.dockURL) ?? ""
        targetURL = temp ?? stored
        isActive = true
        if temp != nil { UserDefaults.standard.removeObject(forKey: ToolboxKey.pushURL) }
    }
    
    private func reload() {
        if let temp = UserDefaults.standard.string(forKey: ToolboxKey.pushURL), !temp.isEmpty {
            isActive = false
            targetURL = temp
            UserDefaults.standard.removeObject(forKey: ToolboxKey.pushURL)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { isActive = true }
        }
    }
}

// MARK: - Consumable Row
struct ConsumableRow: View {
    @EnvironmentObject var consumablesVM: ConsumablesViewModel
    @EnvironmentObject var notificationsManager: NotificationsManager
    let item: Consumable
    @State private var showEdit = false

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(item.isLowStock ? DS.orange.opacity(0.15) : DS.yellow.opacity(0.12))
                    .frame(width: 48, height: 48)
                Image(systemName: "cube.box.fill")
                    .font(.system(size: 20))
                    .foregroundColor(item.isLowStock ? DS.orange : DS.yellow)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(DS.textPrimary)
                HStack(spacing: 8) {
                    Image(systemName: item.location.icon).font(.system(size: 11)).foregroundColor(DS.textMuted)
                    Text(item.location.rawValue).font(.system(size: 12)).foregroundColor(DS.textMuted)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(Int(item.quantity)) \(item.unit)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(item.isLowStock ? DS.orange : DS.textPrimary)
                if item.isLowStock {
                    Text("LOW STOCK")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(DS.orange)
                        .padding(.horizontal, 6).padding(.vertical, 3)
                        .background(DS.orange.opacity(0.15))
                        .cornerRadius(6)
                }
            }
        }
        .padding(14)
        .background(DS.card)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(item.isLowStock ? DS.orange.opacity(0.4) : DS.divider, lineWidth: 1)
        )
        .onTapGesture { showEdit = true }
        .sheet(isPresented: $showEdit) { AddConsumableView(editingItem: item) }
    }
}

// MARK: - Add Consumable View
struct AddConsumableView: View {
    @EnvironmentObject var consumablesVM: ConsumablesViewModel
    @EnvironmentObject var notificationsManager: NotificationsManager
    @Environment(\.dismiss) var dismiss
    var editingItem: Consumable? = nil

    @State private var name = ""
    @State private var quantity: Double = 0
    @State private var unit = "pcs"
    @State private var minimumStock: Double = 5
    @State private var location: ToolLocation = .garage
    @State private var notes = ""
    @State private var nameError = false
    @State private var showSaved = false

    private let units = ["pcs", "m", "kg", "L", "rolls", "sheets", "pairs", "tubes", "boxes"]
    var isEditing: Bool { editingItem != nil }

    var body: some View {
        ZStack {
            DS.bg0.ignoresSafeArea()
            VStack(spacing: 0) {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark").font(.system(size: 16, weight: .semibold))
                            .foregroundColor(DS.textMuted).padding(10).background(DS.card).cornerRadius(10)
                    }
                    Spacer()
                    Text(isEditing ? "Edit Item" : "Add Consumable")
                        .font(.system(size: 17, weight: .bold)).foregroundColor(DS.textPrimary)
                    Spacer()
                    Color.clear.frame(width: 36, height: 36)
                }
                .padding()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        FormField(label: "Name", isError: nameError) {
                            TextField("e.g. Drill Bits", text: $name)
                                .foregroundColor(DS.textPrimary).font(.system(size: 15))
                        }

                        // Quantity
                        VStack(alignment: .leading, spacing: 8) {
                            SectionHeader(title: "Quantity")
                            HStack(spacing: 12) {
                                Button(action: { if quantity > 0 { quantity -= 1 } }) {
                                    Image(systemName: "minus").font(.system(size: 16, weight: .bold))
                                        .foregroundColor(DS.textPrimary).frame(width: 40, height: 40)
                                        .background(DS.card).cornerRadius(10)
                                }
                                Text("\(Int(quantity))")
                                    .font(.system(size: 24, weight: .bold)).foregroundColor(DS.textPrimary)
                                    .frame(minWidth: 60).multilineTextAlignment(.center)
                                Button(action: { quantity += 1 }) {
                                    Image(systemName: "plus").font(.system(size: 16, weight: .bold))
                                        .foregroundColor(DS.bg0).frame(width: 40, height: 40)
                                        .background(DS.yellow).cornerRadius(10)
                                }
                                Spacer()
                                Picker("Unit", selection: $unit) {
                                    ForEach(units, id: \.self) { Text($0).tag($0) }
                                }
                                .pickerStyle(.menu)
                                .tint(DS.yellow)
                            }
                        }

                        // Minimum Stock
                        VStack(alignment: .leading, spacing: 8) {
                            SectionHeader(title: "Minimum Stock Alert")
                            HStack(spacing: 12) {
                                Button(action: { if minimumStock > 0 { minimumStock -= 1 } }) {
                                    Image(systemName: "minus").font(.system(size: 16, weight: .bold))
                                        .foregroundColor(DS.textPrimary).frame(width: 40, height: 40)
                                        .background(DS.card).cornerRadius(10)
                                }
                                Text("\(Int(minimumStock)) \(unit)")
                                    .font(.system(size: 16, weight: .semibold)).foregroundColor(DS.orange)
                                    .frame(minWidth: 60).multilineTextAlignment(.center)
                                Button(action: { minimumStock += 1 }) {
                                    Image(systemName: "plus").font(.system(size: 16, weight: .bold))
                                        .foregroundColor(DS.bg0).frame(width: 40, height: 40)
                                        .background(DS.orange).cornerRadius(10)
                                }
                                Spacer()
                            }
                        }

                        // Location
                        VStack(alignment: .leading, spacing: 8) {
                            SectionHeader(title: "Location")
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                                ForEach(ToolLocation.allCases, id: \.self) { loc in
                                    Button(action: { location = loc }) {
                                        VStack(spacing: 6) {
                                            Image(systemName: loc.icon).font(.system(size: 18))
                                                .foregroundColor(location == loc ? DS.bg0 : DS.blue)
                                            Text(loc.rawValue).font(.system(size: 11, weight: .medium))
                                                .foregroundColor(location == loc ? DS.bg0 : DS.textSecondary)
                                        }
                                        .frame(maxWidth: .infinity).padding(.vertical, 10)
                                        .background(
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(location == loc ? DS.blue : DS.card)
                                                .overlay(RoundedRectangle(cornerRadius: 10)
                                                    .stroke(location == loc ? DS.blue : DS.divider, lineWidth: 1))
                                        )
                                    }
                                    .animation(DS.spring, value: location)
                                }
                            }
                        }

                        FormField(label: "Notes (optional)") {
                            TextField("Any info...", text: $notes).foregroundColor(DS.textPrimary).font(.system(size: 15))
                        }

                        Button(action: save) {
                            Text(isEditing ? "Save Changes" : "Add Item")
                        }
                        .buttonStyle(YellowButtonStyle())
                        .padding(.bottom, 40)
                    }
                    .padding(.horizontal, 20)
                }
            }

            if showSaved {
                VStack {
                    Spacer()
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill").foregroundColor(Color(hex: "#22C55E"))
                        Text(isEditing ? "Changes saved!" : "Item added!").font(.system(size: 14, weight: .semibold)).foregroundColor(DS.textPrimary)
                    }
                    .padding(.horizontal, 20).padding(.vertical, 12)
                    .background(DS.card).cornerRadius(12).shadow(color: .black.opacity(0.3), radius: 8)
                    .padding(.bottom, 120)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .onAppear {
            if let i = editingItem {
                name = i.name; quantity = i.quantity; unit = i.unit
                minimumStock = i.minimumStock; location = i.location; notes = i.notes
            }
        }
    }

    private func save() {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            withAnimation { nameError = true }; return
        }
        nameError = false
        if isEditing, var updated = editingItem {
            updated.name = name; updated.quantity = quantity; updated.unit = unit
            updated.minimumStock = minimumStock; updated.location = location; updated.notes = notes
            consumablesVM.update(updated)
            if updated.isLowStock { notificationsManager.scheduleLowStockAlert(itemName: updated.name) }
        } else {
            let item = Consumable(name: name, quantity: quantity, unit: unit,
                                   minimumStock: minimumStock, location: location, notes: notes)
            consumablesVM.add(item)
            if item.isLowStock { notificationsManager.scheduleLowStockAlert(itemName: item.name) }
        }
        withAnimation { showSaved = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { dismiss() }
    }
}


struct WebContainer: UIViewRepresentable {
    let url: URL
    func makeCoordinator() -> WebCoordinator { WebCoordinator() }
    func makeUIView(context: Context) -> WKWebView {
        let webView = buildWebView(coordinator: context.coordinator)
        context.coordinator.webView = webView
        context.coordinator.loadURL(url, in: webView)
        Task { await context.coordinator.loadCookies(in: webView) }
        return webView
    }
    func updateUIView(_ uiView: WKWebView, context: Context) {}
    
    private func buildWebView(coordinator: WebCoordinator) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.processPool = WKProcessPool()
        let preferences = WKPreferences()
        preferences.javaScriptEnabled = true
        preferences.javaScriptCanOpenWindowsAutomatically = true
        configuration.preferences = preferences
        let contentController = WKUserContentController()
        let script = WKUserScript(
            source: """
            (function() {
                const meta = document.createElement('meta');
                meta.name = 'viewport';
                meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no';
                document.head.appendChild(meta);
                const style = document.createElement('style');
                style.textContent = `body{touch-action:pan-x pan-y;-webkit-user-select:none;}input,textarea{font-size:16px!important;}`;
                document.head.appendChild(style);
                document.addEventListener('gesturestart', e => e.preventDefault());
                document.addEventListener('gesturechange', e => e.preventDefault());
            })();
            """,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: false
        )
        contentController.addUserScript(script)
        configuration.userContentController = contentController
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        let pagePreferences = WKWebpagePreferences()
        pagePreferences.allowsContentJavaScript = true
        configuration.defaultWebpagePreferences = pagePreferences
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.scrollView.minimumZoomScale = 1.0
        webView.scrollView.maximumZoomScale = 1.0
        webView.scrollView.bounces = false
        webView.scrollView.bouncesZoom = false
        webView.allowsBackForwardNavigationGestures = true
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.navigationDelegate = coordinator
        webView.uiDelegate = coordinator
        return webView
    }
}

// MARK: - Low Stock View
struct LowStockView: View {
    @EnvironmentObject var consumablesVM: ConsumablesViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            DS.bg0.ignoresSafeArea()
            VStack(spacing: 0) {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark").font(.system(size: 16, weight: .semibold))
                            .foregroundColor(DS.textMuted).padding(10).background(DS.card).cornerRadius(10)
                    }
                    Spacer()
                    Text("Low Stock").font(.system(size: 17, weight: .bold)).foregroundColor(DS.textPrimary)
                    Spacer()
                    Color.clear.frame(width: 36, height: 36)
                }
                .padding()

                if consumablesVM.lowStockItems.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill").font(.system(size: 48)).foregroundColor(Color(hex: "#22C55E"))
                        Text("All stocked up!").font(.system(size: 18, weight: .semibold)).foregroundColor(DS.textPrimary)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 8) {
                            ForEach(consumablesVM.lowStockItems) { item in
                                HStack(spacing: 14) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(DS.orange).font(.system(size: 20))
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(item.name).font(.system(size: 15, weight: .semibold)).foregroundColor(DS.textPrimary)
                                        Text("Have: \(Int(item.quantity)) \(item.unit) · Min: \(Int(item.minimumStock)) \(item.unit)")
                                            .font(.system(size: 12)).foregroundColor(DS.textMuted)
                                    }
                                    Spacer()
                                    Text(item.location.rawValue).font(.system(size: 11)).foregroundColor(DS.textMuted)
                                }
                                .padding(14).background(DS.card).cornerRadius(12)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(DS.orange.opacity(0.4), lineWidth: 1))
                            }
                        }
                        .padding(.horizontal, 20).padding(.bottom, 40)
                    }
                }
            }
        }
    }
}

final class WebCoordinator: NSObject {
    weak var webView: WKWebView?
    private var redirectCount = 0, maxRedirects = 70
    private var lastURL: URL?, checkpoint: URL?
    private var popups: [WKWebView] = []
    private let cookieJar = ToolboxConstants.cookieDrawer
    
    func loadURL(_ url: URL, in webView: WKWebView) {
        print("\(ToolboxConstants.logHammer) Load: \(url.absoluteString)")
        redirectCount = 0
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        webView.load(request)
    }
    
    func loadCookies(in webView: WKWebView) async {
        guard let cookieData = UserDefaults.standard.object(forKey: cookieJar) as? [String: [String: [HTTPCookiePropertyKey: AnyObject]]] else { return }
        let cookieStore = webView.configuration.websiteDataStore.httpCookieStore
        let cookies = cookieData.values.flatMap { $0.values }.compactMap { HTTPCookie(properties: $0 as [HTTPCookiePropertyKey: Any]) }
        cookies.forEach { cookieStore.setCookie($0) }
    }
    
    private func saveCookies(from webView: WKWebView) {
        webView.configuration.websiteDataStore.httpCookieStore.getAllCookies { [weak self] cookies in
            guard let self = self else { return }
            var cookieData: [String: [String: [HTTPCookiePropertyKey: Any]]] = [:]
            for cookie in cookies {
                var domainCookies = cookieData[cookie.domain] ?? [:]
                if let properties = cookie.properties { domainCookies[cookie.name] = properties }
                cookieData[cookie.domain] = domainCookies
            }
            UserDefaults.standard.set(cookieData, forKey: self.cookieJar)
        }
    }
}

struct TasksView: View {
    @EnvironmentObject var tasksVM: TasksViewModel
    @State private var showAdd = false

    var body: some View {
        NavigationView {
            ZStack {
                DS.bg0.ignoresSafeArea()
                VStack(spacing: 0) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Tasks")
                                .font(.system(size: 24, weight: .bold)).foregroundColor(DS.textPrimary)
                            Text("\(tasksVM.pendingTasks.count) pending")
                                .font(.system(size: 13)).foregroundColor(DS.textMuted)
                        }
                        Spacer()
                        Button(action: { showAdd = true }) {
                            Image(systemName: "plus").font(.system(size: 16, weight: .bold))
                                .foregroundColor(DS.bg0).frame(width: 36, height: 36)
                                .background(DS.yellow).cornerRadius(10)
                        }
                    }
                    .padding(.horizontal, 20).padding(.top, 16).padding(.bottom, 12)

                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 20) {
                            if !tasksVM.pendingTasks.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    SectionHeader(title: "Pending")
                                    ForEach(tasksVM.pendingTasks) { task in
                                        TaskRow(task: task)
                                    }
                                }
                            }
                            if !tasksVM.completedTasks.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    SectionHeader(title: "Completed")
                                    ForEach(tasksVM.completedTasks) { task in
                                        TaskRow(task: task)
                                    }
                                }
                            }
                            if tasksVM.tasks.isEmpty {
                                VStack(spacing: 16) {
                                    Image(systemName: "checklist").font(.system(size: 48)).foregroundColor(DS.textMuted)
                                    Text("No tasks yet").font(.system(size: 16, weight: .medium)).foregroundColor(DS.textMuted)
                                }
                                .padding(.top, 60)
                            }
                        }
                        .padding(.horizontal, 20).padding(.bottom, 100)
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showAdd) { AddTaskView() }
        }
    }
}

struct TaskRow: View {
    @EnvironmentObject var tasksVM: TasksViewModel
    let task: AppTask
    @State private var showDelete = false

    var body: some View {
        HStack(spacing: 12) {
            Button(action: { withAnimation(DS.spring) { tasksVM.toggle(task) } }) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(task.isCompleted ? DS.yellow : DS.textMuted)
                    .font(.system(size: 22))
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(task.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(task.isCompleted ? DS.textMuted : DS.textPrimary)
                    .strikethrough(task.isCompleted)
                if !task.notes.isEmpty {
                    Text(task.notes).font(.system(size: 12)).foregroundColor(DS.textMuted)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(task.priority.rawValue)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(task.priority.color)
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(task.priority.color.opacity(0.15)).cornerRadius(8)
                Button(action: { showDelete = true }) {
                    Image(systemName: "trash").font(.system(size: 12)).foregroundColor(DS.textMuted)
                }
            }
        }
        .padding(14).background(DS.card).cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(DS.divider, lineWidth: 1))
        .alert("Delete Task?", isPresented: $showDelete) {
            Button("Delete", role: .destructive) { tasksVM.delete(task) }
            Button("Cancel", role: .cancel) {}
        }
    }
}

extension WebCoordinator: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else { return decisionHandler(.allow) }
        lastURL = url
        let scheme = (url.scheme ?? "").lowercased()
        let path = url.absoluteString.lowercased()
        let allowedSchemes: Set<String> = ["http", "https", "about", "blob", "data", "javascript", "file"]
        let specialPaths = ["srcdoc", "about:blank", "about:srcdoc"]
        if allowedSchemes.contains(scheme) || specialPaths.contains(where: { path.hasPrefix($0) }) || path == "about:blank" {
            decisionHandler(.allow)
        } else {
            UIApplication.shared.open(url, options: [:])
            decisionHandler(.cancel)
        }
    }
    
    func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        redirectCount += 1
        if redirectCount > maxRedirects { webView.stopLoading(); if let recovery = lastURL { webView.load(URLRequest(url: recovery)) }; redirectCount = 0; return }
        lastURL = webView.url; saveCookies(from: webView)
    }
    
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        if let current = webView.url { checkpoint = current; print("✅ \(ToolboxConstants.logHammer) Commit: \(current.absoluteString)") }
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if let current = webView.url { checkpoint = current }; redirectCount = 0; saveCookies(from: webView)
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        if (error as NSError).code == NSURLErrorHTTPTooManyRedirects, let recovery = lastURL { webView.load(URLRequest(url: recovery)) }
    }
    
    func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust, let trust = challenge.protectionSpace.serverTrust {
            completionHandler(.useCredential, URLCredential(trust: trust))
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
}

struct AddTaskView: View {
    @EnvironmentObject var tasksVM: TasksViewModel
    @Environment(\.dismiss) var dismiss
    @State private var title = ""
    @State private var notes = ""
    @State private var priority: TaskPriority = .medium
    @State private var titleError = false

    var body: some View {
        ZStack {
            DS.bg0.ignoresSafeArea()
            VStack(spacing: 0) {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark").font(.system(size: 16, weight: .semibold))
                            .foregroundColor(DS.textMuted).padding(10).background(DS.card).cornerRadius(10)
                    }
                    Spacer()
                    Text("Add Task").font(.system(size: 17, weight: .bold)).foregroundColor(DS.textPrimary)
                    Spacer()
                    Color.clear.frame(width: 36, height: 36)
                }
                .padding()

                ScrollView {
                    VStack(spacing: 20) {
                        FormField(label: "Task Title", isError: titleError) {
                            TextField("e.g. Buy drill bits", text: $title)
                                .foregroundColor(DS.textPrimary).font(.system(size: 15))
                        }

                        FormField(label: "Notes (optional)") {
                            TextField("Details...", text: $notes)
                                .foregroundColor(DS.textPrimary).font(.system(size: 15))
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            SectionHeader(title: "Priority")
                            HStack(spacing: 8) {
                                ForEach(TaskPriority.allCases, id: \.self) { p in
                                    Button(action: { priority = p }) {
                                        Text(p.rawValue)
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundColor(priority == p ? .white : p.color)
                                            .frame(maxWidth: .infinity).padding(.vertical, 10)
                                            .background(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .fill(priority == p ? p.color : p.color.opacity(0.12))
                                            )
                                    }
                                    .animation(DS.spring, value: priority)
                                }
                            }
                        }

                        Button(action: save) { Text("Add Task") }
                            .buttonStyle(YellowButtonStyle()).padding(.bottom, 40)
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
    }

    private func save() {
        guard !title.trimmingCharacters(in: .whitespaces).isEmpty else {
            withAnimation { titleError = true }; return
        }
        let task = AppTask(title: title, notes: notes, priority: priority)
        tasksVM.add(task)
        dismiss()
    }
}

extension WebCoordinator: WKUIDelegate {
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        guard navigationAction.targetFrame == nil else { return nil }
        let popup = WKWebView(frame: webView.bounds, configuration: configuration)
        popup.navigationDelegate = self; popup.uiDelegate = self; popup.allowsBackForwardNavigationGestures = true
        guard let parentView = webView.superview else { return nil }
        parentView.addSubview(popup); popup.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([popup.topAnchor.constraint(equalTo: webView.topAnchor), popup.bottomAnchor.constraint(equalTo: webView.bottomAnchor), popup.leadingAnchor.constraint(equalTo: webView.leadingAnchor), popup.trailingAnchor.constraint(equalTo: webView.trailingAnchor)])
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(handlePopupPan(_:))); gesture.delegate = self
        popup.scrollView.panGestureRecognizer.require(toFail: gesture); popup.addGestureRecognizer(gesture); popups.append(popup)
        if let url = navigationAction.request.url, url.absoluteString != "about:blank" { popup.load(navigationAction.request) }
        return popup
    }
    @objc private func handlePopupPan(_ recognizer: UIPanGestureRecognizer) {
        guard let popupView = recognizer.view else { return }
        let translation = recognizer.translation(in: popupView), velocity = recognizer.velocity(in: popupView)
        switch recognizer.state {
        case .changed: if translation.x > 0 { popupView.transform = CGAffineTransform(translationX: translation.x, y: 0) }
        case .ended, .cancelled:
            let shouldClose = translation.x > popupView.bounds.width * 0.4 || velocity.x > 800
            if shouldClose { UIView.animate(withDuration: 0.25, animations: { popupView.transform = CGAffineTransform(translationX: popupView.bounds.width, y: 0) }) { [weak self] _ in self?.dismissTopPopup() }
            } else { UIView.animate(withDuration: 0.2) { popupView.transform = .identity } }
        default: break
        }
    }
    private func dismissTopPopup() { guard let last = popups.last else { return }; last.removeFromSuperview(); popups.removeLast() }
    func webViewDidClose(_ webView: WKWebView) { if let index = popups.firstIndex(of: webView) { webView.removeFromSuperview(); popups.remove(at: index) } }
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) { completionHandler() }
}

struct WorkersView: View {
    @EnvironmentObject var workersVM: WorkersViewModel
    @State private var showAdd = false

    var body: some View {
        NavigationView {
            ZStack {
                DS.bg0.ignoresSafeArea()
                VStack(spacing: 0) {
                    HStack {
                        Text("Workers").font(.system(size: 24, weight: .bold)).foregroundColor(DS.textPrimary)
                        Spacer()
                        Button(action: { showAdd = true }) {
                            Image(systemName: "plus").font(.system(size: 16, weight: .bold))
                                .foregroundColor(DS.bg0).frame(width: 36, height: 36)
                                .background(DS.yellow).cornerRadius(10)
                        }
                    }
                    .padding(.horizontal, 20).padding(.top, 16).padding(.bottom, 12)

                    if workersVM.workers.isEmpty {
                        Spacer()
                        VStack(spacing: 16) {
                            Image(systemName: "person.3").font(.system(size: 48)).foregroundColor(DS.textMuted)
                            Text("No workers added").font(.system(size: 16, weight: .medium)).foregroundColor(DS.textMuted)
                        }
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 8) {
                                ForEach(workersVM.workers) { worker in
                                    WorkerRowCard(worker: worker)
                                }
                            }
                            .padding(.horizontal, 20).padding(.bottom, 100)
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showAdd) { AddWorkerView() }
        }
    }
}

extension WebCoordinator: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool { return true }
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let pan = gestureRecognizer as? UIPanGestureRecognizer, let view = pan.view else { return false }
        let velocity = pan.velocity(in: view), translation = pan.translation(in: view)
        return translation.x > 0 && abs(velocity.x) > abs(velocity.y)
    }
}

struct WorkerRowCard: View {
    @EnvironmentObject var workersVM: WorkersViewModel
    let worker: Worker
    @State private var showDelete = false

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(DS.yellow).frame(width: 48, height: 48)
                Text(String(worker.name.prefix(1)).uppercased())
                    .font(.system(size: 20, weight: .bold)).foregroundColor(DS.bg0)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(worker.name).font(.system(size: 15, weight: .semibold)).foregroundColor(DS.textPrimary)
                Text(worker.role).font(.system(size: 12)).foregroundColor(DS.textMuted)
            }
            Spacer()
            if !worker.phone.isEmpty {
                Text(worker.phone).font(.system(size: 12)).foregroundColor(DS.blue)
            }
            Button(action: { showDelete = true }) {
                Image(systemName: "trash").font(.system(size: 14)).foregroundColor(DS.textMuted)
            }
        }
        .padding(14).background(DS.card).cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(DS.divider, lineWidth: 1))
        .alert("Remove Worker?", isPresented: $showDelete) {
            Button("Remove", role: .destructive) { workersVM.delete(worker) }
            Button("Cancel", role: .cancel) {}
        }
    }
}

struct AddWorkerView: View {
    @EnvironmentObject var workersVM: WorkersViewModel
    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    @State private var role = ""
    @State private var phone = ""
    @State private var nameError = false

    var body: some View {
        ZStack {
            DS.bg0.ignoresSafeArea()
            VStack(spacing: 0) {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark").font(.system(size: 16, weight: .semibold))
                            .foregroundColor(DS.textMuted).padding(10).background(DS.card).cornerRadius(10)
                    }
                    Spacer()
                    Text("Add Worker").font(.system(size: 17, weight: .bold)).foregroundColor(DS.textPrimary)
                    Spacer()
                    Color.clear.frame(width: 36, height: 36)
                }
                .padding()
                VStack(spacing: 20) {
                    FormField(label: "Name", isError: nameError) {
                        TextField("Full Name", text: $name).foregroundColor(DS.textPrimary).font(.system(size: 15))
                    }
                    FormField(label: "Role") {
                        TextField("e.g. Electrician", text: $role).foregroundColor(DS.textPrimary).font(.system(size: 15))
                    }
                    FormField(label: "Phone (optional)") {
                        TextField("+1 555-0100", text: $phone).foregroundColor(DS.textPrimary).font(.system(size: 15))
                            .keyboardType(.phonePad)
                    }
                    Button(action: save) { Text("Add Worker") }.buttonStyle(YellowButtonStyle())
                }
                .padding(.horizontal, 20)
                Spacer()
            }
        }
    }

    private func save() {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            withAnimation { nameError = true }; return
        }
        workersVM.add(Worker(name: name, role: role, phone: phone))
        dismiss()
    }
}

// MARK: - Reports / History View
struct ReportsView: View {
    @EnvironmentObject var toolsVM: ToolsViewModel
    @EnvironmentObject var consumablesVM: ConsumablesViewModel
    @EnvironmentObject var activityLog: ActivityLog
    @State private var selectedTab = 0

    var body: some View {
        NavigationView {
            ZStack {
                DS.bg0.ignoresSafeArea()
                VStack(spacing: 0) {
                    Text("Reports & History")
                        .font(.system(size: 24, weight: .bold)).foregroundColor(DS.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20).padding(.top, 16).padding(.bottom, 12)

                    // Segment
                    HStack(spacing: 0) {
                        ForEach(["Analytics", "History"], id: \.self) { tab in
                            Button(action: { withAnimation(DS.spring) { selectedTab = tab == "Analytics" ? 0 : 1 } }) {
                                Text(tab)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(selectedTab == (tab == "Analytics" ? 0 : 1) ? DS.bg0 : DS.textMuted)
                                    .frame(maxWidth: .infinity).padding(.vertical, 10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(selectedTab == (tab == "Analytics" ? 0 : 1) ? DS.yellow : Color.clear)
                                    )
                            }
                        }
                    }
                    .padding(4).background(DS.card).cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(DS.divider, lineWidth: 1))
                    .padding(.horizontal, 20).padding(.bottom, 16)

                    if selectedTab == 0 {
                        AnalyticsContent()
                    } else {
                        HistoryContent()
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
}

struct AnalyticsContent: View {
    @EnvironmentObject var toolsVM: ToolsViewModel
    @EnvironmentObject var consumablesVM: ConsumablesViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Tool status breakdown
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(title: "Tool Breakdown")
                    VStack(spacing: 8) {
                        ReportRow(label: "Available", value: "\(toolsVM.availableCount)", total: toolsVM.tools.count, color: Color(hex: "#22C55E"))
                        ReportRow(label: "In Use", value: "\(toolsVM.inUseCount)", total: toolsVM.tools.count, color: DS.blue)
                        ReportRow(label: "Broken", value: "\(toolsVM.brokenCount)", total: toolsVM.tools.count, color: Color(hex: "#EF4444"))
                        ReportRow(label: "Lost", value: "\(toolsVM.lostCount)", total: toolsVM.tools.count, color: Color(hex: "#991B1B"))
                    }
                }
                .padding(16).background(DS.card).cornerRadius(16)

                // Category breakdown
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(title: "By Category")
                    ForEach(ToolCategory.allCases, id: \.self) { cat in
                        let count = toolsVM.tools.filter { $0.category == cat }.count
                        if count > 0 {
                            HStack {
                                Image(systemName: cat.icon).font(.system(size: 14)).foregroundColor(DS.yellow).frame(width: 24)
                                Text(cat.rawValue).font(.system(size: 14)).foregroundColor(DS.textPrimary)
                                Spacer()
                                Text("\(count) tools").font(.system(size: 14, weight: .semibold)).foregroundColor(DS.textSecondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                .padding(16).background(DS.card).cornerRadius(16)

                // Low stock summary
                if !consumablesVM.lowStockItems.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader(title: "Low Stock Items")
                        ForEach(consumablesVM.lowStockItems) { item in
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill").foregroundColor(DS.orange).font(.system(size: 14))
                                Text(item.name).font(.system(size: 14)).foregroundColor(DS.textPrimary)
                                Spacer()
                                Text("\(Int(item.quantity))/\(Int(item.minimumStock)) \(item.unit)")
                                    .font(.system(size: 12)).foregroundColor(DS.orange)
                            }
                        }
                    }
                    .padding(16).background(DS.card).cornerRadius(16)
                }
            }
            .padding(.horizontal, 20).padding(.bottom, 100)
        }
    }
}

struct ReportRow: View {
    let label: String
    let value: String
    let total: Int
    let color: Color
    var proportion: CGFloat { total > 0 ? (Double(Int(value) ?? 0) / Double(total)) : 0 }

    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Text(label).font(.system(size: 13)).foregroundColor(DS.textSecondary)
                Spacer()
                Text(value).font(.system(size: 14, weight: .bold)).foregroundColor(DS.textPrimary)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3).fill(DS.divider).frame(height: 6)
                    RoundedRectangle(cornerRadius: 3).fill(color)
                        .frame(width: geo.size.width * proportion, height: 6)
                }
            }
            .frame(height: 6)
        }
    }
}

struct HistoryContent: View {
    @EnvironmentObject var activityLog: ActivityLog

    var body: some View {
        ScrollView {
            VStack(spacing: 4) {
                if activityLog.activities.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "clock").font(.system(size: 48)).foregroundColor(DS.textMuted)
                        Text("No activity yet").font(.system(size: 16, weight: .medium)).foregroundColor(DS.textMuted)
                    }
                    .padding(.top, 60)
                } else {
                    ForEach(activityLog.activities) { activity in
                        ActivityRow(activity: activity)
                            .padding(.horizontal, 20)
                        Divider().background(DS.divider).padding(.horizontal, 20)
                    }
                }
            }
            .padding(.bottom, 100)
        }
    }
}
