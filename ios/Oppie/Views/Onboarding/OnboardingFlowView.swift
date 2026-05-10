//
//  OnboardingFlowView.swift
//  Oppie — Welcome → Personalize → Get to know you → Health profile → Home.
//

import SwiftUI

enum OnboardingStep: Int, CaseIterable {
    case welcome, meetFriend, getToKnow, healthProfile
}

struct OnboardingFlowView: View {
    @EnvironmentObject var state: OppieAppState
    @State private var step: OnboardingStep = .welcome

    var body: some View {
        ZStack {
            switch step {
            case .welcome:
                WelcomeToOppieView { advance() }
            case .meetFriend:
                MeetYourFriendView { advance() }
            case .getToKnow:
                GettingToKnowYouView { advance() }
            case .healthProfile:
                HealthProfileView {
                    state.hasOnboarded = true
                }
            }
        }
        .background(OppieColor.background.ignoresSafeArea())
        .animation(.easeInOut(duration: 0.35), value: step)
    }

    private func advance() {
        if let next = OnboardingStep(rawValue: step.rawValue + 1) {
            step = next
        } else {
            state.hasOnboarded = true
        }
    }
}

#Preview {
    OnboardingFlowView()
        .environmentObject(OppieAppState())
}
