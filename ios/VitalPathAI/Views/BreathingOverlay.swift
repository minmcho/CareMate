//
//  BreathingOverlay.swift
//  Animated box-breathing overlay.
//

import SwiftUI

struct BreathingOverlay: View {
    @Environment(AppState.self) private var appState
    @State private var phaseIndex = 0
    @State private var scale: CGFloat = 1.0

    private let phases: [(label: String, duration: Double)] = [
        ("Inhale", 4),
        ("Hold", 4),
        ("Exhale", 4),
        ("Hold", 4)
    ]

    var body: some View {
        ZStack {
            Color.black.opacity(0.85).ignoresSafeArea()

            VStack(spacing: 40) {
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

                Text(phases[phaseIndex].label)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("Inhale · Hold · Exhale · Hold")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
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
            runPhase()
        }
    }

    private func runPhase() {
        let duration = phases[phaseIndex].duration
        withAnimation(.easeInOut(duration: duration)) {
            scale = phaseIndex == 0 ? 1.3 : (phaseIndex == 2 ? 0.85 : 1.05)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            phaseIndex = (phaseIndex + 1) % phases.count
            if appState.breathingVisible { runPhase() }
        }
    }
}
