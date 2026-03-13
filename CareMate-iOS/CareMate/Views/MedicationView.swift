import SwiftUI

struct MedicationView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = MedicationViewModel()
    @State private var showAddSheet = false

    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading {
                    ProgressView("Loading medications...")
                } else if viewModel.medications.isEmpty {
                    emptyState
                } else {
                    medicationList
                }
            }
            .navigationTitle("Medications")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showAddSheet = true } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            }
            .sheet(isPresented: $showAddSheet) {
                AddMedicationSheet(viewModel: viewModel, userId: appState.userId)
            }
        }
        .task { await viewModel.loadMedications(userId: appState.userId) }
    }

    private var medicationList: some View {
        List {
            if viewModel.overdueCount > 0 {
                Section {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                        Text("\(viewModel.overdueCount) medication(s) overdue")
                            .foregroundColor(.red)
                            .font(.subheadline.bold())
                    }
                }
            }

            Section("Today's Medications") {
                ForEach(viewModel.medications) { med in
                    MedicationRow(med: med, language: appState.language.rawValue) {
                        Task { await viewModel.toggleTaken(med) }
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            Task { await viewModel.deleteMedication(med) }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "pills")
                .font(.system(size: 60))
                .foregroundColor(.blue.opacity(0.5))
            Text("No medications scheduled")
                .font(.headline)
        }
    }
}

// MARK: - MedicationRow

struct MedicationRow: View {
    let med: Medication
    let language: String
    let onToggle: () -> Void

    var body: some View {
        HStack {
            Button(action: onToggle) {
                Image(systemName: med.taken ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(med.taken ? .green : (med.isOverdue ? .red : .gray))
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text(med.name(for: language))
                    .font(.headline)
                    .strikethrough(med.taken)
                Text(med.dosage)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                if let notes = med.notes {
                    Text(notes)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
            VStack(alignment: .trailing) {
                Text(med.time)
                    .font(.subheadline.monospacedDigit())
                if med.isOverdue && !med.taken {
                    Text("Overdue")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - AddMedicationSheet

struct AddMedicationSheet: View {
    @ObservedObject var viewModel: MedicationViewModel
    let userId: String
    @Environment(\.dismiss) var dismiss

    @State private var nameEn = ""
    @State private var nameMy = ""
    @State private var dosage = ""
    @State private var time = "08:00"
    @State private var notes = ""

    var body: some View {
        NavigationView {
            Form {
                Section("Medication Name") {
                    TextField("English name", text: $nameEn)
                    TextField("Myanmar name", text: $nameMy)
                }
                Section("Dosage & Time") {
                    TextField("Dosage (e.g. 5mg)", text: $dosage)
                    TextField("Time (HH:MM)", text: $time)
                }
                Section("Notes (optional)") {
                    TextField("Side effects, instructions...", text: $notes, axis: .vertical)
                        .lineLimit(3)
                }
            }
            .navigationTitle("Add Medication")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        Task {
                            let med = MedicationCreate(
                                nameEn: nameEn,
                                nameMy: nameMy.isEmpty ? nameEn : nameMy,
                                dosage: dosage,
                                time: time,
                                notes: notes.isEmpty ? nil : notes,
                                userId: userId
                            )
                            await viewModel.addMedication(med)
                            dismiss()
                        }
                    }
                    .disabled(nameEn.isEmpty || dosage.isEmpty)
                }
            }
        }
    }
}
