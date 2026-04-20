//
//  ProfileView.swift
//  Preferences, language, dietary, privacy.
//

import SwiftUI
import SwiftData

struct ProfileView: View {
    @Environment(AppState.self) private var appState
    @Query private var profiles: [WellnessProfile]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let profile = profiles.first {
                        GlassCard {
                            HStack(spacing: 14) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(LinearGradient(colors: [.indigo, .purple, .pink],
                                                             startPoint: .topLeading, endPoint: .bottomTrailing))
                                        .frame(width: 64, height: 64)
                                    Text(profile.displayName.prefix(1).uppercased())
                                        .font(.title.bold())
                                        .foregroundStyle(.white)
                                }
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(profile.displayName).font(.title3.bold())
                                    Text("Account \(profile.id.uuidString.prefix(8))")
                                        .font(.caption2).foregroundStyle(.secondary)
                                }
                            }
                        }
                    }

                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Language", systemImage: "globe")
                                .font(.headline)
                            Picker("Language", selection: .constant(appState.language)) {
                                ForEach(AppLanguage.allCases) { lang in
                                    Text(lang.label).tag(lang)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                    }

                    GlassCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Label("Privacy & safety", systemImage: "lock.shield")
                                .font(.headline)
                            Text("Your data stays on-device unless you sign in to sync. Crisis inputs are never stored in plain text.")
                                .font(.callout)
                                .foregroundStyle(.secondary)
                            HStack {
                                Image(systemName: "externaldrive")
                                Text("Stored on this device").font(.caption)
                            }
                            .foregroundStyle(.secondary)
                        }
                    }

                    GlassCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Label("App Store readiness", systemImage: "checkmark.seal")
                                .font(.headline)
                            Text("Production controls required for submission.")
                                .font(.callout)
                                .foregroundStyle(.secondary)
                            Label("Report unsafe content", systemImage: "exclamationmark.bubble")
                                .font(.caption)
                            Label("Delete account and local data", systemImage: "trash")
                                .font(.caption)
                            Label("Wellness guidance disclaimer", systemImage: "cross.case")
                                .font(.caption)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 120)
            }
            .navigationTitle("Profile")
            .scrollContentBackground(.hidden)
        }
    }
}
