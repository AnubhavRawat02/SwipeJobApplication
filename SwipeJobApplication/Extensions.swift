//
//  Extensions.swift
//  SwipeJobApplication
//
//  Created by Anubhav Rawat on 1/31/25.
//

import SwiftUI
import Network

class NetworkManager {
    static let shared = NetworkManager()
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue.global(qos: .background)
    
    var isConnected: Bool = false
    
    func onlineStatus() -> Bool{
        monitor.pathUpdateHandler = { path in
            self.isConnected = path.status == .satisfied
            print("Network status changed: \(self.isConnected ? "Online" : "Offline")")
            
        }
        return self.isConnected
    }
    
    private init() {
        monitor.pathUpdateHandler = { path in
            self.isConnected = path.status == .satisfied
            print("Network status changed: \(self.isConnected ? "Online" : "Offline")")
        }
        monitor.start(queue: queue)
    }
}

extension Image {
    func productImageSize(width: CGFloat = 100, height: CGFloat = 100) -> some View {
        self.resizable()
            .scaledToFill()
            .frame(width: width, height: height)
            .clipped()
    }
}

extension TextField{
    func addImageInputSize() -> some View{
        self.padding()
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .frame(width: 200)
    }
}


extension Data{
    mutating func append(_ string: String){
        if let data = string.data(using: .utf8){
            self.append(data)
        }
    }
}


extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
