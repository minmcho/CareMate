import SwiftUI

struct ReviewView: View {
    @State private var items = ReviewItem.sample

    var body: some View {
        VitesScreen {
            VStack(alignment: .leading, spacing: VitesSpace.lg) {
                header
                ForEach(items) { item in
                    ReviewCard(item: item)
                }
            }
            .padding(.horizontal, VitesSpace.containerMargin)
            .padding(.bottom, VitesSpace.section)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            VitesChip(label: "WORKSPACE", style: .lavender)
            Text("Content Review\nQueue")
                .font(VitesFont.headlineLarge())
                .foregroundColor(VitesColor.onSurface)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
            Text("Audit your team's content drafts before publication.")
                .font(VitesFont.bodyMedium())
                .foregroundColor(VitesColor.onSurfaceVariant)
        }
    }
}

private struct ReviewCard: View {
    let item: ReviewItem

    var body: some View {
        VitesCard(background: cardBackground, padding: 18) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    VitesChip(label: item.tag, style: .lavender)
                    Spacer()
                    Text(item.age)
                        .font(VitesFont.caption())
                        .foregroundColor(VitesColor.onSurfaceVariant)
                    Image(systemName: "ellipsis")
                        .foregroundColor(VitesColor.onSurfaceVariant)
                        .padding(.leading, 4)
                }

                if item.status == .articlePreview {
                    articlePreview
                }

                Text(item.title)
                    .font(VitesFont.headlineMedium())
                    .foregroundColor(VitesColor.onSurface)
                    .fixedSize(horizontal: false, vertical: true)

                Text(item.summary)
                    .font(VitesFont.bodyMedium())
                    .foregroundColor(VitesColor.onSurfaceVariant)
                    .lineSpacing(2)

                verifierStrip

                if !item.issues.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.octagon.fill")
                            .foregroundColor(VitesColor.error)
                        Text(item.issues.joined(separator: " • "))
                            .font(VitesFont.caption())
                            .foregroundColor(VitesColor.onErrorContainer)
                    }
                }
                if let s = item.originalityScore {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(VitesColor.secondary)
                        Text("\(s)% Originality scoring")
                            .font(VitesFont.caption())
                            .foregroundColor(VitesColor.onSecondaryContainer)
                    }
                }

                actionRow
            }
        }
    }

    private var cardBackground: Color {
        switch item.status {
        case .signOffReady:   return Color(hex: 0xEAF7EE)
        case .articlePreview: return VitesColor.surfaceContainerLowest
        case .draft:          return VitesColor.surfaceContainerLowest
        }
    }

    private var verifierStrip: some View {
        HStack(spacing: 10) {
            verifierBadge(label: "CLAIMS",   passed: item.verifiers.claims,
                          passSymbol: "doc.text.fill", failSymbol: "doc.text")
            verifierBadge(label: "FACTS",    passed: item.verifiers.facts,
                          passSymbol: "checkmark.seal.fill", failSymbol: "questionmark.circle.fill")
            verifierBadge(label: "ORIGINAL", passed: item.verifiers.original,
                          passSymbol: "sparkles", failSymbol: "exclamationmark.triangle.fill")
        }
    }

    private func verifierBadge(label: String, passed: Bool, passSymbol: String, failSymbol: String) -> some View {
        VStack(spacing: 4) {
            ZStack {
                Circle().fill(passed ? VitesColor.secondaryContainer : VitesColor.errorContainer)
                Image(systemName: passed ? passSymbol : failSymbol)
                    .foregroundColor(passed ? VitesColor.onSecondaryContainer : VitesColor.onErrorContainer)
                    .font(.system(size: 14, weight: .bold))
            }
            .frame(width: 36, height: 36)
            Text(label)
                .font(VitesFont.caption())
                .foregroundColor(VitesColor.onSurfaceVariant)
                .tracking(0.4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(VitesColor.surfaceContainerLow)
        )
    }

    @ViewBuilder private var actionRow: some View {
        switch item.status {
        case .draft:
            VitesSecondaryButton(title: "Review Details", icon: "arrow.right") {}
        case .signOffReady:
            VitesPrimaryButton(title: "Sign Off", icon: "checkmark.circle.fill") {}
        case .articlePreview:
            HStack(spacing: 10) {
                VitesSecondaryButton(title: "Edit Draft", icon: "square.and.pencil") {}
                VitesPrimaryButton(title: "Assign Reviewer", icon: "person.crop.circle.badge.plus") {}
            }
        }
    }

    private var articlePreview: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(LinearGradient(colors: [Color(hex: 0x27313F), Color(hex: 0x121C2A)],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(height: 150)
                .overlay(
                    Image(systemName: "rectangle.stack.fill.badge.plus")
                        .foregroundColor(VitesColor.primaryFixedDim.opacity(0.7))
                        .font(.system(size: 36))
                )
            Text("ARTICLE PREVIEW")
                .font(VitesFont.labelBold())
                .foregroundColor(VitesColor.surface)
                .padding(.horizontal, 10).padding(.vertical, 4)
                .background(Capsule().fill(Color.black.opacity(0.45)))
                .padding(12)
        }
    }
}

#Preview { ReviewView().background(VitesColor.surface) }
