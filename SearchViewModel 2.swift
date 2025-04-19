
import Foundation

class SearchViewModel: ObservableObject {
    @Published var query: String = ""
    @Published var results: [Product] = []
    private var currentPage = 1
    private var isLoading = false
    private var hasMoreResults = true

    func search(reset: Bool) {
        guard !query.isEmpty, !isLoading, hasMoreResults else { return }

        if reset {
            results = []
            currentPage = 1
            hasMoreResults = true
        }

        isLoading = true

        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://www.shoppo.co.nz/search/?vq=\(encodedQuery)&page=\(currentPage)") else {
            isLoading = false
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, error in
            defer { self.isLoading = false }

            guard let data = data, error == nil else {
                print("Error fetching data: \(error?.localizedDescription ?? "Unknown")")
                return
            }

            do {
                let decoded = try JSONDecoder().decode([Product].self, from: data)
                DispatchQueue.main.async {
                    self.results += decoded
                    self.hasMoreResults = decoded.count == 24
                    if self.hasMoreResults {
                        self.currentPage += 1
                    }
                }
            } catch {
                print("Error decoding: \(error)")
            }
        }.resume()
    }
}
