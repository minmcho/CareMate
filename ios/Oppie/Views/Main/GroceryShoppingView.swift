//
//  GroceryShoppingView.swift
//  Oppie — voice grocery shopping with essentials and healthy suggestions.
//

import SwiftUI

struct GroceryShoppingView: View {
    private struct Essential: Identifiable {
        let id = UUID()
        let name: String
        let icon: MaterialIcon
    }
    private let essentials: [Essential] = [
        .init(name: "Milk",  icon: .glassCup),
        .init(name: "Bread", icon: .bakeryDining),
        .init(name: "Eggs",  icon: .egg)
    ]

    var body: some View {
        VStack(spacing: 0) {
            OppieTopBar()
            ScrollView {
                VStack(spacing: OppieSpacing.stackLg) {
                    voiceCard
                    essentialsSection
                    healthySuggestions
                    Color.clear.frame(height: 200)
                }
                .padding(.horizontal, OppieSpacing.marginMobile)
                .padding(.top, OppieSpacing.stackMd)
            }
            .background(OppieColor.background)
        }
        .overlay(alignment: .bottom) {
            checkoutBar
                .padding(.horizontal, OppieSpacing.marginMobile)
                .padding(.bottom, 110)
        }
    }

    private var voiceCard: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle().fill(OppieColor.onPrimaryContainer)
                OppieIcon(.mic, size: 30, weight: .bold).foregroundStyle(OppieColor.primary)
            }
            .frame(width: 72, height: 72)

            VStack(alignment: .leading, spacing: 4) {
                Text("Tap to Speak").font(OppieFont.headlineMedium())
                Text("\"Add eggs and whole wheat bread\"")
                    .font(OppieFont.bodyMedium())
                    .opacity(0.95)
            }
            Spacer()
        }
        .foregroundStyle(OppieColor.onPrimaryContainer)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: OppieRadius.large, style: .continuous)
                .fill(OppieColor.primaryContainer)
        )
        .oppieElevatedShadow()
    }

    private var essentialsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Essentials").font(OppieFont.headlineMedium()).padding(.leading, 4)
            LazyVGrid(columns: [GridItem(.flexible(), spacing: OppieSpacing.gutter),
                                GridItem(.flexible(), spacing: OppieSpacing.gutter)],
                      spacing: OppieSpacing.gutter) {
                ForEach(essentials) { e in
                    essentialCard(e)
                }
                addMoreCard
            }
        }
    }

    private func essentialCard(_ e: GroceryShoppingView.Essential) -> some View {
        VStack(spacing: 10) {
            OppieIcon(e.icon, size: 44, weight: .regular).foregroundStyle(OppieColor.primary)
            Text(e.name).font(OppieFont.headlineMedium())
            Button { } label: {
                Text("Add")
                    .font(OppieFont.labelLarge())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .foregroundStyle(OppieColor.onPrimary)
                    .background(Capsule().fill(OppieColor.primary))
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: OppieRadius.large, style: .continuous)
                .fill(OppieColor.surfaceContainerLow)
        )
        .oppieElevatedShadow()
    }

    private var addMoreCard: some View {
        VStack(spacing: 10) {
            OppieIcon(.add, size: 30, weight: .semibold).foregroundStyle(OppieColor.onSurfaceVariant)
            Text("View All Essentials")
                .font(OppieFont.labelLarge())
                .foregroundStyle(OppieColor.onSurfaceVariant)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 150)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: OppieRadius.large, style: .continuous)
                .fill(OppieColor.surfaceContainerLow)
                .overlay(
                    RoundedRectangle(cornerRadius: OppieRadius.large, style: .continuous)
                        .strokeBorder(OppieColor.outlineVariant, style: StrokeStyle(lineWidth: 2, dash: [6, 6]))
                )
        )
    }

    private var healthySuggestions: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                OppieIcon(.heartFavorite, size: 22, weight: .bold).foregroundStyle(OppieColor.safetyGreen)
                Text("Healthy Suggestions").font(OppieFont.headlineMedium())
            }
            .padding(.leading, 4)

            VStack(spacing: OppieSpacing.gutter) {
                healthyTip(icon: .nutrition, color: .orange,
                           title: "Fresh Spinach", subtitle: "Good for heart health")
                healthyTip(icon: .waterDrop, color: OppieColor.healthBlue,
                           title: "Sparkling Water", subtitle: "Sugar-free choice")
            }
        }
    }

    private func healthyTip(icon: MaterialIcon, color: Color, title: String, subtitle: String) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous).fill(.white)
                OppieIcon(icon, size: 30, weight: .semibold).foregroundStyle(color)
            }
            .frame(width: 60, height: 60)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(OppieFont.headlineMedium())
                Text(subtitle).font(OppieFont.bodyMedium()).foregroundStyle(OppieColor.onSurfaceVariant)
            }
            Spacer()
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: OppieRadius.large, style: .continuous)
                .fill(OppieColor.surfaceContainerHigh)
        )
        .oppieElevatedShadow()
    }

    private var checkoutBar: some View {
        Button { } label: {
            HStack {
                HStack(spacing: 14) {
                    OppieIcon(.shoppingCartCheckout, size: 28, weight: .bold)
                    Text("Checkout").font(OppieFont.headlineLarge())
                }
                Spacer()
                Text("$24.50").font(OppieFont.headlineLarge())
            }
            .foregroundStyle(OppieColor.onSecondary)
            .padding(.horizontal, 24)
            .padding(.vertical, 22)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: OppieRadius.large, style: .continuous)
                    .fill(OppieColor.secondary)
            )
            .oppieElevatedShadow()
        }
        .buttonStyle(.plain)
    }
}

#Preview { GroceryShoppingView() }
