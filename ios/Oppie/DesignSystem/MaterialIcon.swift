//
//  MaterialIcon.swift
//  Oppie — maps Material Symbols names used in the Stitch design to SF Symbols
//  so we can render the same iconography natively on iOS.
//

import SwiftUI

enum MaterialIcon: String {
    case settings              = "gearshape.fill"
    case home                  = "house.fill"
    case medicalServices       = "cross.case.fill"
    case group                 = "person.2.fill"
    case theaters              = "play.tv.fill"
    case person                = "person.crop.circle.fill"
    case mic                   = "mic.fill"
    case sunny                 = "sun.max.fill"
    case heartFavorite         = "heart.fill"
    case call                  = "phone.fill"
    case musicNote             = "music.note"
    case restaurant            = "fork.knife"
    case emergency             = "exclamationmark.triangle.fill"
    case videocam              = "video.fill"
    case bedtime               = "moon.zzz.fill"
    case steps                 = "figure.walk"
    case pill                  = "pills.fill"
    case medication            = "cross.vial.fill"
    case check                 = "checkmark"
    case verified              = "checkmark.seal.fill"
    case verifiedUser          = "shield.lefthalf.filled.badge.checkmark"
    case shield                = "shield.fill"
    case block                 = "hand.raised.fill"
    case callEnd               = "phone.down.fill"
    case emergencyHome         = "house.lodge.fill"
    case chevronRight          = "chevron.right"
    case chevronLeft           = "chevron.left"
    case arrowForward          = "arrow.right"
    case edit                  = "pencil"
    case lock                  = "lock.fill"
    case logout                = "rectangle.portrait.and.arrow.right"
    case favorite              = "heart.circle.fill"
    case volunteerActivism     = "hands.sparkles.fill"
    case accessibility         = "figure.roll"
    case verifiedShield        = "checkmark.shield.fill"
    case spa                   = "leaf.fill"
    case bolt                  = "bolt.fill"
    case volumeUp              = "speaker.wave.3.fill"
    case badge                 = "tag.fill"
    case palette               = "paintpalette.fill"
    case voiceOver             = "waveform"
    case schedule              = "clock.fill"
    case potted                = "leaf.circle.fill"
    case menuBook              = "book.fill"
    case extensionPuzzle       = "puzzlepiece.extension.fill"
    case playArrow             = "play.fill"
    case playCircle            = "play.circle.fill"
    case radio                 = "antenna.radiowaves.left.and.right"
    case sensors               = "waveform.path.ecg"
    case language              = "character.book.closed.fill"
    case historyEdu            = "books.vertical.fill"
    case lightbulb             = "lightbulb.fill"
    case psychology            = "brain.head.profile"
    case exercise              = "figure.run"
    case healthSafety          = "heart.text.square.fill"
    case sentimentSatisfied    = "face.smiling.fill"
    case sentimentNeutral      = "face.dashed.fill"
    case directionsRun         = "figure.run.circle.fill"
    case chatBubble            = "message.fill"
    case shoppingCart          = "cart.fill"
    case shoppingCartCheckout  = "cart.fill.badge.plus"
    case addShoppingCart       = "cart.badge.plus"
    case glassCup              = "cup.and.saucer.fill"
    case bakeryDining          = "birthday.cake.fill"
    case egg                   = "circle.dotted"
    case add                   = "plus"
    case waterDrop             = "drop.fill"
    case nutrition             = "leaf.arrow.circlepath"
    case sparkles              = "sparkles"
    case starFill              = "star.fill"
    case calendar              = "calendar"

    var systemImage: String { rawValue }
}

struct OppieIcon: View {
    let icon: MaterialIcon
    var size: CGFloat = 24
    var weight: Font.Weight = .regular

    init(_ icon: MaterialIcon, size: CGFloat = 24, weight: Font.Weight = .regular) {
        self.icon = icon
        self.size = size
        self.weight = weight
    }

    var body: some View {
        Image(systemName: icon.systemImage)
            .font(.system(size: size, weight: weight))
            .symbolRenderingMode(.hierarchical)
    }
}
