import SwiftUI

struct MedicationView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = MedicationViewModel()
    @State private var showAddSheet = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if viewModel.isLoading {
                        GlassProgressView(label: "Loading medications...")
                    } else {
                        if viewModel.overdueCount > 0 {
                            overdueWarning
                        }

                        if viewModel.medications.isEmpty {
                            emptyState
                        } else {
                            LazyVStack(spacing: 12) {
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
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.top, 8)
                .padding(.bottom, 110)
            }
            .navigationTitle("Medications")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .scrollContentBackground(.hidden)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showAddSheet = true } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.blue)
                    }
                }
            }
            .sheet(isPresented: $showAddSheet) {
                AddMedicationSheet(viewModel: viewModel, userId: appState.userId)
            }
        }
        .task { await viewModel.loadMedications(userId: appState.userId) }
    }

    // MARK: - Overdue warning

    private var overdueWarning: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title2)
                .foregroundStyle(.white)
                .symbolEffect(.pulse)
            VStack(alignment: .leading, spacing: 2) {
                Text("\(viewModel.overdueCount) medication\(viewModel.overdueCount > 1 ? "s" : "") overdue")
                    .font(.headline)
                    .foregroundStyle(.white)
                Text("Please take them now")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.85))
            }
            Spacer()
        }
        .padding(16)
        .background(
            LinearGradient(colors: [.red, .orange], startPoint: .leading, endPoint: .trailing),
            in: RoundedRectangle(cornerRadius: 18)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .stroke(.white.opacity(0.3), lineWidth: 0.8)
        }
        .shadow(color: .red.opacity(0.3), radius: 12, x: 0, y: 6)
        .padding(.horizontal)
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "pills")
                .font(.system(size: 64))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.blue)
            Text("No medications scheduled")
                .font(.title3.bold())
            Text("Tap + to add a medication")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .glassCard(cornerRadius: 24, padding: 40)
        .padding(.horizontal)
    }
}

// MARK: - MedicationRow

struct MedicationRow: View {
    let med: Medication
    let language: String
    let onToggle: () -> Void

    var statusColor: Color {
        if med.taken { return .green }
        if med.isOverdue { return .red }
        return .blue
    }

    var body: some View {
        HStack(spacing: 14) {
            Button(action: onToggle) {
                ZStack {
                    Circle()
                        .fill(statusColor.opacity(0.12))
                        .frame(width: 44, height: 44)
                    Image(systemName: med.taken ? "checkmark.circle.fill" : (med.isOverdue ? "exclamationmark.circle.fill" : "circle"))
                        .font(.title2)
                        .foregroundStyle(statusColor)
                }
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 3) {
                Text(med.name(for: language))
                    .font(.headline)
                    .strikethrough(med.taken, color: .secondary)
                    .foregroundStyle(med.taken ? .secondary : .primary)
                Text(med.dosage)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if let notes = med.notes {
                    Text(notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Text(med.time)
                    .font(.subheadline.monospacedDigit().bold())
                    .foregroundStyle(.primary)
                if med.isOverdue && !med.taken {
                    Text("Overdue")
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(.red, in: Capsule())
                } else if med.taken {
                    Text("Done")
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(.green, in: Capsule())
                }
            }
        }
        .glassCard(cornerRadius: 18, padding: 14)
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
        NavigationStack {
            ZStack {
                GlassBackground().ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Medication Name", systemImage: "pills")
                                .font(.caption.bold())
                                .foregroundStyle(.secondary)
                                .textCase(.uppercase)
                            TextField("English name", text: $nameEn)
                                .padding(12)
                                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                            TextField("Myanmar name", text: $nameMy)
                                .padding(12)
                                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                        }
                        .glassCard()

                        VStack(alignment: .leading, spacing: 12) {
                            Label("Dosage & Time", systemImage: "clock")
                                .font(.caption.bold())
                                .foregroundStyle(.secondary)
                                .textCase(.uppercase)
                            TextField("Dosage (e.g. 5mg)", text: $dosage)
                                .padding(12)
                                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                            TextField("Time (HH:MM)", text: $time)
                                .padding(12)
                                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                        }
                        .glassCard()

                        VStack(alignment: .leading, spacing: 12) {
                            Label("Notes (optional)", systemImage: "note.text")
                                .font(.caption.bold())
                                .foregroundStyle(.secondary)
                                .textCase(.uppercase)
                            TextField("Side effects, instructions...", text: $notes, axis: .vertical)
                                .lineLimit(3)
                                .padding(12)
                                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                        }
                        .glassCard()
                    }
                    .padding()
                }
            }
            .navigationTitle("Add Medication")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
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
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationCornerRadius(28)
        .presentationBackground(.ultraThinMaterial)
    }
}
