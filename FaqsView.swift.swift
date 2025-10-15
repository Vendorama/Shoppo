import SwiftUI

struct FAQsView: View {
    @State private var showContactSheet = false
    private let faqsFallback = " "
    @State private var faqsText: String = " "

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                
                Text(.init(faqsText))
                    .font(.body)
                    .foregroundColor(.primary)
                

                Spacer()
                Spacer()
                Spacer()

                
                
                HStack(spacing: 10) {
                    Image("vendorama")
                        .resizable()
                        .scaledToFit()
                        .padding(0)
                        .frame(maxWidth: .infinity, maxHeight: 100)
                        .frame(width: 170, height: 37, alignment: .center)
                        .offset(x:78)
                    
                }
                
                Text("""

Shoppo is 100% owned and operated by Vendorama limited (NZBN: 9429035722168).

If you have feedback or suggestions, I’d love to hear from you.
""")
                
                // Contact link-style button
                Button {
                    showContactSheet = true
                } label: {
                    Label("Contact us or add your store here", systemImage: "envelope")
                        .font(.body.weight(.semibold))
                }
                .buttonStyle(.borderless)
                .tint(.accentColor)
                .padding(.top, 4)
                
                
                Section(header:
                    Text("\nFor our privacy and security policies please visit our website at www.shoppo.co.nz/privacy\n\nFor our terms and conditions please visit our website at www.shoppo.co.nz/terms\n\n")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .textCase(nil)
                ) {
                    
                }
            }
            
            
            .padding()
        }
        .navigationTitle("FAQs")
        //.navigationBarHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showContactSheet) {
            NavigationView {
                ContactView()
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") { showContactSheet = false }
                        }
                    }
                
            }
        }
        
        
        .task {
            await loadContent(id: 2)
        }
        
    }
    
    private struct ContentResponse: Decodable {
        let content: String
    }

    @MainActor
    private func loadContent(id: Int = 1) async {
        // Keep fallback until we successfully fetch and decode
        guard let url = URL(string: "https://www.shoppo.co.nz/app/content?x=9&id=\(id)") else {
            faqsText = faqsFallback
            return
        }
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                faqsText = faqsFallback
                return
            }
            let decoded = try JSONDecoder().decode(ContentResponse.self, from: data)
            faqsText = decoded.content.isEmpty ? faqsFallback : decoded.content
        } catch {
            faqsText = faqsFallback
        }
    }
}
