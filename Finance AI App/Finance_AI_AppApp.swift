//
//  Finance_AI_AppApp.swift
//  Finance AI App
//
//  Created by Sai Pulavarthy on 1/15/25.
//

import SwiftUI

@main
struct Finance_AI_AppApp: App {
    
    init() {
        // Configure OpenAI API key for development
        // Replace YOUR_API_KEY_HERE with your actual OpenAI API key
        UserDefaults.standard.set("YOUR_API_KEY_HERE", forKey: "OpenAI_API_Key")
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
