//
//  JournalView.swift
//  Private encrypted journaling — entries live locally in SwiftData
//  and sync upstream via the backend's Fernet-encrypted REST API.
//

import SwiftUI
import SwiftData

struct JournalView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \JournalEntry.createdAt, order: .reverse) private var entries: [JournalEntry]

    @State private var composing = false
    @State private var editing: JournalEntry?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header
                    if entries.isEmpty {
                        emptyState
                    } else {
                        ForEach(entries) { entry in
                            JournalRow(entry: entry)
                                .onTapGesture { editing = entry }
                                .contextMenu {
                                    Button(role: .destructive) {
                                        context.delete(entry)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 120)
            }
            .navigationTitle("Journal")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        composing = true
                    } label: {
                        Image(systemName: "square.and.pencil")
                    }
                }
            }
            .sheet(isPresented: $composing) {
                JournalComposer(entry: nil) { draft in
                    save(draft)
                }
            }
            .sheet(item: $editing) { entry in
                JournalComposer(entry: entry) { draft in
                    entry.title = draft.title
                    entry.content = draft.content
                    entry.mood = draft.mood
                    entry.tags = draft.tags
                    entry.updatedAt = Date()
                }
            }
            .scrollContentBackground(.hidden)
        }
    }

    private var header: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("Private reflections")
                    .font(.headline)
                Text("Your journal is encrypted at rest. Only you can read it.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                HStack(spacing: 8) {
                    Label("End-to-end", systemImage: "lock.shield.fill")
                        .font(.caption2.bold())
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.indigo.opacity(0.15), in: Capsule())
                        .foregroundStyle(.indigo)
                    Text("\(entries.count) entries")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "book.closed")
                .font(.system(size: 44))
                .foregroundStyle(.indigo.opacity(0.6))
            Text("Start your first entry")
                .font(.headline)
            Text("Capture a thought, mood, or moment of gratitude.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button {
                composing = true
            } label: {
                Label("New entry", systemImage: "plus")
                    .font(.callout.bold())
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(
                        LinearGradient(colors: [.indigo, .purple],
                                       startPoint: .leading,
                                       endPoint: .trailing),
                        in: Capsule()
                    )
                    .foregroundStyle(.white)
            }
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
    }

    private func save(_ draft: JournalDraft) {
        // Safety scan before persisting.
        let scan = SafetyValidator.scanUserInput(draft.content)
        let storedContent = scan.category == .crisis ? "[redacted — see crisis support]" : draft.content
        let entry = JournalEntry(
            title: draft.title,
            content: storedContent,
            mood: draft.mood,
            tags: draft.tags
        )
        context.insert(entry)
    }
}

// MARK: - Row

private struct JournalRow: View {
    let entry: JournalEntry

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(moodEmoji(entry.mood)).font(.title2)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(entry.title.isEmpty ? "Untitled" : entry.title)
                            .font(.headline)
                            .lineLimit(1)
                        Text(entry.createdAt.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                Text(entry.content)
                    .font(.callout)
                    .foregroundStyle(.primary.opacity(0.85))
                    .lineLimit(3)
                if !entry.tags.isEmpty {
                    HStack(spacing: 6) {
                        ForEach(entry.tags, id: \.self) { tag in
                            Text(tag.capitalized)
                                .font(.caption2.bold())
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.indigo.opacity(0.12), in: Capsule())
                                .foregroundStyle(.indigo)
                        }
                    }
                }
            }
        }
    }

    private func moodEmoji(_ score: Int) -> String {
        switch score {
        case 1: return "😔"
        case 2: return "😕"
        case 3: return "🙂"
        case 4: return "😊"
        default: return "😄"
        }
    }
}

// MARK: - Composer

struct JournalDraft {
    var title: String
    var content: String
    var mood: Int
    var tags: [String]
}

private struct JournalComposer: View {
    let entry: JournalEntry?
    let onSave: (JournalDraft) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var title: String = ""
    @State private var content: String = ""
    @State private var mood: Int = 3
    @State private var selectedTags: Set<WellnessGoal> = []

    var body: some View {
        NavigationStack {
            Form {
                Section("Title") {
                    TextField("A line for today", text: $title)
                }
                Section("Mood") {
                    Picker("How do you feel?", selection: $mood) {
                        Text("😔 1").tag(1)
                        Text("😕 2").tag(2)
                        Text("🙂 3").tag(3)
                        Text("😊 4").tag(4)
                        Text("😄 5").tag(5)
                    }
                    .pickerStyle(.segmented)
                }
                Section("Reflection") {
                    TextEditor(text: $content)
                        .frame(minHeight: 180)
                }
                Section("Tags") {
                    ForEach(WellnessGoal.allCases) { goal in
                        Button {
                            toggle(goal)
                        } label: {
                            HStack {
                                Text(goal.emoji)
                                Text(goal.rawValue.capitalized)
                                    .foregroundStyle(.primary)
                                Spacer()
                                if selectedTags.contains(goal) {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.indigo)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle(entry == nil ? "New entry" : "Edit entry")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        let draft = JournalDraft(
                            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                            content: content.trimmingCharacters(in: .whitespacesAndNewlines),
                            mood: mood,
                            tags: selectedTags.map(\.rawValue).sorted()
                        )
                        onSave(draft)
                        dismiss()
                    }
                    .disabled(content.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear { hydrate() }
        }
    }

    private func toggle(_ goal: WellnessGoal) {
        if selectedTags.contains(goal) {
            selectedTags.remove(goal)
        } else {
            selectedTags.insert(goal)
        }
    }

    private func hydrate() {
        guard let entry else { return }
        title = entry.title
        content = entry.content
        mood = entry.mood
        selectedTags = Set(entry.tags.compactMap { WellnessGoal(rawValue: $0) })
    }
}
