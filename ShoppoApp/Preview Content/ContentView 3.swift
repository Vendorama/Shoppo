
import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = SearchViewModel()
    let columns = [GridItem(.flexible())]
    @FocusState var textFieldIsFocused: Bool
    
    var body: some View {
        NavigationView {
            VStack {
                // Logo at top
                
                AsyncImage(url: URL(string: "https://www.shoppo.co.nz/img/shoppo.png")) { image in
                    image.resizable()
                } placeholder: {
                    ProgressView()
                }
                .frame(width: 128, height: 32)
                //.padding(.top)
                .padding(EdgeInsets(top: 10, leading: 0, bottom: 0, trailing: 0))
                
                
                HStack {
                    TextField("Shop for...", text: $viewModel.query, onCommit: {
                        viewModel.search()
                    })
                    //.textFieldStyle(RoundedBorderTextFieldStyle())
                    //.padding(EdgeInsets(top: 1, leading: 0, bottom: 3, trailing: 0))
                    .aspectRatio(contentMode: .fit)
                    .frame(width: UIScreen.main.bounds.width - 80)
                    .offset(x: 13.0, y: 0.0)
                    
                    
                    .padding(7)
                    .overlay(
                        RoundedRectangle(cornerRadius: 25)
                            .stroke(Color.lightGray)
                            .offset(x: 13.0, y: 0.0)
                            .frame(width: UIScreen.main.bounds.width - 40)
                    )
                    
                    .onSubmit {
                        textFieldIsFocused = false
                    }
                    

                    Button(action: {
                        viewModel.search()
                    }) {
                        Image(systemName: "magnifyingglass")
                            .padding(EdgeInsets(top: 1, leading: 0, bottom: 5, trailing: 0))
                            .offset(x: -20.0, y: 1.0)
                            .foregroundColor(.lightGray)
                    }
                }

                ScrollView {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(viewModel.results) { product in
                            VStack {
                                
                                Button(action: {
                                    guard let thisURL = URL(string: product.url),
                                        UIApplication.shared.canOpenURL(thisURL) else {
                                        return
                                    }
                                    UIApplication.shared.open(thisURL,
                                        options: [:],
                                        completionHandler: nil)
                                }) {
                                    
                                    AsyncImage(url: URL(string: product.image)) { image in
                                        image
                                            .resizable()
                                            .scaledToFit() // preserve original aspect ratio
                                            .frame(width: 300, height: 300) // fixed height
                                            .clipped()
                                            .buttonStyle(PlainButtonStyle())
                                        
                                    } placeholder: {
                                        ProgressView()
                                    }
                                }
                                
                                
                                
                                
                                //.frame(height: 200)
                                //.aspectRatio(contentMode: .fit)
                                
                                let link = "[\(product.name)](\(product.url))"
                                
                                Text(product.price)
                                    //.font(.headline)
                                    //.font(.system(size: 60))
                                    .font(.system(size: 20, weight: .bold))
                                    //.foregroundColor(.secondary)
                                    //.tint(.black)
                                
                                Text(.init(link))
                                    .font(.subheadline)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.center)
                                    .tint(.gray)
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            //.cornerRadius(8)
                            //.shadow(radius: 12)
                        }
                    }
                    .padding()
                }
            }
            .onAppear {
                // 🔁 Trigger initial search with empty query
                if viewModel.results.isEmpty {
                    viewModel.search()
                }
            }
            //.navigationTitle("Shoppo Search")
        }
    }
}
