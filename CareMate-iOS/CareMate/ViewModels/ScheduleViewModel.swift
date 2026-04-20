import SwiftUI
import Combine

@MainActor
class ScheduleViewModel: ObservableObject {
    @Published var tasks: [ScheduleTask] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showAddSheet = false

    private let api = APIService.shared

    func loadTasks(userId: String) async {
        isLoading = true
        defer { isLoading = false }
        do {
            tasks = try await api.get("/api/schedule/\(userId)")
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func addTask(_ task: ScheduleTaskCreate) async {
        do {
            let created: ScheduleTask = try await api.post("/api/schedule/", body: task)
            tasks.append(created)
            tasks.sort { $0.time < $1.time }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func cycleStatus(task: ScheduleTask) async {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        let newStatus = task.status.next
        struct StatusUpdate: Codable { let status: TaskStatus }
        do {
            let updated: ScheduleTask = try await api.patch(
                "/api/schedule/\(task.id)",
                body: StatusUpdate(status: newStatus)
            )
            tasks[index] = updated
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteTask(_ task: ScheduleTask) async {
        do {
            try await api.delete("/api/schedule/\(task.id)")
            tasks.removeAll { $0.id == task.id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func timeRemaining(for task: ScheduleTask) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        guard let taskTime = formatter.date(from: task.time) else { return "" }
        let now = Date()
        let cal = Calendar.current
        var comps = cal.dateComponents([.hour, .minute], from: now)
        comps.second = 0
        let todayNow = cal.date(from: comps) ?? now
        let diff = taskTime.timeIntervalSince(todayNow)
        if diff < 0 { return "Overdue" }
        let hrs = Int(diff) / 3600
        let mins = (Int(diff) % 3600) / 60
        if hrs > 0 { return "\(hrs)h \(mins)m" }
        return "\(mins)m"
    }
}
