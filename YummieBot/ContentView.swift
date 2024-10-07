import SwiftUI
import Combine

let OPEN_AI_KEY = ""
let SPOONACULAR_API_KEY = ""

extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct Recipe {
    let title: String
    let fullRecipe: String
}

// Recipe Detail View
struct RecipeDetailView: View {
    var recipe: String
    
    var body: some View {
        ScrollView {
            Text(recipe)
                .padding()
        }
        .background(Color.white)  // Set background to white in detail view
        .navigationTitle("Recipe Details")
    }
}

struct SpoonacularRecipe: Identifiable, Decodable {
    let id: Int
    let title: String
    let image: String
    let imageType: String
}

struct SpoonacularRecipeDetailView: View {
    let recipeID: Int
    @ObservedObject private var viewModel = SpoonacularViewModel()
    
    var body: some View {
        ScrollView {
            if viewModel.isLoading {
                ProgressView()
                    .padding()
            } else if let recipeDetails = viewModel.selectedRecipeDetails {
                VStack(alignment: .leading, spacing: 16) {
                    
                    // Display the image at the top
                    if let imageURL = URL(string: recipeDetails.image) {
                        AsyncImage(url: imageURL) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(maxWidth: .infinity)
                                .frame(height: 250) // Adjust the height as needed
                                .clipped() // Clip the image if it overflows
                        } placeholder: {
                            ProgressView()
                        }
                    }

                    // Display the recipe title
                    Text(recipeDetails.title)
                        .font(.title)
                        .bold()
                        .padding(.top)

                    // Display the cooking time and servings
                    HStack {
                        Text("Ready in: \(recipeDetails.readyInMinutes) minutes")
                        Spacer()
                        Text("Servings: \(recipeDetails.servings)")
                    }
                    .font(.subheadline)
                    .padding(.bottom, 16)

                    // Display the ingredients list
                    Text("Ingredients")
                        .font(.headline)

                    ForEach(recipeDetails.extendedIngredients, id: \.name) { ingredient in
                        HStack {
                            Text("- \(ingredient.name.capitalized)")
                            Spacer()
                            Text("\(ingredient.amount, specifier: "%.2f") \(ingredient.unit)")
                        }
                        .padding(.vertical, 4)
                    }

                    Divider()

                    // Display the instructions
                    Text("Instructions")
                        .font(.headline)
                        .padding(.top, 16)

                    Text(recipeDetails.instructions.isEmpty ? "No instructions available." : recipeDetails.instructions)
                        .padding(.vertical)
                }
                .padding()
            } else {
                Text("No details available.")
                    .padding()
            }
        }
        .onAppear {
            viewModel.fetchRecipeDetails(by: recipeID)
        }
        .navigationTitle("Recipe Details")
        .background(Color.white)
    }
}

class SpoonacularViewModel: ObservableObject {
    @Published var recipes: [SpoonacularRecipe] = []
    @Published var isLoading: Bool = false
    
    // For the selected recipe details
    @Published var selectedRecipeDetails: RecipeDetails?

    func fetchRecipes(ingredients: String) {
        guard let url = URL(string: "https://api.spoonacular.com/recipes/findByIngredients?apiKey=\(SPOONACULAR_API_KEY)&ingredients=\(ingredients)&number=10") else {
            print("Invalid URL")
            return
        }

        isLoading = true

        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
            }

            if let error = error {
                print("Error fetching recipes: \(error)")
                return
            }

            guard let data = data else {
                print("No data received")
                return
            }

            do {
                let recipes = try JSONDecoder().decode([SpoonacularRecipe].self, from: data)
                DispatchQueue.main.async {
                    self?.recipes = recipes
                }
            } catch {
                print("Error decoding JSON: \(error)")
            }
        }

        task.resume()
    }

    // Fetch full recipe details by ID
    func fetchRecipeDetails(by id: Int) {
        guard let url = URL(string: "https://api.spoonacular.com/recipes/\(id)/information?apiKey=\(SPOONACULAR_API_KEY)") else {
            print("Invalid URL for fetching recipe details")
            return
        }

        isLoading = true

        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
            }

            if let error = error {
                print("Error fetching recipe details: \(error)")
                return
            }

            guard let data = data else {
                print("No data received")
                return
            }

            do {
                let recipeDetails = try JSONDecoder().decode(RecipeDetails.self, from: data)
                DispatchQueue.main.async {
                    self?.selectedRecipeDetails = recipeDetails
                }
            } catch {
                print("Error decoding recipe details: \(error)")
            }
        }

        task.resume()
    }
}

// Recipe Details Model to store information from the API
// Recipe Details Model to store information from the API
struct RecipeDetails: Decodable {
    let title: String
    let readyInMinutes: Int
    let servings: Int
    let instructions: String
    let extendedIngredients: [Ingredient]
    let image: String // Add this field for the recipe image URL

    struct Ingredient: Decodable {
        let name: String
        let amount: Double
        let unit: String
    }
}

struct ContentView: View {
    @State private var userMessage: String = ""
    @State private var chatResponse: String = ""
    @State private var isLoading: Bool = false
    @State private var savedRecipes: [Recipe] = []
    @State private var ingredients: String = ""
    
    @ObservedObject private var keyboardResponder = KeyboardResponder()
    @ObservedObject private var spoonacularViewModel = SpoonacularViewModel()
    
    var body: some View {
        TabView {
            // First Tab: Chat with GPT
            ZStack {
                VStack {
                    ScrollView {
                        VStack(alignment: .leading) {
                            if !chatResponse.isEmpty {
                                Text(chatResponse)
                                    .padding()
                                    .foregroundColor(isLoading ? .gray : .black)
                                    .background(Color.white)
                                    .cornerRadius(12)
                                    .shadow(color: Color.gray.opacity(0.2), radius: 5, x: 0, y: 5)
                            }
                        }
                        .padding(.horizontal)
                    }
                    .cornerRadius(15)
                    .padding(.top)
                    
                    Spacer() // Adds flexible space between the ScrollView and the TextField/Button
                    
                    // Input and button side by side
                    HStack {
                        TextField("", text: $userMessage)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                            .shadow(color: Color.gray.opacity(0.2), radius: 5, x: 0, y: 5)
                            .padding(.leading)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .foregroundColor(Color(.darkGray))
                            .onSubmit {
                                UIApplication.shared.endEditing()
                                isLoading = true
                                sendMessageToChatGPT(message: userMessage)
                            }
                        
                        Button(action: {
                            isLoading = true
                            UIApplication.shared.endEditing()
                            sendMessageToChatGPT(message: userMessage)
                        }) {
                            Text(isLoading ? "..." : "Send")
                                .bold()
                                .frame(width: 60, height: 54)
                                .background(isLoading ? Color.gray : Color.red.opacity(0.8))
                                .foregroundColor(.white)
                                .cornerRadius(12)
                                .shadow(color: Color.red.opacity(0.3), radius: 5, x: 0, y: 5)
                        }
                        .disabled(isLoading || userMessage.isEmpty)
                        .padding(.trailing, 16)
                    }
                    .padding(.bottom, 8) // Adjust for more space below the input
                    .background(Color.white)
                    .padding(.bottom, keyboardResponder.currentHeight) // Adjust based on keyboard height
                    .animation(.easeOut(duration: 0.16)) // Smooth animation when the keyboard appears/disappears
                }
                .background(Color.white)
            }
            .tabItem {
                Image(systemName: "message.fill")
                Text("Chat")
            }
            
            // Second Tab: Saved Recipes
            NavigationView {
                List(savedRecipes, id: \.title) { recipe in
                    NavigationLink(destination: RecipeDetailView(recipe: recipe.fullRecipe)) {
                        Text(recipe.title)
                            .padding()
                    }
                }
                .navigationTitle("Saved Recipes")
            }
            .tabItem {
                Image(systemName: "doc.text")
                Text("Recipes")
            }
            
            // Third Tab: Spoonacular Recipe Search
            NavigationView {
                VStack {
                    TextField("Enter ingredients (comma separated)", text: $ingredients)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(8)
                        .padding(.horizontal)
                    
                    Button(action: {
                        spoonacularViewModel.fetchRecipes(ingredients: ingredients)
                    }) {
                        Text("Search Recipes")
                            .bold()
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                            .padding(.horizontal)
                    }
                    .padding(.top)
                    
                    if spoonacularViewModel.isLoading {
                        ProgressView()
                            .padding()
                    }
                    
                    List(spoonacularViewModel.recipes) { recipe in
                        NavigationLink(destination: SpoonacularRecipeDetailView(recipeID: recipe.id)) {
                            HStack {
                                AsyncImage(url: URL(string: recipe.image)) { image in
                                    image
                                        .resizable()
                                        .frame(width: 60, height: 60)
                                        .cornerRadius(8)
                                } placeholder: {
                                    ProgressView()
                                }
                                
                                Text(recipe.title)
                                    .bold()
                            }
                        }
                    }
                }
                .navigationTitle("Find Recipes")
            }
            .tabItem {
                Image(systemName: "magnifyingglass")
                Text("Spoonacular")
            }
        }
        .accentColor(Color.red.opacity(0.8)) // Change the tab bar icon and label color to red with opacity
    }
    
    func sendMessageToChatGPT(message: String) {
        
        print("OpenAI Key: \(OPEN_AI_KEY)")
        print("Spoonacular Key: \(SPOONACULAR_API_KEY)")
        
        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            print("Invalid URL")
            return
        }
        
        let headers = [
            "Authorization": "Bearer \(OPEN_AI_KEY)",
            "Content-Type": "application/json"
        ]
        
        let requestBody: [String: Any] = [
            "model": "gpt-4o-mini",
            "messages": [
                ["role": "system", "content": """
                You are a recipe assistant for an iOS application. Your job is to suggest recipes that are clear, concise, and easy to follow. Each recipe must include:
                1. A list of ingredients with quantities in European units (deciliter, milliliter, grams, etc.).
                2. Step-by-step instructions for preparing the dish.
                - Only use ingredients that work well together. Avoid bad combinations.
                - Be engaging and fun, but ensure the instructions are clear.
                - Always start with the title and an emoji
                """],
                ["role": "user", "content": message]
            ]
        ]
        
        guard let httpBody = try? JSONSerialization.data(withJSONObject: requestBody) else {
            print("Failed to serialize request body")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = headers
        request.httpBody = httpBody
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false
            }
            
            if let error = error {
                print("Error: \(error.localizedDescription)")
                return
            }
            
            guard let data = data else {
                print("No data received")
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let choices = json["choices"] as? [[String: Any]],
                   let message = choices.first?["message"] as? [String: Any],
                   let content = message["content"] as? String {
                    
                    // Clean the content by removing '#' and '*' characters
                    let cleanedResponse = content.replacingOccurrences(of: "#", with: "")
                        .replacingOccurrences(of: "*", with: "")
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    DispatchQueue.main.async {
                        self.chatResponse = cleanedResponse
                        
                        // Extract title from the first line of the response
                        let recipeLines = cleanedResponse.split(separator: "\n", omittingEmptySubsequences: true)
                        let recipeTitle = recipeLines.first.map(String.init) ?? "Untitled Recipe"
                        
                        // Save both title and full recipe
                        self.savedRecipes.append(Recipe(title: recipeTitle, fullRecipe: cleanedResponse))
                    }
                } else {
                    print("Failed to parse JSON")
                }
            } catch {
                print("JSON parsing error: \(error)")
            }
        }
        
        task.resume()
    }
}
