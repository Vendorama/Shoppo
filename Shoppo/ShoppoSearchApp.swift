import SwiftUI

@main
struct ShoppoSearchApp: App {
    @StateObject private var favorites = FavoritesStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(favorites)
        }
    }
}
extension Color {
    static let lightGray = Color(red: 0.8, green: 0.8, blue: 0.8)
}
