
import Foundation

class SearchViewModel: ObservableObject {
    @Published var query: String = ""
    @Published var results: [Product] = []
    
    func search() {
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
                    self.results = decoded
                }
            } catch {
                print("Error decoding: \(error)")
            }
        }.resume()
    }
}
