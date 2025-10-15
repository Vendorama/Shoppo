
import Foundation

struct Product: Identifiable, Equatable, Codable {
    var id: String { vendor_id + "." + product_id }
    let name: String
    let price: String
    let sale_price: String
    let image: String
    let url: String
    let product_id: String
    let vendor_id: String
    let vendor_name: String
    let summary: String

    enum CodingKeys: String, CodingKey {
        case name
        case price = "price"
        case sale_price = "sale_price"
        case image = "image"
        case url = "url"
        case product_id = "product_id"
        case vendor_id = "vendor_id"
        case vendor_name = "vendor_name"
        case summary = "summary"
    }
}

