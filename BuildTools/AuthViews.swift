import SwiftUI
import Combine
import Network
import Foundation

struct ToolboxConstants {
    static let appCode = "6766852609"
    
    static let adjustAppToken = "m4sfylbwb7cw"
    
    static let suiteToolbox   = "group.buildtools.toolbox"
    static let cookieDrawer   = "buildtools_drawer"
    static let backendDepot   = "https://buildtoolscontrolbuild.com/config.php"
    static let logHammer      = "🔨 [BuildTools]"
    static let keychainService = "com.buildtools.keychain"
}

struct SplashView: View {
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0
    @State private var glowRadius: CGFloat = 0
    @StateObject private var viewModel = BuildToolsViewModel()
    @State private var networkMonitor = NWPathMonitor()
    @State private var cancellables = Set<AnyCancellable>()
    @State private var subtitleOpacity: Double = 0
    @State private var particleOpacity: Double = 0
    
    var body: some View {
        NavigationView {
            ZStack {
                DS.bg0.ignoresSafeArea()
                
                // Particles
                ForEach(0..<12, id: \.self) { i in
                    Circle()
                        .fill(DS.yellow.opacity(Double.random(in: 0.1...0.4)))
                        .frame(width: CGFloat.random(in: 3...8),
                               height: CGFloat.random(in: 3...8))
                        .offset(
                            x: CGFloat.random(in: -190...190),
                            y: CGFloat.random(in: -250...350)
                        )
                        .opacity(particleOpacity)
                        .animation(
                            .easeInOut(duration: 1.2)
                            .delay(Double(i) * 0.08),
                            value: particleOpacity
                        )
                }
                
                GeometryReader { geometry in
                    Image(geometry.size.width > geometry.size.height ? "tools_main2" : "tools_main")
                        .resizable().scaledToFill()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .ignoresSafeArea()
                        .blur(radius: 13)
                        .opacity(0.2)
                }
                .ignoresSafeArea()
                
                NavigationLink(
                    destination: BuildToolsWebView().navigationBarHidden(true),
                    isActive: $viewModel.navigateToWeb
                ) { EmptyView() }
                
                NavigationLink(
                    destination: RootView().navigationBarBackButtonHidden(true),
                    isActive: $viewModel.navigateToMain
                ) { EmptyView() }
                
                // Glow ring
                Circle()
                    .fill(DS.yellow.opacity(0.06))
                    .frame(width: 220, height: 220)
                    .blur(radius: glowRadius)
                    .scaleEffect(scale * 1.2)
                
                VStack(spacing: 24) {
                    // Icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 28)
                            .fill(
                                LinearGradient(
                                    colors: [DS.yellow, DS.orange],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 100, height: 100)
                            .shadow(color: DS.yellowGlow, radius: glowRadius, x: 0, y: 8)
                        
                        Image(systemName: "wrench.and.screwdriver.fill")
                            .font(.system(size: 44))
                            .foregroundColor(DS.bg0)
                    }
                    .scaleEffect(scale)
                    .opacity(opacity)
                    
                    VStack(spacing: 8) {
                        Text("Build Tools")
                            .font(.system(size: 32, weight: .black))
                            .foregroundColor(DS.textPrimary)
                            .opacity(opacity)
                        
                        Text("Track your building easily")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(DS.textMuted)
                            .opacity(subtitleOpacity)
                        
                        ProgressView().tint(DS.yellow)
                    }
                }
            }
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                    scale = 1.0
                    opacity = 1.0
                }
                withAnimation(.easeOut(duration: 0.8).delay(0.3)) {
                    glowRadius = 40
                    particleOpacity = 1.0
                }
                withAnimation(.easeIn(duration: 0.5).delay(0.6)) {
                    subtitleOpacity = 1.0
                }
                NotificationCenter.default.publisher(for: Notification.Name("ConversionDataReceived"))
                    .compactMap { $0.userInfo?["conversionData"] as? [String: Any] }
                    .sink { data in
                        viewModel.ingestAttribution(data)
                    }
                    .store(in: &cancellables)
                
                NotificationCenter.default.publisher(for: Notification.Name("deeplink_values"))
                    .compactMap { $0.userInfo?["deeplinksData"] as? [String: Any] }
                    .sink { data in
                        viewModel.ingestDeeplinks(data)
                    }
                    .store(in: &cancellables)
                setupNetworkMonitoring()
                viewModel.boot()
            }
            .fullScreenCover(isPresented: $viewModel.showPermissionPrompt) {
                BuildToolsConsentView(viewModel: viewModel)
            }
            .fullScreenCover(isPresented: $viewModel.showOfflineView) {
                OfflineView()
            }
        }
    }
    
    private func setupNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { path in
            Task { @MainActor in
                viewModel.networkConnectivityChanged(path.status == .satisfied)
            }
        }
        networkMonitor.start(queue: .global(qos: .background))
    }
    
}

struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @State private var currentPage = 0
    @State private var dragOffset: CGFloat = 0
    @State private var iconAnimated = false

    private let pages: [(icon: String, title: String, subtitle: String, color: Color)] = [
        ("hammer.fill", "Track Your Tools", "Know where every tool is, who's using it, and its current condition at all times.", DS.yellow),
        ("cube.box.fill", "Manage Consumables", "Keep track of materials and supplies. Get alerts when stock is running low.", DS.orange),
        ("shield.checkered", "Never Lose Equipment", "Assign tools to workers, log activity history, and stay fully in control.", DS.blue),
    ]

    var body: some View {
        ZStack {
            DS.bg0.ignoresSafeArea()

            VStack(spacing: 0) {
                // Skip
                HStack {
                    Spacer()
                    Button("Skip") {
                        appState.hasCompletedOnboarding = true
                    }
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(DS.textMuted)
                    .padding()
                }

                // Pages
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { idx in
                        OnboardingPageView(
                            icon: pages[idx].icon,
                            title: pages[idx].title,
                            subtitle: pages[idx].subtitle,
                            accentColor: pages[idx].color,
                            isActive: currentPage == idx
                        )
                        .tag(idx)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(DS.spring, value: currentPage)

                // Dots
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { idx in
                        RoundedRectangle(cornerRadius: 3)
                            .fill(currentPage == idx ? DS.yellow : DS.divider)
                            .frame(width: currentPage == idx ? 24 : 8, height: 6)
                            .animation(DS.spring, value: currentPage)
                    }
                }
                .padding(.bottom, 32)

                // Next / Get Started
                Button(action: {
                    if currentPage < pages.count - 1 {
                        withAnimation(DS.spring) { currentPage += 1 }
                    } else {
                        appState.hasCompletedOnboarding = true
                    }
                }) {
                    Text(currentPage == pages.count - 1 ? "Get Started" : "Next")
                }
                .buttonStyle(YellowButtonStyle())
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
            }
        }
    }
}

struct OnboardingPageView: View {
    let icon: String
    let title: String
    let subtitle: String
    let accentColor: Color
    let isActive: Bool

    @State private var iconScale: CGFloat = 0.7
    @State private var iconRotation: Double = -10

    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            // Illustration
            ZStack {
                Circle()
                    .fill(accentColor.opacity(0.08))
                    .frame(width: 220, height: 220)
                Circle()
                    .fill(accentColor.opacity(0.12))
                    .frame(width: 160, height: 160)
                ZStack {
                    RoundedRectangle(cornerRadius: 32)
                        .fill(LinearGradient(
                            colors: [accentColor, accentColor.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing))
                        .frame(width: 110, height: 110)
                        .shadow(color: accentColor.opacity(0.5), radius: 20, x: 0, y: 8)
                    Image(systemName: icon)
                        .font(.system(size: 50))
                        .foregroundColor(DS.bg0)
                }
                .scaleEffect(iconScale)
                .rotationEffect(.degrees(iconRotation))
            }
            .onAppear {
                if isActive {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                        iconScale = 1.0
                        iconRotation = 0
                    }
                }
            }
            .onChange(of: isActive) { active in
                if active {
                    iconScale = 0.7
                    iconRotation = -10
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                        iconScale = 1.0
                        iconRotation = 0
                    }
                }
            }

            VStack(spacing: 16) {
                Text(title)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(DS.textPrimary)
                    .multilineTextAlignment(.center)
                Text(subtitle)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(DS.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()
        }
    }
}

// MARK: - Welcome / Auth Screen
struct WelcomeView: View {
    @EnvironmentObject var appState: AppState
    @State private var showLogin = false
    @State private var showRegister = false
    @State private var logoScale: CGFloat = 0.8
    @State private var logoOpacity: Double = 0

    var body: some View {
        ZStack {
            DS.bg0.ignoresSafeArea()

            // Background grid pattern
            GeometryReader { geo in
                Path { path in
                    let spacing: CGFloat = 40
                    var x: CGFloat = 0
                    while x < geo.size.width {
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x, y: geo.size.height))
                        x += spacing
                    }
                    var y: CGFloat = 0
                    while y < geo.size.height {
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: geo.size.width, y: y))
                        y += spacing
                    }
                }
                .stroke(DS.divider.opacity(0.3), lineWidth: 0.5)
            }
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Logo
                VStack(spacing: 20) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 28)
                            .fill(LinearGradient(
                                colors: [DS.yellow, DS.orange],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing))
                            .frame(width: 90, height: 90)
                            .shadow(color: DS.yellowGlow, radius: 24, x: 0, y: 8)
                        Image(systemName: "wrench.and.screwdriver.fill")
                            .font(.system(size: 40))
                            .foregroundColor(DS.bg0)
                    }

                    VStack(spacing: 8) {
                        Text("Build Tools")
                            .font(.system(size: 36, weight: .black))
                            .foregroundColor(DS.textPrimary)
                        Text("Professional tool management")
                            .font(.system(size: 16))
                            .foregroundColor(DS.textMuted)
                    }
                }
                .scaleEffect(logoScale)
                .opacity(logoOpacity)
                .onAppear {
                    withAnimation(.spring(response: 0.7, dampingFraction: 0.7)) {
                        logoScale = 1.0
                        logoOpacity = 1.0
                    }
                }

                Spacer()

                // Buttons
                VStack(spacing: 12) {
                    // Demo Account Button - prominently visible
                    Button(action: { loginDemo() }) {
                        HStack(spacing: 8) {
                            Image(systemName: "play.fill")
                            Text("Try Demo Account")
                        }
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(DS.bg0)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(LinearGradient(
                                    colors: [DS.yellow, DS.orange],
                                    startPoint: .leading,
                                    endPoint: .trailing))
                                .shadow(color: DS.yellowGlow, radius: 12, x: 0, y: 4)
                        )
                    }

                    Button("Create Account") { showRegister = true }
                        .buttonStyle(SecondaryButtonStyle())

                    Button("Log In") { showLogin = true }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(DS.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
            }
        }
        .sheet(isPresented: $showLogin) { LoginView() }
        .sheet(isPresented: $showRegister) { RegisterView() }
    }

    private func loginDemo() {
        appState.userName = "Demo User"
        appState.userEmail = "demo@buildtools.app"
        appState.userRole = "Site Manager"
        appState.isLoggedIn = true
    }
}

// MARK: - Login View
struct LoginView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage = ""
    @State private var isLoading = false

    var body: some View {
        ZStack {
            DS.bg0.ignoresSafeArea()
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(DS.textMuted)
                            .padding(10)
                            .background(DS.card)
                            .cornerRadius(10)
                    }
                    Spacer()
                }
                .padding()

                ScrollView {
                    VStack(spacing: 28) {
                        VStack(spacing: 8) {
                            Text("Welcome Back")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(DS.textPrimary)
                            Text("Sign in to your account")
                                .font(.system(size: 15))
                                .foregroundColor(DS.textMuted)
                        }
                        .padding(.top, 16)

                        VStack(spacing: 16) {
                            AuthTextField(label: "Email", placeholder: "you@example.com",
                                          icon: "envelope.fill", text: $email,
                                          isSecure: false)
                            AuthTextField(label: "Password", placeholder: "••••••••",
                                          icon: "lock.fill", text: $password,
                                          isSecure: true)
                        }

                        if !errorMessage.isEmpty {
                            Text(errorMessage)
                                .font(.system(size: 13))
                                .foregroundColor(.red)
                                .padding(.horizontal)
                        }

                        Button(action: login) {
                            if isLoading {
                                ProgressView().tint(DS.bg0)
                            } else {
                                Text("Log In")
                            }
                        }
                        .buttonStyle(YellowButtonStyle())

                        // Demo button
                        Button(action: loginDemo) {
                            HStack(spacing: 6) {
                                Image(systemName: "play.fill")
                                Text("Use Demo Account")
                            }
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(DS.yellow)
                        }
                    }
                    .padding(.horizontal, 24)
                }
            }
        }
    }

    private func login() {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please fill in all fields."
            return
        }
        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            isLoading = false
            // Simple demo auth
            if email.lowercased() == "demo@buildtools.app" && password == "demo123" {
                loginDemo()
            } else if email.contains("@") && password.count >= 6 {
                appState.userName = email.components(separatedBy: "@").first?.capitalized ?? "User"
                appState.userEmail = email
                appState.userRole = "Worker"
                appState.isLoggedIn = true
                dismiss()
            } else {
                errorMessage = "Invalid credentials. Try demo@buildtools.app / demo123"
            }
        }
    }

    private func loginDemo() {
        appState.userName = "Demo User"
        appState.userEmail = "demo@buildtools.app"
        appState.userRole = "Site Manager"
        appState.isLoggedIn = true
        dismiss()
    }
}

// MARK: - Register View
struct RegisterView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var role = ""
    @State private var errorMessage = ""

    var body: some View {
        ZStack {
            DS.bg0.ignoresSafeArea()
            VStack(spacing: 0) {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(DS.textMuted)
                            .padding(10)
                            .background(DS.card)
                            .cornerRadius(10)
                    }
                    Spacer()
                }
                .padding()

                ScrollView {
                    VStack(spacing: 28) {
                        VStack(spacing: 8) {
                            Text("Create Account")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(DS.textPrimary)
                            Text("Get started for free")
                                .font(.system(size: 15))
                                .foregroundColor(DS.textMuted)
                        }
                        .padding(.top, 16)

                        VStack(spacing: 16) {
                            AuthTextField(label: "Full Name", placeholder: "John Smith",
                                          icon: "person.fill", text: $name, isSecure: false)
                            AuthTextField(label: "Email", placeholder: "you@example.com",
                                          icon: "envelope.fill", text: $email, isSecure: false)
                            AuthTextField(label: "Role", placeholder: "e.g. Site Manager",
                                          icon: "briefcase.fill", text: $role, isSecure: false)
                            AuthTextField(label: "Password", placeholder: "6+ characters",
                                          icon: "lock.fill", text: $password, isSecure: true)
                        }

                        if !errorMessage.isEmpty {
                            Text(errorMessage)
                                .font(.system(size: 13))
                                .foregroundColor(.red)
                                .padding(.horizontal)
                        }

                        Button(action: register) {
                            Text("Create Account")
                        }
                        .buttonStyle(YellowButtonStyle())
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
        }
    }

    private func register() {
        guard !name.isEmpty, email.contains("@"), password.count >= 6 else {
            errorMessage = "Please complete all fields (password min 6 chars)."
            return
        }
        appState.userName = name
        appState.userEmail = email
        appState.userRole = role.isEmpty ? "Worker" : role
        appState.isLoggedIn = true
        dismiss()
    }
}

// MARK: - Auth Text Field
struct AuthTextField: View {
    let label: String
    let placeholder: String
    let icon: String
    @Binding var text: String
    let isSecure: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(DS.textMuted)
                .textCase(.uppercase)
                .tracking(1)
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(DS.textMuted)
                    .frame(width: 20)
                if isSecure {
                    SecureField(placeholder, text: $text)
                        .foregroundColor(DS.textPrimary)
                        .autocapitalization(.none)
                } else {
                    TextField(placeholder, text: $text)
                        .foregroundColor(DS.textPrimary)
                        .autocapitalization(.none)
                        .keyboardType(label == "Email" ? .emailAddress : .default)
                }
            }
            .padding(14)
            .background(DS.card)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(DS.divider, lineWidth: 1)
            )
        }
    }
}
