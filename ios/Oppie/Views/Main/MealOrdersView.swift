//
//  MealOrdersView.swift
//  Oppie — voice-driven meal ordering with specials and recent orders.
//

import SwiftUI

struct MealOrdersView: View {
    private struct Meal: Identifiable {
        let id = UUID()
        let title: String
        let subtitle: String
        let icon: MaterialIcon
        let bg: Color
    }

    private let secondaries: [Meal] = [
        .init(title: "Garden Soup", subtitle: "Comforting · Daily", icon: .restaurant, bg: OppieColor.tertiaryFixed),
        .init(title: "House Salad", subtitle: "Fresh greens", icon: .restaurant, bg: OppieColor.safetyGreen.opacity(0.25))
    ]
    private let recents: [Meal] = [
        .init(title: "Grilled Chicken Salad", subtitle: "Last ordered Monday",
              icon: .restaurant, bg: OppieColor.surfaceContainer),
        .init(title: "Veggie Flatbread", subtitle: "Last ordered Friday",
              icon: .restaurant, bg: OppieColor.surfaceContainer)
    ]

    var body: some View {
        VStack(spacing: 0) {
            OppieTopBar()
            ScrollView {
                VStack(alignment: .leading, spacing: OppieSpacing.stackLg) {
                    greeting
                    voiceZone
                    todaysSpecials
                    recentOrders
                    Color.clear.frame(height: 110)
                }
                .padding(.horizontal, OppieSpacing.marginMobile)
                .padding(.top, OppieSpacing.stackMd)
            }
            .background(OppieColor.background)
        }
    }

    private var greeting: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Good morning!")
                .font(OppieFont.displayLarge())
            Text("What can I help you order today?")
                .font(OppieFont.bodyLarge())
                .foregroundStyle(OppieColor.onSurfaceVariant)
        }
    }

    private var voiceZone: some View {
        VStack(spacing: 14) {
            Text("\"Oppie, I'd like a salad\"")
                .font(OppieFont.headlineMedium())
            Button { } label: {
                ZStack {
                    Circle().fill(OppieColor.surface).oppieElevatedShadow()
                    OppieIcon(.mic, size: 40, weight: .bold).foregroundStyle(OppieColor.primary)
                }
                .frame(width: 96, height: 96)
            }
            .buttonStyle(.plain)
            Text("TAP TO SPEAK")
                .font(OppieFont.labelLarge())
                .tracking(2.0)
                .opacity(0.9)
        }
        .foregroundStyle(OppieColor.onPrimaryContainer)
        .frame(maxWidth: .infinity)
        .padding(28)
        .background(
            RoundedRectangle(cornerRadius: OppieRadius.large, style: .continuous)
                .fill(OppieColor.primaryContainer)
        )
        .oppieElevatedShadow()
    }

    private var todaysSpecials: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Today's Specials", trailing: "View All")

            // Hero special
            ZStack(alignment: .bottomLeading) {
                LinearGradient(colors: [OppieColor.tertiary, OppieColor.secondary],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
                    .frame(height: 240)
                LinearGradient(colors: [.black.opacity(0.7), .clear],
                               startPoint: .bottom, endPoint: .top)
                    .frame(height: 240)

                VStack(alignment: .leading, spacing: 10) {
                    Text("Roasted Salmon Bowl")
                        .font(OppieFont.headlineMedium())
                        .foregroundStyle(.white)
                    Text("Heart-healthy and fresh")
                        .font(OppieFont.bodyMedium())
                        .foregroundStyle(.white.opacity(0.9))
                    Button { } label: {
                        Text("Order Now")
                            .font(OppieFont.labelLarge())
                            .padding(.horizontal, 24).padding(.vertical, 10)
                            .background(Capsule().fill(OppieColor.secondaryContainer))
                            .foregroundStyle(OppieColor.onSecondaryContainer)
                            .oppieSoftShadow()
                    }
                    .buttonStyle(.plain)
                }
                .padding(20)
            }
            .clipShape(RoundedRectangle(cornerRadius: OppieRadius.large, style: .continuous))
            .oppieSoftShadow()

            LazyVGrid(columns: [GridItem(.flexible(), spacing: OppieSpacing.gutter),
                                GridItem(.flexible(), spacing: OppieSpacing.gutter)],
                      spacing: OppieSpacing.gutter) {
                ForEach(secondaries) { m in
                    secondaryMealCard(m)
                }
            }
        }
    }

    private func secondaryMealCard(_ m: Meal) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous).fill(m.bg)
                    .frame(height: 110)
                OppieIcon(m.icon, size: 38, weight: .bold)
                    .foregroundStyle(OppieColor.onSurface.opacity(0.4))
            }
            Text(m.title).font(OppieFont.labelLarge())
            Button { } label: {
                Text("Add")
                    .font(OppieFont.labelLarge())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .foregroundStyle(OppieColor.primary)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(OppieColor.primary, lineWidth: 2)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: OppieRadius.large, style: .continuous)
                .fill(OppieColor.surfaceContainerHigh)
        )
        .oppieSoftShadow()
    }

    private var recentOrders: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Recently Ordered")
                .font(OppieFont.headlineMedium())
                .padding(.leading, 4)
            VStack(spacing: 12) {
                ForEach(recents) { m in
                    HStack(spacing: 14) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12, style: .continuous).fill(m.bg)
                            OppieIcon(m.icon, size: 24, weight: .semibold)
                                .foregroundStyle(OppieColor.onSurface.opacity(0.5))
                        }
                        .frame(width: 64, height: 64)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(m.title).font(OppieFont.labelLarge())
                            Text(m.subtitle).font(OppieFont.bodyMedium())
                                .foregroundStyle(OppieColor.onSurfaceVariant)
                        }
                        Spacer()
                        Button { } label: {
                            OppieIcon(.addShoppingCart, size: 20, weight: .bold)
                                .foregroundStyle(OppieColor.primary)
                                .padding(10)
                                .background(Circle().fill(OppieColor.primaryFixed))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(OppieColor.surfaceContainerLow)
                    )
                    .oppieSoftShadow()
                }
            }
        }
    }
}

#Preview { MealOrdersView() }
