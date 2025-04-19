
import SwiftUI

struct ProductRowView: View {
    let product: Product

    var body: some View {
        VStack(alignment: .leading) {
            AsyncImage(url: URL(string: product.url)) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFit()
                        .frame(height: 200)
                case .failure:
                    Color.gray.frame(height: 200)
                case .empty:
                    ProgressView().frame(height: 200)
                @unknown default:
                    EmptyView()
                }
            }

            Text(product.name)
                .font(.headline)
                .padding(.top, 4)
            Text(product.price)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.vertical)
    }
}
