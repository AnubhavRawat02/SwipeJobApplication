//
//  SwipeJobApplicationApp.swift
//  SwipeJobApplication
//
//  Created by Anubhav Rawat on 1/30/25.
//


import SwiftUI
import SwiftData

@main
struct SwipeJobApplicationApp: App {
    var body: some Scene {
        WindowGroup {
            ListingPage()
                .preferredColorScheme(.dark)
        }
        .modelContainer(for: [ToBeAddedProduct.self, SavedProduct.self])
        
    }
}
