
import Foundation

class SearchViewModel: ObservableObject {
    
    
    @Published var products: [Product] = []
    private var historyStack: [[Product]] = []
    @Published var query: String = ""
    @Published var isLoading: Bool = false
    @Published var hasMorePages: Bool = true
    @Published var searchID = UUID()
    @Published var searchType: String = "search"
    
    //private var cancellables = Set<AnyCancellable>()
    private var currentPage = 1
    private var isFetching = false
    
    func search(reset: Bool = true) {
        // Save current state
        if !products.isEmpty {
            historyStack.append(products)
        }
        guard !isFetching else { return }

        //if reset {
            products = []
            currentPage = 1
            hasMorePages = true
            searchID = UUID() // triggers scroll-to-top
            searchType = "search"
        //}
        
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://www.shoppo.co.nz/app/?vq=\(encodedQuery)") else {
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data, error == nil else {
                print("Error fetching data: \(error?.localizedDescription ?? "Unknown")")
                return
            }
            do {
                let decoded = try JSONDecoder().decode([Product].self, from: data)
                DispatchQueue.main.async {
                    self.products = decoded
                }
            } catch {
                print("Error decoding: \(error)")
            }
        }.resume()
    }
    func searchRelated(to productID: String) {
        if !products.isEmpty {
            historyStack.append(products)
        }
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
                    return
                }

                self.products = newProducts
            }
        }.resume()
    }
    
    func goBack() {
        if let previous = historyStack.popLast() {
            self.products = previous
        }
    }

    var canGoBack: Bool {
        !historyStack.isEmpty
    }
    

}
