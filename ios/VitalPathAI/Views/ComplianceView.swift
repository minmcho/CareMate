//
//  ComplianceView.swift
//  Privacy policy, health disclaimer, and App Store compliance views.
//

import SwiftUI

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    section("Data Collection", content: """
                    VitalPath AI collects the following data to provide personalized wellness coaching:

                    • Profile information (display name, language preference)
                    • Wellness goals and dietary preferences
                    • Chat messages with our AI wellness coach
                    • Journal entries (encrypted at rest using AES-256)
                    • Habit tracking data
                    • Sleep and mood logs
                    • Video analysis results (processed in real-time, not stored)
                    • Community posts and replies
                    """)

                    section("HealthKit Data", content: """
                    When you grant permission, VitalPath AI reads the following HealthKit data to enhance your wellness insights:

                    • Sleep analysis (duration, stages)
                    • Step count
                    • Active energy burned
                    • Heart rate
                    • Mindful sessions

                    HealthKit data is processed locally and never shared with third parties. We only read data — we never write to your Apple Health records.
                    """)

                    section("AI Processing", content: """
                    Your messages and wellness data may be processed by open-source AI models hosted on our secure infrastructure:

                    • Llama 4 Maverick — conversational coaching
                    • DeepSeek R1 — complex reasoning and insights
                    • Qwen 2.5 VL — vision-based meal and exercise analysis

                    AI conversations are not used to train models. Crisis-related content is never stored in plain text — only cryptographic hashes are retained for safety auditing.
                    """)

                    section("Data Storage & Security", content: """
                    • All data is encrypted in transit (TLS 1.3) and at rest
                    • Journal entries use Fernet symmetric encryption (AES-128-CBC)
                    • Authentication is handled via Supabase with JWT tokens
                    • No health data is stored in iCloud
                    • Crisis audit records store only SHA-256 hashes, never raw text
                    • You can delete all your data at any time from the Profile tab
                    """)

                    section("Third-Party Services", content: """
                    • Supabase — authentication and user management
                    • Sentry — anonymous crash reporting (no PII)
                    • No advertising or marketing use of health data
                    • No data is sold to third parties
                    """)

                    section("Your Rights", content: """
                    • Access: View all your stored data from the Profile tab
                    • Delete: Remove all data permanently at any time
                    • Export: Request a copy of your data via support
                    • Opt-out: Decline HealthKit access without losing functionality
                    """)

                    Text("Last updated: April 2026")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                .padding(20)
            }
            .navigationTitle("Privacy Policy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func section(_ title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            Text(content)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}


struct HealthDisclaimerView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Image(systemName: "heart.text.clipboard")
                        .font(.system(size: 48))
                        .foregroundStyle(.indigo)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 10)

                    Text("Important Health Information")
                        .font(.title2.bold())
                        .frame(maxWidth: .infinity, alignment: .center)

                    disclaimerCard("Not Medical Advice", icon: "stethoscope", text: """
                    VitalPath AI is a wellness companion, not a medical device. It does not diagnose, treat, cure, or prevent any disease or medical condition.
                    """)

                    disclaimerCard("Consult Professionals", icon: "person.badge.shield.checkmark", text: """
                    Always consult a qualified healthcare professional before making changes to your diet, exercise routine, sleep habits, or mental health care.
                    """)

                    disclaimerCard("AI Limitations", icon: "cpu", text: """
                    Our AI coach provides general wellness suggestions based on open-source language models. These suggestions may not be appropriate for your specific health situation.
                    """)

                    disclaimerCard("Emergency Services", icon: "phone.arrow.up.right", text: """
                    If you are experiencing a medical emergency, call your local emergency services immediately. VitalPath AI is not a substitute for emergency medical care.
                    """)

                    disclaimerCard("Data Accuracy", icon: "chart.bar.xaxis", text: """
                    Sleep, mood, and activity data from wearables and manual entry may not be clinically accurate. Use these metrics as general wellness indicators, not medical measurements.
                    """)

                    Text("By using VitalPath AI, you acknowledge that you have read and understood this disclaimer.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
                .padding(20)
            }
            .navigationTitle("Health Disclaimer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func disclaimerCard(_ title: String, icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.indigo)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.subheadline.bold())
                Text(text).font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
