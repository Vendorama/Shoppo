import SwiftUI
import SDWebImageSwiftUI

struct ProductRowView: View {
    let product: Product
    @State private var imageLoaded = false

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
                        .frame(width: 120, height: 145)
                        .clipped()
                        .opacity(imageLoaded ? 1 : 0)
                        //.animation(.easeIn(duration: 0.3), value: imageLoaded)
                    
                        .animation(.easeIn(duration: 0.3), value: imageLoaded)
                            .overlay(
                                Group {
                                    if !imageLoaded {
                                        ProgressView()
                                            .frame(width: 120, height: 145)
                                    }
                                }
                            )
                }
            }

            let link = "[\(product.name)](\(product.url))"
            
            Text(product.price)
                .font(.system(size: 16, weight: .bold))
                .frame(maxWidth: .infinity, alignment: .center)
            
            Text(.init(link))
                .font(.system(size: 12))
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, alignment: .center)
                .tint(.gray)
                .background(Color(.systemBackground))
        }
        .background(Color(.systemBackground))
        .padding(.vertical)
    }
}
