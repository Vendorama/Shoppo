
import SwiftUI
import SDWebImageSwiftUI

struct ContentView: View {
    @StateObject private var viewModel = SearchViewModel()
    @FocusState private var textFieldIsFocused: Bool
    @State private var imageLoaded = false
    @State private var inputQuery: String = ""
    @Environment(\.dismissSearch) private var dismissSearch
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                let screenWidth = geometry.size.width
                let desiredItemWidth: CGFloat = 160 // you can tweak this
                let columnCount = max(Int(screenWidth / desiredItemWidth), 1)
                let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: columnCount)
                
                ScrollView {
                    
                    if viewModel.canGoBack {
                        Button("< Back ") {
                            viewModel.goBack()
                            textFieldIsFocused = false
                        }
                        .padding(2)
                        .foregroundColor(.gray)
                        .font(.system(size: 10))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .offset(x: 20.0, y: 1.0)
                    } else if viewModel.searchType == "search" {
                        
                        Text("New Arrivals")
                            .padding(2)
                            .foregroundColor(.gray)
                            .font(.system(size: 12))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .offset(x: 20.0, y: 1.0)
                            .bold()
                    }
                    
                    
                    LazyVGrid(columns: columns, spacing: 1) {
                        
                        
                        ForEach(Array(viewModel.products.enumerated()), id: \.element.id) { index, product in
                            if index == 0 && viewModel.searchType == "related" {
                                ProductRowViewRelated(product: product, viewModel: viewModel)
                            } else if index == 0 && viewModel.searchType == "vendor" {
                                ProductRowViewVendor(product: product, viewModel: viewModel)
                            } else {
                                ProductRowView(product: product, viewModel: viewModel)
                            }
                        }
                        
                        if viewModel.isLoading {
                            ProgressView()
                                .padding()
                        }
                    }
                }
                .padding(EdgeInsets(top: 0, leading: 7, bottom: 0, trailing: 7))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        if !textFieldIsFocused {
                            Button(action: {
                                textFieldIsFocused = true
                            }) {
                                Image("shoppo")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 30)
                                    .padding(.bottom, 5)
                            }
                        }
                    }
                }
                .searchable(text: $viewModel.query, placement: .navigationBarDrawer(displayMode: .always))
                .onSubmit(of: .search) {
                    viewModel.query = inputQuery
                    textFieldIsFocused = false
                    //viewModel.search(reset: true, thisType: "search")
                    viewModel.search()
                }
                .onChange(of: viewModel.products) {
                    textFieldIsFocused = false
                }
                .onAppear {
                    // Trigger initial search with empty query
                    if viewModel.products.isEmpty {
                        //viewModel.search(reset: true, thisType: "search")
                        viewModel.search()
                    }
                }
                
                
                
                
                
            }
            .contentShape(Rectangle()) // Make the whole ZStack tappable
            .onTapGesture {
                textFieldIsFocused = false
            }
            .onChange(of: viewModel.query) { oldValue, newValue in
                inputQuery = newValue
            }
        }
    }
}

