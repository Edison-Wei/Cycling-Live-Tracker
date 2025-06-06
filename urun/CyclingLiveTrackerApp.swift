//
//  urunApp.swift
//  CyclingLiveTracker
//
//  Created by Edison Wei on 2025-02-18.
//

import SwiftUI

@main
struct urunApp: App {
    @State private var networkMonitor = NetworkMonitor()
    @StateObject private var dataController = DataController()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(networkMonitor)
                .environmentObject(dataController)
        }
    }
}
