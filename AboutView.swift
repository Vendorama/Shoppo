import SwiftUI

struct AboutView: View {
    @State private var showContactSheet = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                
                Text("""
Shoppo is discovery shopping platform for New Zealand retailers to showcase, promote and sell their products. Shoppo makes it easier for kiwis to **shop local** for over 2 million products from over 12 thousand online stores from around New Zealand.

Businesses with an online store can list their products so customers can click through to their website to purchase. Shoppo scans websites in New Zealand looking for products to list, and provided the criteria are met displays them along with company name and any contact details if available. 

""")
                .font(.body)
                .foregroundColor(.primary)
                

                HStack(spacing: 10) {
                    Image("sean-sm")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 70, height: 70, alignment: .center)
                        .clipped()
                        .background(Color(.systemBackground))
                        .clipShape(Circle())
                        .cornerRadius(60.0)
                            .overlay(
                                RoundedRectangle(cornerRadius: 60.0)
                                    .stroke(Color.white, lineWidth: 7)
                            )
                            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Shoppo is designed and built by Sean Naden in Auckland, New Zealand. Sean has been designing online stores since 2000. Visit www.seannaden.co.nz")
                            .font(.system(size: 14))
                            .lineSpacing(2)
                        
                    }
                }
                
                    Text("""
    
    **List my products on Shoppo**
    You can create a storefront at www.shoppo.co.nz/list or click on the Add Store link in the menu above and Sean will add your store for you. To edit store details, you will need to log into the website and create an account. 
    
    You can manage your profile and set the update frequency: monthly (default), weekly or daily. This is how often Shoppobot visits your website. You can also configure a dedicated data feed in XML or CSV formats.
    
    **Requirements**
    Your business must be located in New Zealand and your online store must be secure (https) and offer online purchasing, with products containing a name, price, and clear product image(s). You can learn more about how Shoppobot indexes online stores and elegibilty requirements at www.shoppo.co.nz/bot
    
    **Pricing**
    It's free to list your store on Shoppo. For advanced options like more frequent updates, more products, boosted rankings and promoted products stores can upgrade to Premium. View more details at www.shoppo.co.nz/pricing
    
    """)
                    .font(.body)
                    .foregroundColor(.primary)
                
                
                HStack(spacing: 12) {
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
        .navigationTitle("About Shoppo")
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
    }
}
