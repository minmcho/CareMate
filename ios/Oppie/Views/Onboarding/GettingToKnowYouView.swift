//
//  GettingToKnowYouView.swift
//  Oppie — onboarding step capturing name + hobbies.
//

import SwiftUI

struct GettingToKnowYouView: View {
    var onContinue: () -> Void = {}

    @State private var name: String = ""
    @State private var hobbies: String = ""

    var body: some View {
        VStack(spacing: 0) {
            OppieTopBar()

            ScrollView {
                VStack(alignment: .leading, spacing: OppieSpacing.stackMd) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Let's get to know you!")
                            .font(OppieFont.displayLarge())
                            .foregroundStyle(OppieColor.onSurface)
                        Text("I'm so excited to help you today. First, I just need a few details to make your experience perfect.")
                            .font(OppieFont.bodyLarge())
                            .foregroundStyle(OppieColor.onSurfaceVariant)
                    }

                    inputCard(label: "What is your name?") {
                        TextField("Type your name here…", text: $name)
                            .textFieldStyle(.plain)
                            .font(OppieFont.bodyLarge())
                            .padding(20)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(OppieColor.surfaceContainerHighest)
                            )
                    }

                    inputCard(label: "What are your hobbies?") {
                        ZStack(alignment: .topLeading) {
                            if hobbies.isEmpty {
                                Text("I love gardening, reading, or maybe walking in the park…")
                                    .foregroundStyle(OppieColor.outline)
                                    .padding(20)
                                    .font(OppieFont.bodyLarge())
                            }
                            TextEditor(text: $hobbies)
                                .scrollContentBackground(.hidden)
                                .padding(14)
                                .frame(minHeight: 110)
                                .font(OppieFont.bodyLarge())
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(OppieColor.surfaceContainerHighest)
                        )

                        HStack(spacing: 8) {
                            OppieIcon(.lightbulb, size: 16, weight: .semibold)
                                .foregroundStyle(OppieColor.primary)
                            Text("Knowing what you love helps me suggest fun things to do!")
                                .font(OppieFont.bodyMedium().italic())
                                .foregroundStyle(OppieColor.onSurfaceVariant)
                        }
                        .padding(.top, 8)
                    }

                    encouragementCard

                    Color.clear.frame(height: 120)
                }
                .padding(.horizontal, OppieSpacing.marginMobile)
                .padding(.top, OppieSpacing.stackLg)
            }
            .background(OppieColor.background)
        }
        .background(OppieColor.background.ignoresSafeArea())
        .overlay(alignment: .bottom) {
            VStack {
                Button(action: onContinue) {
                    HStack {
                        Text("Next Step")
                        OppieIcon(.arrowForward, size: 22, weight: .bold)
                    }
                    .frame(maxWidth: .infinity)
                    .font(OppieFont.headlineMedium())
                    .padding(.vertical, 18)
                    .background(
                        Capsule().fill(OppieColor.primary)
                    )
                    .foregroundStyle(OppieColor.onPrimary)
                    .oppieSoftShadow()
                }
                .padding(.horizontal, OppieSpacing.marginMobile)
                .padding(.bottom, 28)
            }
            .padding(.top, 16)
            .background(OppieColor.surfaceContainerLow.clipShape(RoundedCornerShape(corners: [.topLeft, .topRight], radius: 28)))
            .ignoresSafeArea(edges: .bottom)
        }
    }

    private func inputCard<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(label)
                .font(OppieFont.headlineMedium())
                .foregroundStyle(OppieColor.onSurface)
            content()
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(OppieColor.surfaceContainerLow)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(OppieColor.surfaceContainerHighest, lineWidth: 1)
                )
        )
        .oppieSoftShadow()
    }

    private var encouragementCard: some View {
        HStack(alignment: .top, spacing: 16) {
            OppieIcon(.chatBubble, size: 26, weight: .bold)
                .foregroundStyle(OppieColor.primaryContainer)
                .padding(.top, 4)
            Text("\"You're doing great! Just one more step and we'll be all set.\"")
                .font(OppieFont.headlineMedium())
                .foregroundStyle(OppieColor.primary)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(OppieColor.primaryContainer.opacity(0.10))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(OppieColor.primaryContainer, style: StrokeStyle(lineWidth: 2, dash: [6, 6]))
                )
        )
    }
}

#Preview { GettingToKnowYouView() }
