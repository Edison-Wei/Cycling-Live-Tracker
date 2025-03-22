//
//  LiveTrackerLocation.swift
//  CyclingLiveTracker
//
//  Created by Edison Wei on 2025-03-20.
//

import SwiftUI

class LiveTrackerLocation: ObservableObject {
    private var coordinatesNotSent: [Coordinates] = []
    
    // Connection to the database
    private let url: URL? = URL(string: "https://jsonplaceholder.typicode.com/posts") // Change URL
    private let sessionManager: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 30
        return URLSession(configuration: configuration)
    }()
    
    func networkSession() -> URLSession {
        return sessionManager
    }
    
    func postCurrentCoordinate(userCurrentCoordinate: Coordinates) {
        coordinatesNotSent.append(userCurrentCoordinate)
        
        if url == nil {
            return
        }
        var request = URLRequest(url: url!)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpMethod = "POST"
        request.httpBody = try! JSONEncoder().encode(coordinatesNotSent)
        
        sessionManager.dataTask(with: request) { _, response, error in
            guard
                let response = response as? HTTPURLResponse,
                error == nil
            else {
                print("error", error ?? URLError(.badServerResponse))
                return
            }
            if (200...299).contains(response.statusCode) {
                self.coordinatesNotSent.removeAll()
            }
        }.resume()
    }
}
