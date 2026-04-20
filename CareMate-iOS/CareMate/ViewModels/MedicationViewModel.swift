import SwiftUI

@MainActor
class MedicationViewModel: ObservableObject {
    @Published var medications: [Medication] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let api = APIService.shared

    func loadMedications(userId: String) async {
        isLoading = true
        defer { isLoading = false }
        do {
            medications = try await api.get("/api/medication/\(userId)")
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func toggleTaken(_ med: Medication) async {
        guard let index = medications.firstIndex(where: { $0.id == med.id }) else { return }
        do {
            let updated: Medication = try await api.post("/api/medication/\(med.id)/toggle-taken", body: EmptyBody())
            medications[index] = updated
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func addMedication(_ med: MedicationCreate) async {
        do {
            let created: Medication = try await api.post("/api/medication/", body: med)
            medications.append(created)
            medications.sort { $0.time < $1.time }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteMedication(_ med: Medication) async {
        do {
            try await api.delete("/api/medication/\(med.id)")
            medications.removeAll { $0.id == med.id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    var overdueCount: Int {
        medications.filter { $0.isOverdue }.count
    }
}

struct EmptyBody: Codable {}
