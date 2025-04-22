import SwiftUI
import SDWebImageSwiftUI

struct ProductRowView: View {
    let product: Product
    @ObservedObject var viewModel: SearchViewModel
    @State private var imageLoaded = false
    @Environment(\.dismissSearch) private var dismissSearch

    var body: some View {
        
        VStack(alignment: .leading) {
            
            Button(action: {
                guard let thisURL = URL(string: product.url),
                      UIApplication.shared.canOpenURL(thisURL) else {
                    return
                }
                UIApplication.shared.open(thisURL, options: [:], completionHandler: nil)
            }) {
                if let imageURL = URL(string: product.image) {
                    WebImage(url: imageURL)
                        .onSuccess { _, _, _ in
                            DispatchQueue.main.async {
                                imageLoaded = true
                            }
                        }
                    
                        //.placeholder(ProgressView().frame(width: 125, height: 145))
                        .resizable()
                        .scaledToFit()
                        .frame(width: 180, height: 180)
                        .clipped()
                        .opacity(imageLoaded ? 1 : 0)
                        //.animation(.easeIn(duration: 0.3), value: imageLoaded)
                    
                        .animation(.easeIn(duration: 0.3), value: imageLoaded)
                            .overlay(
                                Group {
                                    if !imageLoaded {
                                        ProgressView()
                                            //.frame(width: 180, height: 180)
                                    }
                                }
                            )
                }
            }

            let link = "[\(product.name)](\(product.url))"
            
            PriceView(price: product.price, sale_price: product.sale_price)
            
            
            Text(.init(link))
                .font(.system(size: 13))
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, alignment: .center)
                .tint(.gray)
                .background(Color(.systemBackground))
            
            
            Button("+ more like this") {
                dismissSearch()
                viewModel.searchRelated(to: product.id)
            }
            .font(.system(size: 12))
            .foregroundColor(.gray)
            .frame(maxWidth: .infinity)
            .padding(1)
        }
        .background(Color(.systemBackground))
        .padding(.vertical)
    }
}

struct PriceView: View {
    var price: String
    var sale_price: String

    var body: some View {
        HStack(spacing: 5) {
            Text(sale_price)
                .foregroundColor(.red)
                .strikethrough()
            Text(price)
                .foregroundColor(.black)
                .bold()
        }
        .frame(maxWidth: .infinity)
        .font(.system(size: 16))
    }
}


struct ProductRowViewRelated: View {
    let product: Product
    @ObservedObject var viewModel: SearchViewModel
    @State private var imageLoaded = false
    @Environment(\.dismissSearch) private var dismissSearch

    var body: some View {
        
        VStack(alignment: .leading) {
            
            Button(action: {
                guard let thisURL = URL(string: product.url),
                      UIApplication.shared.canOpenURL(thisURL) else {
                    return
                }
                UIApplication.shared.open(thisURL, options: [:], completionHandler: nil)
            }) {
                if let imageURL = URL(string: product.image) {
                    WebImage(url: imageURL)
                        .onSuccess { _, _, _ in
                            DispatchQueue.main.async {
                                imageLoaded = true
                            }
                        }
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120)
                        .clipped()
                        .background(Color(.systemBackground))
                        .clipShape(Circle())
                        .cornerRadius(80.0)
                            .overlay(
                                RoundedRectangle(cornerRadius: 80.0)
                                    .stroke(Color.white, lineWidth: 10)
                            )
                            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
        
            Text("showing more like this")
        
                .font(.system(size: 12))
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity)
                .padding(.top, 12)
                .padding(.bottom, 2)
                .frame(maxWidth: .infinity, alignment: .center)
            
            Button("+ more from this store") {
                dismissSearch()
                viewModel.searchVendor(to: product.id)
            }
            .font(.system(size: 12))
            .foregroundColor(.gray)
            .frame(maxWidth: .infinity)
            .padding(.top, 2)
            .padding(.bottom, 6)
        }
    }
}

struct ProductRowViewVendor: View {
    let product: Product
    @ObservedObject var viewModel: SearchViewModel
    @State private var imageLoaded = false
    @Environment(\.dismissSearch) private var dismissSearch

    var body: some View {
        
        VStack(alignment: .leading) {
            
            Button(action: {
                guard let thisURL = URL(string: product.url),
                      UIApplication.shared.canOpenURL(thisURL) else {
                    return
                }
                UIApplication.shared.open(thisURL, options: [:], completionHandler: nil)
            }) {
                if let imageURL = URL(string: product.image) {
                    WebImage(url: imageURL)
                        .onSuccess { _, _, _ in
                            DispatchQueue.main.async {
                                imageLoaded = true
                            }
                        }
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120)
                        .clipped()
                        .background(Color(.systemBackground))
                        .clipShape(Circle())
                        .cornerRadius(80.0)
                            .overlay(
                                RoundedRectangle(cornerRadius: 80.0)
                                    .stroke(Color.white, lineWidth: 10)
                            )
                            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
        
            Text(.init("showing more from \n**\(product.vendor_name)**"))
        
                .font(.system(size: 12))
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity)
                .padding(.top, 12)
                .padding(.bottom, 52)
                .frame(maxWidth: .infinity, alignment: .center)
            
            
        }
    }
}
/*
 struct BackButton: View {
 @ObservedObject var viewModel: SearchViewModel
 @Environment(\.dismissSearch) private var dismissSearch
 
 var body: some View {
 
 HStack {
 
 Button("< Back ") {
 dismissSearch()
 viewModel.goBack()
 }
 .padding(2)
 .foregroundColor(.gray)
 .font(.system(size: 10))
 .frame(maxWidth: .infinity, alignment: .leading)
 .offset(x: 20.0, y: 1.0)
 
 }
 }
 }
 */
