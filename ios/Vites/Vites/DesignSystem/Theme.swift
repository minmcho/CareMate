import SwiftUI
import UIKit

/// Vites design tokens. Mirrors the `vites_design_system` package from the
/// Stitch design package and the spec in `editorspec.md` / `compliance.md`.
///
/// Palette is "Functional Pastels": Soft Lavender primary, Mint secondary,
/// Blush tertiary, balanced by deep charcoal text for WCAG AA contrast.
enum VitesColor {
    // Surfaces (off-white lavender tint to reduce eye strain).
    static let surface              = Color(hex: 0xF8F9FF)
    static let surfaceDim           = Color(hex: 0xD0DBED)
    static let surfaceBright        = Color(hex: 0xF8F9FF)
    static let surfaceContainerLow  = Color(hex: 0xEFF4FF)
    static let surfaceContainer     = Color(hex: 0xE6EEFF)
    static let surfaceContainerHigh = Color(hex: 0xDEE9FC)
    static let surfaceContainerHighest = Color(hex: 0xD9E3F6)
    static let surfaceContainerLowest  = Color.white

    // Brand.
    static let primary              = Color(hex: 0x674BB5)
    static let onPrimary            = Color.white
    static let primaryContainer     = Color(hex: 0xA78BFA)
    static let onPrimaryContainer   = Color(hex: 0x3C1989)
    static let primaryFixed         = Color(hex: 0xE8DDFF)
    static let primaryFixedDim      = Color(hex: 0xCEBDFF)
    static let inversePrimary       = Color(hex: 0xCEBDFF)

    static let secondary            = Color(hex: 0x1B6B4F)
    static let onSecondary          = Color.white
    static let secondaryContainer   = Color(hex: 0xA6F2CF)
    static let onSecondaryContainer = Color(hex: 0x247155)

    static let tertiary             = Color(hex: 0x765469)
    static let onTertiary           = Color.white
    static let tertiaryContainer    = Color(hex: 0xB992A9)
    static let tertiaryFixed        = Color(hex: 0xFFD8ED)
    static let tertiaryFixedDim     = Color(hex: 0xE5BAD3)

    static let error                = Color(hex: 0xBA1A1A)
    static let onError              = Color.white
    static let errorContainer       = Color(hex: 0xFFDAD6)
    static let onErrorContainer     = Color(hex: 0x93000A)

    // Text / outlines.
    static let onSurface            = Color(hex: 0x121C2A)
    static let onSurfaceVariant     = Color(hex: 0x494552)
    static let outline              = Color(hex: 0x7A7583)
    static let outlineVariant       = Color(hex: 0xCAC4D4)

    // Auxiliary accents used by status pills in the Stitch designs.
    static let accentBlush          = Color(hex: 0xFBCFE8)
    static let accentMint           = Color(hex: 0xA7F3D0)
    static let accentLavender       = Color(hex: 0xA78BFA)
}

enum VitesRadius {
    static let sm: CGFloat   = 8
    static let `default`: CGFloat = 16
    static let md: CGFloat   = 24
    static let lg: CGFloat   = 32
    static let xl: CGFloat   = 48
    static let pill: CGFloat = 9999
}

enum VitesSpace {
    static let unit: CGFloat        = 8
    static let xs: CGFloat          = 4
    static let sm: CGFloat          = 8
    static let md: CGFloat          = 16
    static let lg: CGFloat          = 24
    static let xl: CGFloat          = 32
    static let section: CGFloat     = 48
    static let containerMargin: CGFloat = 16   // mobile container margin
}

/// Typography. Quicksand is the headline / label voice; Be Vietnam Pro is the
/// body voice. We fall back to system fonts if the custom fonts are not bundled
/// so the project always builds — designers can drop the TTFs in later.
enum VitesFont {
    static func headlineLarge() -> Font {
        custom("Quicksand-Bold", size: 26, fallback: .system(size: 26, weight: .bold, design: .rounded))
    }
    static func headlineMedium() -> Font {
        custom("Quicksand-Bold", size: 22, fallback: .system(size: 22, weight: .bold, design: .rounded))
    }
    static func title() -> Font {
        custom("Quicksand-SemiBold", size: 18, fallback: .system(size: 18, weight: .semibold, design: .rounded))
    }
    static func labelBold() -> Font {
        custom("Quicksand-Bold", size: 13, fallback: .system(size: 13, weight: .bold, design: .rounded))
    }
    static func bodyLarge() -> Font {
        custom("BeVietnamPro-Regular", size: 16, fallback: .system(size: 16, weight: .regular))
    }
    static func bodyMedium() -> Font {
        custom("BeVietnamPro-Regular", size: 14, fallback: .system(size: 14, weight: .regular))
    }
    static func caption() -> Font {
        custom("BeVietnamPro-Medium", size: 12, fallback: .system(size: 12, weight: .medium))
    }

    private static func custom(_ name: String, size: CGFloat, fallback: Font) -> Font {
        guard UIFont(name: name, size: size) != nil else { return fallback }
        return .custom(name, size: size)
    }
}

// MARK: - Hex color helper

extension Color {
    init(hex: UInt32, opacity: Double = 1.0) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >>  8) & 0xFF) / 255.0
        let b = Double( hex        & 0xFF) / 255.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: opacity)
    }
}

// MARK: - Ambient shadow

extension View {
    /// Level 1 ambient shadow. The Stitch design system specifies coloured
    /// lavender shadows (12px blur, 4px offset, 10% opacity) to make cards
    /// feel like they are resting on a soft light.
    func vitesAmbientShadow(level: Int = 1) -> some View {
        let blur: CGFloat = level >= 2 ? 24 : 12
        let y: CGFloat    = level >= 2 ? 8  : 4
        let opacity       = level >= 2 ? 0.15 : 0.10
        return shadow(color: VitesColor.primary.opacity(opacity),
                      radius: blur, x: 0, y: y)
    }
}
