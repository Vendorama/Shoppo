
import Foundation

struct Product: Identifiable, Decodable {
    let id = UUID()
    let name: String
    let price: String
    let image: String
}
