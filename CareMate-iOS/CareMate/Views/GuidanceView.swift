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
        ("all", "All", "square.grid.2x2.fill"),
        ("theory", "Theory", "book.fill"),
        ("practical", "Practical", "hands.sparkles.fill"),
        ("specific", "Specific Skills", "star.fill"),
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
        NavigationView {
            VStack(spacing: 0) {
                // Category filter chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(categories, id: \.0) { code, label, icon in
                            CategoryChip(
                                label: label,
                                icon: icon,
                                isSelected: selectedCategory == code
                            ) {
                                selectedCategory = code
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }

                if isLoading {
                    ProgressView().padding()
                } else if filtered.isEmpty {
                    Text("No modules found")
                        .foregroundColor(.secondary)
                        .padding()
                } else {
                    List(filtered) { module in
                        NavigationLink {
                            GuidanceModuleDetailView(module: module, language: appState.language.rawValue)
                        } label: {
                            GuidanceModuleRow(module: module, language: appState.language.rawValue)
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Caregiver Guidance")
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
            HStack(spacing: 4) {
                Image(systemName: icon)
                Text(label)
            }
            .font(.caption.bold())
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isSelected ? Color.blue : Color(.systemGray5))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(20)
        }
    }
}

// MARK: - GuidanceModuleRow

struct GuidanceModuleRow: View {
    let module: GuidanceModule
    let language: String

    var categoryColor: Color {
        switch module.category {
        case "theory":   return .blue
        case "practical": return .green
        case "specific": return .purple
        default: return .gray
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(module.title(for: language))
                    .font(.headline)
                Spacer()
                Label("\(module.durationMins) min", systemImage: "clock")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Text(module.description(for: language))
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(2)
            HStack {
                Text(module.category.capitalized)
                    .font(.caption.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(categoryColor.opacity(0.15))
                    .foregroundColor(categoryColor)
                    .cornerRadius(8)
                ForEach(module.tags.prefix(2), id: \.self) { tag in
                    Text("#\(tag)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - GuidanceModuleDetailView

struct GuidanceModuleDetailView: View {
    let module: GuidanceModule
    let language: String

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Video placeholder
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemGray5))
                        .aspectRatio(16/9, contentMode: .fit)
                    VStack {
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        Text("Watch Training Video")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .onTapGesture {
                    if let url = URL(string: module.videoUrl) {
                        UIApplication.shared.open(url)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(module.title(for: language))
                        .font(.title2.bold())
                    HStack {
                        Label("\(module.durationMins) min", systemImage: "clock")
                        Label(module.category.capitalized, systemImage: "tag")
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                }

                Text(module.description(for: language))
                    .font(.body)

                FlowTagView(tags: module.tags)
            }
            .padding()
        }
        .navigationTitle(module.title(for: language))
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - FlowTagView

struct FlowTagView: View {
    let tags: [String]
    var body: some View {
        HStack(flexibleContent: true, spacing: 8) {
            ForEach(tags, id: \.self) { tag in
                Text("#\(tag)")
                    .font(.caption)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(12)
            }
        }
    }
}

// Simple HStack that wraps (poor man's flow layout)
extension HStack {
    init(flexibleContent: Bool, spacing: CGFloat? = nil, @ViewBuilder content: () -> Content) {
        self.init(spacing: spacing, content: content)
    }
}
