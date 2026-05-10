import Foundation

// MARK: - Platforms

enum VitesPlatform: String, CaseIterable, Identifiable, Codable {
    case tiktok, instagram, facebook, youtube, x, telegram
    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .tiktok:    return "TikTok"
        case .instagram: return "Instagram"
        case .facebook:  return "Facebook"
        case .youtube:   return "YouTube"
        case .x:         return "X"
        case .telegram:  return "Telegram"
        }
    }

    /// SF Symbol that stands in for the platform glyph. Real builds replace
    /// these with brand-licensed assets in `Assets.xcassets`.
    var symbol: String {
        switch self {
        case .tiktok:    return "music.note"
        case .instagram: return "camera.fill"
        case .facebook:  return "f.circle.fill"
        case .youtube:   return "play.rectangle.fill"
        case .x:         return "xmark"
        case .telegram:  return "paperplane.fill"
        }
    }
}

// MARK: - Niche / Trend

struct Niche: Identifiable, Hashable {
    enum Heat: Hashable {
        case risingFast(deltaPct: Int)
        case steadyGrowth
        case alpha(deltaPct: Int)
        case communityFave
        case alert(reason: String)

        var label: String {
            switch self {
            case .risingFast:    return "RISING FAST"
            case .steadyGrowth:  return "STEADY GROWTH"
            case .alpha:         return "NICHE ALPHA"
            case .communityFave: return "COMMUNITY FAVE"
            case .alert:         return "ALERT"
            }
        }
    }

    let id = UUID()
    let title: String
    let summary: String
    let heat: Heat
    let platforms: [VitesPlatform]
    let velocity: [Double]              // sparkline samples
    let velocityChangePct: Int          // headline number
    let mascotSymbol: String            // SF Symbol stand-in for the mascot
    let accent: AccentTint

    enum AccentTint { case mint, blush, lavender, peach, alert }
}

extension Niche {
    static let sample: [Niche] = [
        Niche(
            title: "Low-impact fitness",
            summary: "“Slow” is the new fast. Holistic wellness takes center stage.",
            heat: .risingFast(deltaPct: 84),
            platforms: [.tiktok, .youtube],
            velocity: [2, 3, 3, 4, 6, 7, 9, 11, 13, 15],
            velocityChangePct: 84,
            mascotSymbol: "pawprint.fill",
            accent: .mint
        ),
        Niche(
            title: "Quiet Luxury",
            summary: "The “Old Money” aesthetic is evolving into intentional minimalism.",
            heat: .steadyGrowth,
            platforms: [.instagram, .x],
            velocity: [3, 4, 5, 5, 6, 7, 8, 9, 10, 11],
            velocityChangePct: 32,
            mascotSymbol: "leaf.fill",
            accent: .blush
        ),
        Niche(
            title: "Agentic Workflows",
            summary: "Twitter/X mentions +120% and GitHub Stars +45% in the past week.",
            heat: .alpha(deltaPct: 120),
            platforms: [.x, .youtube],
            velocity: [1, 2, 2, 3, 5, 8, 10, 13, 16, 20],
            velocityChangePct: 120,
            mascotSymbol: "bolt.fill",
            accent: .lavender
        ),
        Niche(
            title: "Retro Tech",
            summary: "Wired headphones and point-and-shoot cameras are back as Gen Z rebels against polish.",
            heat: .communityFave,
            platforms: [.tiktok, .instagram],
            velocity: [4, 4, 5, 6, 6, 7, 7, 8, 8, 9],
            velocityChangePct: 22,
            mascotSymbol: "headphones",
            accent: .mint
        ),
        Niche(
            title: "Digital Detox",
            summary: "Has entered the high-velocity zone in the last 24h.",
            heat: .alert(reason: "Velocity alert"),
            platforms: [.tiktok, .instagram, .x],
            velocity: [3, 3, 3, 4, 4, 5, 9, 14, 18, 22],
            velocityChangePct: 168,
            mascotSymbol: "moon.zzz.fill",
            accent: .alert
        )
    ]
}

// MARK: - Brief

struct Brief: Identifiable, Hashable {
    let id = UUID()
    let niche: String                // e.g. "Productivity Tech"
    let title: String                // e.g. "Notion for Solopreneurs"
    let summary: String
    let painPoints: [String]
    let desiredOutcomes: [String]
    let hookFormat: String           // "7-Sec Hook"
    let hookDetail: String
    let revealDetail: String
    let ctaPattern: String
    let goal: String
    let visualStyle: String
    let storyboard: String
    let intensity: Intensity

    enum Intensity { case low, medium, high }
}

extension Brief {
    static let sample = Brief(
        niche: "Productivity Tech",
        title: "Notion for Solopreneurs",
        summary: "Audience profiling and high-conversion content structures for the productivity niche.",
        painPoints: [
            "Digital clutter overwhelm",
            "Time planning vs. doing"
        ],
        desiredOutcomes: [
            "“Set & forget” systems",
            "Aesthetic workspace"
        ],
        hookFormat: "7-Sec Hook",
        hookDetail: "Visual: split screen comparing “Manual” vs “Automated” workflow.",
        revealDetail: "Audio: lo-fi beat drop during the workspace transition reveal.",
        ctaPattern: "Soft-sell: “Grab the template in the bio to reclaim 2 hrs/day.”",
        goal: "Drive template downloads through educational storytelling.",
        visualStyle: "Minimalist, high-key lighting, soft lavender accents.",
        storyboard: "Start with a shot of 50 browser tabs open. Cut to a single Notion page with a deep breath audio. Show the ‘Solopreneur Engine’ template in action.",
        intensity: .high
    )
}

// MARK: - Review Queue

struct ReviewItem: Identifiable, Hashable {
    enum Status: Hashable {
        case draft, signOffReady, articlePreview
    }

    struct VerifierState: Hashable {
        let claims: Bool
        let facts: Bool
        let original: Bool
    }

    let id = UUID()
    let tag: String                  // e.g. #Marketing
    let age: String                  // "2d ago"
    let title: String
    let summary: String
    let verifiers: VerifierState
    let status: Status
    let issues: [String]
    let originalityScore: Int?       // 0...100
}

extension ReviewItem {
    static let sample: [ReviewItem] = [
        ReviewItem(
            tag: "#Marketing", age: "2d ago",
            title: "Sustainable Energy Guide 2024",
            summary: "A comprehensive overview of solar and wind energy trends for residential consumers in 2024.",
            verifiers: .init(claims: true, facts: true, original: false),
            status: .draft,
            issues: ["1 claim missing citation"],
            originalityScore: nil
        ),
        ReviewItem(
            tag: "#Product", age: "5h ago",
            title: "Release Notes v1.2.0",
            summary: "Detailing the new agent-led collaborative workspace features and the enhanced Content…",
            verifiers: .init(claims: true, facts: true, original: true),
            status: .signOffReady,
            issues: [],
            originalityScore: 100
        ),
        ReviewItem(
            tag: "#Research", age: "12h ago",
            title: "The Future of AI Collaboration",
            summary: "Drafting a long-form article regarding the ethical implications of multi-agent systems in modern software engineering…",
            verifiers: .init(claims: false, facts: true, original: true),
            status: .articlePreview,
            issues: ["2 claims needing citation"],
            originalityScore: 100
        )
    ]
}

// MARK: - Agent Hub

struct AgentCard: Identifiable, Hashable {
    enum Status: Hashable {
        case syncing(label: String)
        case sniffing(label: String)
        case napping
        case storing(label: String)
    }
    let id = UUID()
    let name: String
    let role: String                 // "Processing 12 trend reports"
    let mascotSymbol: String
    let accent: Niche.AccentTint
    let status: Status
}

extension AgentCard {
    static let sample: [AgentCard] = [
        AgentCard(name: "tiktok-ingest",
                  role: "Processing 12 trend reports",
                  mascotSymbol: "globe.americas.fill",
                  accent: .lavender,
                  status: .syncing(label: "Syncing Feed")),
        AgentCard(name: "fact-verifier",
                  role: "Validating 3 active briefs",
                  mascotSymbol: "checkmark.seal.fill",
                  accent: .blush,
                  status: .sniffing(label: "Sniffing Facts")),
        AgentCard(name: "content-chef",
                  role: "Ready for orders",
                  mascotSymbol: "fork.knife.circle.fill",
                  accent: .mint,
                  status: .napping),
        AgentCard(name: "archivist",
                  role: "Indexing 1.2k entries",
                  mascotSymbol: "books.vertical.fill",
                  accent: .lavender,
                  status: .storing(label: "Wise Storing"))
    ]
}

struct MissionControlItem: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let symbol: String
    let progress: Double
}

extension MissionControlItem {
    static let sample: [MissionControlItem] = [
        .init(title: "Global Content Brief v2", symbol: "globe", progress: 0.75),
        .init(title: "Source Verification",     symbol: "magnifyingglass.circle.fill", progress: 0.40)
    ]
}

// MARK: - Library bundles

struct LibraryBundle: Identifiable, Hashable {
    enum Origin: String { case creativeHub = "Creative Hub", motionLab = "Motion Lab", analysisSuite = "Analysis Suite", designStudio = "Design Studio" }
    enum Reviewer: String { case agentZephyr = "Agent Zephyr", humanVerified = "Human Verified", leadAnalyst = "Lead Analyst", agentPixel = "Agent Pixel" }

    let id = UUID()
    let title: String
    let mascot: String
    let mascotSymbol: String
    let assets: Int
    let ledgerId: String
    let origin: Origin
    let reviewer: Reviewer
    let released: Bool
    let accent: Niche.AccentTint
    let extraCount: Int              // "+4" badge on the avatar strip
}

extension LibraryBundle {
    static let sample: [LibraryBundle] = [
        .init(title: "Echo Campaign",  mascot: "Elephant Mascot",
              mascotSymbol: "sparkles", assets: 12, ledgerId: "#882-FXP",
              origin: .creativeHub, reviewer: .agentZephyr,
              released: true, accent: .lavender, extraCount: 2),
        .init(title: "Neon Reels",     mascot: "Rabbit Mascot",
              mascotSymbol: "hare.fill", assets: 5, ledgerId: "#421-VOS",
              origin: .motionLab, reviewer: .humanVerified,
              released: true, accent: .blush, extraCount: 1),
        .init(title: "Data Briefs",    mascot: "Owl Mascot",
              mascotSymbol: "bird.fill", assets: 8, ledgerId: "#990-TRK",
              origin: .analysisSuite, reviewer: .leadAnalyst,
              released: true, accent: .mint, extraCount: 4),
        .init(title: "Style Guide",    mascot: "Bird Mascot",
              mascotSymbol: "paintbrush.pointed.fill", assets: 24, ledgerId: "#162-ART",
              origin: .designStudio, reviewer: .agentPixel,
              released: true, accent: .lavender, extraCount: 0)
    ]
}
