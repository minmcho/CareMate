import SwiftUI

struct AgentsView: View {
    @State private var agents = AgentCard.sample
    @State private var missions = MissionControlItem.sample

    var body: some View {
        VitesScreen {
            VStack(alignment: .leading, spacing: VitesSpace.lg) {
                header
                ForEach(agents) { agent in
                    AgentRowCard(agent: agent)
                }
                missionControl
                hatchCallout
            }
            .padding(.horizontal, VitesSpace.containerMargin)
            .padding(.bottom, VitesSpace.section)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Agent Hub")
                .font(VitesFont.headlineLarge())
                .foregroundColor(VitesColor.onSurface)
            Text("Meet your friendly team of AI companions working behind the scenes.")
                .font(VitesFont.bodyMedium())
                .foregroundColor(VitesColor.onSurfaceVariant)
        }
    }

    private var missionControl: some View {
        VitesCard(background: VitesColor.surfaceContainerLowest, padding: 18) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .foregroundColor(VitesColor.primary)
                        Text("Mission Control")
                            .font(VitesFont.title())
                            .foregroundColor(VitesColor.onSurface)
                    }
                    Spacer()
                    VitesChip(label: "96.2% Efficiency", icon: "checkmark.seal.fill", style: .mint)
                }
                ForEach(missions) { m in
                    missionRow(m)
                }
            }
        }
    }

    private func missionRow(_ m: MissionControlItem) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: m.symbol)
                    .foregroundColor(VitesColor.primary)
                Text(m.title)
                    .font(VitesFont.bodyMedium())
                    .foregroundColor(VitesColor.onSurface)
                Spacer()
                Text("\(Int(m.progress * 100))%")
                    .font(VitesFont.labelBold())
                    .foregroundColor(VitesColor.primary)
            }
            VitesProgressBar(progress: m.progress, tint: VitesColor.primary)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(VitesColor.surfaceContainerLow)
        )
    }

    private var hatchCallout: some View {
        VitesCard(background: VitesColor.primary, padding: 22, radius: VitesRadius.lg, shadowLevel: 2) {
            VStack(alignment: .leading, spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(VitesColor.primaryContainer.opacity(0.35))
                    Image(systemName: "wand.and.stars.inverse")
                        .foregroundColor(.white)
                        .font(.system(size: 22, weight: .bold))
                }
                .frame(width: 48, height: 48)

                Text("Instant Scale")
                    .font(VitesFont.headlineMedium())
                    .foregroundColor(.white)
                Text("Need more processing power? Hatch a new companion to handle the workload!")
                    .font(VitesFont.bodyMedium())
                    .foregroundColor(.white.opacity(0.9))
                    .lineSpacing(2)
                Button(action: {}) {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                        Text("Hatch New Agent").font(VitesFont.labelBold())
                    }
                    .foregroundColor(VitesColor.primary)
                    .padding(.horizontal, 18).padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(Capsule().fill(Color.white))
                }
                .buttonStyle(BouncyButtonStyle())
            }
        }
    }
}

// MARK: - Agent row card

private struct AgentRowCard: View {
    let agent: AgentCard

    var body: some View {
        VitesCard(background: VitesColor.surfaceContainerLowest, padding: 18) {
            VStack(spacing: 14) {
                ZStack {
                    if case .syncing = agent.status {
                        VitesPulseRing(color: VitesColor.primary)
                            .frame(width: 96, height: 96)
                    } else if case .sniffing = agent.status {
                        VitesPulseRing(color: VitesColor.secondary)
                            .frame(width: 96, height: 96)
                    }
                    VitesMascot(symbol: agent.mascotSymbol, tint: agent.accent, size: 80)
                }
                Text(agent.name)
                    .font(VitesFont.headlineMedium())
                    .foregroundColor(VitesColor.onSurface)
                Text(agent.role)
                    .font(VitesFont.bodyMedium())
                    .foregroundColor(VitesColor.onSurfaceVariant)

                statusRow
            }
            .frame(maxWidth: .infinity)
        }
    }

    @ViewBuilder private var statusRow: some View {
        switch agent.status {
        case .syncing(let label):
            statusPill(label: label, symbol: "arrow.triangle.2.circlepath", tint: .lavender)
        case .sniffing(let label):
            statusPill(label: label, symbol: "magnifyingglass", tint: .mint)
        case .napping:
            statusPill(label: "Napping", symbol: "moon.zzz.fill", tint: .blush)
        case .storing(let label):
            statusPill(label: label, symbol: "tray.full.fill", tint: .lavender)
        }
    }

    private func statusPill(label: String, symbol: String, tint: Niche.AccentTint) -> some View {
        HStack(spacing: 8) {
            Image(systemName: symbol)
                .font(.system(size: 12, weight: .bold))
            Text(label).font(VitesFont.labelBold())
        }
        .foregroundColor(pillFg(tint))
        .padding(.horizontal, 14).padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background(Capsule().fill(pillBg(tint)))
    }

    private func pillBg(_ t: Niche.AccentTint) -> Color {
        switch t {
        case .mint:     return VitesColor.secondaryContainer
        case .blush:    return VitesColor.tertiaryFixed
        case .lavender: return VitesColor.primaryFixed
        case .peach:    return Color(hex: 0xFFE0C2)
        case .alert:    return VitesColor.errorContainer
        }
    }
    private func pillFg(_ t: Niche.AccentTint) -> Color {
        switch t {
        case .mint:     return VitesColor.onSecondaryContainer
        case .blush:    return Color(hex: 0x5C3D51)
        case .lavender: return VitesColor.onPrimaryContainer
        case .peach:    return Color(hex: 0x7A4A1F)
        case .alert:    return VitesColor.onErrorContainer
        }
    }
}

#Preview { AgentsView().background(VitesColor.surface) }
