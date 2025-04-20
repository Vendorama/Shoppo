
import SwiftUI
import SDWebImageSwiftUI

struct ContentView: View {
    @StateObject private var viewModel = SearchViewModel()
    let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
    @FocusState var textFieldIsFocused: Bool
    @State private var imageLoaded = false
    
    var body: some View {
        NavigationView {
            VStack {
                // Logo at top
                WebImage(url: URL(string: "https://www.shoppo.co.nz/img/shoppo.gif")) { image in
                    image.resizable()
                } placeholder: {
                    ProgressView()
                }
                .frame(width: 119, height: 30)
                //.padding(.top)
                .padding(EdgeInsets(top: 10, leading: 0, bottom: 0, trailing: 0))
                
                
                HStack {
                    TextField("Shop for...", text: $viewModel.query, onCommit: {
                        viewModel.search()
                    })
                    //.textFieldStyle(RoundedBorderTextFieldStyle())
                    //.padding(EdgeInsets(top: 1, leading: 0, bottom: 3, trailing: 0))
                    .aspectRatio(contentMode: .fit)
                    .frame(width: UIScreen.main.bounds.width - 70)
                    .offset(x: 13.0, y: 0.0)
                    
                    
                    .padding(5)
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
                    LazyVGrid(columns: columns, spacing: 1) {
                        ForEach(viewModel.products) { product in
                            ProductRowView(product: product)
                                .onAppear {
                                   // viewModel.loadNextPageIfNeeded(currentItem: product)
                                }
                        }

                        if viewModel.isLoading {
                            ProgressView()
                                .padding()
                        }
                    }
                }
                .padding(5)
                
            }
            .onAppear {
                // Trigger initial search with empty query
                if viewModel.products.isEmpty {
                    viewModel.search()
                }
            }
            //.navigationTitle("Shoppo Search")
        }
    }
}
