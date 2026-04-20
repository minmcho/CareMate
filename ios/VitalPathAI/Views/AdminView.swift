//
//  AdminView.swift
//  Production readiness + operations dashboard for internal admins.
//

import SwiftUI

struct AdminView: View {
    private let metrics: [(label: String, value: String, delta: String)] = [
        ("Daily Active Users", "2,480", "+8.6%"),
        ("7-Day Retention", "62%", "+3.4%"),
        ("Pose Sessions / Day", "1,120", "+15.1%"),
        ("Safety Interventions", "14", "-11.0%")
    ]

    private let niches: [(title: String, summary: String)] = [
        ("Desk Ergonomics Coach", "Real-time posture checks for remote teams."),
        ("Perimenopause Wellness", "Lifestyle support routines with trend journaling."),
        ("Teen Athlete Recovery", "Pose feedback with hydration + mood coaching."),
        ("Shift Worker Sleep", "Circadian-friendly recovery plans for night shifts.")
    ]

    private let iosChecklist: [String] = [
        "Privacy manifest and App Privacy labels aligned with runtime behavior.",
        "Sign in with Apple enabled when any third-party sign in is offered.",
        "In-app unsafe-content reporting and moderation escalation flow.",
        "Wellness-not-medicine disclaimer visible before coach interactions.",
        "User data deletion available from account settings."
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Production Dashboard")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.primary)

                    metricsGrid

                    GlassCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Growth Niches")
                                .font(.headline)
                            ForEach(niches, id: \.title) { niche in
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(niche.title).font(.subheadline.weight(.semibold))
                                    Text(niche.summary)
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(10)
                                .background(Color.white.opacity(0.45), in: RoundedRectangle(cornerRadius: 14))
                            }
                        }
                    }

                    GlassCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("App Store Readiness")
                                .font(.headline)
                            ForEach(iosChecklist, id: \.self) { item in
                                HStack(alignment: .top, spacing: 8) {
                                    Image(systemName: "checkmark.seal.fill")
                                        .foregroundStyle(.green)
                                    Text(item)
                                        .font(.footnote)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 28)
            }
            .navigationTitle("Admin")
        }
    }

    private var metricsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            ForEach(metrics, id: \.label) { metric in
                GlassCard {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(metric.label)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(metric.value)
                            .font(.title3.weight(.bold))
                        Text(metric.delta)
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.green)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }
}

#Preview {
    AdminView()
}
