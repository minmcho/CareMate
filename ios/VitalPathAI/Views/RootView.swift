//
//  RootView.swift
//  Dynamic tab shell — users can add, remove, and reorder tabs.
//

import SwiftUI

struct RootView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        @Bindable var appState = appState
        ZStack {
            AmbientBackdrop()

            TabView(selection: $appState.selectedTab) {
                ForEach(appState.visibleTabs, id: \.self) { tab in
                    tabContent(for: tab)
                        .tag(tab)
                        .tabItem { Label(tab.label, systemImage: tab.icon) }
                }

                MoreTabView()
                    .tag(AppTab.more)
                    .tabItem { Label("More", systemImage: "ellipsis.circle") }
            }
            .tint(.indigo)
            .background(.ultraThinMaterial)

            if appState.breathingVisible {
                BreathingOverlay()
                    .transition(.opacity.combined(with: .scale))
                    .zIndex(10)
            }

            if appState.crisisVisible {
                CrisisModal()
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(20)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: appState.breathingVisible)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: appState.crisisVisible)
    }

    @ViewBuilder
    private func tabContent(for tab: AppTab) -> some View {
        switch tab {
        case .home:      HomeView()
        case .plan:      PlanView()
        case .insights:  InsightsView()
        case .chat:      ChatView()
        case .vision:    VisionView()
        case .habits:    HabitsView()
        case .journal:   JournalView()
        case .community: CommunityView()
        case .manifest:  ManifestationView()
        case .profile:   ProfileView()
        case .more:      MoreTabView()
        }
    }
}

// MARK: - More Tab

struct MoreTabView: View {
    @Environment(AppState.self) private var appState
    @State private var showingEditor = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    if appState.hiddenTabs.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "checkmark.circle")
                                .font(.system(size: 40))
                                .foregroundStyle(.green)
                            Text("All Tabs Visible")
                                .font(.headline)
                            Text("Every tab is in your tab bar. Use Edit Tabs to customize.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 60)
                    } else {
                        ForEach(appState.hiddenTabs) { tab in
                            NavigationLink {
                                moreDestination(for: tab)
                            } label: {
                                HStack(spacing: 14) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .fill(Color.indigo.opacity(0.12))
                                            .frame(width: 38, height: 38)
                                        Image(systemName: tab.icon)
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundStyle(.indigo)
                                    }
                                    Text(tab.label)
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption.bold())
                                        .foregroundStyle(.tertiary)
                                }
                                .padding(14)
                                .background(
                                    .ultraThinMaterial,
                                    in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .stroke(Color.white.opacity(0.55), lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 100)
            }
            .navigationTitle("More")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingEditor = true } label: {
                        Label("Edit Tabs", systemImage: "slider.horizontal.3")
                    }
                }
            }
            .sheet(isPresented: $showingEditor) {
                TabEditorView()
            }
            .scrollContentBackground(.hidden)
        }
    }

    @ViewBuilder
    private func moreDestination(for tab: AppTab) -> some View {
        switch tab {
        case .home:      HomeView()
        case .plan:      PlanView()
        case .insights:  InsightsView()
        case .chat:      ChatView()
        case .vision:    VisionView()
        case .habits:    HabitsView()
        case .journal:   JournalView()
        case .community: CommunityView()
        case .manifest:  ManifestationView()
        case .profile:   ProfileView()
        case .more:      EmptyView()
        }
    }
}

// MARK: - Tab Editor

struct TabEditorView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    @State private var draftVisible: [AppTab] = []
    @State private var draftHidden: [AppTab] = []

    private let minTabs = 5

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(draftVisible, id: \.self) { tab in
                        HStack(spacing: 14) {
                            Image(systemName: "line.3.horizontal")
                                .foregroundStyle(.tertiary)
                            ZStack {
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(Color.indigo.opacity(0.12))
                                    .frame(width: 30, height: 30)
                                Image(systemName: tab.icon)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(.indigo)
                            }
                            Text(tab.label)
                                .font(.body)
                            Spacer()
                            if draftVisible.count > minTabs {
                                Button { withAnimation { hide(tab) } } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundStyle(.red)
                                        .font(.title3)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                    .onMove { from, to in
                        draftVisible.move(fromOffsets: from, toOffset: to)
                    }
                } header: {
                    Text("Visible Tabs (min \(minTabs))")
                } footer: {
                    Text("Drag ☰ to reorder. Tap — to hide a tab.")
                }

                if !draftHidden.isEmpty {
                    Section("Hidden Tabs") {
                        ForEach(draftHidden, id: \.self) { tab in
                            HStack(spacing: 14) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .fill(Color.secondary.opacity(0.1))
                                        .frame(width: 30, height: 30)
                                    Image(systemName: tab.icon)
                                        .font(.system(size: 13))
                                        .foregroundStyle(.secondary)
                                }
                                Text(tab.label)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Button { withAnimation { show(tab) } } label: {
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundStyle(.green)
                                        .font(.title3)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
            }
            .environment(\.editMode, .constant(.active))
            .navigationTitle("Edit Tabs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        appState.visibleTabs = draftVisible
                        appState.saveTabs()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                draftVisible = appState.visibleTabs
                draftHidden = appState.hiddenTabs
            }
        }
    }

    private func hide(_ tab: AppTab) {
        guard draftVisible.count > minTabs else { return }
        draftVisible.removeAll { $0 == tab }
        draftHidden.append(tab)
    }

    private func show(_ tab: AppTab) {
        draftHidden.removeAll { $0 == tab }
        draftVisible.append(tab)
    }
}

// MARK: - Ambient Backdrop

struct AmbientBackdrop: View {
    @State private var animate = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(.systemIndigo).opacity(0.12),
                         Color(.systemPurple).opacity(0.10),
                         Color(.systemTeal).opacity(0.10)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Circle()
                .fill(Color.indigo.opacity(0.25))
                .frame(width: 420, height: 420)
                .blur(radius: 100)
                .offset(x: animate ? -80 : -40, y: animate ? -180 : -140)

            Circle()
                .fill(Color.pink.opacity(0.22))
                .frame(width: 440, height: 440)
                .blur(radius: 120)
                .offset(x: animate ? 120 : 60, y: animate ? 280 : 220)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 14).repeatForever(autoreverses: true)) {
                animate = true
            }
        }
    }
}

// MARK: - Glass Card

struct GlassCard<Content: View>: View {
    let content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        content()
            .padding(20)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(Color.white.opacity(0.6), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.08), radius: 24, x: 0, y: 12)
    }
}
