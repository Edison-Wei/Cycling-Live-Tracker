//
//  LiveTrackerLocation.swift
//  CyclingLiveTracker
//
//  Created by Edison Wei on 2025-03-20.
//

import SwiftUI

class LiveTrackerLocation {
    private var coordinatesNotSent: [NetworkCoordinate] = []
    
    // Connection to the database
    let sessionManager: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 30
        return URLSession(configuration: configuration)
    }()
    
    func postCurrentCoordinate(userCurrentCoordinate: NetworkCoordinate?) {
        if let lastKnownLocation = userCurrentCoordinate {
            coordinatesNotSent.append(lastKnownLocation)
        }
        else {
            print("User Coordinate could not be received")
            return
        }
//        guard let url = URL(string: "https://www.sfucycling.ca/api/ClubActivity/LiveTrackerConnection") else { return } // Change URL
        guard let url = URL(string: "http://localhost:3000/api/ClubActivity/LiveTrackerConnection") else { return } // Change URL
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.setValue("bearer: \(ProcessInfo.processInfo.environment["LiveTrackerID"]!)", forHTTPHeaderField: "Authorization")
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
