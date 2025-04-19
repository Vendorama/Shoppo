
import Foundation

struct Product: Identifiable, Decodable {
    var id: String { name + price }
    let name: String
    let price: String
    let image: String
    let url: String

    enum CodingKeys: String, CodingKey {
        case name
        case price
        case image = "image"
        case url = "url"
    }
}

