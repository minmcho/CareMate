import SwiftUI

// MARK: - Pill / chip

struct VitesChip: View {
    enum Style { case mint, blush, lavender, alert, neutral }
    let label: String
    var icon: String? = nil
    var style: Style = .neutral

    var body: some View {
        HStack(spacing: 6) {
            if let icon { Image(systemName: icon).font(.system(size: 11, weight: .bold)) }
            Text(label)
                .font(VitesFont.labelBold())
                .tracking(0.4)
        }
        .foregroundColor(foreground)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule().fill(background)
        )
        .overlay(
            Capsule().strokeBorder(border, lineWidth: 1)
        )
    }

    private var background: Color {
        switch style {
        case .mint:     return VitesColor.secondaryContainer
        case .blush:    return VitesColor.tertiaryFixed
        case .lavender: return VitesColor.primaryFixed
        case .alert:    return VitesColor.errorContainer
        case .neutral:  return VitesColor.surfaceContainerLow
        }
    }
    private var foreground: Color {
        switch style {
        case .mint:     return VitesColor.onSecondaryContainer
        case .blush:    return Color(hex: 0x5C3D51)
        case .lavender: return VitesColor.onPrimaryContainer
        case .alert:    return VitesColor.onErrorContainer
        case .neutral:  return VitesColor.onSurfaceVariant
        }
    }
    private var border: Color { foreground.opacity(0.15) }
}

// MARK: - Card

struct VitesCard<Content: View>: View {
    var background: Color = VitesColor.surfaceContainerLowest
    var padding: CGFloat = 20
    var radius: CGFloat = VitesRadius.md
    var shadowLevel: Int = 1
    var content: Content

    init(background: Color = VitesColor.surfaceContainerLowest,
         padding: CGFloat = 20,
         radius: CGFloat = VitesRadius.md,
         shadowLevel: Int = 1,
         @ViewBuilder content: () -> Content) {
        self.background = background
        self.padding = padding
        self.radius = radius
        self.shadowLevel = shadowLevel
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(background)
            )
            .vitesAmbientShadow(level: shadowLevel)
    }
}

// MARK: - Buttons

struct VitesPrimaryButton: View {
    let title: String
    var icon: String? = nil
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon { Image(systemName: icon) }
                Text(title)
                    .font(VitesFont.labelBold())
                    .tracking(0.3)
            }
            .foregroundColor(VitesColor.onPrimary)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(
                Capsule().fill(VitesColor.primary)
            )
            .vitesAmbientShadow(level: 1)
        }
        .buttonStyle(BouncyButtonStyle())
        .frame(minHeight: 44)
        .accessibilityLabel(title)
    }
}

struct VitesSecondaryButton: View {
    let title: String
    var icon: String? = nil
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon { Image(systemName: icon) }
                Text(title)
                    .font(VitesFont.labelBold())
                    .tracking(0.3)
            }
            .foregroundColor(VitesColor.primary)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(
                Capsule().fill(VitesColor.surfaceContainerLowest)
            )
            .overlay(
                Capsule().strokeBorder(VitesColor.primary, lineWidth: 2)
            )
        }
        .buttonStyle(BouncyButtonStyle())
        .frame(minHeight: 44)
        .accessibilityLabel(title)
    }
}

/// Squishy press animation per design-system note: elevation changes should
/// feel bouncy. Honours reduce-motion by collapsing to a crossfade.
struct BouncyButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.97 : 1.0)
            .opacity(configuration.isPressed && reduceMotion ? 0.7 : 1.0)
            .animation(.spring(response: 0.28, dampingFraction: 0.55), value: configuration.isPressed)
    }
}

// MARK: - Status dot

struct VitesStatusDot: View {
    enum State { case running, pass, warn, fail, escalated, idle }
    let state: State

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 8, height: 8)
            .overlay(Circle().strokeBorder(color.opacity(0.3), lineWidth: 3).scaleEffect(1.8))
            .accessibilityLabel(label)
    }

    private var color: Color {
        switch state {
        case .running:   return VitesColor.primaryContainer
        case .pass:      return VitesColor.secondary
        case .warn:      return Color(hex: 0xE0A458)
        case .fail:      return VitesColor.error
        case .escalated: return Color(hex: 0x8B5CF6)
        case .idle:      return VitesColor.outlineVariant
        }
    }
    private var label: String {
        switch state {
        case .running:   return "Running"
        case .pass:      return "Pass"
        case .warn:      return "Warning"
        case .fail:      return "Failed"
        case .escalated: return "Escalated to human review"
        case .idle:      return "Not started"
        }
    }
}

// MARK: - Velocity sparkline (lightweight)

struct VitesSparkline: View {
    let samples: [Double]
    var tint: Color = VitesColor.primary

    var body: some View {
        GeometryReader { proxy in
            let w = proxy.size.width
            let h = proxy.size.height
            let maxV = (samples.max() ?? 1).rounded(.up)
            let minV = (samples.min() ?? 0)
            let range = max(0.001, maxV - minV)
            Path { path in
                guard samples.count > 1 else { return }
                let step = w / CGFloat(samples.count - 1)
                for (i, v) in samples.enumerated() {
                    let x = CGFloat(i) * step
                    let y = h - CGFloat((v - minV) / range) * h
                    if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
                    else      { path.addLine(to: CGPoint(x: x, y: y)) }
                }
            }
            .stroke(tint, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
        }
        .frame(height: 28)
        .accessibilityHidden(true)
    }
}

// MARK: - Progress bar

struct VitesProgressBar: View {
    let progress: Double // 0...1
    var tint: Color = VitesColor.primary

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(VitesColor.surfaceContainer)
                Capsule()
                    .fill(LinearGradient(
                        colors: [tint.opacity(0.85), tint],
                        startPoint: .leading, endPoint: .trailing))
                    .frame(width: proxy.size.width * max(0, min(1, progress)))
            }
        }
        .frame(height: 8)
        .accessibilityValue(Text("\(Int(progress * 100)) percent"))
    }
}

// MARK: - Top bar

struct VitesTopBar: View {
    let title: String
    var hasNotification: Bool = true

    var body: some View {
        HStack {
            HStack(spacing: 8) {
                ZStack {
                    Circle().fill(VitesColor.primaryFixed)
                    Image(systemName: "wand.and.stars")
                        .foregroundColor(VitesColor.primary)
                        .font(.system(size: 14, weight: .bold))
                }
                .frame(width: 28, height: 28)
                Text(title)
                    .font(VitesFont.title())
                    .foregroundColor(VitesColor.primary)
            }
            Spacer()
            Button(action: {}) {
                ZStack {
                    Circle().fill(VitesColor.surfaceContainerLowest)
                    Image(systemName: "bell.fill")
                        .foregroundColor(VitesColor.primary)
                        .font(.system(size: 14, weight: .semibold))
                    if hasNotification {
                        Circle().fill(VitesColor.error)
                            .frame(width: 8, height: 8)
                            .offset(x: 8, y: -8)
                    }
                }
                .frame(width: 36, height: 36)
                .vitesAmbientShadow()
            }
            .accessibilityLabel("Notifications")
        }
        .padding(.horizontal, VitesSpace.containerMargin)
        .padding(.top, 8)
        .padding(.bottom, 8)
    }
}
