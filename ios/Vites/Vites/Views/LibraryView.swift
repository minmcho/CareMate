import SwiftUI

struct LibraryView: View {
    @State private var search = ""
    @State private var bundles = LibraryBundle.sample
    @State private var typeFilter = "All Types"
    @State private var sortKey   = "Recent"

    var body: some View {
        VitesScreen {
            VStack(alignment: .leading, spacing: VitesSpace.lg) {
                header
                searchField
                filterRow
                ForEach(bundles) { bundle in
                    BundleCard(bundle: bundle)
                }
            }
            .padding(.horizontal, VitesSpace.containerMargin)
            .padding(.bottom, VitesSpace.section)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Library")
                .font(VitesFont.headlineLarge())
                .foregroundColor(VitesColor.primary)
            Text("Access your verified multi-agent content bundles.")
                .font(VitesFont.bodyMedium())
                .foregroundColor(VitesColor.onSurfaceVariant)
        }
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(VitesColor.onSurfaceVariant)
            TextField("Search bundles...", text: $search)
                .font(VitesFont.bodyMedium())
        }
        .padding(.horizontal, 16).padding(.vertical, 14)
        .background(Capsule().fill(VitesColor.surfaceContainerLowest))
        .overlay(Capsule().strokeBorder(VitesColor.outlineVariant.opacity(0.6), lineWidth: 1))
    }

    private var filterRow: some View {
        HStack(spacing: 10) {
            filterChip(label: typeFilter, icon: "line.3.horizontal.decrease", selected: true)
            filterChip(label: sortKey, icon: "arrow.up.arrow.down", selected: false)
            Spacer()
        }
    }

    private func filterChip(label: String, icon: String, selected: Bool) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .bold))
            Text(label).font(VitesFont.labelBold())
        }
        .foregroundColor(selected ? VitesColor.onPrimaryContainer : VitesColor.onSurfaceVariant)
        .padding(.horizontal, 14).padding(.vertical, 10)
        .background(
            Capsule().fill(selected ? VitesColor.primaryFixed : VitesColor.surfaceContainerLowest)
        )
        .overlay(
            Capsule().strokeBorder(VitesColor.outlineVariant.opacity(selected ? 0 : 0.5), lineWidth: 1)
        )
    }
}

// MARK: - Bundle card

private struct BundleCard: View {
    let bundle: LibraryBundle

    var body: some View {
        VitesCard(background: VitesColor.surfaceContainerLowest, padding: 18) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 12) {
                    VitesMascot(symbol: bundle.mascotSymbol, tint: bundle.accent, size: 56, floats: false)
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Text(bundle.title)
                                .font(VitesFont.headlineMedium())
                                .foregroundColor(VitesColor.onSurface)
                            Spacer()
                            if bundle.released {
                                VitesChip(label: "RELEASED", icon: "pawprint.fill", style: .mint)
                            }
                        }
                        Text("\(bundle.mascot) · \(bundle.assets) Assets")
                            .font(VitesFont.bodyMedium())
                            .foregroundColor(VitesColor.onSurfaceVariant)
                    }
                }

                ledgerRow

                HStack(spacing: 10) {
                    metaCell(label: "ORIGIN",   value: bundle.origin.rawValue)
                    metaCell(label: "REVIEWER", value: bundle.reviewer.rawValue)
                }

                HStack(spacing: 12) {
                    avatarStrip
                    Spacer()
                    Button(action: {}) {
                        Text("Open")
                            .font(VitesFont.labelBold())
                            .foregroundColor(.white)
                            .padding(.horizontal, 22).padding(.vertical, 10)
                            .background(Capsule().fill(VitesColor.primary))
                    }
                    .buttonStyle(BouncyButtonStyle())
                }
            }
        }
    }

    private var ledgerRow: some View {
        HStack(spacing: 8) {
            Image(systemName: "circles.hexagongrid.fill")
                .foregroundColor(VitesColor.onSurfaceVariant)
            Text("LEDGER ID")
                .font(VitesFont.caption())
                .tracking(0.6)
                .foregroundColor(VitesColor.onSurfaceVariant)
            Spacer()
            Text(bundle.ledgerId)
                .font(VitesFont.labelBold())
                .foregroundColor(VitesColor.primary)
                .padding(.horizontal, 10).padding(.vertical, 4)
                .background(Capsule().fill(VitesColor.primaryFixed))
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(VitesColor.surfaceContainerLow)
        )
    }

    private func metaCell(label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(VitesFont.caption())
                .foregroundColor(VitesColor.onSurfaceVariant)
                .tracking(0.6)
            Text(value)
                .font(VitesFont.labelBold())
                .foregroundColor(VitesColor.onSurface)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(VitesColor.surfaceContainerLow)
        )
    }

    private var avatarStrip: some View {
        HStack(spacing: -10) {
            ForEach(0..<min(2, max(1, bundle.assets / 3)), id: \.self) { i in
                Circle()
                    .fill(i == 0 ? VitesColor.tertiaryFixedDim : VitesColor.secondaryContainer)
                    .frame(width: 28, height: 28)
                    .overlay(Circle().strokeBorder(VitesColor.surfaceContainerLowest, lineWidth: 2))
            }
            if bundle.extraCount > 0 {
                Text("+\(bundle.extraCount)")
                    .font(VitesFont.caption().bold())
                    .foregroundColor(VitesColor.onPrimaryContainer)
                    .frame(width: 28, height: 28)
                    .background(Circle().fill(VitesColor.primaryFixed))
                    .overlay(Circle().strokeBorder(VitesColor.surfaceContainerLowest, lineWidth: 2))
            }
        }
    }
}

#Preview { LibraryView().background(VitesColor.surface) }
