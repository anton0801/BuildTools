import SwiftUI

// MARK: - Color Hex Init
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB,
                  red: Double(r) / 255,
                  green: Double(g) / 255,
                  blue: Double(b) / 255,
                  opacity: Double(a) / 255)
    }
}

struct OfflineView: View {
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()
                
                Image(geometry.size.width > geometry.size.height ? "tools_main2" : "tools_main")
                    .resizable().scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .ignoresSafeArea()
                    .blur(radius: 15)
                    .opacity(0.6)
                
                Image("tools_alert")
                    .resizable()
                    .frame(width: 250, height: 220)
            }
        }
        .ignoresSafeArea()
    }
}

struct DS {
    // Backgrounds
    static let bg0       = Color(hex: "#0F172A")
    static let bg1       = Color(hex: "#111827")
    static let bg2       = Color(hex: "#1A1F2E")
    static let card      = Color(hex: "#1E293B")
    static let cardHover = Color(hex: "#263244")
    static let divider   = Color(hex: "#334155")

    // Accents
    static let yellow    = Color(hex: "#FACC15")
    static let yellowAct = Color(hex: "#EAB308")
    static let yellowLt  = Color(hex: "#FDE047")

    static let orange    = Color(hex: "#F97316")
    static let orangeSft = Color(hex: "#FB923C")

    static let blue      = Color(hex: "#3B82F6")
    static let blueSft   = Color(hex: "#60A5FA")

    // Text
    static let textPrimary   = Color(hex: "#F8FAFC")
    static let textSecondary = Color(hex: "#CBD5E1")
    static let textMuted     = Color(hex: "#64748B")

    // Glows
    static let yellowGlow = Color(hex: "#FACC15").opacity(0.4)
    static let orangeGlow = Color(hex: "#F97316").opacity(0.4)

    // Spring animation
    static let spring = Animation.spring(response: 0.4, dampingFraction: 0.7)
}

// MARK: - Custom Button Style
struct YellowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .bold))
            .foregroundColor(DS.bg0)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(DS.yellow)
                    .shadow(color: DS.yellowGlow, radius: configuration.isPressed ? 4 : 12, x: 0, y: 4)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(DS.spring, value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(DS.textPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(DS.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(DS.divider, lineWidth: 1)
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(DS.spring, value: configuration.isPressed)
    }
}

// MARK: - Card View
struct DSCard<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }

    var body: some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(DS.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(DS.divider, lineWidth: 1)
                    )
            )
    }
}

// MARK: - Status Badge
struct StatusBadge: View {
    let status: ToolStatus
    var body: some View {
        HStack(spacing: 4) {
            Circle().fill(status.color).frame(width: 6, height: 6)
            Text(status.rawValue)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(status.color)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(status.color.opacity(0.15))
        .cornerRadius(20)
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(color)
                Spacer()
            }
            Text(value)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(DS.textPrimary)
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(DS.textMuted)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(DS.card)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Section Header
struct SectionHeader: View {
    let title: String
    var body: some View {
        Text(title)
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(DS.textMuted)
            .textCase(.uppercase)
            .tracking(1.2)
    }
}
