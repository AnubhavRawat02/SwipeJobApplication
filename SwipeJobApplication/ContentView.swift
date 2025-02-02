//
//  ContentView.swift
//  SwipeJobApplication
//
//  Created by Anubhav Rawat on 1/30/25.
//

import SwiftUI
import SwiftData

struct ListingPage: View {
    
    @StateObject var viewModel = ListingPageViewModel()
    @Environment(\.modelContext) var modelContext
    
    var body: some View {
        NavigationView {
            ScrollView{
                TextField("Search products...", text: $viewModel.searchedText)
                    .padding(10)
                    .padding(.leading, 30) // Space for the magnifying glass icon
                    .background(Color(.systemGray5).opacity(0.3))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.white.opacity(0.6), lineWidth: 1) // White border with slight opacity
                    )
                    .overlay(
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.gray)
                                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                                .padding(.leading, 8)
                            
                            if !viewModel.searchedText.isEmpty {
                                Button(action: { viewModel.searchedText = "" }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.gray)
                                        .padding(.trailing, 8)
                                }
                            }
                        }
                    )
                    .foregroundColor(.white)
                    .keyboardType(.default)
                    .padding(.all, 5)
                
                VStack {
                    if !viewModel.feedbackMessage.isEmpty{
                        Text("\(viewModel.feedbackMessage)")
                            .onAppear {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 3){
                                    self.viewModel.feedbackMessage = ""
                                }
                            }
                    }
                    
                    ForEach(viewModel.favoriteProducts, id: \.id){product in
                        ProductView(product: product, modelContext: modelContext)
                    }
                    ForEach(viewModel.nonFavoriteProducts, id: \.id){product in
                        ProductView(product: product, modelContext: modelContext)
                    }
                }
                
            }
            .scrollIndicators(.hidden)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink {
                        AddNewProduct(viewModel: viewModel)
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 13))
                            .foregroundColor(.white)
                            .padding(.all, 10)
                            .background(Color.orange.opacity(0.9))
                            .clipShape(Circle())
                            .shadow(color: .blue.opacity(0.5), radius: 10, x: 0, y: 5)
                    }

                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        Task{
//                            viewModel.allProducts = []
//                            viewModel.fetchSavedProducts(modelContext: modelContext)
                            await viewModel.getProducts(modelContext: modelContext)
                        }
                        
                    } label: {
                        Text("get new products")
                    }

                    
                }
                ToolbarItem(placement: .navigationBarLeading){
                    Button {
                        viewModel.printInfo(modelContext: modelContext)
                    } label: {
                        Text("print")
                    }

                }
                
            }
        }
        .onAppear {
            
            viewModel.fetchSavedProducts(modelContext: modelContext)
            
            Task{
                await viewModel.getProducts(modelContext: modelContext)
                
//                execute reqeusts which were not completed.
                let descriptor = FetchDescriptor<ToBeAddedProduct>()
                if let toBeAddedProducts = try? modelContext.fetch(descriptor){
                    await viewModel.executePreviousRequests(toBeAddedProducts: toBeAddedProducts)
//                    delete requests once complete.
                    for obj in toBeAddedProducts{
                        modelContext.delete(obj)
                    }
                    
                }
                
            }
            
        }
        
    }
}

struct ProductView: View {
    
    var product: SavedProduct
    var modelContext: ModelContext
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10){
            AsyncImage(url: URL(string: product.image)){phase in
                switch phase {
                case .empty:
                    Image("placeholder").productImageSize()
                case .success(let image):
                    image.productImageSize()
                case .failure(_):
                    Image("placeholder").productImageSize()
                @unknown default:
                    Image("placeholder").productImageSize()
                }
            }
            .scaledToFit()
            .frame(height: 150)
            .clipped()
            .cornerRadius(10)
            
            VStack(alignment: .leading, spacing: 5){
                HStack(spacing: 10){
                    Text(product.productName)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Button {
                        product.isFavourite.toggle()
                        try? modelContext.save()
                    } label: {
                        Image(systemName: product.isFavourite ? "heart.fill" : "heart")
                            .foregroundColor(product.isFavourite ? .red : .white)
                            .font(.title2)
                    }
                }
                
                Text(product.productType)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                HStack(alignment: .top, spacing: 10){
                    VStack(alignment: .leading){
                        Text("Selling Price")
                        Text("$\(product.price, specifier: "%.2f")")
                    }
                    .font(.title2)
                    .bold()
                    .foregroundColor(.green)
                    
                    VStack(alignment: .leading){
                        Text("Tax")
                        Text("$\(product.tax, specifier: "%.2f")")
                    }
                    .font(.footnote)
                    .foregroundColor(.gray)
                    
                }
                
            }

        }
    }
}

#Preview {
    ListingPage()
}
