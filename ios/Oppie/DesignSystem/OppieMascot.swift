//
//  OppieMascot.swift
//  Oppie — vector rendering of the Oppie companion mascot.
//  We draw the mascot programmatically so the app does not need to ship
//  external image assets to demonstrate the UI.
//

import SwiftUI

struct OppieMascot: View {
    var furColor: Color = OppieColor.primaryContainer
    var size: CGFloat = 160

    var body: some View {
        ZStack {
            // Soft halo
            Circle()
                .fill(OppieColor.primaryFixed.opacity(0.45))
                .blur(radius: size * 0.18)
                .scaleEffect(1.05)

            // Body
            ZStack {
                Ellipse()
                    .fill(furColor.opacity(0.95))
                    .frame(width: size * 0.85, height: size * 0.78)
                    .offset(y: size * 0.06)

                // Belly
                Ellipse()
                    .fill(OppieColor.warmSurface)
                    .frame(width: size * 0.45, height: size * 0.45)
                    .offset(y: size * 0.18)

                // Head
                Circle()
                    .fill(furColor)
                    .frame(width: size * 0.70, height: size * 0.70)
                    .offset(y: -size * 0.18)

                // Ears
                ZStack {
                    Capsule()
                        .fill(furColor)
                        .frame(width: size * 0.20, height: size * 0.24)
                        .rotationEffect(.degrees(-22))
                        .offset(x: -size * 0.22, y: -size * 0.42)
                    Capsule()
                        .fill(furColor)
                        .frame(width: size * 0.20, height: size * 0.24)
                        .rotationEffect(.degrees(22))
                        .offset(x: size * 0.22, y: -size * 0.42)
                }

                // Inner ears
                Capsule()
                    .fill(OppieColor.secondaryFixed)
                    .frame(width: size * 0.10, height: size * 0.14)
                    .rotationEffect(.degrees(-22))
                    .offset(x: -size * 0.21, y: -size * 0.41)
                Capsule()
                    .fill(OppieColor.secondaryFixed)
                    .frame(width: size * 0.10, height: size * 0.14)
                    .rotationEffect(.degrees(22))
                    .offset(x: size * 0.21, y: -size * 0.41)

                // Mask area around eyes
                Capsule()
                    .fill(OppieColor.onPrimaryFixed.opacity(0.20))
                    .frame(width: size * 0.55, height: size * 0.22)
                    .offset(y: -size * 0.18)

                // Eyes
                Group {
                    Circle().fill(Color.white).frame(width: size * 0.14, height: size * 0.14)
                        .overlay(
                            Circle().fill(OppieColor.onSurface)
                                .frame(width: size * 0.07, height: size * 0.07)
                                .offset(x: size * 0.01, y: size * 0.01)
                        )
                        .offset(x: -size * 0.13, y: -size * 0.18)
                    Circle().fill(Color.white).frame(width: size * 0.14, height: size * 0.14)
                        .overlay(
                            Circle().fill(OppieColor.onSurface)
                                .frame(width: size * 0.07, height: size * 0.07)
                                .offset(x: size * 0.01, y: size * 0.01)
                        )
                        .offset(x: size * 0.13, y: -size * 0.18)
                }

                // Nose
                Ellipse()
                    .fill(OppieColor.onSurface)
                    .frame(width: size * 0.06, height: size * 0.05)
                    .offset(y: -size * 0.05)

                // Smile
                Path { path in
                    path.move(to: CGPoint(x: -size * 0.06, y: 0))
                    path.addQuadCurve(to: CGPoint(x: size * 0.06, y: 0),
                                      control: CGPoint(x: 0, y: size * 0.05))
                }
                .stroke(OppieColor.onSurface, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                .frame(width: size * 0.12, height: size * 0.05)
                .offset(y: size * 0.0)

                // Cheeks
                Circle().fill(OppieColor.secondaryFixedDim.opacity(0.6))
                    .frame(width: size * 0.10, height: size * 0.07)
                    .offset(x: -size * 0.22, y: -size * 0.05)
                Circle().fill(OppieColor.secondaryFixedDim.opacity(0.6))
                    .frame(width: size * 0.10, height: size * 0.07)
                    .offset(x: size * 0.22, y: -size * 0.05)
            }
        }
        .frame(width: size, height: size)
        .accessibilityLabel("Oppie companion mascot")
    }
}

/// Small avatar version used in top app bars.
struct OppieAvatar: View {
    var size: CGFloat = 40
    var body: some View {
        OppieMascot(size: size * 1.45)
            .scaleEffect(0.85)
            .frame(width: size, height: size)
            .background(OppieColor.primaryFixed)
            .clipShape(Circle())
    }
}

#Preview {
    VStack(spacing: 24) {
        OppieMascot(size: 220)
        OppieAvatar(size: 48)
    }
    .padding()
    .background(OppieColor.background)
}
