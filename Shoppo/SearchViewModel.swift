import SwiftUI
import Foundation

struct ProductsResponse: Decodable {
    let results: [Product]
    let total_count: Int
    let page: Int
    let per_page: Int
}

class SearchViewModel: ObservableObject {
    
    @Published var products: [Product] = []
    @Published private var historyStack: [(products: [Product], query: String, searchType: String)] = []
    
    @Published var query: String = ""
    @Published var isLoading: Bool = false
    @Published var hasMorePages: Bool = true
    @Published var searchID = UUID()
    @Published var searchType: String = "search"
    @Published var lastQuery: String = ""
    @Published var lastSearchType: String = "search"
    @Published var totalResults: Int? = nil  // <-- NEW
    @Published var hasSearched: Bool = false
    
    // Pagination
    private var currentPage = 1
    private var isFetching = false
    
    // Context for paginated endpoints
    private var currentRelatedID: String?
    private var currentVendorID: String?
    
    // Toggle to enable/disable debug logging
    private let debugLogging: Bool = true

    // Session-scoped URLSession with in-memory cache only (no disk persistence)
    private let session: URLSession = {
        let cache = URLCache(memoryCapacity: 50 * 1024 * 1024, // 50 MB
                             diskCapacity: 0,
                             diskPath: nil)
        let config = URLSessionConfiguration.default
        config.urlCache = cache
        config.requestCachePolicy = .useProtocolCachePolicy
        // Optional: accept gzip/deflate/brotli automatically (default behavior applies)
        return URLSession(configuration: config)
    }()
    
    func search(reset: Bool = true, thisType: String = "search") {
        if !products.isEmpty {
            historyStack.append((products: products, query: lastQuery, searchType: lastSearchType))
        }
        lastQuery = query
        lastSearchType = searchType
        guard !isFetching else { return }

        products = []
        currentPage = 1
        hasMorePages = true
        searchID = UUID()
        searchType = thisType
        currentRelatedID = nil
        currentVendorID = nil
        totalResults = nil
        
        fetchPage()
    }
    
    /// Accepts a `Product` and uses its `.id` as the vs value for related searches.
    func searchRelated(to product: Product) {
        if !products.isEmpty {
            historyStack.append((products: products, query: lastQuery, searchType: searchType))
        }
        lastQuery = query
        lastSearchType = searchType
        self.products = []
        self.isLoading = true
        self.hasMorePages = true
        self.currentPage = 1
        searchType = "related"
        currentRelatedID = product.id
        currentVendorID = nil
        totalResults = nil

        fetchPage(relatedTo: product.id)
    }
    
    func searchVendor(to vendorID: String) {
        if !products.isEmpty {
            historyStack.append((products: products, query: lastQuery, searchType: searchType))
        }
        lastQuery = query
        lastSearchType = searchType
        self.products = []
        self.isLoading = true
        self.hasMorePages = true
        self.currentPage = 1
        searchType = "vendor"
        currentVendorID = vendorID
        currentRelatedID = nil
        totalResults = nil

        fetchPage(vendorID: vendorID)
    }
    
    func loadNextPageIfNeeded(currentItem item: Product?) {
        guard let item = item else { return }
        // Trigger when the item is within the last 6 items
        let thresholdIndex = products.index(products.endIndex, offsetBy: -6, limitedBy: products.startIndex) ?? products.startIndex
        if let itemIndex = products.firstIndex(where: { $0.id == item.id }), itemIndex >= thresholdIndex {
            switch searchType {
            case "related":
                loadNextPage(relatedTo: currentRelatedID)
            case "vendor":
                loadNextPage(vendorID: currentVendorID)
            default:
                loadNextPage()
            }
        }
    }
    
    func loadNextPage(relatedTo relatedID: String? = nil, vendorID: String? = nil) {
        guard hasMorePages, !isFetching else { return }
        currentPage += 1
        fetchPage(relatedTo: relatedID ?? currentRelatedID, vendorID: vendorID ?? currentVendorID, append: true)
    }
    
    // Public refresh helpers
    
    // Refresh the current context from the start (page 1), bypassing cache.
    func refreshFirstPage() {
        guard !isFetching else { return }
        hasMorePages = true
        currentPage = 1
        totalResults = nil
        products = []
        fetchPage(relatedTo: currentRelatedID, vendorID: currentVendorID, append: false, forceRefresh: true)
    }
    
    // Refresh the currently visible page (without resetting to page 1), bypassing cache.
    func refreshCurrentPage() {
        guard !isFetching else { return }
        fetchPage(relatedTo: currentRelatedID, vendorID: currentVendorID, append: false, forceRefresh: true)
    }
    
    // Convenience alias: decide what “refresh” means for your UI.
    func refresh() {
        refreshFirstPage()
    }
    
    // forceRefresh: set to true if you want to bypass cache for this specific call
    private func fetchPage(relatedTo relatedID: String? = nil, vendorID: String? = nil, append: Bool = false, forceRefresh: Bool = false) {
        guard !isFetching else { return }
        isFetching = true
        isLoading = true
        
        let base = "https://www.shoppo.co.nz/app/"
        var components = URLComponents(string: base)!
        var queryItems: [URLQueryItem] = []
        
        switch searchType {
        case "related":
            guard let vsValue = relatedID else {
                isFetching = false
                isLoading = false
                if debugLogging { print("[SearchVM] Missing relatedID for related fetch. Aborting page \(currentPage).") }
                return
            }
            queryItems.append(URLQueryItem(name: "vs", value: vsValue))
        case "vendor":
            guard let vid = vendorID else {
                isFetching = false
                isLoading = false
                if debugLogging { print("[SearchVM] Missing vendorID for vendor fetch. Aborting page \(currentPage).") }
                return
            }
            queryItems.append(URLQueryItem(name: "vu", value: vid))
        default:
            queryItems.append(URLQueryItem(name: "vq", value: query))
        }
        
        // Do NOT add a timestamp cache-buster. Allow session cache to work.
        // Page starts at 1
        queryItems.append(URLQueryItem(name: "page", value: String(currentPage)))
        components.queryItems = queryItems
        
        guard let url = components.url else {
            isFetching = false
            isLoading = false
            print("[SearchVM] Error building URL for page \(currentPage).")
            return
        }
        
        if debugLogging {
            print("[SearchVM] Fetching page \(currentPage) [\(searchType)] -> \(url.absoluteString)")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        // Default: use protocol cache policy (honors Cache-Control/ETag)
        request.cachePolicy = forceRefresh ? .reloadIgnoringLocalCacheData : .useProtocolCachePolicy
        
        session.dataTask(with: request) { data, response, error in
            let status = (response as? HTTPURLResponse)?.statusCode
            if self.debugLogging {
                if let status = status {
                    print("[SearchVM] HTTP status: \(status) for page \(self.currentPage)")
                } else {
                    print("[SearchVM] No HTTP status for page \(self.currentPage)")
                }
            }
            
            DispatchQueue.main.async {
                self.isFetching = false
                self.isLoading = false
                self.hasSearched = true
            }
            if let error = error {
                print("[SearchVM] Network error: \(error.localizedDescription)")
                return
            }
            guard let data = data else {
                print("[SearchVM] No data received.")
                return
            }
            do {
                let response = try JSONDecoder().decode(ProductsResponse.self, from: data)
                let newProducts = response.results
                if self.debugLogging {
                    print("[SearchVM] Decoded \(newProducts.count) items on page \(self.currentPage). Append: \(append)")
                    print("[SearchVM] Total results: \(response.total_count)")
                }
                DispatchQueue.main.async {
                    self.totalResults = response.total_count
                    if append {
                        self.products.append(contentsOf: newProducts)
                    } else {
                        self.products = newProducts
                    }
                    // If we've loaded all products, stop pagination
                    if self.products.count >= response.total_count || newProducts.isEmpty {
                        self.hasMorePages = false
                        if self.debugLogging {
                            print("[SearchVM] No more pages after page \(self.currentPage).")
                        }
                    }
                }
            } catch {
                if self.debugLogging {
                    if let raw = String(data: data, encoding: .utf8) {
                        print("[SearchVM] Decoding error: \(error). Raw response: \(raw.prefix(300))...")
                    } else {
                        print("[SearchVM] Decoding error: \(error). Unable to print raw response.")
                    }
                } else {
                    print("[SearchVM] Decoding error: \(error)")
                }
            }
        }.resume()
    }
    
    func goBack() {
        if let previous = historyStack.popLast() {
            withAnimation {
                self.products = previous.products
                self.query = previous.query
                self.searchType = previous.searchType
                self.hasMorePages = false
                self.currentPage = 1
                self.currentRelatedID = nil
                self.currentVendorID = nil
                self.totalResults = nil
            }
            if debugLogging {
                print("[SearchVM] Restored previous state. Disabled pagination until a new search.")
            }
        }
    }
    /*
    func goToHome() {
        if let firstState = historyStack.first {
            // Optionally clear all navigation history
            historyStack = [firstState]
            withAnimation {
                self.products = firstState.products
                self.query = firstState.query
                self.searchType = firstState.searchType
                self.hasMorePages = false
                self.currentPage = 1
                self.currentRelatedID = nil
                self.currentVendorID = nil
                self.totalResults = nil
            }
            if debugLogging {
                print("[SearchVM] Restored first state. Navigation stack now reset to home.")
            }
        }
    }
     */

    var canGoBack: Bool {
        !historyStack.isEmpty
    }
}
