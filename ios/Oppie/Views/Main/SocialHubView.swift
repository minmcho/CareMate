//
//  SocialHubView.swift
//  Oppie — Meet new friends, featured neighbors, events, groups.
//

import SwiftUI

struct SocialHubView: View {
    private struct Neighbor: Identifiable {
        let id = UUID()
        let name: String
        let bio: String
        let initial: String
        let bg: Color
    }
    private struct EventInfo: Identifiable {
        let id = UUID()
        let badge: String
        let title: String
        let time: String
        let icon: MaterialIcon
        let accent: Color
        let badgeBg: Color
        let badgeFg: Color
    }
    private struct Group: Identifiable {
        let id = UUID()
        let name: String
        let count: String
        let icon: MaterialIcon
        let bg: Color
        let tint: Color
    }

    private let neighbors: [Neighbor] = [
        .init(name: "Evelyn", bio: "Loves knitting and classical music",
              initial: "E", bg: OppieColor.secondaryFixed),
        .init(name: "Arthur", bio: "Chess player and history enthusiast",
              initial: "A", bg: OppieColor.tertiaryFixed)
    ]

    private let events: [EventInfo] = [
        .init(badge: "TOMORROW", title: "Morning Choir", time: "10:00 AM",
              icon: .musicNote, accent: OppieColor.primary,
              badgeBg: OppieColor.primaryContainer, badgeFg: OppieColor.onPrimaryContainer),
        .init(badge: "SAT, OCT 12", title: "Gardening Club", time: "02:30 PM",
              icon: .potted, accent: OppieColor.safetyGreen,
              badgeBg: OppieColor.secondaryFixed, badgeFg: OppieColor.onSecondaryFixed)
    ]

    private let groups: [Group] = [
        .init(name: "Book Enthusiasts", count: "12 members active",
              icon: .menuBook, bg: OppieColor.primaryFixed, tint: OppieColor.primary),
        .init(name: "Sunday Brunch Circle", count: "5 members active",
              icon: .restaurant, bg: OppieColor.tertiaryFixed, tint: OppieColor.tertiary)
    ]

    var body: some View {
        VStack(spacing: 0) {
            OppieTopBar()

            ScrollView {
                VStack(spacing: OppieSpacing.stackLg) {
                    introSection
                    featuredSection
                    eventsSection
                    groupsSection
                    Color.clear.frame(height: 110)
                }
                .padding(.horizontal, OppieSpacing.marginMobile)
                .padding(.top, OppieSpacing.stackLg)
            }
            .background(OppieColor.background)
        }
    }

    private var introSection: some View {
        VStack(spacing: 12) {
            ZStack(alignment: .topTrailing) {
                OppieMascot(size: 130)
                Text("New!")
                    .font(OppieFont.labelLarge())
                    .foregroundStyle(OppieColor.onPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(OppieColor.primary))
                    .oppieSoftShadow()
                    .offset(x: 10, y: -8)
            }
            Text("Meet New Friends")
                .font(OppieFont.displayLarge())
                .foregroundStyle(OppieColor.primary)
            Text("It's a beautiful day to connect with people who share your passions.")
                .font(OppieFont.bodyLarge())
                .foregroundStyle(OppieColor.onSurfaceVariant)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 360)
        }
    }

    private var featuredSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Featured Neighbors")
                .font(OppieFont.headlineMedium())
                .padding(.leading, 4)

            ForEach(neighbors) { n in
                neighborCard(n)
            }
        }
    }

    private func neighborCard(_ n: Neighbor) -> some View {
        HStack(spacing: 18) {
            ZStack {
                Circle()
                    .fill(n.bg)
                    .overlay(Circle().stroke(.white, lineWidth: 4))
                    .oppieSoftShadow()
                Text(n.initial)
                    .font(OppieFont.headlineLarge())
                    .foregroundStyle(OppieColor.onSurface)
            }
            .frame(width: 88, height: 88)

            VStack(alignment: .leading, spacing: 8) {
                Text(n.name).font(OppieFont.headlineMedium())
                Text(n.bio)
                    .font(OppieFont.bodyMedium())
                    .foregroundStyle(OppieColor.onSurfaceVariant)
                Button { } label: {
                    HStack(spacing: 8) {
                        OppieIcon(.chatBubble, size: 18, weight: .semibold)
                        Text("Say Hello").font(OppieFont.labelLarge())
                    }
                    .foregroundStyle(OppieColor.onPrimary)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(OppieColor.primary))
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
            }
            Spacer()
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: OppieRadius.large, style: .continuous)
                .fill(OppieColor.surfaceContainer)
                .overlay(
                    RoundedRectangle(cornerRadius: OppieRadius.large, style: .continuous)
                        .stroke(OppieColor.outlineVariant, lineWidth: 1)
                )
        )
        .oppieSoftShadow()
    }

    private var eventsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Upcoming Events", trailing: "See All")
            LazyVGrid(columns: [GridItem(.flexible(), spacing: OppieSpacing.gutter),
                                GridItem(.flexible(), spacing: OppieSpacing.gutter)],
                      spacing: OppieSpacing.gutter) {
                ForEach(events) { e in
                    eventCard(e)
                }
            }
        }
    }

    private func eventCard(_ e: EventInfo) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(e.badge)
                    .font(OppieFont.labelSmall())
                    .tracking(1.2)
                    .padding(.horizontal, 10).padding(.vertical, 4)
                    .background(RoundedRectangle(cornerRadius: 6, style: .continuous).fill(e.badgeBg))
                    .foregroundStyle(e.badgeFg)
                Spacer()
                OppieIcon(e.icon, size: 22, weight: .semibold)
                    .foregroundStyle(e.accent)
            }
            Text(e.title).font(OppieFont.headlineMedium())
            HStack(spacing: 6) {
                OppieIcon(.schedule, size: 16, weight: .semibold)
                Text(e.time)
            }
            .font(OppieFont.bodyMedium())
            .foregroundStyle(OppieColor.onSurfaceVariant)
            Spacer(minLength: 4)
            Button { } label: {
                Text("Join Event")
                    .font(OppieFont.labelLarge())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .foregroundStyle(OppieColor.primary)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(OppieColor.primary, lineWidth: 2)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: OppieRadius.large, style: .continuous)
                .fill(OppieColor.surfaceContainerHigh)
                .overlay(
                    VStack(spacing: 0) {
                        Spacer()
                        Rectangle().fill(e.accent).frame(height: 4)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: OppieRadius.large, style: .continuous))
                )
        )
    }

    private var groupsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("My Groups")
                .font(OppieFont.headlineMedium())
                .padding(.leading, 4)
            ForEach(groups) { g in
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14, style: .continuous).fill(g.bg)
                        OppieIcon(g.icon, size: 24, weight: .semibold).foregroundStyle(g.tint)
                    }
                    .frame(width: 56, height: 56)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(g.name).font(OppieFont.labelLarge())
                        Text(g.count).font(OppieFont.bodyMedium()).foregroundStyle(OppieColor.onSurfaceVariant)
                    }
                    Spacer()
                    OppieIcon(.chevronRight, size: 22, weight: .semibold)
                        .foregroundStyle(OppieColor.onSurfaceVariant)
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(OppieColor.outlineVariant, lineWidth: 1)
                        )
                )
            }
        }
    }
}

#Preview { SocialHubView() }
