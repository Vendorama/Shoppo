
import Foundation

class SearchViewModel: ObservableObject {
    
    
    @Published var products: [Product] = []
    @Published var query: String = ""
    @Published var isLoading: Bool = false
    @Published var hasMorePages: Bool = true
    @Published var searchID = UUID()
    
    //private var cancellables = Set<AnyCancellable>()
    private var currentPage = 1
    private var isFetching = false
    
    func search(reset: Bool = true) {
        guard !isFetching else { return }

        if reset {
            products = []
            currentPage = 1
            hasMorePages = true
            searchID = UUID() // triggers scroll-to-top
        }
        
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
}
