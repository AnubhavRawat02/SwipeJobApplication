//
//  ApiManager.swift
//  SwipeJobApplication
// 
//  Created by Anubhav Rawat on 1/31/25.
//

import Foundation
import SwiftData

@Model
class ToBeAddedProduct{
    var image: Data? 
    var price: Double
    var tax: Double
    var name: String
    var type: String
    
    init(image: Data? = nil, price: Double, tax: Double, name: String, type: String) {
        self.image = image
        self.price = price
        self.tax = tax
        self.name = name
        self.type = type
    }
}

@Model
class SavedProduct: Identifiable{
    var id: UUID = UUID()
    var image: String
    var price: Double
    var productName: String
    var productType: String
    var tax: Double
    var isFavourite: Bool = false
    
    init(product: Product) {
        self.id = product.id
        self.image = product.image
        self.price = product.price
        self.productName = product.productName
        self.productType = product.productType
        self.tax = product.tax
    }
}

struct APIResponse: Decodable{
    let message: String
    let productId: Int
    let success: Bool
    let productDetails: Product
    
    enum CodingKeys: String, CodingKey{
        case message, success
        case productId = "product_id"
        case productDetails = "product_details"
    }
}

struct Product: Identifiable, Codable{
    let id: UUID = UUID()
    let image: String
    let price: Double
    let productName: String
    let productType: String
    let tax: Double
    
    enum CodingKeys: String, CodingKey{
        case image, price, tax
        case productName = "product_name"
        case productType = "product_type"
    }
}

class ApiManager{
    
    enum ApiEndpoints: String{
        case getProducts = "https://app.getswipe.in/api/public/get"
        case addProduct = "https://app.getswipe.in/api/public/add"
    }
    
    static func getProducts() async throws -> [Product]?{
        let request = URLRequest(url: URL(string: ApiEndpoints.getProducts.rawValue)!)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let _ = response as? HTTPURLResponse else{
            return nil
        }
        
        let products = try JSONDecoder().decode([Product].self, from: data)
        
        return products
        
    }
    
    static func addProduct(bodyData: Data, boundary: String) async throws -> APIResponse?{
        var request = URLRequest(url: URL(string: ApiEndpoints.addProduct.rawValue)!)
        request.httpMethod = "POST"
        
        request.httpBody = bodyData
        request.setValue("multipart/form-data; boundary=" + boundary, forHTTPHeaderField: "Content-Type")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let jsonString = String(data: data, encoding: .utf8) {
            print("Raw JSON Response: \(jsonString)")
        }
        
        guard let _ = response as? HTTPURLResponse else{
            return nil
        }
        
        let apiResponse = try JSONDecoder().decode(APIResponse.self, from: data)
        
        return apiResponse
        
    }
}
