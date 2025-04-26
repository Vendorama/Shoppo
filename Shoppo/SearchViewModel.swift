import SwiftUI
import Foundation

class SearchViewModel: ObservableObject {
    
    @Published var products: [Product] = []
    //@Published var historyStack: [[Product]] = []
    @Published private var historyStack: [(products: [Product], query: String, searchType: String)] = []
    
    @Published var query: String = ""
    @Published var isLoading: Bool = false
    @Published var hasMorePages: Bool = true
    @Published var searchID = UUID()
    @Published var searchType: String = "search"
    @Published var lastQuery: String = ""
    @Published var lastSearchType: String = "search"
    
    //private var cancellables = Set<AnyCancellable>()
    private var currentPage = 1
    private var isFetching = false
    
    func search(reset: Bool = true, thisType: String = "search") {
        // Save current state
        if !products.isEmpty {
            historyStack.append((products: products, query: lastQuery, searchType: lastSearchType))
        }
        lastQuery = query
        lastSearchType = searchType
        guard !isFetching else { return }

        //if reset {
            products = []
            currentPage = 1
            hasMorePages = true
            searchID = UUID() // triggers scroll-to-top
            searchType = thisType
        
        //}
        
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://www.shoppo.co.nz/app/?vq=\(encodedQuery)") else {
              print("Error fetching URL")
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data, error == nil else {
                print("Error fetching data: \(error?.localizedDescription ?? "Unknown")")
                return
            }
            do {
                let newProducts = try JSONDecoder().decode([Product].self, from: data)
                DispatchQueue.main.async {
                    self.products = newProducts
                }
            } catch {
                print("Error decoding: \(error)")
            }
        }.resume()
    }
    func searchRelated(to productID: String) {
        if !products.isEmpty {
            historyStack.append((products: products, query: lastQuery, searchType: searchType))
        }
        lastQuery = query
        lastSearchType = searchType
        self.products = []
        self.isLoading = true
        self.hasMorePages = false
        self.currentPage = 1
        searchType = "related"

        let urlString = "https://www.shoppo.co.nz/app/?vs=\(productID)"
        guard let url = URL(string: urlString) else {
            isLoading = false
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false

                guard let data = data,
                      let newProducts = try? JSONDecoder().decode([Product].self, from: data) else {
                    print("Error fetching vs")
                   return
                }

                self.products = newProducts
            }
        }.resume()
    }
    func searchVendor(to vendorID: String) {
        if !products.isEmpty {
            historyStack.append((products: products, query: lastQuery, searchType: searchType))
        }
        lastQuery = query
        lastSearchType = searchType
        self.products = []
        self.isLoading = true
        self.hasMorePages = false
        self.currentPage = 1
        searchType = "vendor"

        let urlString = "https://www.shoppo.co.nz/app/?vu=\(vendorID)"
        guard let url = URL(string: urlString) else {
            isLoading = false
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false

                guard let data = data,
                      let newProducts = try? JSONDecoder().decode([Product].self, from: data) else {
                    print("Error fetching vu")
                   return
                }

                self.products = newProducts
            }
        }.resume()
    }
    
    func goBack() {
        if let previous = historyStack.popLast() {
            withAnimation {
                self.products = previous.products
                self.query = previous.query
                self.searchType = previous.searchType
            }
        }
    }

    var canGoBack: Bool {
        !historyStack.isEmpty
    }
    

}
