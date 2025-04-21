
import SwiftUI
import SDWebImageSwiftUI

struct ContentView: View {
    @StateObject private var viewModel = SearchViewModel()
    //let columns = [GridItem(.flexible()), GridItem(.flexible())]
    @FocusState private var textFieldIsFocused: Bool
    @State private var imageLoaded = false
    @State private var inputQuery: String = ""
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                let screenWidth = geometry.size.width
                let desiredItemWidth: CGFloat = 160 // you can tweak this
                let columnCount = max(Int(screenWidth / desiredItemWidth), 1)
                let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: columnCount)
                
                ZStack {
                    VStack {
                        
                        /*
                        
                        Link(destination: URL(string: "https://www.shoppo.co.nz")!) {
                            Image("shoppo")
                                .resizable()
                                .scaledToFit()
                                .frame(height: 30)
                                .padding(EdgeInsets(top: 10, leading: 0, bottom: 0, trailing: 0))
                        }
                        */
                        Button(action: {
                            // e.g. reset search, go to homepage products
                            //viewModel.query = ""
                            //viewModel.search(reset: true)
                            textFieldIsFocused = true
                        }) {
                            Image("shoppo")
                                .resizable()
                                .scaledToFit()
                                .frame(height: 30)
                                .padding(EdgeInsets(top: 10, leading: 0, bottom: 0, trailing: 0))
                        }
                        
                        HStack {
                            TextField("Shop for...", text: $inputQuery, onCommit: {
                                viewModel.query = inputQuery
                                textFieldIsFocused = false
                                viewModel.search()
                            })
                            //.textFieldStyle(RoundedBorderTextFieldStyle())
                            //.padding(EdgeInsets(top: 1, leading: 0, bottom: 3, trailing: 0))
                            .aspectRatio(contentMode: .fit)
                            .frame(width: UIScreen.main.bounds.width - 70)
                            .offset(x: 13.0, y: 0.0)
                            .focused($textFieldIsFocused)
                            
                            .padding(4)
                            .overlay(
                                RoundedRectangle(cornerRadius: 25)
                                    .stroke(Color.lightGray)
                                    .offset(x: 13.0, y: 0.0)
                                    .frame(width: UIScreen.main.bounds.width - 40)
                            )
                            
                            .onSubmit {
                            }
                            
                            Button(action: {
                                viewModel.search()
                            }) {
                                Image(systemName: "magnifyingglass")
                                    .padding(EdgeInsets(top: 1, leading: 0, bottom: 5, trailing: 0))
                                    .offset(x: -17.0, y: 1.0)
                                    .foregroundColor(.lightGray)
                            }
                        }
                            
                        ScrollView {
                            
                            if viewModel.query == "" && viewModel.searchType == "search" {
                                Text("New Arrivals")
                                    .padding(2)
                                    .foregroundColor(.gray)
                                    .font(.system(size: 12))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .offset(x: 20.0, y: 1.0)
                                    .bold()
                            }
                            
                            else if viewModel.canGoBack {
                                Button("< Back ") {
                                    viewModel.goBack()
                                }
                                .padding(2)
                                .foregroundColor(.gray)
                                .font(.system(size: 10))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .offset(x: 20.0, y: 1.0)
                            }
                            LazyVGrid(columns: columns, spacing: 1) {
                                
                                
                                ForEach(Array(viewModel.products.enumerated()), id: \.element.id) { index, product in
                                    if index == 0 && viewModel.searchType == "related" {
                                        ProductRowViewRelated(product: product, viewModel: viewModel)
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
                        .padding(5)
                        
                    }
                    .onChange(of: viewModel.products) {
                        textFieldIsFocused = false
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

