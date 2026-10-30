import SwiftUI
import UIKit

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255,
                  opacity: opacity)
    }

    static func dynamic(_ light: UInt32, _ dark: UInt32) -> Color {
        Color(UIColor { traits in
            let hex = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(red: CGFloat((hex >> 16) & 0xFF) / 255,
                           green: CGFloat((hex >> 8) & 0xFF) / 255,
                           blue: CGFloat(hex & 0xFF) / 255, alpha: 1)
        })
    }
}

/// ScamSense look: warm paper background, deep "guardian" navy and blue, traffic-light signals.
enum Theme {
    static let bg = Color.dynamic(0xF4F2EC, 0x0A0F1E)
    static let card = Color.dynamic(0xFFFFFF, 0x151C31)
    static let cardAlt = Color.dynamic(0xECEAE3, 0x1D2540)
    static let ink = Color.dynamic(0x0E1630, 0xF2F4FA)
    static let subtle = Color.dynamic(0x4E5874, 0xAAB3CA)
    static let line = Color.dynamic(0xDDD9CF, 0x2A3352)
    static let brand = Color.dynamic(0x2347E0, 0x7B93FF)
    /// Solid fills behind white text: keep >= 4.5:1 contrast in light and dark.
    static let brandFill = Color.dynamic(0x2347E0, 0x3550E8)
    static let scamFill = Color(hex: 0xC2261C)
    static let safeFill = Color(hex: 0x0D7550)
    static let brandDeep = Color(hex: 0x111B4D)
    static let brandMid = Color(hex: 0x2A4BD8)
    static let scam = Color.dynamic(0xC8261B, 0xFF6A5E)
    static let warn = Color.dynamic(0xB06A00, 0xFFB43C)
    static let safe = Color.dynamic(0x0D7A52, 0x3DD598)
    static let gold = Color(hex: 0xF5B83D)
    static let bubbleGray = Color.dynamic(0xE9E9EE, 0x2C2C30)

    static let heroGradient = LinearGradient(colors: [Color(hex: 0x0F1846), Color(hex: 0x23409F), Color(hex: 0x3361F0)],
                                             startPoint: .topLeading, endPoint: .bottomTrailing)

    static func title(_ style: Font.TextStyle = .largeTitle) -> Font {
        .system(style, design: .rounded, weight: .bold)
    }
}

// MARK: - Buttons

struct PrimaryButtonStyle: ButtonStyle {
    var fill: Color = Theme.brandFill
    var foreground: Color = .white
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .labelStyle(ButtonIconLabelStyle())
            .font(.system(.title3, design: .rounded, weight: .bold))
            .multilineTextAlignment(.center)
            .foregroundStyle(foreground)
            .frame(maxWidth: .infinity, minHeight: 58)
            .padding(.horizontal, 18)
            .background(fill.opacity(isEnabled ? 1 : 0.35), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(duration: 0.25), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    var tint: Color = Theme.brand

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .labelStyle(ButtonIconLabelStyle())
            .font(.system(.headline, design: .rounded, weight: .semibold))
            .multilineTextAlignment(.center)
            .foregroundStyle(tint)
            .frame(maxWidth: .infinity, minHeight: 54)
            .padding(.horizontal, 14)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(tint.opacity(0.45), lineWidth: 1.5))
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(duration: 0.25), value: configuration.isPressed)
    }
}

/// Icon + title for the big buttons: the icon is a little larger and centered vertically on the title
/// (the default label pins it to the first text line, which looks off when the title wraps or the symbol is tall).
struct ButtonIconLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(alignment: .center, spacing: 8) {
            configuration.icon
                .imageScale(.large)
            configuration.title
        }
    }
}

struct PressableStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.spring(duration: 0.2), value: configuration.isPressed)
    }
}

// MARK: - Cards & chips

struct CardModifier: ViewModifier {
    var padding: CGFloat = 18
    var fill: Color = Theme.card

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(fill, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(Theme.line.opacity(0.7), lineWidth: 1))
            .shadow(color: .black.opacity(0.05), radius: 10, y: 4)
    }
}

extension View {
    func card(padding: CGFloat = 18, fill: Color = Theme.card) -> some View {
        modifier(CardModifier(padding: padding, fill: fill))
    }

    /// Section heading style used across the app.
    func sectionTitle() -> some View {
        font(.system(.title3, design: .rounded, weight: .bold)).foregroundStyle(Theme.ink)
    }
}

struct Chip: View {
    let title: LocalizedStringResource
    let symbol: String
    let selected: Bool

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: symbol).font(.subheadline.weight(.semibold))
            Text(title).font(.system(.subheadline, design: .rounded, weight: .semibold))
        }
        .padding(.horizontal, 14)
        .frame(minHeight: 44)
        .foregroundStyle(selected ? .white : Theme.ink)
        .background(selected ? Theme.brandFill : Theme.card, in: Capsule())
        .overlay(Capsule().stroke(selected ? Color.clear : Theme.line, lineWidth: 1.2))
        .contentShape(Capsule())
    }
}

struct VerdictChip: View {
    let verdict: Verdict

    var body: some View {
        Label { Text(verdict.label) } icon: { Image(systemName: verdict.symbol) }
            .font(.system(.caption, design: .rounded, weight: .bold))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .foregroundStyle(verdict.headerText)
            .background(verdict.headerFill, in: Capsule())
    }
}

/// Simple wrapping layout for chips.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0, maxX: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x > 0 && x + size.width > width {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            x += size.width + spacing
            maxX = max(maxX, x - spacing)
            rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: min(maxX, width), height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, rowHeight: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x > bounds.minX && x + size.width > bounds.maxX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            view.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

/// App logo mark: shield with the three traffic-light signals (same drawing as the app icon).
struct LogoMark: View {
    var size: CGFloat = 84

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.26, style: .continuous)
                .fill(Theme.heroGradient)
            ShieldShape()
                .fill(.white)
                .frame(width: size * 0.62, height: size * 0.7)
                .shadow(color: .black.opacity(0.2), radius: size * 0.04, y: size * 0.02)
            Capsule()
                .fill(Color(hex: 0x121A44))
                .frame(width: size * 0.22, height: size * 0.46)
                .offset(y: -size * 0.02)
            VStack(spacing: size * 0.035) {
                Circle().fill(Color(hex: 0xFF4D3D))
                Circle().fill(Color(hex: 0xFFB020))
                Circle().fill(Color(hex: 0x2BD47D))
            }
            .frame(width: size * 0.13, height: size * 0.42)
            .offset(y: -size * 0.02)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

struct ShieldShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        let w = r.width, h = r.height
        p.move(to: CGPoint(x: r.minX + w * 0.5, y: r.minY))
        p.addCurve(to: CGPoint(x: r.maxX, y: r.minY + h * 0.14),
                   control1: CGPoint(x: r.minX + w * 0.68, y: r.minY + h * 0.09),
                   control2: CGPoint(x: r.minX + w * 0.86, y: r.minY + h * 0.12))
        p.addCurve(to: CGPoint(x: r.minX + w * 0.5, y: r.maxY),
                   control1: CGPoint(x: r.maxX, y: r.minY + h * 0.58),
                   control2: CGPoint(x: r.minX + w * 0.8, y: r.minY + h * 0.86))
        p.addCurve(to: CGPoint(x: r.minX, y: r.minY + h * 0.14),
                   control1: CGPoint(x: r.minX + w * 0.2, y: r.minY + h * 0.86),
                   control2: CGPoint(x: r.minX, y: r.minY + h * 0.58))
        p.addCurve(to: CGPoint(x: r.minX + w * 0.5, y: r.minY),
                   control1: CGPoint(x: r.minX + w * 0.14, y: r.minY + h * 0.12),
                   control2: CGPoint(x: r.minX + w * 0.32, y: r.minY + h * 0.09))
        p.closeSubpath()
        return p
    }
}

/// Applies "Large text mode" (bigger layout everywhere) or keeps the system size within a sane range.
struct LargeTextModifier: ViewModifier {
    let on: Bool
    @Environment(\.dynamicTypeSize) private var systemSize

    func body(content: Content) -> some View {
        if on {
            content.dynamicTypeSize(max(systemSize, .xxxLarge))
        } else {
            content.dynamicTypeSize(...DynamicTypeSize.accessibility3)
        }
    }
}
