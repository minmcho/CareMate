import SwiftUI

/// Soft, rounded "mascot" container — a circular avatar with a coloured glow
/// and a subtle floating animation. Stand-in for the bespoke mascot
/// illustrations in the Stitch designs.
struct VitesMascot: View {
    let symbol: String
    var tint: Niche.AccentTint = .lavender
    var size: CGFloat = 72
    var floats: Bool = true

    @State private var floatPhase: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            Circle()
                .fill(LinearGradient(colors: [bg.opacity(0.95), bg.opacity(0.7)],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
            Circle()
                .strokeBorder(VitesColor.surfaceContainerLowest, lineWidth: 3)
            Image(systemName: symbol)
                .font(.system(size: size * 0.4, weight: .bold))
                .foregroundColor(fg)
        }
        .frame(width: size, height: size)
        .vitesAmbientShadow(level: 1)
        .offset(y: floatPhase)
        .onAppear {
            guard floats, !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                floatPhase = -4
            }
        }
        .accessibilityHidden(true)
    }

    private var bg: Color {
        switch tint {
        case .mint:     return VitesColor.secondaryContainer
        case .blush:    return VitesColor.tertiaryFixed
        case .lavender: return VitesColor.primaryFixed
        case .peach:    return Color(hex: 0xFFE0C2)
        case .alert:    return VitesColor.errorContainer
        }
    }
    private var fg: Color {
        switch tint {
        case .mint:     return VitesColor.onSecondaryContainer
        case .blush:    return Color(hex: 0x5C3D51)
        case .lavender: return VitesColor.onPrimaryContainer
        case .peach:    return Color(hex: 0x7A4A1F)
        case .alert:    return VitesColor.onErrorContainer
        }
    }
}

/// Subtle "pulse" ring around a processing avatar, per the design-system
/// component note for Agent Avatars.
struct VitesPulseRing: View {
    var color: Color = VitesColor.secondary
    @State private var animate = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Circle()
            .strokeBorder(color, lineWidth: 2)
            .scaleEffect(animate ? 1.15 : 1.0)
            .opacity(animate ? 0 : 0.7)
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.easeOut(duration: 1.8).repeatForever(autoreverses: false)) {
                    animate = true
                }
            }
    }
}
