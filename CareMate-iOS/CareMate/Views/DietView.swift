import SwiftUI
import PhotosUI

struct DietView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedTab = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Glass segmented picker
                Picker("", selection: $selectedTab) {
                    Text("Meals").tag(0)
                    Text("Recipes").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial)

                if selectedTab == 0 {
                    MealsTab()
                } else {
                    RecipesTab()
                }
            }
            .navigationTitle("Diet & Nutrition")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
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
        ScrollView {
            VStack(spacing: 14) {
                if isLoading {
                    GlassProgressView(label: "Loading meals...")
                } else {
                    ForEach(mealTypes, id: \.self) { type in
                        MealSectionCard(type: type, meals: meals.filter { $0.type == type })
                    }
                }
            }
            .padding()
            .padding(.bottom, 110)
        }
        .scrollContentBackground(.hidden)
        .task { await loadMeals() }
    }

    func loadMeals() async {
        isLoading = true
        meals = (try? await APIService.shared.get("/api/diet/meals/\(appState.userId)")) ?? []
        isLoading = false
    }
}

struct MealSectionCard: View {
    let type: MealType
    let meals: [Meal]

    var mealColor: Color {
        switch type {
        case .breakfast: return .orange
        case .lunch:     return .green
        case .dinner:    return .indigo
        case .snack:     return .pink
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: type.icon)
                    .font(.title3)
                    .foregroundStyle(.white)
                    .frame(width: 34, height: 34)
                    .background(mealColor, in: RoundedRectangle(cornerRadius: 10))
                Text(type.displayName)
                    .font(.headline)
                Spacer()
                Text("\(meals.count)")
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                    .frame(width: 24, height: 24)
                    .background(mealColor.opacity(0.8), in: Circle())
            }

            if meals.isEmpty {
                Text("No \(type.displayName.lowercased()) planned")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 4)
            } else {
                ForEach(meals) { meal in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(meal.title)
                                .font(.subheadline.bold())
                            Text(meal.time)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(10)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .glassCard()
    }
}

// MARK: - Recipes Tab

struct RecipesTab: View {
    @EnvironmentObject var appState: AppState
    @State private var recipes: [Recipe] = []
    @State private var isLoading = false
    @State private var selectedItem: PhotosPickerItem?
    @State private var isExtracting = false
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                // Scan button card
                PhotosPicker(selection: $selectedItem, matching: .images) {
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 48, height: 48)
                            Image(systemName: "camera.viewfinder")
                                .font(.title3)
                                .foregroundStyle(.white)
                        }
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Scan Recipe from Photo")
                                .font(.headline)
                                .foregroundStyle(.primary)
                            Text("AI-powered recipe extraction")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.secondary)
                    }
                }
                .glassCard()
                .onChange(of: selectedItem) { item in
                    Task { await extractRecipe(from: item) }
                }

                if isExtracting {
                    GlassProgressView(label: "Extracting recipe with AI...")
                } else if isLoading {
                    GlassProgressView(label: "Loading...")
                }

                if !recipes.isEmpty {
                    LazyVStack(spacing: 12) {
                        ForEach(recipes) { recipe in
                            NavigationLink {
                                RecipeDetailView(recipe: recipe, language: appState.language.rawValue)
                            } label: {
                                RecipeRowView(recipe: recipe)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                } else if !isLoading {
                    VStack(spacing: 16) {
                        Image(systemName: "fork.knife.circle")
                            .font(.system(size: 56))
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.green)
                        Text("No recipes yet")
                            .font(.title3.bold())
                        Text("Scan a recipe photo to get started")
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .glassCard(cornerRadius: 24, padding: 36)
                }
            }
            .padding()
            .padding(.bottom, 110)
        }
        .scrollContentBackground(.hidden)
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
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(LinearGradient(colors: [.green.opacity(0.7), .teal.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 52, height: 52)
                Image(systemName: "fork.knife")
                    .font(.title3)
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(recipe.title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                HStack(spacing: 10) {
                    Label(recipe.cookingTime, systemImage: "clock")
                    Text("·")
                    Text("\(recipe.ingredientsEn.count) ingredients")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .glassCard(cornerRadius: 18, padding: 14)
    }
}

// MARK: - RecipeDetailView

struct RecipeDetailView: View {
    let recipe: Recipe
    let language: String

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header card
                HStack {
                    Label(recipe.cookingTime, systemImage: "clock")
                    Spacer()
                    Label("\(recipe.ingredientsEn.count) ingredients", systemImage: "list.bullet")
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .glassCard()

                ingredientsSection
                instructionsSection
            }
            .padding()
            .padding(.bottom, 40)
        }
        .scrollContentBackground(.hidden)
        .navigationTitle(recipe.title)
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
    }

    private var ingredientsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Ingredients", systemImage: "checklist")
                .font(.title3.bold())
            ForEach(Array(recipe.ingredients(for: language).enumerated()), id: \.0) { _, ingredient in
                HStack(spacing: 10) {
                    Circle().fill(.green).frame(width: 7, height: 7)
                    Text(ingredient)
                        .font(.subheadline)
                }
            }
        }
        .glassCard()
    }

    private var instructionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Instructions", systemImage: "list.number")
                .font(.title3.bold())
            ForEach(Array(recipe.instructions(for: language).enumerated()), id: \.0) { i, step in
                HStack(alignment: .top, spacing: 12) {
                    Text("\(i + 1)")
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                        .frame(width: 26, height: 26)
                        .background(.blue, in: Circle())
                    Text(step)
                        .font(.subheadline)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .glassCard()
    }
}
