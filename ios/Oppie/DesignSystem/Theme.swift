//
//  Theme.swift
//  Oppie — Design tokens (colors, typography, spacing) ported from the
//  Stitch design system used by the Malacors / Oppie web prototypes.
//

import SwiftUI

// MARK: - Colors

enum OppieColor {
    // Brand
    static let primary               = Color(hex: 0x4343D5)
    static let primaryContainer      = Color(hex: 0x5D5FEF)
    static let primaryFixed          = Color(hex: 0xE1E0FF)
    static let primaryFixedDim       = Color(hex: 0xC1C1FF)
    static let onPrimary             = Color.white
    static let onPrimaryContainer    = Color(hex: 0xFAF7FF)
    static let onPrimaryFixed        = Color(hex: 0x07006C)
    static let onPrimaryFixedVariant = Color(hex: 0x2E2BC2)

    // Secondary (warm orange)
    static let secondary             = Color(hex: 0x9F4122)
    static let secondaryContainer    = Color(hex: 0xFD8863)
    static let secondaryFixed        = Color(hex: 0xFFDBD0)
    static let secondaryFixedDim     = Color(hex: 0xFFB59E)
    static let onSecondary           = Color.white
    static let onSecondaryContainer  = Color(hex: 0x722104)
    static let onSecondaryFixed      = Color(hex: 0x3A0B00)

    // Tertiary (amber)
    static let tertiary              = Color(hex: 0x904400)
    static let tertiaryContainer     = Color(hex: 0xB65700)
    static let tertiaryFixed         = Color(hex: 0xFFDBC8)
    static let tertiaryFixedDim      = Color(hex: 0xFFB689)
    static let onTertiary            = Color.white
    static let onTertiaryFixed       = Color(hex: 0x321300)
    static let onTertiaryFixedVariant = Color(hex: 0x743500)

    // Surfaces
    static let background            = Color(hex: 0xFCF8FF)
    static let surface               = Color(hex: 0xFCF8FF)
    static let surfaceBright         = Color(hex: 0xFCF8FF)
    static let surfaceDim            = Color(hex: 0xDBD8E5)
    static let surfaceContainerLowest = Color.white
    static let surfaceContainerLow   = Color(hex: 0xF5F2FE)
    static let surfaceContainer      = Color(hex: 0xEFECF9)
    static let surfaceContainerHigh  = Color(hex: 0xE9E6F3)
    static let surfaceContainerHighest = Color(hex: 0xE4E1ED)
    static let warmSurface           = Color(hex: 0xFDFCFB)

    // Text
    static let onSurface             = Color(hex: 0x1B1B23)
    static let onSurfaceVariant      = Color(hex: 0x464555)
    static let onBackground          = Color(hex: 0x1B1B23)
    static let outline               = Color(hex: 0x767586)
    static let outlineVariant        = Color(hex: 0xC7C4D7)

    // Semantic / accent
    static let scamAlertRed          = Color(hex: 0xD00000)
    static let safetyGreen           = Color(hex: 0x2D6A4F)
    static let healthBlue            = Color(hex: 0x0077B6)
    static let companionFur          = Color(hex: 0xA1887F)
    static let error                 = Color(hex: 0xBA1A1A)
    static let errorContainer        = Color(hex: 0xFFDAD6)
    static let onErrorContainer      = Color(hex: 0x93000A)
}

extension Color {
    init(hex: UInt32, alpha: Double = 1.0) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >>  8) & 0xFF) / 255.0
        let b = Double( hex        & 0xFF) / 255.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: alpha)
    }
}

// MARK: - Typography
//
// The Stitch design system uses Atkinson Hyperlegible Next. We fall back to
// the system font (which iOS resolves to SF Pro) when the font is unavailable
// to keep the bundle lean. Sizes/weights mirror the design tokens.

enum OppieFont {
    static func displayLarge() -> Font  { .system(size: 40, weight: .heavy,    design: .rounded) }
    static func headlineLarge() -> Font { .system(size: 32, weight: .bold,     design: .rounded) }
    static func headlineLargeMobile() -> Font { .system(size: 28, weight: .bold, design: .rounded) }
    static func headlineMedium() -> Font { .system(size: 24, weight: .bold,    design: .rounded) }
    static func bodyLarge() -> Font     { .system(size: 20, weight: .regular,  design: .rounded) }
    static func bodyMedium() -> Font    { .system(size: 18, weight: .regular,  design: .rounded) }
    static func labelLarge() -> Font    { .system(size: 16, weight: .semibold, design: .rounded) }
    static func labelSmall() -> Font    { .system(size: 13, weight: .semibold, design: .rounded) }
}

// MARK: - Spacing

enum OppieSpacing {
    static let stackSm: CGFloat = 12
    static let stackMd: CGFloat = 24
    static let stackLg: CGFloat = 40
    static let gutter:  CGFloat = 20
    static let marginMobile: CGFloat = 24
}

enum OppieRadius {
    static let `default`: CGFloat = 4
    static let lg: CGFloat = 8
    static let xl: CGFloat = 12
    static let card: CGFloat = 24
    static let large: CGFloat = 28
}

// MARK: - Shadows

struct OppieSoftShadow: ViewModifier {
    func body(content: Content) -> some View {
        content
            .shadow(color: Color.black.opacity(0.05),
                    radius: 4, x: 0, y: 2)
    }
}

struct OppieElevatedShadow: ViewModifier {
    func body(content: Content) -> some View {
        content
            .shadow(color: Color.black.opacity(0.08),
                    radius: 30, x: 0, y: 20)
    }
}

extension View {
    func oppieSoftShadow() -> some View { modifier(OppieSoftShadow()) }
    func oppieElevatedShadow() -> some View { modifier(OppieElevatedShadow()) }
}
