//
//  NetworkMonitor.swift
//  CyclingLiveTracker
//
//  Created by Edison Wei on 2025-03-12.
//
import Network
import Foundation

@Observable
final class NetworkMonitor {
    private let networkMonitor = NWPathMonitor()
    private let workerQueue = DispatchQueue(label: "Monitor")
    var isConnected = false
    
    init() {
        networkMonitor.pathUpdateHandler = { path in
            self.isConnected = path.status == .satisfied
        }
        networkMonitor.start(queue: workerQueue)
    }
}
