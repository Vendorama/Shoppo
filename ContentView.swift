
import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = SearchViewModel()
    
    var body: some View {
        NavigationView {
            VStack {
                // Logo at top
                AsyncImage(url: URL(string: "https://www.shoppo.co.nz/img/shoppo.png")) { image in
                    image.resizable()
                } placeholder: {
                    ProgressView()
                }
                .frame(width: 200, height: 60)
                .padding(.top)

                HStack {
                    TextField("Search...", text: $viewModel.query, onCommit: {
                        viewModel.search(reset: true)
                    })
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.leading)

                    Button(action: {
                        viewModel.search(reset: true)
                    }) {
                        Image(systemName: "magnifyingglass")
                            .padding()
                    }
                }

                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(viewModel.results.indices, id: \ .self) { index in
                            let product = viewModel.results[index]
                            VStack(alignment: .leading) {
                                AsyncImage(url: URL(string: product.image)) { image in
                                    image.resizable()
                                } placeholder: {
                                    ProgressView()
                                }
                                .frame(height: 200)
                                .aspectRatio(contentMode: .fit)
                                
                                Text(product.name)
                                    .font(.headline)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.leading)
                                
                                Text(product.price)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal)
                            .onAppear {
                                if index == viewModel.results.count - 1 {
                                    viewModel.search(reset: false)
                                }
                            }
                        }
                    }
                    .padding(.top)
                }
            }
            .navigationTitle("Shoppo Search")
        }
    }
}
