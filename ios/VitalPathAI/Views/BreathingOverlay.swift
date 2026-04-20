//
//  BreathingOverlay.swift
//  Animated breathwork overlay — drives any BreathworkTechnique from the
//  catalog with phase-accurate timing and a rounds counter.
//

import SwiftUI

struct BreathingOverlay: View {
    @Environment(AppState.self) private var appState
    @State private var phaseIndex = 0
    @State private var round = 1
    @State private var scale: CGFloat = 1.0

    private var technique: BreathworkTechnique {
        BreathworkCatalog.find(appState.breathingTechniqueID) ?? BreathworkCatalog.default
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.85).ignoresSafeArea()

            VStack(spacing: 28) {
                VStack(spacing: 4) {
                    Text(technique.name.uppercased())
                        .font(.caption.bold())
                        .tracking(1.6)
                        .foregroundStyle(.white.opacity(0.7))
                    Text("Round \(min(round, technique.rounds)) of \(technique.rounds)")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.55))
                }

                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [.indigo, .purple, .pink.opacity(0.8)],
                                center: .center,
                                startRadius: 0,
                                endRadius: 200
                            )
                        )
                        .frame(width: 260, height: 260)
                        .scaleEffect(scale)
                        .shadow(color: .purple.opacity(0.5), radius: 80)

                    Circle()
                        .strokeBorder(Color.white.opacity(0.4), lineWidth: 1)
                        .frame(width: 220, height: 220)
                }

                Text(phaseLabel)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text(technique.summary)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            VStack {
                HStack {
                    Spacer()
                    Button {
                        appState.breathingVisible = false
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundStyle(.white.opacity(0.8))
                            .padding(12)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                    .padding(.top, 60)
                    .padding(.trailing, 24)
                }
                Spacer()
            }
        }
        .onAppear {
            phaseIndex = 0
            round = 1
            runPhase()
        }
        .onChange(of: appState.breathingTechniqueID) { _, _ in
            phaseIndex = 0
            round = 1
            runPhase()
        }
    }

    private var phaseLabel: String {
        let phase = technique.phases[phaseIndex]
        switch phase {
        case .inhale: return "Inhale"
        case .exhale: return "Exhale"
        case .hold, .hold2: return "Hold"
        }
    }

    private func runPhase() {
        guard appState.breathingVisible else { return }
        let duration = technique.pattern[phaseIndex]
        // Zero-duration phases are skipped — advance immediately.
        if duration <= 0 {
            advance()
            return
        }
        let phase = technique.phases[phaseIndex]
        withAnimation(.easeInOut(duration: duration)) {
            switch phase {
            case .inhale: scale = 1.3
            case .exhale: scale = 0.85
            default:      scale = 1.05
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            advance()
        }
    }

    private func advance() {
        let nextIdx = phaseIndex + 1
        if nextIdx >= technique.phases.count {
            // Completed one round.
            if round + 1 > technique.rounds {
                // Session finished — close overlay.
                appState.breathingVisible = false
                return
            }
            round += 1
            phaseIndex = 0
        } else {
            phaseIndex = nextIdx
        }
        if appState.breathingVisible { runPhase() }
    }
}
