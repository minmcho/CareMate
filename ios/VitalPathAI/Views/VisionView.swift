//
//  VisionView.swift
//  Multi-modal video analysis surface (meal / movement).
//

import SwiftUI

struct VisionView: View {
    @State private var mode: Mode = .meal
    @State private var recording = false
    @State private var analysing = false
    @State private var result: VisionResult?

    enum Mode: String { case meal, exercise }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    modePicker
                    cameraPreview
                    if let result {
                        AnalysisCard(result: result)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 120)
            }
            .navigationTitle("Vision")
            .scrollContentBackground(.hidden)
        }
    }

    private var modePicker: some View {
        HStack(spacing: 12) {
            modeButton(.meal, label: "Meal", icon: "leaf.fill", tint: .green)
            modeButton(.exercise, label: "Movement", icon: "figure.run", tint: .blue)
        }
    }

    private func modeButton(_ value: Mode, label: String, icon: String, tint: Color) -> some View {
        Button {
            mode = value
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: icon).font(.title3)
                Text(label).font(.headline)
                Text("Qwen 3.5 VL").font(.caption2).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(
                mode == value
                    ? AnyShapeStyle(LinearGradient(colors: [tint, tint.opacity(0.7)],
                                                   startPoint: .top, endPoint: .bottom))
                    : AnyShapeStyle(.ultraThinMaterial)
            )
            .foregroundStyle(mode == value ? .white : .primary)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var cameraPreview: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28)
                .fill(LinearGradient(colors: [.black, .gray.opacity(0.4)],
                                     startPoint: .top, endPoint: .bottom))
                .aspectRatio(4/5, contentMode: .fit)

            RoundedRectangle(cornerRadius: 22)
                .strokeBorder(Color.white.opacity(0.25), lineWidth: 1)
                .padding(16)
                .aspectRatio(4/5, contentMode: .fit)

            VStack {
                Spacer()
                HStack {
                    if !recording && !analysing {
                        Button("Start") { recording = true }
                            .buttonStyle(.borderedProminent)
                            .buttonBorderShape(.capsule)
                            .tint(.indigo)
                    } else if recording {
                        Button("Analyze") { Task { await runAnalysis() } }
                            .buttonStyle(.borderedProminent)
                            .buttonBorderShape(.capsule)
                            .tint(.red)
                    } else {
                        ProgressView("Analyzing…").foregroundStyle(.white)
                    }
                }
                .padding(.bottom, 20)
            }
        }
    }

    private func runAnalysis() async {
        recording = false
        analysing = true
        try? await Task.sleep(nanoseconds: 900_000_000)
        analysing = false
        withAnimation(.spring) {
            result = VisionResult(
                mode: mode,
                score: 86,
                highlights: ["Colourful vegetables", "Lean protein"],
                cautions: [],
                nutritionEstimate: mode == .meal ? "Balanced plate with greens, protein and whole grains." : nil,
                formNotes: mode == .exercise ? ["Knees behind toes", "Brace core"] : nil
            )
        }
    }
}

struct VisionResult {
    let mode: VisionView.Mode
    let score: Int
    let highlights: [String]
    let cautions: [String]
    let nutritionEstimate: String?
    let formNotes: [String]?
}

struct AnalysisCard: View {
    let result: VisionResult

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text(result.mode == .meal ? "Meal" : "Movement")
                        .font(.title3.bold())
                    Spacer()
                    Label("Wellness-safe", systemImage: "checkmark.shield.fill")
                        .font(.caption.bold())
                        .foregroundStyle(.green)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Wellness score").font(.caption).foregroundStyle(.secondary)
                        Spacer()
                        Text("\(result.score)/100").font(.caption.bold())
                    }
                    ProgressView(value: Double(result.score), total: 100)
                        .tint(LinearGradient(colors: [.green, .teal, .blue],
                                             startPoint: .leading, endPoint: .trailing))
                }

                if let nutrition = result.nutritionEstimate {
                    InfoBlock(title: "Nutrition estimate", text: nutrition)
                }
                if let notes = result.formNotes, !notes.isEmpty {
                    InfoBlock(title: "Form notes", list: notes)
                }
                if !result.highlights.isEmpty {
                    InfoBlock(title: "Highlights", list: result.highlights)
                }
                if !result.cautions.isEmpty {
                    InfoBlock(title: "Gentle cautions", list: result.cautions)
                }
            }
        }
    }
}

struct InfoBlock: View {
    let title: String
    var text: String?
    var list: [String]?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased())
                .font(.caption2.bold())
                .foregroundStyle(.secondary)
            if let text {
                Text(text).font(.body)
            }
            if let list {
                ForEach(list, id: \.self) { item in
                    HStack(alignment: .top, spacing: 6) {
                        Text("•").foregroundStyle(.indigo)
                        Text(item)
                    }
                }
            }
        }
    }
}
