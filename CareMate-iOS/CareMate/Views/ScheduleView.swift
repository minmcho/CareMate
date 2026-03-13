import SwiftUI

struct ScheduleView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = ScheduleViewModel()
    @State private var showAddSheet = false
    @State private var newTitleEn = ""
    @State private var newTitleMy = ""
    @State private var newTime = "09:00"

    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading {
                    ProgressView("Loading tasks...")
                } else if viewModel.tasks.isEmpty {
                    emptyState
                } else {
                    taskList
                }
            }
            .navigationTitle("Today's Schedule")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showAddSheet = true } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            }
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

    // MARK: - Task list

    private var taskList: some View {
        List {
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
        .listStyle(.insetGrouped)
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 60))
                .foregroundColor(.blue.opacity(0.5))
            Text("No tasks today")
                .font(.headline)
            Text("Tap + to add a task")
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Add task sheet

    private var addTaskSheet: some View {
        NavigationView {
            Form {
                Section("Task Name") {
                    TextField("English title", text: $newTitleEn)
                    TextField("Myanmar title (ဘာသာပြန်)", text: $newTitleMy)
                }
                Section("Time") {
                    TextField("HH:MM", text: $newTime)
                        .keyboardType(.numbersAndPunctuation)
                }
            }
            .navigationTitle("New Task")
            .navigationBarTitleDisplayMode(.inline)
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
                }
            }
        }
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

    var body: some View {
        HStack {
            Circle()
                .fill(statusColor)
                .frame(width: 12, height: 12)
            VStack(alignment: .leading, spacing: 2) {
                Text(task.title(for: language))
                    .font(.headline)
                    .strikethrough(task.status == .completed)
                HStack {
                    Text(task.time)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    if task.status != .completed {
                        Text("· \(timeRemaining)")
                            .font(.caption)
                            .foregroundColor(timeRemaining == "Overdue" ? .red : .secondary)
                    }
                }
            }
            Spacer()
            Button {
                onCycleStatus()
            } label: {
                Text(task.status.displayName)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor.opacity(0.15))
                    .foregroundColor(statusColor)
                    .cornerRadius(8)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }
}
