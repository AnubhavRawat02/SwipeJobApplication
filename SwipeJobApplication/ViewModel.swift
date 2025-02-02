//
//  ViewModel.swift
//  SwipeJobApplication
//
//  Created by Anubhav Rawat on 2/1/25.
//

import SwiftUI
import SwiftData

class ListingPageViewModel: ObservableObject{
    
    let boundary: String = "Boundary-\(UUID().uuidString)"
    
    @Published var searchedText: String = ""
    @Published var feedbackMessage: String = ""
    @Published var allProducts: [SavedProduct] = []
    
    
    var filteredProducts: [SavedProduct] {
        if searchedText.isEmpty {
            return allProducts
        } else {
            return allProducts.filter { $0.productName.localizedCaseInsensitiveContains(searchedText) }
        }
    }
    
    var favoriteProducts: [SavedProduct]{
        return filteredProducts.filter{ $0.isFavourite }
    }
    
    var nonFavoriteProducts: [SavedProduct]{
        return filteredProducts.filter{ !$0.isFavourite }
    }
    
    //    add product parameters
    @Published var name: String = ""
    @Published var type: String = "type 1"
    @Published var sellingPrice: Double = 0.0
    @Published var taxRate: Double = 0.0
    @Published var pickedImage: UIImage? = nil
    
    @Published var addProductsFeedback: String = ""
    @Published var addProductValidationError: String = ""
    
    let options = ["type 1", "type 2", "type 3", "type 4"]
    
    
    func fetchSavedProducts(modelContext: ModelContext){
        
        let descriptors = FetchDescriptor<SavedProduct>()
        if let fetchedProducts = try? modelContext.fetch(descriptors){
            self.allProducts = fetchedProducts
        }
    }
    
    func printInfo(modelContext: ModelContext){
        let descriptors = FetchDescriptor<SavedProduct>()
        if let fetchedProducts = try? modelContext.fetch(descriptors){
            for product in fetchedProducts{
                if product.isFavourite{
                    print(product.productName)
                }
            }
        }
    }
    
    @MainActor
    func getProducts(modelContext: ModelContext) async {
        do{
//            getting products from api
            let allProducts = try await ApiManager.getProducts()
            DispatchQueue.main.async {
                if let allProducts = allProducts{
                    print("got all products")
//                    all favourites
                    print("offline products: \(self.allProducts.count)")
                    let favorites: [SavedProduct] = self.allProducts.filter{$0.isFavourite}
                    
                    let favoriteNames: [String] = favorites.map{$0.productName}
                    
                    print("removing all products. Favourite names: \(favoriteNames)")
//                    remove all saved products
                    for obj in self.allProducts{
                        modelContext.delete(obj)
                    }
//                    save these products
                    let toBeSavedObjects: [SavedProduct] = allProducts.map{ SavedProduct(product: $0) }
                    
                    for obj in toBeSavedObjects{
//                        if the product was favourite previously, then it should remain favourite. 
                        if favoriteNames.contains(obj.productName){
                            print("found \(obj.productName) in favorites")
                            obj.isFavourite = true
                        }
                        modelContext.insert(obj)
                    }
                    
                    try? modelContext.save()
                    
//                    when saved, show them to the ui.
                    self.allProducts = toBeSavedObjects
                }else{
                    self.feedbackMessage = "empty product list"
                }
            }
        }catch{
            DispatchQueue.main.async{
                self.feedbackMessage = error.localizedDescription
            }
        }
    }
    
    func executePreviousRequests(toBeAddedProducts: [ToBeAddedProduct]) async {
        var success: String = ""
        var failures: String = ""
        for product in toBeAddedProducts{
            if let res = try? await ApiManager.addProduct(bodyData: self.createRequestBodyData(name: product.name, type: product.type, sellingPrice: product.price, tax: product.tax, imageData: product.image), boundary: self.boundary){
                if res.success{
                    success += product.name + " "
                }else{
                    failures += product.name + " "
                }
            }else{
                failures += product.name + " "
            }
        }
        
        DispatchQueue.main.async { [success, failures] in
            
            self.feedbackMessage = "\(success.isEmpty ? "" : "successfully added \(success)"). \(failures.isEmpty ? "" : "Failed to add \(failures)")"
        }
    }
    
    private func resetForm(){
        name = ""
        type = "type 1"
        sellingPrice = 0.0
        taxRate = 0.0
        pickedImage = nil
    }
    
    func addButtonPressed(context: ModelContext){
        if isValid(){
            
            if NetworkManager.shared.onlineStatus(){
                Task{
                    do{
                        let bodyData = createRequestBodyData(name: name, type: type, sellingPrice: sellingPrice, tax: taxRate, imageData: pickedImage?.jpegData(compressionQuality: 0.9))
                        let response = try await ApiManager.addProduct(bodyData: bodyData, boundary: boundary)
                        
                        if let success = response?.success, success == true{
                            self.addProductsFeedback = "Successfully added \(self.name)"
                        }else{
                            self.addProductsFeedback = "Unsuccessful in adding the Product."
                        }
                    }catch{
                        print("some error while sending the add request")
                    }
                }
                
            }else{
                
                //                store the request, so it can be executed when device is connected.
                
                let newRequest = ToBeAddedProduct(image: pickedImage?.jpegData(compressionQuality: 0.9), price: sellingPrice, tax: taxRate, name: name, type: type)
                
                context.insert(newRequest)
                
                self.addProductsFeedback = "You are offline. Product \(self.name) will be added once you are back online"
                
            }
            
            resetForm()
            
        }else{
            return
        }
    }
    
    private func isValid() -> Bool{
        
        if name.isEmpty{
            self.addProductValidationError = "name cannot be empty"
            return false
        }
        
        if sellingPrice == 0.0{
            self.addProductValidationError = "selling price cannot be zero"
            return false
        }
        
        
        return true
    }
    
    private func createRequestBodyData(name: String, type: String, sellingPrice: Double, tax: Double, imageData: Data?) -> Data{
        var body = Data()
        let lineBreak = "\r\n"
        
        
        body = addToData(data: body, propertyName: "product_name", property: name)
        body = addToData(data: body, propertyName: "product_type", property: type)
        body = addToData(data: body, propertyName: "price", property: "\(sellingPrice)")
        body = addToData(data: body, propertyName: "tax", property: "\(tax)")
        
        if let data = imageData{
            
            body.append("--\(boundary + lineBreak)")
            body.append("Content-Disposition: form-data; name=\"files[]\"; filename=\"image.jpg\"\(lineBreak)")
            body.append("Content-Type: image/jpeg\(lineBreak + lineBreak)")
            body.append(data)
            body.append(lineBreak)
        }
        
        body.append("--\(boundary)--\(lineBreak)")
        
        return body
    }
    
    private func addToData(data: Data, propertyName: String, property: String) -> Data{
        let lineBreak = "\r\n"
        
        var body = data
        
        body.append("--\(boundary + lineBreak)")
        body.append("Content-Disposition: form-data; name=\"\(propertyName)\"\(lineBreak + lineBreak)")
        body.append("\(property + lineBreak)")
        
        return body
    }
}
