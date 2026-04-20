//
//  CrisisModal.swift
//  Full-screen gentle interruption with localized hotlines.
//

import SwiftUI

struct CrisisResource: Identifiable {
    let id = UUID()
    let name: String
    let number: String
}

struct CrisisModal: View {
    @Environment(AppState.self) private var appState

    let resources: [CrisisResource] = [
        CrisisResource(name: "988 Suicide & Crisis Lifeline (US)", number: "988"),
        CrisisResource(name: "Samaritans (UK)", number: "116 123"),
        CrisisResource(name: "Lifeline (AU)", number: "13 11 14"),
        CrisisResource(name: "Department of Mental Health (TH)", number: "1323"),
        CrisisResource(name: "Inochi no Denwa (JP)", number: "0120-783-556")
    ]

    var body: some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea()

            GlassCard {
                VStack(alignment: .leading, spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 22)
                            .fill(LinearGradient(colors: [.pink, .red],
                                                 startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 56, height: 56)
                        Image(systemName: "cross.case.fill")
                            .foregroundStyle(.white)
                            .font(.title2)
                    }

                    Text("You are not alone")
                        .font(.title2.bold())
                    Text("We noticed something that sounds serious. Please reach out to people trained to help.")
                        .font(.callout)
                        .foregroundStyle(.secondary)

                    VStack(spacing: 10) {
                        ForEach(resources) { r in
                            Link(destination: URL(string: "tel:\(r.number.replacingOccurrences(of: " ", with: ""))")!) {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(r.name).font(.subheadline.bold())
                                        Text(r.number).font(.caption).foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: "phone.fill")
                                        .foregroundStyle(.green)
                                }
                                .padding(12)
                                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                            }
                        }
                    }

                    HStack {
                        Button {
                            appState.crisisVisible = false
                            appState.breathingVisible = true
                        } label: {
                            Label("Try breathing", systemImage: "wind")
                        }
                        .buttonStyle(.bordered)
                        .buttonBorderShape(.capsule)

                        Button {
                            appState.crisisVisible = false
                        } label: {
                            Text("Close")
                        }
                        .buttonStyle(.borderedProminent)
                        .buttonBorderShape(.capsule)
                        .tint(.indigo)
                    }
                }
            }
            .padding(24)
        }
    }
}
