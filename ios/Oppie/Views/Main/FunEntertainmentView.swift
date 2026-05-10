//
//  FunEntertainmentView.swift
//  Oppie — Brain training, music & radio, video & shows, hobbies & learning.
//

import SwiftUI

struct FunEntertainmentView: View {
    private struct MediaItem: Identifiable {
        let id = UUID()
        let title: String
        let subtitle: String
        let icon: MaterialIcon
        let bg: Color
        let trailing: MaterialIcon
        let trailingColor: Color
    }
    private struct VideoItem: Identifiable {
        let id = UUID()
        let title: String
        let detail: String
        let badge: String?
        let cta: String
        let bg: Color
        let icon: MaterialIcon
    }
    private struct Hobby: Identifiable {
        let id = UUID()
        let title: String
        let detail: String
        let icon: MaterialIcon
        let tint: Color
        let bg: Color
    }

    private let media: [MediaItem] = [
        .init(title: "Relaxing Jazz", subtitle: "24 Songs · 1h 45m",
              icon: .musicNote, bg: OppieColor.secondaryFixed,
              trailing: .playCircle, trailingColor: OppieColor.primary),
        .init(title: "Classic Hits", subtitle: "Radio Station",
              icon: .radio, bg: OppieColor.tertiaryFixed,
              trailing: .radio, trailingColor: OppieColor.primary),
        .init(title: "News Updates", subtitle: "Live Broadcast",
              icon: .sensors, bg: OppieColor.outlineVariant,
              trailing: .sensors, trailingColor: OppieColor.scamAlertRed)
    ]

    private let videos: [VideoItem] = [
        .init(title: "Senior Zumba Flow", detail: "Starts in 15 mins",
              badge: "LIVE", cta: "Remind Me",
              bg: OppieColor.secondaryFixedDim, icon: .exercise),
        .init(title: "Gentle Morning Yoga", detail: "45 mins · Beginner Friendly",
              badge: nil, cta: "Watch Now",
              bg: OppieColor.safetyGreen.opacity(0.30), icon: .spa),
        .init(title: "Roman Holiday", detail: "1h 58m · Comedy/Romance",
              badge: nil, cta: "Watch Now",
              bg: OppieColor.primaryFixed, icon: .theaters)
    ]

    private let hobbies: [Hobby] = [
        .init(title: "Painting Basics", detail: "Level 1 · 4 Lessons",
              icon: .palette, tint: OppieColor.secondary, bg: OppieColor.secondaryFixed),
        .init(title: "Learn Spanish", detail: "Level 2 · 12 Lessons",
              icon: .language, tint: OppieColor.tertiary, bg: OppieColor.tertiaryFixed),
        .init(title: "Mediterranean Cooking", detail: "Masterclass",
              icon: .restaurant, tint: OppieColor.primary, bg: OppieColor.primaryFixed),
        .init(title: "Ancestry & History", detail: "Archive Access",
              icon: .historyEdu, tint: OppieColor.onSurfaceVariant, bg: OppieColor.outlineVariant)
    ]

    var body: some View {
        VStack(spacing: 0) {
            OppieTopBar()
            ScrollView {
                VStack(spacing: OppieSpacing.stackLg) {
                    brainHero
                    mediaSection
                    videoSection
                    hobbiesSection
                    Color.clear.frame(height: 110)
                }
                .padding(.horizontal, OppieSpacing.marginMobile)
                .padding(.top, OppieSpacing.stackLg)
            }
            .background(OppieColor.background)
        }
    }

    private var brainHero: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: 14) {
                Text("Morning Ritual")
                    .font(OppieFont.labelLarge())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.white.opacity(0.18)))

                Text("Brain Training")
                    .font(OppieFont.headlineLargeMobile())
                    .foregroundStyle(.white)

                Text("Keep your mind sharp with today's 5-minute puzzle collection.")
                    .font(OppieFont.bodyLarge())
                    .opacity(0.9)
                    .foregroundStyle(.white)
                    .frame(maxWidth: 320, alignment: .leading)

                Button { } label: {
                    HStack(spacing: 8) {
                        OppieIcon(.playArrow, size: 22, weight: .bold)
                        Text("Play Now")
                    }
                    .font(OppieFont.headlineMedium())
                    .foregroundStyle(OppieColor.primary)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(.white))
                    .oppieSoftShadow()
                }
                .buttonStyle(.plain)
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: OppieRadius.xl, style: .continuous).fill(OppieColor.primaryContainer)
            )
            .oppieElevatedShadow()

            OppieIcon(.extensionPuzzle, size: 80, weight: .bold)
                .foregroundStyle(.white.opacity(0.30))
                .padding(20)
        }
    }

    private var mediaSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Music & Radio", trailing: "View All")
            VStack(spacing: 12) {
                ForEach(media) { item in
                    HStack(spacing: 14) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12, style: .continuous).fill(item.bg)
                            OppieIcon(item.icon, size: 28, weight: .semibold)
                                .foregroundStyle(OppieColor.onSurface.opacity(0.6))
                        }
                        .frame(width: 64, height: 64)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.title).font(OppieFont.labelLarge())
                            Text(item.subtitle).font(OppieFont.bodyMedium())
                                .foregroundStyle(OppieColor.onSurfaceVariant)
                        }
                        Spacer()
                        OppieIcon(item.trailing, size: 28, weight: .bold)
                            .foregroundStyle(item.trailingColor)
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: OppieRadius.xl, style: .continuous)
                            .fill(OppieColor.surfaceContainer)
                    )
                    .oppieSoftShadow()
                }
            }
        }
    }

    private var videoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Video & Shows")
                .font(OppieFont.headlineMedium())
                .padding(.leading, 4)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: OppieSpacing.gutter) {
                    ForEach(videos) { v in
                        videoCard(v)
                    }
                }
                .padding(.horizontal, 2)
            }
        }
    }

    private func videoCard(_ v: VideoItem) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 0).fill(v.bg)
                    .frame(height: 140)
                OppieIcon(v.icon, size: 60, weight: .semibold)
                    .foregroundStyle(.white.opacity(0.7))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                if let badge = v.badge {
                    Text(badge)
                        .font(OppieFont.labelSmall())
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(RoundedRectangle(cornerRadius: 4).fill(OppieColor.scamAlertRed))
                        .foregroundStyle(.white)
                        .padding(12)
                }
            }
            VStack(alignment: .leading, spacing: 8) {
                Text(v.title).font(OppieFont.labelLarge())
                Text(v.detail).font(OppieFont.bodyMedium())
                    .foregroundStyle(OppieColor.onSurfaceVariant)
                Button { } label: {
                    Text(v.cta)
                        .font(OppieFont.labelLarge())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(OppieColor.surfaceContainerHigh))
                        .foregroundStyle(OppieColor.primary)
                }
                .buttonStyle(.plain)
            }
            .padding(14)
        }
        .frame(width: 260)
        .background(
            RoundedRectangle(cornerRadius: OppieRadius.xl, style: .continuous).fill(.white)
        )
        .clipShape(RoundedRectangle(cornerRadius: OppieRadius.xl, style: .continuous))
        .oppieSoftShadow()
    }

    private var hobbiesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Hobbies & Learning")
                .font(OppieFont.headlineMedium())
                .padding(.leading, 4)
            LazyVGrid(columns: [GridItem(.flexible(), spacing: OppieSpacing.gutter),
                                GridItem(.flexible(), spacing: OppieSpacing.gutter)],
                      spacing: OppieSpacing.gutter) {
                ForEach(hobbies) { h in
                    VStack(alignment: .leading, spacing: 10) {
                        ZStack {
                            Circle().fill(h.bg)
                            OppieIcon(h.icon, size: 22, weight: .semibold).foregroundStyle(h.tint)
                        }
                        .frame(width: 48, height: 48)
                        Text(h.title).font(OppieFont.labelLarge())
                        Text(h.detail).font(OppieFont.bodyMedium()).foregroundStyle(OppieColor.onSurfaceVariant)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: OppieRadius.xl, style: .continuous)
                            .fill(.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: OppieRadius.xl, style: .continuous)
                                    .stroke(OppieColor.outlineVariant, lineWidth: 1)
                            )
                    )
                }
            }
        }
    }
}

#Preview { FunEntertainmentView() }
