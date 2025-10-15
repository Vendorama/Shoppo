import SwiftUI
import SDWebImageSwiftUI

struct ContentView: View {
    var body: some View {
        BrowseView()
    }
}

// The original browsing UI, now with a toolbar Menu presenting About/Contact as sheets
struct BrowseView: View {
    @StateObject private var viewModel = SearchViewModel()
    @FocusState private var textFieldIsFocused: Bool
    @Environment(\.dismissSearch) private var dismissSearch
    @EnvironmentObject private var favorites: FavoritesStore

    // Sheet presentation state
    @State private var showAboutSheet = false
    @State private var showContactSheet = false
    @State private var showFAQsSheet = false
    @State private var showAddURLSheet = false
    @State private var showFavoritesSheet = false

    // Intro content state
    private let introFallback = "Shop for over 2,000,000 products in 12,000 stores from around New Zealand"
    @State private var introText: String = "Shop for over 2,000,000 products in 12,000 stores from around New Zealand"

    // Toast state
    @State private var lastUpdated: Date?
    @State private var showUpdatedToast: Bool = false

    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                let screenWidth = geometry.size.width
                let desiredItemWidth: CGFloat = 180 // you can tweak this
                let columnCount = max(Int(screenWidth / desiredItemWidth), 1)
                let columns = Array(repeating: GridItem(.flexible(), spacing: 7), count: columnCount)
                
                ScrollViewReader { proxy in
                    ZStack {
                        ScrollView {
                            // Invisible top anchor for ScrollViewReader
                            Color.clear
                                .frame(height: 0)
                                .id("top")
                            
                            if viewModel.searchType == "search" && viewModel.query.isEmpty {
                                if !viewModel.canGoBack {
                                    Text(.init(introText))
                                        .foregroundColor(.secondary)
                                        .font(.system(size: 12))
                                        .frame(maxWidth: .infinity, alignment: .center)
                                        .lineSpacing(2)
                                        .multilineTextAlignment(.center)
                                        .padding(EdgeInsets(top: 0, leading: 29, bottom: 2, trailing: 33))
                                }
                                if viewModel.lastQuery.isEmpty {
                                    Text("New Arrivals")
                                        .padding(2)
                                        .foregroundColor(.secondary)
                                        .font(.system(size: 12))
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .offset(x: 14.0, y: 0.0)
                                        .bold()
                                }
                            }
                            
                            LazyVGrid(columns: columns, spacing: 1) {
                                ForEach(Array(viewModel.products.enumerated()), id: \.element.id) { index, product in
                                    Group {
                                        if index == 0 && viewModel.searchType == "related" {
                                            ProductRowViewRelated(product: product, viewModel: viewModel)
                                        } else if index == 0 && viewModel.searchType == "vendor" {
                                            ProductRowViewVendor(product: product, viewModel: viewModel)
                                        } else {
                                            ProductRowView(product: product, viewModel: viewModel)
                                        }
                                    }
                                    .onAppear {
                                        viewModel.loadNextPageIfNeeded(currentItem: product)
                                    }
                                }
                                
                                if viewModel.isLoading {
                                    ProgressView()
                                        .padding()
                                }
                            }
                            
                            // Footer when no more pages
                            if !viewModel.hasMorePages && !viewModel.products.isEmpty && viewModel.products.count > 12 {
                                Button(action: {
                                    withAnimation {
                                        proxy.scrollTo("top", anchor: .top)
                                    }
                                    textFieldIsFocused = false
                                }) {
                                    Label("", systemImage: "chevron.up.circle.fill")
                                }
                                .buttonStyle(.plain)
                                .font(.system(size: 38))
                                .foregroundColor(.secondary)
                                .padding(10)
                                .frame(width: 100, height: 80, alignment: .center)
                                .clipped()
                                .background(Color(.systemBackground))
                                .clipShape(Circle())
                                .offset(x:5)
                                .opacity(0.3)
                            } else if viewModel.products.count < 12 {
                                /*
                                 Text("Showing all \(viewModel.products.count) products  ")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                                .padding(10)
                                .opacity(0.3)
                                 */
                            }
                            
                            if !viewModel.isLoading && viewModel.hasSearched && viewModel.products.isEmpty && !viewModel.query.isEmpty {
                                VStack {
                                    Text("No results")
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity, minHeight: 20)
                                .font(.system(size: 10))
                            }
                        }
                        .padding(EdgeInsets(top: 0, leading: 7, bottom: 0, trailing: 7))
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            // Leading Back button in the nav bar
                            ToolbarItem(placement: .navigationBarLeading) {
                                if viewModel.canGoBack {
                                    Button {
                                        viewModel.goBack()
                                        textFieldIsFocused = false
                                        dismissSearch()
                                    } label: {
                                        Label("Back", systemImage: "chevron.left")
                                    }
                                    .font(.system(size: 14))
                                    .tint(.secondary)
                                }
                            }
                            
                            // Center title/logo tap-to-focus
                            ToolbarItem(placement: .principal) {
                                if !textFieldIsFocused {
                                    Button(action: {
                                        textFieldIsFocused = true
                                        viewModel.search(reset: true, thisType: "search")
                                    }) {
                                        Image("shoppo")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(height: 28)
                                    }
                                }
                            }
                            
                            // Favorites button (trailing)
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button {
                                    showFavoritesSheet = true
                                } label: {
                                    Image(systemName: favoritesIconName)
                                        .padding(.trailing, -14)
                                    
                                    VStack(alignment: .leading) {
                                        Text("\(favorites.favorites.count)")
                                            .font(.system(size: 9))
                                            .bold()
                                            .frame(alignment: .top)
                                            .padding(5)
                                            .foregroundColor(Color(.systemBackground))
                                            .cornerRadius(22)
                                            .clipped()
                                            .background(favoritesIconColor)
                                            .clipShape(Circle())
                                    }
                                    .offset(x: -1, y: -6.0)
                                    .opacity(favoritesTotalOpacity)
                                }
                                .accessibilityLabel("Favorites")
                                .foregroundColor(.secondary)
                                .opacity(favoritesIconOpacity)
                                .padding(.trailing, -14)
                            }
                            
                            // "More" menu (trailing)
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Menu {
                                    Button {
                                        showAboutSheet = true
                                    } label: {
                                        Label("About Shoppo", systemImage: "info.circle")
                                    }
                                    Button {
                                        showContactSheet = true
                                    } label: {
                                        Label("Contact Us", systemImage: "envelope")
                                    }
                                    Button {
                                        showAddURLSheet = true
                                    } label: {
                                        Label("Add Store", systemImage: "storefront")
                                    }
                                    Button {
                                        showFAQsSheet = true
                                    } label: {
                                        Label("FAQs", systemImage: "questionmark.circle")
                                    }
                                    Divider()
                                    Button {
                                        print("[ContentView] Manual refresh tapped")
                                        hapticRefresh()
                                        withAnimation(.easeInOut) {
                                            proxy.scrollTo("top", anchor: .top)
                                        }
                                        viewModel.refreshFirstPage()
                                    } label: {
                                        Label("Refresh", systemImage: "arrow.clockwise")
                                    }
                                } label: {
                                    Label(" ", systemImage: "ellipsis.circle")
                                        .labelStyle(.iconOnly)
                                        .padding(.leading, -14)
                                        .padding(.trailing, 10)
                                }
                                .tint(.secondary)
                                .accessibilityLabel("More Iinfo")
                            }
                        }
                        
                        // search bar
                        .searchable(text: $viewModel.query, placement: .navigationBarDrawer(displayMode: .always), prompt: "discover, shop, buy ...")
                        .onSubmit(of: .search) {
                            textFieldIsFocused = false
                            viewModel.search(reset: true, thisType: "search")
                        }
                        .onChange(of: viewModel.products) {
                            textFieldIsFocused = false
                        }
                        
                        // Pull to refresh: refresh the first page and bypass cache
                        .refreshable {
                            print("[ContentView] Pull-to-refresh triggered")
                            hapticRefresh()
                            withAnimation(.easeInOut) {
                                proxy.scrollTo("top", anchor: .top)
                            }
                            viewModel.refreshFirstPage()
                        }
                        
                        // Observe loading changes to show a toast when refresh completes
                        .onChange(of: viewModel.isLoading) { oldValue, newValue in
                            if oldValue == true && newValue == false {
                                lastUpdated = Date()
                                //showJustUpdatedToast()
                            }
                        }

                        // Toast overlay
                        if showUpdatedToast {
                            VStack {
                                Spacer()
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                    Text("Updated")
                                        .font(.footnote)
                                        .foregroundColor(.primary)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(.thinMaterial)
                                .cornerRadius(12)
                                .shadow(radius: 2)
                                .padding(.bottom, 12)
                            }
                            .transition(.opacity)
                            .animation(.easeInOut(duration: 0.2), value: showUpdatedToast)
                        }
                    }
                    // Ensure first request is triggered once and visible in logs
                    .task {
                        if viewModel.products.isEmpty && viewModel.searchType == "search" {
                            print("[ContentView] First-load trigger: refreshing first page (vq=, page=1)")
                            viewModel.refreshFirstPage()
                        }
                        await loadContent(id: 1)
                    }
                }
            }
            .contentShape(Rectangle()) // Make the whole ZStack tappable
            .onTapGesture {
                textFieldIsFocused = false
            }
            .background(Color(.systemBackground))
        }
        // Sheets
        .sheet(isPresented: $showFavoritesSheet) {
            NavigationView {
                FavoritesView(viewModel: viewModel)
                    .navigationTitle("Favourites")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Done") { showFavoritesSheet = false }
                        }
                    }
            }
        }
        .sheet(isPresented: $showAboutSheet) {
            NavigationView {
                AboutView()
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") { showAboutSheet = false }
                        }
                    }
            }
        }
        .sheet(isPresented: $showContactSheet) {
            NavigationView {
                ContactView()
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") { showContactSheet = false }
                        }
                    }
            }
        }
        .sheet(isPresented: $showFAQsSheet) {
            NavigationView {
                FAQsView()
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") { showFAQsSheet = false }
                        }
                    }
            }
        }
        .sheet(isPresented: $showAddURLSheet) {
            NavigationView {
                AddURLView()
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") { showAddURLSheet = false }
                        }
                    }
            }
        }
    }

    private struct ContentResponse: Decodable {
        let content: String
    }

    @MainActor
    private func loadContent(id: Int = 1) async {
        // Keep fallback until we successfully fetch and decode
        guard let url = URL(string: "https://www.shoppo.co.nz/app/content?x=1&id=\(id)") else {
            introText = introFallback
            return
        }
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                introText = introFallback
                return
            }
            let decoded = try JSONDecoder().decode(ContentResponse.self, from: data)
            introText = decoded.content.isEmpty ? introFallback : decoded.content
        } catch {
            introText = introFallback
        }
    }

    // MARK: - Haptics
    private func hapticRefresh() {
        #if os(iOS)
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        #endif
    }

    // MARK: - Toast
    private func showJustUpdatedToast() {
        withAnimation {
            showUpdatedToast = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                showUpdatedToast = false
            }
        }
    }

    // MARK: - Helpers
    private var favoritesIconName: String {
        favorites.favorites.isEmpty ? "heart" : "heart"
        //heart.fill
    }
    private var favoritesIconColor: Color {
        favorites.favorites.isEmpty ? .secondary : .purple
    }
    private var favoritesIconBackgroundColor: Color {
        favorites.favorites.isEmpty ? Color(.systemBackground).opacity(0.4) : Color(.systemBackground).opacity(0.8)
    }
    private var favoritesIconOpacity: Double {
        favorites.favorites.isEmpty ? 0.8 : 1.0
    }
    private var favoritesTotalOpacity: Double {
        favorites.favorites.isEmpty ? 0.0 : 1.0
    }
    private var favoritesIconBackground: Double {
        favorites.favorites.isEmpty ? 0.4 : 1.0
    }
}
