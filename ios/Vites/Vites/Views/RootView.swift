import SwiftUI
import UIKit

enum VitesTab: String, CaseIterable, Identifiable {
    case discover, briefs, review, agents, library
    var id: String { rawValue }

    var label: String {
        switch self {
        case .discover: return "Discover"
        case .briefs:   return "Briefs"
        case .review:   return "Review"
        case .agents:   return "Agents"
        case .library:  return "Library"
        }
    }

    var symbol: String {
        switch self {
        case .discover: return "compass.drawing"
        case .briefs:   return "doc.text.fill"
        case .review:   return "checkmark.square.fill"
        case .agents:   return "person.2.fill"
        case .library:  return "books.vertical.fill"
        }
    }
}

struct RootView: View {
    @State private var selected: VitesTab = .discover

    var body: some View {
        ZStack(alignment: .bottom) {
            content
                .padding(.bottom, 80)   // leave room for the floating tab bar
            VitesTabBar(selected: $selected)
                .padding(.horizontal, 12)
                .padding(.bottom, 8)
        }
        .background(VitesColor.surface.ignoresSafeArea())
        .preferredColorScheme(.light)
    }

    @ViewBuilder private var content: some View {
        switch selected {
        case .discover: DiscoverView()
        case .briefs:   BriefsView()
        case .review:   ReviewView()
        case .agents:   AgentsView()
        case .library:  LibraryView()
        }
    }
}

// MARK: - Tab bar

struct VitesTabBar: View {
    @Binding var selected: VitesTab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(VitesTab.allCases) { tab in
                Button {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.65)) {
                        selected = tab
                    }
                    UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                } label: {
                    VStack(spacing: 4) {
                        ZStack {
                            if selected == tab {
                                Circle()
                                    .fill(VitesColor.primary)
                                    .frame(width: 38, height: 38)
                                    .vitesAmbientShadow()
                            }
                            Image(systemName: tab.symbol)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(selected == tab ? .white : VitesColor.onSurfaceVariant)
                        }
                        .frame(height: 38)
                        Text(tab.label)
                            .font(VitesFont.caption())
                            .foregroundColor(selected == tab ? VitesColor.primary : VitesColor.onSurfaceVariant)
                    }
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                }
                .buttonStyle(BouncyButtonStyle())
                .accessibilityLabel(tab.label)
                .accessibilityAddTraits(selected == tab ? .isSelected : [])
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .strokeBorder(VitesColor.outlineVariant.opacity(0.4), lineWidth: 1)
        )
        .vitesAmbientShadow(level: 2)
    }
}

#Preview { RootView() }
