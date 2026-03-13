import SwiftUI
import PhotosUI

struct DietView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedTab = 0

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                Picker("", selection: $selectedTab) {
                    Text("Meals").tag(0)
                    Text("Recipes").tag(1)
                }
                .pickerStyle(.segmented)
                .padding()

                if selectedTab == 0 {
                    MealsTab()
                } else {
                    RecipesTab()
                }
            }
            .navigationTitle("Diet & Nutrition")
        }
    }
}

// MARK: - Meals Tab

struct MealsTab: View {
    @EnvironmentObject var appState: AppState
    @State private var meals: [Meal] = []
    @State private var isLoading = false

    let mealTypes: [MealType] = [.breakfast, .lunch, .dinner, .snack]

    var body: some View {
        List(mealTypes, id: \.self) { type in
            Section(type.displayName) {
                let typeMeals = meals.filter { $0.type == type }
                if typeMeals.isEmpty {
                    Text("No \(type.displayName.lowercased()) planned")
                        .foregroundColor(.secondary)
                        .font(.subheadline)
                } else {
                    ForEach(typeMeals) { meal in
                        HStack {
                            Image(systemName: type.icon)
                                .foregroundColor(.orange)
                            Text(meal.title)
                            Spacer()
                            Text(meal.time)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .task { await loadMeals() }
    }

    func loadMeals() async {
        isLoading = true
        meals = (try? await APIService.shared.get("/api/diet/meals/\(appState.userId)")) ?? []
        isLoading = false
    }
}

// MARK: - Recipes Tab

struct RecipesTab: View {
    @EnvironmentObject var appState: AppState
    @State private var recipes: [Recipe] = []
    @State private var isLoading = false
    @State private var showImagePicker = false
    @State private var selectedItem: PhotosPickerItem?
    @State private var isExtracting = false
    @State private var errorMessage: String?

    var body: some View {
        VStack {
            if isLoading || isExtracting {
                ProgressView(isExtracting ? "Extracting recipe with AI..." : "Loading...")
                    .padding()
            }

            List {
                Section {
                    PhotosPicker(selection: $selectedItem, matching: .images) {
                        Label("Scan Recipe from Photo", systemImage: "camera.viewfinder")
                            .foregroundColor(.blue)
                    }
                    .onChange(of: selectedItem) { item in
                        Task { await extractRecipe(from: item) }
                    }
                }

                ForEach(recipes) { recipe in
                    NavigationLink {
                        RecipeDetailView(recipe: recipe, language: appState.language.rawValue)
                    } label: {
                        RecipeRowView(recipe: recipe)
                    }
                }
                .onDelete { indices in
                    Task {
                        for i in indices {
                            let recipe = recipes[i]
                            try? await APIService.shared.delete("/api/diet/recipes/\(recipe.id)")
                            recipes.remove(atOffsets: indices)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
        }
        .task { await loadRecipes() }
        .alert("Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") { errorMessage = nil }
        } message: { Text(errorMessage ?? "") }
    }

    func loadRecipes() async {
        isLoading = true
        recipes = (try? await APIService.shared.get("/api/diet/recipes/\(appState.userId)")) ?? []
        isLoading = false
    }

    func extractRecipe(from item: PhotosPickerItem?) async {
        guard let item else { return }
        isExtracting = true
        defer { isExtracting = false }
        do {
            guard let data = try await item.loadTransferable(type: Data.self) else { return }
            let b64 = data.base64EncodedString()
            struct Req: Codable { let image_base64: String; let user_id: String }
            let recipe: Recipe = try await APIService.shared.post(
                "/api/diet/recipes/extract-from-image",
                body: Req(image_base64: b64, user_id: appState.userId)
            )
            recipes.insert(recipe, at: 0)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - RecipeRowView

struct RecipeRowView: View {
    let recipe: Recipe
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(recipe.title)
                .font(.headline)
            HStack {
                Image(systemName: "clock")
                Text(recipe.cookingTime)
                Spacer()
                Text("\(recipe.ingredientsEn.count) ingredients")
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding(.vertical, 2)
    }
}

// MARK: - RecipeDetailView

struct RecipeDetailView: View {
    let recipe: Recipe
    let language: String

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Label(recipe.cookingTime, systemImage: "clock")
                    Spacer()
                    Label("\(recipe.ingredientsEn.count) ingredients", systemImage: "list.bullet")
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.horizontal)

                Divider()

                ingredientsSection
                instructionsSection
            }
            .padding()
        }
        .navigationTitle(recipe.title)
        .navigationBarTitleDisplayMode(.large)
    }

    private var ingredientsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Ingredients")
                .font(.title3.bold())
            ForEach(Array(recipe.ingredients(for: language).enumerated()), id: \.0) { _, ingredient in
                HStack {
                    Circle().fill(.green).frame(width: 6, height: 6)
                    Text(ingredient)
                }
            }
        }
    }

    private var instructionsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Instructions")
                .font(.title3.bold())
            ForEach(Array(recipe.instructions(for: language).enumerated()), id: \.0) { i, step in
                HStack(alignment: .top, spacing: 12) {
                    Text("\(i + 1)")
                        .font(.caption.bold())
                        .frame(width: 24, height: 24)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .clipShape(Circle())
                    Text(step)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}
