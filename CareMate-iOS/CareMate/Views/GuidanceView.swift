import SwiftUI

struct GuidanceModule: Identifiable, Codable {
    var id: String
    var category: String
    var titleEn: String
    var titleMy: String
    var descriptionEn: String
    var descriptionMy: String
    var videoUrl: String
    var durationMins: Int
    var tags: [String]

    enum CodingKeys: String, CodingKey {
        case id, category, tags
        case titleEn       = "title_en"
        case titleMy       = "title_my"
        case descriptionEn = "description_en"
        case descriptionMy = "description_my"
        case videoUrl      = "video_url"
        case durationMins  = "duration_mins"
    }

    func title(for language: String) -> String {
        language == "my" ? titleMy : titleEn
    }

    func description(for language: String) -> String {
        language == "my" ? descriptionMy : descriptionEn
    }
}

struct GuidanceView: View {
    @EnvironmentObject var appState: AppState
    @State private var modules: [GuidanceModule] = []
    @State private var isLoading = false
    @State private var selectedCategory = "all"
    @State private var searchText = ""

    let categories = [
        ("all",      "All",            "square.grid.2x2.fill"),
        ("theory",   "Theory",         "book.fill"),
        ("practical","Practical",      "hands.sparkles.fill"),
        ("specific", "Specific Skills","star.fill"),
    ]

    var filtered: [GuidanceModule] {
        modules.filter { module in
            let matchesCategory = selectedCategory == "all" || module.category == selectedCategory
            let matchesSearch = searchText.isEmpty ||
                module.titleEn.localizedCaseInsensitiveContains(searchText) ||
                module.titleMy.localizedCaseInsensitiveContains(searchText)
            return matchesCategory && matchesSearch
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Glass category filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(categories, id: \.0) { code, label, icon in
                            CategoryChip(label: label, icon: icon, isSelected: selectedCategory == code) {
                                withAnimation(.spring(response: 0.3)) {
                                    selectedCategory = code
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                }
                .background(.ultraThinMaterial)

                ScrollView {
                    VStack(spacing: 12) {
                        if isLoading {
                            GlassProgressView(label: "Loading modules...")
                        } else if filtered.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 48))
                                    .symbolRenderingMode(.hierarchical)
                                    .foregroundStyle(.secondary)
                                Text("No modules found")
                                    .font(.title3.bold())
                                Text("Try a different search or category")
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .glassCard(cornerRadius: 24, padding: 40)
                        } else {
                            LazyVStack(spacing: 12) {
                                ForEach(filtered) { module in
                                    NavigationLink {
                                        GuidanceModuleDetailView(module: module, language: appState.language.rawValue)
                                    } label: {
                                        GuidanceModuleRow(module: module, language: appState.language.rawValue)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    .padding()
                    .padding(.bottom, 110)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Caregiver Guidance")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .searchable(text: $searchText, prompt: "Search modules...")
        }
        .task { await loadModules() }
    }

    func loadModules() async {
        isLoading = true
        modules = (try? await APIService.shared.get("/api/guidance/")) ?? []
        isLoading = false
    }
}

// MARK: - CategoryChip

struct CategoryChip: View {
    let label: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption.bold())
                Text(label)
                    .font(.caption.bold())
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 9)
            .background {
                if isSelected {
                    Capsule().fill(.blue)
                } else {
                    Capsule().fill(.ultraThinMaterial)
                }
            }
            .overlay {
                Capsule().stroke(isSelected ? .blue.opacity(0.4) : .white.opacity(0.3), lineWidth: 0.8)
            }
            .foregroundStyle(isSelected ? .white : .primary)
            .shadow(color: isSelected ? .blue.opacity(0.3) : .clear, radius: 6, x: 0, y: 3)
        }
    }
}

// MARK: - GuidanceModuleRow

struct GuidanceModuleRow: View {
    let module: GuidanceModule
    let language: String

    var categoryColor: Color {
        switch module.category {
        case "theory":    return .blue
        case "practical": return .green
        case "specific":  return .purple
        default:          return .gray
        }
    }

    var categoryIcon: String {
        switch module.category {
        case "theory":    return "book.fill"
        case "practical": return "hands.sparkles.fill"
        case "specific":  return "star.fill"
        default:          return "square.grid.2x2.fill"
        }
    }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(categoryColor.opacity(0.15))
                    .frame(width: 50, height: 50)
                    .overlay {
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(categoryColor.opacity(0.3), lineWidth: 0.8)
                    }
                Image(systemName: categoryIcon)
                    .font(.title3)
                    .foregroundStyle(categoryColor)
            }

            VStack(alignment: .leading, spacing: 5) {
                Text(module.title(for: language))
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Text(module.description(for: language))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                HStack(spacing: 6) {
                    Label("\(module.durationMins) min", systemImage: "clock")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    ForEach(module.tags.prefix(2), id: \.self) { tag in
                        Text("#\(tag)")
                            .font(.caption2)
                            .foregroundStyle(categoryColor.opacity(0.8))
                    }
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .glassCard(cornerRadius: 18, padding: 14)
    }
}

// MARK: - GuidanceModuleDetailView

struct GuidanceModuleDetailView: View {
    let module: GuidanceModule
    let language: String

    var categoryColor: Color {
        switch module.category {
        case "theory":    return .blue
        case "practical": return .green
        case "specific":  return .purple
        default:          return .gray
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Video card
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.ultraThinMaterial)
                        .aspectRatio(16/9, contentMode: .fit)
                        .overlay {
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(.white.opacity(0.35), lineWidth: 0.8)
                        }
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 72, height: 72)
                            Image(systemName: "play.fill")
                                .font(.title2)
                                .foregroundStyle(.white)
                                .offset(x: 2)
                        }
                        .shadow(color: .blue.opacity(0.4), radius: 16, x: 0, y: 6)
                        Text("Watch Training Video")
                            .font(.subheadline.bold())
                            .foregroundStyle(.secondary)
                    }
                }
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
                .onTapGesture {
                    if let url = URL(string: module.videoUrl) {
                        UIApplication.shared.open(url)
                    }
                }

                // Info card
                VStack(alignment: .leading, spacing: 10) {
                    Text(module.title(for: language))
                        .font(.title2.bold())
                    HStack(spacing: 16) {
                        Label("\(module.durationMins) min", systemImage: "clock")
                        Label(module.category.capitalized, systemImage: "tag")
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
                .glassCard()

                // Description
                VStack(alignment: .leading, spacing: 8) {
                    Text("About")
                        .font(.headline)
                    Text(module.description(for: language))
                        .font(.body)
                        .foregroundStyle(.primary.opacity(0.85))
                }
                .glassCard()

                // Tags
                if !module.tags.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Tags")
                            .font(.headline)
                        FlowTagView(tags: module.tags, color: categoryColor)
                    }
                    .glassCard()
                }
            }
            .padding()
            .padding(.bottom, 40)
        }
        .scrollContentBackground(.hidden)
        .navigationTitle(module.title(for: language))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
    }
}

// MARK: - FlowTagView

struct FlowTagView: View {
    let tags: [String]
    var color: Color = .blue

    var body: some View {
        HStack(spacing: 8) {
            ForEach(tags, id: \.self) { tag in
                Text("#\(tag)")
                    .font(.caption.bold())
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(color.opacity(0.12), in: Capsule())
                    .overlay(Capsule().stroke(color.opacity(0.25), lineWidth: 0.8))
                    .foregroundStyle(color)
            }
        }
    }
}
