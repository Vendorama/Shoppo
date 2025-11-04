import SwiftUI
import SDWebImageSwiftUI

// MARK: - Row subview to simplify type-checking

struct ProductListRow: View {
    let product: Product
    @ObservedObject var viewModel: SearchViewModel
    @Environment(\.dismissSearch) private var dismissSearch
    @EnvironmentObject private var favorites: FavoritesStore

    // Call back to parent to open detail
    var onSelect: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            // Image -> triggers detail
            Button {
                onSelect()
            } label: {
                ZStack {
                    if let url = apiURL(product.image) {
                        WebImage(url: url)
                            .resizable()
                            .scaledToFill()
                    } else {
                        Rectangle()
                            .fill(Color(.secondarySystemBackground))
                    }
                }
                .frame(width: 90, height: 90)
                .clipped()
                .cornerRadius(8)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.leading, 8)
            .padding(.trailing, 6)

            // Texts
            VStack(alignment: .leading, spacing: 4) {
                // Product name -> triggers detail
                Button {
                    onSelect()
                } label: {
                    Text(product.name)
                        .font(.subheadline)
                        .lineLimit(2)
                        .foregroundStyle(.primary)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                // Price (non-tappable)
                PriceView(price: product.price, sale_price: product.sale_price)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Vendor name -> vendor search (kept as requested)
                Button {
                    dismissSearch()
                    viewModel.searchVendor(to: product.vendor_id)
                } label: {
                    /*
                    Image("store")
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(.secondary)
                        .frame(height: 11)
                        .opacity(0.5)
                        //.offset(x:1, y:1)
                     */
                    Text(product.vendor_name)
                        .font(.subheadline)
                        .lineLimit(1)
                        .foregroundStyle(.secondary)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                    /*
                if product.suburb != "" {
                    Text(product.suburb)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                     */
                Button("+ more like this") {
                    dismissSearch()
                    // Clear filters for related searches as requested
                    viewModel.priceFrom = nil
                    viewModel.priceTo = nil
                    viewModel.onSale = false
                    // Comment out raw resets for testing
                    // viewModel.priceFromRaw = nil
                    // viewModel.priceToRaw = nil
                    viewModel.restrictedOnly = false
                    // Prefer product_id for the related endpoint
                    viewModel.searchRelated(to: product)
                }
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading )
            }

            // Favorite toggle (visible)
            Button {
                favorites.toggleFavorite(product.id)
            } label: {
                Image(systemName: favorites.isFavorite(product.id) ? "heart.fill" : "heart")
                    .foregroundStyle(favorites.isFavorite(product.id) ? .purple : .secondary)
                    .frame(width: 30, height: 50)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // Chevron -> triggers detail
            Button {
                onSelect()
            } label: {
                Image(systemName: "chevron.right")
                    .foregroundStyle(Color(UIColor.tertiaryLabel))
                    .frame(width: 60, height: 70)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(-10)
        }
        .contentShape(Rectangle())
    }
}
