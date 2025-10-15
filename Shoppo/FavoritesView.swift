import SwiftUI
import SDWebImageSwiftUI

struct FavoritesView: View {
    @EnvironmentObject private var favorites: FavoritesStore
    @ObservedObject var viewModel: SearchViewModel

    @State private var loadedFavorites: [Product] = []
    @State private var isLoading: Bool = false
    @AppStorage("favorites_layout") private var showGrid: Bool = false
    @State private var confirmRemoveAll: Bool = false

    // Dismiss the sheet from within this view
    @Environment(\.dismiss) private var dismissSheet

    // Build a stable string of IDs for dependency tracking and requests
    private var orderedIDs: [String] {
        favorites.orderedIDsByDateAddedDesc()
    }
    private var favoriteIDsCSV: String {
        orderedIDs.joined(separator: ",")
    }
    
    // Cache-first view models
    private var cachedOrderedProducts: [Product] {
        orderedIDs.compactMap { favorites.cachedProducts[$0] }
    }
    private var missingIDs: [String] {
        let cachedSet = Set(cachedOrderedProducts.map { $0.id })
        return orderedIDs.filter { !cachedSet.contains($0) }
    }

    var body: some View {
        Group {
            if favorites.favorites.isEmpty {
                emptyState
            } else if showGrid {
                gridView
            } else {
                listView
            }
        }
        .navigationBarItems(
            leading: toggleViewButton,
            trailing: removeAllButton
        )
        .confirmationDialog(
            "Remove all favourites?",
            isPresented: $confirmRemoveAll,
            titleVisibility: .visible
        ) {
            Button("Remove All", role: .destructive) {
                favorites.removeAll()
                loadedFavorites = []
            }
            Button("Cancel", role: .cancel) { }
        }
        // On appearance or when IDs change, show cache immediately and fetch any missing
        .task(id: favoriteIDsCSV) {
            await loadFromCacheThenFetchMissing()
        }
        .refreshable {
            await fetchAllFavoritesReplacingCache()
        }
    }
    
    // MARK: - Subviews
    
    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "heart")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            Text("No favourites yet")
                .font(.headline)
            Text("Tap the heart on any product to save it here.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
    
    private var toggleViewButton: some View {
        Button {
            withAnimation(.easeInOut) {
                showGrid.toggle()
            }
        } label: {
            Image(systemName: showGrid ? "list.bullet" : "square.grid.2x2")
        }
        .accessibilityLabel(showGrid ? "Show list" : "Show grid")
    }
    
    private var removeAllButton: some View {
        Button(role: .destructive) {
            confirmRemoveAll = true
        } label: {
            Image(systemName: "trash")
        }
        .disabled(favorites.favorites.isEmpty)
        .accessibilityLabel("Remove all favourites")
    }
    
    private var listView: some View {
        let items = mergedProducts()
        return Group {
            if isLoading && items.isEmpty {
                VStack {
                    ProgressView()
                    Text("Loading favourites…")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemBackground))
            } else if items.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "heart.slash")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    Text("No details found for favourites")
                        .font(.headline)
                    Text("They may be unavailable. You can remove items or try again later.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemBackground))
            } else {
                List {
                    ForEach(items, id: \.id) { product in
                        NavigationLink(
                            destination:
                                ProductDetailViewShoppo(
                                    product: product,
                                    viewModel: viewModel,
                                    onRequestDismissContainer: { dismissSheet() }
                                )
                        ) {
                            HStack(spacing: 12) {
                                if let url = URL(string: product.image) {
                                    WebImage(url: url)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 60, height: 60)
                                        .clipped()
                                        .cornerRadius(8)
                                } else {
                                    Rectangle()
                                        .fill(Color(.secondarySystemBackground))
                                        .frame(width: 60, height: 60)
                                        .cornerRadius(8)
                                }
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(product.name)
                                        .font(.subheadline)
                                        .lineLimit(1)
                                    PriceView(price: product.price, sale_price: product.sale_price)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        //.font(.footnote)
                                    Text(product.vendor_name)
                                        .font(.subheadline)
                                        .lineLimit(2)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                
                                Button {
                                    favorites.toggleFavorite(product.id)
                                    removeFromLocal(product.id)
                                } label: {
                                    Image(systemName: favorites.isFavorite(product.id) ? "heart.fill" : "heart")
                                        .foregroundColor(favorites.isFavorite(product.id) ? .purple : .secondary)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
    }
    
    private var gridView: some View {
        let items = mergedProducts()
        let columns = [GridItem(.adaptive(minimum: 80), spacing: 12)]
        return ScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(items, id: \.id) { product in
                    NavigationLink(
                        destination:
                            ProductDetailViewShoppo(
                                product: product,
                                viewModel: viewModel,
                                onRequestDismissContainer: { dismissSheet() }
                            )
                    ) {
                        VStack(spacing: 6) {
                            if let url = URL(string: product.image) {
                                WebImage(url: url)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxWidth: .infinity, maxHeight: 160)
                                    .background(Color(.systemBackground))
                                    .cornerRadius(8)
                            } else {
                                Rectangle()
                                    .fill(Color(.secondarySystemBackground))
                                    .frame(height: 160)
                                    .cornerRadius(8)
                            }
                            // Grid shows image + price only
                            PriceView(price: product.price, sale_price: product.sale_price)
                                .font(.footnote)
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                        .padding(8)
                        .background(Color(.systemBackground))
                        .cornerRadius(10)
                        .overlay(
                            HStack {
                                Spacer()
                                VStack {
                                    Button {
                                        favorites.toggleFavorite(product.id)
                                        removeFromLocal(product.id)
                                    } label: {
                                        Image(systemName: favorites.isFavorite(product.id) ? "heart.fill" : "heart")
                                            .foregroundColor(favorites.isFavorite(product.id) ? .purple : .secondary)
                                            .padding(6)
                                            .background(.thinMaterial)
                                            .clipShape(Circle())
                                    }
                                    .buttonStyle(.plain)
                                    Spacer()
                                }
                            }
                            .padding(6)
                        )
                        .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)
        }
        .background(Color(.systemGroupedBackground))
    }
    
    // MARK: - Data helpers
    
    private func mergedProducts() -> [Product] {
        var ordered: [Product] = []
        var seen = Set<String>()
        for id in orderedIDs {
            if let p = favorites.cachedProducts[id] {
                ordered.append(p)
                seen.insert(id)
            }
        }
        for p in loadedFavorites where !seen.contains(p.id) {
            ordered.append(p)
            seen.insert(p.id)
        }
        return ordered
    }
    
    private func removeFromLocal(_ id: String) {
        if !favorites.isFavorite(id) {
            loadedFavorites.removeAll { $0.id == id }
        }
    }
    
    // MARK: - Networking
    
    @MainActor
    private func setLoading(_ value: Bool) {
        isLoading = value
    }
    
    private func loadFromCacheThenFetchMissing() async {
        await MainActor.run {
            loadedFavorites = []
        }
        guard !missingIDs.isEmpty else { return }
        await fetch(ids: missingIDs, replaceAll: false)
    }
    
    private func fetchAllFavoritesReplacingCache() async {
        let ids = orderedIDs
        guard !ids.isEmpty else {
            await MainActor.run {
                loadedFavorites = []
            }
            return
        }
        await fetch(ids: ids, replaceAll: true)
    }
    
    private func fetch(ids: [String], replaceAll: Bool) async {
        await setLoading(true)
        defer { Task { await setLoading(false) } }
        
        let idsCSV = ids.joined(separator: ",")
        guard !idsCSV.isEmpty else { return }
        
        var components = URLComponents(string: "https://www.shoppo.co.nz/app/")!
        components.queryItems = [
            URLQueryItem(name: "fv", value: idsCSV)
        ]
        guard let url = components.url else { return }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else { return }
            let decoded = try JSONDecoder().decode(ProductsResponse.self, from: data)
            let products = decoded.results
            
            await MainActor.run {
                if replaceAll {
                    favorites.updateCache(with: products)
                    loadedFavorites = products
                } else {
                    favorites.updateCache(with: products)
                    var existing = loadedFavorites
                    var seen = Set(existing.map { $0.id })
                    for p in products where !seen.contains(p.id) {
                        existing.append(p)
                        seen.insert(p.id)
                    }
                    loadedFavorites = existing
                }
            }
        } catch {
            // Silent failure: keep current cache/UI
        }
    }
}
