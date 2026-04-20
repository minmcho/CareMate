import SwiftUI

struct ScheduleView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = ScheduleViewModel()
    @State private var showAddSheet = false
    @State private var newTitleEn = ""
    @State private var newTitleMy = ""
    @State private var newTime = "09:00"

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if viewModel.isLoading {
                        GlassProgressView(label: "Loading tasks...")
                    } else if viewModel.tasks.isEmpty {
                        emptyState
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.tasks) { task in
                                TaskRow(
                                    task: task,
                                    language: appState.language.rawValue,
                                    timeRemaining: viewModel.timeRemaining(for: task)
                                ) {
                                    Task { await viewModel.cycleStatus(task: task) }
                                }
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        Task { await viewModel.deleteTask(task) }
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.top, 8)
                .padding(.bottom, 110)
            }
            .navigationTitle("Today's Schedule")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showAddSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.blue)
                    }
                }
            }
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .scrollContentBackground(.hidden)
            .sheet(isPresented: $showAddSheet) {
                addTaskSheet
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
        .task { await viewModel.loadTasks(userId: appState.userId) }
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 64))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.blue)
            Text("No tasks today")
                .font(.title3.bold())
            Text("Tap + to add your first task")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .glassCard(cornerRadius: 24, padding: 40)
        .padding(.horizontal)
    }

    // MARK: - Add task sheet

    private var addTaskSheet: some View {
        NavigationStack {
            ZStack {
                GlassBackground().ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Task Name", systemImage: "text.cursor")
                                .font(.caption.bold())
                                .foregroundStyle(.secondary)
                                .textCase(.uppercase)
                            TextField("English title", text: $newTitleEn)
                                .padding(12)
                                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                            TextField("Myanmar title (ဘာသာပြန်)", text: $newTitleMy)
                                .padding(12)
                                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                        }
                        .glassCard()

                        VStack(alignment: .leading, spacing: 12) {
                            Label("Time", systemImage: "clock")
                                .font(.caption.bold())
                                .foregroundStyle(.secondary)
                                .textCase(.uppercase)
                            TextField("HH:MM", text: $newTime)
                                .keyboardType(.numbersAndPunctuation)
                                .padding(12)
                                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                        }
                        .glassCard()
                    }
                    .padding()
                }
            }
            .navigationTitle("New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showAddSheet = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        Task {
                            let task = ScheduleTaskCreate(
                                titleEn: newTitleEn,
                                titleMy: newTitleMy.isEmpty ? newTitleEn : newTitleMy,
                                time: newTime,
                                userId: appState.userId
                            )
                            await viewModel.addTask(task)
                            showAddSheet = false
                            newTitleEn = ""
                            newTitleMy = ""
                            newTime = "09:00"
                        }
                    }
                    .disabled(newTitleEn.isEmpty)
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationCornerRadius(28)
        .presentationBackground(.ultraThinMaterial)
    }
}

// MARK: - TaskRow

struct TaskRow: View {
    let task: ScheduleTask
    let language: String
    let timeRemaining: String
    let onCycleStatus: () -> Void

    var statusColor: Color {
        switch task.status {
        case .pending:    return .orange
        case .inProgress: return .blue
        case .completed:  return .green
        }
    }

    var statusIcon: String {
        switch task.status {
        case .pending:    return "circle"
        case .inProgress: return "arrow.trianglehead.clockwise.rotate.90.circle.fill"
        case .completed:  return "checkmark.circle.fill"
        }
    }

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: statusIcon)
                .font(.title2)
                .foregroundStyle(statusColor)
                .symbolEffect(.pulse, isActive: task.status == .inProgress)

            VStack(alignment: .leading, spacing: 3) {
                Text(task.title(for: language))
                    .font(.headline)
                    .strikethrough(task.status == .completed, color: .secondary)
                    .foregroundStyle(task.status == .completed ? .secondary : .primary)
                HStack(spacing: 6) {
                    Label(task.time, systemImage: "clock")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if task.status != .completed {
                        Text("·")
                            .foregroundStyle(.secondary)
                        Text(timeRemaining)
                            .font(.caption)
                            .foregroundStyle(timeRemaining == "Overdue" ? .red : .secondary)
                    }
                }
            }

            Spacer()

            Button(action: onCycleStatus) {
                Text(task.status.displayName)
                    .font(.caption.bold())
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(statusColor.opacity(0.15), in: Capsule())
                    .foregroundStyle(statusColor)
                    .overlay(Capsule().stroke(statusColor.opacity(0.3), lineWidth: 0.8))
            }
            .buttonStyle(.plain)
        }
        .glassCard(cornerRadius: 18, padding: 14)
    }
}

// MARK: - Shared Loading View

struct GlassProgressView: View {
    let label: String
    var body: some View {
        VStack(spacing: 12) {
            ProgressView()
                .scaleEffect(1.2)
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .glassCard(cornerRadius: 20, padding: 32)
        .padding(.horizontal)
    }
}
