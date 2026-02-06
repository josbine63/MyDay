//
//  RootView.swift
//  MyDay
//
//  Created by Assistant on 2025-01-15.
//

import SwiftUI

struct RootView: View {
    @StateObject private var userSettings = UserSettings()
    @StateObject private var photoManager = PhotoManager()
    
    var body: some View {
        ContentView()
            .environmentObject(userSettings)
            .environmentObject(photoManager)
    }
}
