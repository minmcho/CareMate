//
//  CommunityView.swift
//  Knowledge-sharing community around shared wellness interests.
//  Every post/reply is safety-scanned on-device before submission;
//  content flagged as crisis is auto-hidden and surfaces crisis support.
//

import SwiftUI
import SwiftData

struct CommunityView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var context
    @Query(sort: \CommunityTopic.title) private var topics: [CommunityTopic]
    @Query(sort: \CommunityPost.createdAt, order: .reverse) private var posts: [CommunityPost]
    @Query private var profiles: [WellnessProfile]

    @State private var selectedTopic: CommunityTopic?
    @State private var filter: WellnessGoal?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header
                    filterChips
                    topicList
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 80)
            }
            .navigationTitle("Community")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { seedIfNeeded() }
            .navigationDestination(item: $selectedTopic) { topic in
                TopicDetailView(
                    topic: topic,
                    authorName: profiles.first?.displayName ?? "You",
                    onCrisis: { appState.crisisVisible = true }
                )
            }
            .scrollContentBackground(.hidden)
        }
    }

    private var header: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 6) {
                Text("Shared wellness, better together")
                    .font(.headline)
                Text("Join topics you care about, share wins, and learn from others on the same journey.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                HStack(spacing: 8) {
                    Label("Moderated", systemImage: "shield.lefthalf.filled")
                        .font(.caption2.bold())
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.emerald.opacity(0.15), in: Capsule())
                        .foregroundStyle(Color.emerald)
                    Text("\(topics.count) official topics")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chip("All", isOn: filter == nil) { filter = nil }
                ForEach(WellnessGoal.allCases) { goal in
                    chip("\(goal.emoji) \(goal.rawValue.capitalized)",
                         isOn: filter == goal) { filter = goal }
                }
            }
            .padding(.vertical, 2)
        }
    }

    private func chip(_ label: String, isOn: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.caption.bold())
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    isOn
                    ? AnyShapeStyle(LinearGradient(colors: [.indigo, .purple],
                                                   startPoint: .leading,
                                                   endPoint: .trailing))
                    : AnyShapeStyle(Color.white.opacity(0.6))
                )
                .foregroundStyle(isOn ? Color.white : Color.primary)
                .clipShape(Capsule())
                .overlay(
                    Capsule().stroke(Color.white.opacity(0.8), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var topicList: some View {
        let filtered = filter.map { goal in topics.filter { $0.category == goal.rawValue } } ?? topics
        ForEach(filtered) { topic in
            TopicRow(topic: topic) {
                selectedTopic = topic
            } onJoin: {
                toggleJoin(topic)
            }
        }
        if filtered.isEmpty {
            Text("No topics match that filter yet.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
                .padding(30)
        }
    }

    private func toggleJoin(_ topic: CommunityTopic) {
        topic.joined.toggle()
        topic.memberCount += topic.joined ? 1 : -1
    }

    private func seedIfNeeded() {
        guard topics.isEmpty else { return }
        let seed: [(String, String, String, WellnessGoal, String, Int)] = [
            ("stress-calm",   "Stress & Calm",       "Share calming techniques and stress management tips.", .stress,      "🌿", 128),
            ("better-sleep",  "Better Sleep",        "Wind-down routines, sleep hygiene, and restful nights.", .sleep,      "🌙",  95),
            ("healthy-eating","Healthy Eating",      "Nutrition tips, meal ideas, and mindful eating.",       .nutrition,  "🥗",  74),
            ("movement",      "Movement & Exercise", "Workouts, stretches, and staying active together.",     .movement,   "🏃", 112),
            ("mindfulness",   "Mindfulness",         "Meditation, breathing, and present-moment awareness.",  .mindfulness,"🧘", 156),
            ("hydration",     "Hydration",           "Water intake tips and hydration reminders.",            .hydration,  "💧",  43),
            ("journaling",    "Journaling",          "Reflective writing prompts and journaling practice.",   .mindfulness,"📝",  67),
            ("wellness-wins", "Wellness Wins",       "Celebrate milestones, streaks, and personal victories.",.movement,   "🎉",  89),
        ]
        for (slug, title, summary, category, icon, members) in seed {
            context.insert(CommunityTopic(
                slug: slug,
                title: title,
                summary: summary,
                category: category,
                icon: icon,
                memberCount: members
            ))
        }
    }
}

// MARK: - Topic Row

private struct TopicRow: View {
    let topic: CommunityTopic
    let onOpen: () -> Void
    let onJoin: () -> Void

    var body: some View {
        GlassCard {
            HStack(spacing: 12) {
                Button(action: onOpen) {
                    HStack(spacing: 12) {
                        Text(topic.icon).font(.title2)
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 6) {
                                Text(topic.title).font(.headline)
                                if topic.isOfficial {
                                    Image(systemName: "checkmark.seal.fill")
                                        .foregroundStyle(Color.emerald)
                                        .font(.caption)
                                }
                            }
                            Text(topic.summary)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                            Label("\(topic.memberCount) members", systemImage: "person.2.fill")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        Spacer(minLength: 0)
                    }
                }
                .buttonStyle(.plain)
                Button(action: onJoin) {
                    Text(topic.joined ? "Joined" : "Join")
                        .font(.caption.bold())
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            topic.joined
                            ? AnyShapeStyle(Color.secondary.opacity(0.18))
                            : AnyShapeStyle(LinearGradient(colors: [.indigo, .purple],
                                                           startPoint: .leading,
                                                           endPoint: .trailing))
                        )
                        .foregroundStyle(topic.joined ? Color.secondary : Color.white)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Topic Detail

private struct TopicDetailView: View {
    @Environment(\.modelContext) private var context
    let topic: CommunityTopic
    let authorName: String
    let onCrisis: () -> Void

    @Query private var allPosts: [CommunityPost]
    @State private var draft: String = ""

    var topicPosts: [CommunityPost] {
        allPosts
            .filter { $0.topicSlug == topic.slug && !$0.isHidden }
            .sorted { $0.createdAt > $1.createdAt }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header
                composer
                if topicPosts.isEmpty {
                    Text("No posts yet — be the first to share.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(30)
                } else {
                    ForEach(topicPosts) { post in
                        PostRow(post: post)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 80)
        }
        .navigationTitle(topic.title)
        .scrollContentBackground(.hidden)
    }

    private var header: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(topic.icon).font(.title)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(topic.title).font(.title3.bold())
                        Label("\(topic.memberCount) members", systemImage: "person.2.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button {
                        topic.joined.toggle()
                        topic.memberCount += topic.joined ? 1 : -1
                    } label: {
                        Text(topic.joined ? "Leave" : "Join")
                            .font(.caption.bold())
                            .padding(.horizontal, 12).padding(.vertical, 6)
                            .background(
                                topic.joined
                                ? AnyShapeStyle(Color.secondary.opacity(0.18))
                                : AnyShapeStyle(LinearGradient(colors: [.indigo, .purple],
                                                               startPoint: .leading,
                                                               endPoint: .trailing))
                            )
                            .foregroundStyle(topic.joined ? Color.secondary : Color.white)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
                Text(topic.summary)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var composer: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("Share a tip or question")
                    .font(.subheadline.bold())
                TextEditor(text: $draft)
                    .frame(minHeight: 80)
                    .scrollContentBackground(.hidden)
                    .background(Color.white.opacity(0.4),
                                in: RoundedRectangle(cornerRadius: 14))
                HStack {
                    Label("Scanned for safety", systemImage: "shield.lefthalf.filled")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button {
                        submit()
                    } label: {
                        Label("Post", systemImage: "paperplane.fill")
                            .font(.caption.bold())
                            .padding(.horizontal, 14).padding(.vertical, 8)
                            .background(
                                LinearGradient(colors: [.indigo, .purple],
                                               startPoint: .leading,
                                               endPoint: .trailing),
                                in: Capsule()
                            )
                            .foregroundStyle(.white)
                    }
                    .disabled(draft.trimmingCharacters(in: .whitespaces).isEmpty)
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func submit() {
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        let scan = SafetyValidator.scanUserInput(text)
        if scan.category == .crisis {
            // Hide crisis content and pop crisis modal via AppState.
            let post = CommunityPost(topicSlug: topic.slug, authorName: authorName, content: "[hidden]")
            post.safetyFlags = ["crisis"]
            post.isHidden = true
            context.insert(post)
            draft = ""
            onCrisis()
            return
        }
        let post = CommunityPost(
            topicSlug: topic.slug,
            authorName: authorName,
            content: scan.sanitized
        )
        if scan.category == .pii {
            post.safetyFlags = ["pii_redacted"]
        }
        context.insert(post)
        draft = ""
    }
}

// MARK: - Post Row

private struct PostRow: View {
    let post: CommunityPost
    @State private var liked = false

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 10) {
                    Circle()
                        .fill(LinearGradient(colors: [.indigo, .purple],
                                             startPoint: .top,
                                             endPoint: .bottom))
                        .frame(width: 28, height: 28)
                        .overlay(
                            Text(String(post.authorName.prefix(1)).uppercased())
                                .font(.caption.bold())
                                .foregroundStyle(.white)
                        )
                    VStack(alignment: .leading, spacing: 1) {
                        Text(post.authorName).font(.subheadline.bold())
                        Text(post.createdAt.formatted(.relative(presentation: .named)))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    if !post.safetyFlags.isEmpty {
                        Image(systemName: "shield.fill")
                            .foregroundStyle(.orange)
                            .font(.caption)
                    }
                }
                Text(post.content)
                    .font(.callout)
                    .foregroundStyle(.primary.opacity(0.9))
                HStack(spacing: 16) {
                    Button {
                        liked.toggle()
                        post.likeCount += liked ? 1 : -1
                    } label: {
                        Label("\(post.likeCount)", systemImage: liked ? "heart.fill" : "heart")
                            .foregroundStyle(liked ? .pink : .secondary)
                    }
                    .buttonStyle(.plain)

                    Label("\(post.replyCount)", systemImage: "bubble.right")
                        .foregroundStyle(.secondary)
                }
                .font(.caption)
            }
        }
    }
}

// MARK: - Emerald convenience

private extension Color {
    static var emerald: Color { Color(red: 0.13, green: 0.77, blue: 0.47) }
}
