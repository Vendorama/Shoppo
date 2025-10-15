import SwiftUI
import SDWebImageSwiftUI

struct ProductDetailViewShoppo: View {
    let product: Product
    @ObservedObject var viewModel: SearchViewModel

    // When presented inside a container (like the Favorites sheet),
    // the presenter can provide a way to dismiss that container.
    var onRequestDismissContainer: (() -> Void)? = nil

    @State private var showSafari = false
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dismissSearch) private var dismissSearch
    @EnvironmentObject private var favorites: FavoritesStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {

                // Full-width image, maintaining aspect ratio
                if let imageURL = URL(string: product.image) {
                    ZStack {
                        // Keep reserved space without showing placeholders/spinners
                        Color(.systemBackground)
                            .frame(maxWidth: .infinity, maxHeight: 300)

                        WebImage(url: imageURL)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: 300, maxHeight: 300, alignment: .center)
                            .clipped()
                    }
                }

                // Title / price
                VStack(alignment: .leading, spacing: 8) {
                    Text(product.name)
                        .font(.system(size: 16))
                        .lineLimit(6)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .tint(.primary)
                        .background(Color(.systemBackground))

                    PriceView(price: product.price, sale_price: product.sale_price)
                        .font(.system(size: 26))
                        .frame(maxWidth: .infinity, alignment: .center)

                    if !product.vendor_name.isEmpty {
                        Button(action: {
                            // Dismiss container (Favorites sheet) if applicable
                            onRequestDismissContainer?()
                            // Dismiss detail if needed
                            dismiss()
                            // Then run the vendor search
                            DispatchQueue.main.async {
                                dismissSearch()
                                viewModel.searchVendor(to: product.vendor_id)
                            }
                        }) {
                            Image("store")
                                .resizable()
                                .scaledToFit()
                                .foregroundColor(.secondary)
                                .frame(height: 14)
                                .opacity(0.5)
                                .offset(x:1, y:1)
                            Text("\(product.vendor_name)")
                                .font(.subheadline)
                                .padding(.top, 2)
                        }
                        .buttonStyle(.plain)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .foregroundColor(.secondary)
                    }

                    if !product.summary.isEmpty {
                        Text("\(product.summary)")
                            .font(.system(size: 13))
                            .lineSpacing(4)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 6)
                            .padding(.bottom, 6)
                            .frame(maxWidth: .infinity)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)

                // Open product URL in-app using SafariView
                if let url = URL(string: product.url) {
                    Button {
                        showSafari = true
                    } label: {
                        Text("View on website")
                            .font(.body.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor.opacity(0.1))
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    .sheet(isPresented: $showSafari) {
                        SafariView(url: url)
                    }
                }

                Button("+ more like this") {
                    // Dismiss container (Favorites sheet) if applicable
                    onRequestDismissContainer?()
                    // Dismiss detail if it’s being presented/pushed
                    dismiss()
                    // Then trigger the related search
                    DispatchQueue.main.async {
                        dismissSearch()
                        viewModel.searchRelated(to: product)
                    }
                }
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity)
            }
            .padding(.top)

            .overlay(
                HStack {
                    Spacer()
                    VStack {
                        Button {
                            favorites.toggleFavorite(product.id)
                        } label: {
                            Image(systemName: favorites.isFavorite(product.id) ? "heart.fill" : "heart")
                                .foregroundColor(favorites.isFavorite(product.id) ? .purple : .secondary)
                                .padding(16)
                                .background(favorites.isFavorite(product.id) ? Color(.systemBackground).opacity(1.0) : Color(.systemBackground).opacity(0.8))
                                .clipShape(Circle())
                                .offset(x:-9, y:-9)
                        }
                        .buttonStyle(.plain)
                        Spacer()
                    }
                }
                .padding(6)
                .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
            )
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Close") { dismiss() }
            }
        }
        .background(Color(.systemBackground))
    }
}

#if DEBUG
struct ProductDetailViewShoppo_Previews: PreviewProvider {
    static var sampleProduct: Product {
        Product(
            name: "Sample Product Title That Wraps Across Multiple Lines For Preview",
            price: "$129.00",
            sale_price: "$159.00",
            image: "https://picsum.photos/seed/shoppo/600/600",
            url: "https://www.example.com/product",
            product_id: "preview-001",
            vendor_id: "vendor-123",
            vendor_name: "Preview Vendor",
            summary: "Preview Summary"
        )
    }

    static var viewModel: SearchViewModel = {
        let vm = SearchViewModel()
        vm.searchType = "search"
        vm.query = "sneakers"
        return vm
    }()

    static var previews: some View {
        Group {
            NavigationView {
                ProductDetailViewShoppo(product: sampleProduct, viewModel: viewModel)
            }
            .previewDisplayName("Light")

            NavigationView {
                ProductDetailViewShoppo(product: sampleProduct, viewModel: viewModel)
            }
            .preferredColorScheme(.dark)
            .previewDisplayName("Dark")
        }
    }
}
#endif
