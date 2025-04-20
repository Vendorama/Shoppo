
import Foundation

struct Product: Identifiable, Decodable {
    var id: String { vendor_id + "." + product_id }
    let name: String
    let price: String
    let image: String
    let url: String
    let product_id: String
    let vendor_id: String

    enum CodingKeys: String, CodingKey {
        case name
        case price
        case image = "image"
        case url = "url"
        case product_id = "product_id"
        case vendor_id = "vendor_id"
    }
}

