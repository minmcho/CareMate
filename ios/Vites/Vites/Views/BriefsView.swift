import SwiftUI

struct BriefsView: View {
    @State private var selectedTab: Tab = .audience
    @State private var brief = Brief.sample

    enum Tab: String, CaseIterable { case audience = "Audience Profile", format = "Format Patterns" }

    var body: some View {
        VitesScreen {
            VStack(alignment: .leading, spacing: VitesSpace.lg) {
                header
                tabSwitcher
                profileCard
                formatPattern(title: brief.hookFormat, detail: brief.hookDetail, symbol: "play.circle.fill", tint: .blush)
                formatPattern(title: "The Reveal",     detail: brief.revealDetail, symbol: "sparkles", tint: .lavender)
                formatPattern(title: "CTA Pattern",    detail: brief.ctaPattern, symbol: "heart.fill",  tint: .mint)
                currentBriefCard
            }
            .padding(.horizontal, VitesSpace.containerMargin)
            .padding(.bottom, VitesSpace.section)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                VitesChip(label: brief.niche, style: .mint)
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 14))
                    .foregroundColor(VitesColor.secondary)
            }
            Text(brief.title)
                .font(VitesFont.headlineLarge())
                .foregroundColor(VitesColor.onSurface)
                .fixedSize(horizontal: false, vertical: true)
            Text(brief.summary)
                .font(VitesFont.bodyMedium())
                .foregroundColor(VitesColor.onSurfaceVariant)
                .lineSpacing(2)
            VitesPrimaryButton(title: "Update Brief", icon: "arrow.triangle.2.circlepath") {}
                .padding(.top, 4)
        }
    }

    private var tabSwitcher: some View {
        HStack(spacing: 0) {
            ForEach(Tab.allCases, id: \.self) { t in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = t
                    }
                } label: {
                    Text(t.rawValue)
                        .font(VitesFont.labelBold())
                        .foregroundColor(t == selectedTab ? VitesColor.onPrimary : VitesColor.primary)
                        .padding(.horizontal, 16).padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(
                            Capsule().fill(t == selectedTab ? VitesColor.primary : VitesColor.surfaceContainerLowest)
                        )
                }
                .buttonStyle(BouncyButtonStyle())
            }
        }
        .padding(4)
        .background(
            Capsule().fill(VitesColor.surfaceContainer)
        )
    }

    private var profileCard: some View {
        VitesCard(background: VitesColor.surfaceContainerLowest, padding: 18) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    HStack(spacing: 6) {
                        VitesMascot(symbol: "person.3.fill", tint: .lavender, size: 40, floats: false)
                        Image(systemName: "person.3.fill")
                            .font(.system(size: 12))
                            .foregroundColor(VitesColor.onPrimaryContainer)
                    }
                    Spacer()
                    Text("The\nSystems-\nSeeker")
                        .multilineTextAlignment(.center)
                        .font(VitesFont.headlineMedium())
                        .foregroundColor(VitesColor.primary)
                    Spacer()
                    VStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .foregroundColor(VitesColor.error)
                        Text("HIGH\nINTENT")
                            .multilineTextAlignment(.center)
                            .font(VitesFont.caption())
                            .foregroundColor(VitesColor.onErrorContainer)
                    }
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(VitesColor.errorContainer)
                    )
                }
                .padding(.bottom, 4)

                painPointsBlock
                outcomesBlock
            }
        }
    }

    private var painPointsBlock: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "xmark.octagon.fill")
                    .foregroundColor(VitesColor.error)
                Text("Pain Points")
                    .font(VitesFont.labelBold())
                    .foregroundColor(VitesColor.onErrorContainer)
            }
            ForEach(brief.painPoints, id: \.self) { p in
                HStack(spacing: 8) {
                    Image(systemName: "xmark").foregroundColor(VitesColor.error)
                    Text(p).font(VitesFont.bodyMedium()).foregroundColor(VitesColor.onSurface)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(VitesColor.errorContainer.opacity(0.5))
        )
    }

    private var outcomesBlock: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundColor(VitesColor.secondary)
                Text("Desired Outcome")
                    .font(VitesFont.labelBold())
                    .foregroundColor(VitesColor.onSecondaryContainer)
            }
            ForEach(brief.desiredOutcomes, id: \.self) { o in
                HStack(spacing: 8) {
                    Image(systemName: "checkmark").foregroundColor(VitesColor.secondary)
                    Text(o).font(VitesFont.bodyMedium()).foregroundColor(VitesColor.onSurface)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(VitesColor.secondaryContainer.opacity(0.5))
        )
    }

    private func formatPattern(title: String, detail: String, symbol: String, tint: Niche.AccentTint) -> some View {
        VitesCard(background: VitesColor.surfaceContainerLowest, padding: 16) {
            HStack(alignment: .top, spacing: 12) {
                VitesMascot(symbol: symbol, tint: tint, size: 40, floats: false)
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(VitesFont.title())
                        .foregroundColor(VitesColor.onSurface)
                    Text(detail)
                        .font(VitesFont.bodyMedium())
                        .foregroundColor(VitesColor.onSurfaceVariant)
                        .lineSpacing(2)
                }
                Spacer(minLength: 0)
            }
        }
    }

    private var currentBriefCard: some View {
        VitesCard(background: VitesColor.surfaceContainerLow, padding: 20, radius: VitesRadius.md) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("Current Brief")
                        .font(VitesFont.headlineMedium())
                        .foregroundColor(VitesColor.onSurface)
                    Spacer()
                    VitesChip(label: "AI GENERATED", icon: "sparkles", style: .lavender)
                }
                briefRow(symbol: "target", title: "GOAL", text: brief.goal, tint: .mint)
                briefRow(symbol: "paintpalette.fill", title: "VISUAL STYLE", text: brief.visualStyle, tint: .lavender)
                Text("“\(brief.storyboard)”")
                    .font(VitesFont.bodyMedium().italic())
                    .foregroundColor(VitesColor.onPrimaryContainer)
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(VitesColor.primaryFixed.opacity(0.7))
                    )
                HStack(spacing: 10) {
                    VitesPrimaryButton(title: "Copy Brief", icon: "doc.on.doc.fill") {}
                        .frame(maxWidth: .infinity)
                    VitesSecondaryButton(title: "Request Revision", icon: "arrow.triangle.2.circlepath") {}
                        .frame(maxWidth: .infinity)
                }
                placeholderPreview
                    .padding(.top, 6)
            }
        }
    }

    private func briefRow(symbol: String, title: String, text: String, tint: Niche.AccentTint) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: symbol).foregroundColor(VitesColor.secondary)
                Text(title)
                    .font(VitesFont.labelBold())
                    .foregroundColor(VitesColor.onSurfaceVariant)
                    .tracking(0.6)
            }
            Text(text)
                .font(VitesFont.bodyMedium())
                .foregroundColor(VitesColor.onSurface)
                .lineSpacing(2)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(tint == .mint ? VitesColor.secondaryContainer.opacity(0.4)
                      : VitesColor.primaryFixed.opacity(0.6))
        )
    }

    private var placeholderPreview: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(LinearGradient(
                colors: [Color(hex: 0xE6EEFF), Color(hex: 0xCEBDFF).opacity(0.7)],
                startPoint: .topLeading, endPoint: .bottomTrailing))
            .frame(height: 140)
            .overlay(
                Image(systemName: "laptopcomputer")
                    .font(.system(size: 36))
                    .foregroundColor(VitesColor.onPrimaryContainer.opacity(0.8))
            )
    }
}

#Preview { BriefsView().background(VitesColor.surface) }
