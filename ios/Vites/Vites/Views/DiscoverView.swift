import SwiftUI

struct DiscoverView: View {
    @State private var niches = Niche.sample

    var body: some View {
        VitesScreen {
            VStack(alignment: .leading, spacing: VitesSpace.lg) {
                header
                ForEach(niches) { niche in
                    NicheCard(niche: niche)
                }
            }
            .padding(.horizontal, VitesSpace.containerMargin)
            .padding(.bottom, VitesSpace.section)
        }
    }

    private var header: some View {
        VStack(alignment: .center, spacing: 8) {
            Text("Trend Discovery")
                .font(VitesFont.headlineLarge())
                .foregroundColor(VitesColor.primary)
            Text("Catch the next wave before it peaks. Explore rising niches with our real-time engagement velocity analysis.")
                .font(VitesFont.bodyMedium())
                .foregroundColor(VitesColor.onSurfaceVariant)
                .multilineTextAlignment(.center)
                .lineSpacing(2)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }
}

// MARK: - Card

private struct NicheCard: View {
    let niche: Niche

    var body: some View {
        VitesCard(background: cardBackground, padding: 18, radius: VitesRadius.md) {
            VStack(alignment: .leading, spacing: 14) {
                heatPill
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(niche.title)
                            .font(VitesFont.headlineMedium())
                            .foregroundColor(VitesColor.onSurface)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 4)
                    if !niche.heat.isAlert {
                        velocityBadge
                    }
                }

                Text(niche.summary)
                    .font(VitesFont.bodyMedium())
                    .foregroundColor(VitesColor.onSurfaceVariant)
                    .lineSpacing(2)

                if niche.heat.isAlert {
                    alertBody
                } else {
                    HStack(spacing: 8) {
                        ForEach(niche.platforms) { p in
                            PlatformPill(platform: p)
                        }
                        Spacer()
                    }
                    if case .alpha = niche.heat {
                        alphaMetrics
                    } else if case .steadyGrowth = niche.heat {
                        velocityIndicator
                    } else {
                        VitesPrimaryButton(title: "Generate Brief", icon: "wand.and.rays") { }
                    }
                }
            }
        }
    }

    private var cardBackground: Color {
        switch niche.accent {
        case .mint:     return Color(hex: 0xE9F8F1)
        case .blush:    return Color(hex: 0xFDECF3)
        case .lavender: return Color(hex: 0xF1ECFF)
        case .peach:    return Color(hex: 0xFFEFDA)
        case .alert:    return Color(hex: 0xFFE3E0)
        }
    }

    private var heatPill: some View {
        HStack(spacing: 8) {
            VitesChip(label: niche.heat.label, style: chipStyle(for: niche.heat))
            Spacer()
            if niche.heat.isAlert {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(VitesColor.error)
            }
        }
    }

    private func chipStyle(for heat: Niche.Heat) -> VitesChip.Style {
        switch heat {
        case .risingFast:    return .mint
        case .steadyGrowth:  return .lavender
        case .alpha:         return .blush
        case .communityFave: return .mint
        case .alert:         return .alert
        }
    }

    private var velocityBadge: some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text("+\(niche.velocityChangePct)%")
                .font(VitesFont.labelBold())
                .foregroundColor(VitesColor.primary)
            Text("Velocity")
                .font(VitesFont.caption())
                .foregroundColor(VitesColor.onSurfaceVariant)
        }
        .padding(.horizontal, 10).padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(VitesColor.surfaceContainerLowest)
        )
    }

    private var velocityIndicator: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Velocity indicator")
                .font(VitesFont.caption())
                .foregroundColor(VitesColor.onSurfaceVariant)
            VitesProgressBar(progress: 0.55, tint: VitesColor.primary)
            VitesSparkline(samples: niche.velocity, tint: VitesColor.primary)
                .frame(height: 28)
        }
    }

    private var alphaMetrics: some View {
        VStack(spacing: 10) {
            metricRow(label: "Twitter/X Mentions", delta: "+120%")
            metricRow(label: "GitHub Stars",       delta: "+45%")
        }
    }

    private func metricRow(label: String, delta: String) -> some View {
        HStack {
            Text(label)
                .font(VitesFont.bodyMedium())
                .foregroundColor(VitesColor.onSurface)
            Spacer()
            Text(delta)
                .font(VitesFont.labelBold())
                .foregroundColor(VitesColor.secondary)
                .padding(.horizontal, 10).padding(.vertical, 4)
                .background(Capsule().fill(VitesColor.secondaryContainer))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(VitesColor.surfaceContainerLowest)
        )
    }

    private var alertBody: some View {
        VStack(alignment: .center, spacing: 10) {
            VitesMascot(symbol: niche.mascotSymbol, tint: .alert, size: 56)
            Text("RABBIT")
                .font(VitesFont.labelBold())
                .foregroundColor(VitesColor.error)
                .tracking(2)
            if case let .alert(reason) = niche.heat {
                Text(reason)
                    .font(VitesFont.caption())
                    .foregroundColor(VitesColor.onErrorContainer)
            }
            Text(niche.summary)
                .font(VitesFont.bodyMedium())
                .foregroundColor(VitesColor.onSurfaceVariant)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Platform pill

private struct PlatformPill: View {
    let platform: VitesPlatform

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: platform.symbol)
                .font(.system(size: 11, weight: .bold))
            Text(platform.displayName)
                .font(VitesFont.labelBold())
        }
        .foregroundColor(VitesColor.onSurface)
        .padding(.horizontal, 10).padding(.vertical, 6)
        .background(
            Capsule().fill(VitesColor.surfaceContainerLowest)
        )
        .overlay(
            Capsule().strokeBorder(VitesColor.outlineVariant, lineWidth: 1)
        )
    }
}

// MARK: - Heat helpers

private extension Niche.Heat {
    var isAlert: Bool {
        if case .alert = self { return true }
        return false
    }
}

#Preview {
    DiscoverView()
        .background(VitesColor.surface)
}
