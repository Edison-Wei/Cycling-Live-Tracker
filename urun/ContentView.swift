//
//  ContentView.swift
//  CyclingLiveTracker
//
//  Created by Edison Wei on 2025-02-18.
//

import Combine
import SwiftUI

// TODO
// 1. Figure out data being retrieved from sfucycling.ca
//      Most likely like:
//                    let gpx: [Coordinates]
//                    let distance: Double
//                    let start_date: Date
//                    let start_time: TimeInterval
//                    let end_time: TimeInterval
// 2. Create a parser for the geojson data or gpx im not 100% which (if needed)
// 3. display data on the map and have a userCurrentPosition
// 4. Figure out how to send the data to the server
// 5. Have a cache system that stores the routeinfo to reduce calculation time and data usage


struct ContentView: View {
    @Environment(NetworkMonitor.self) private var networkMonitor
    @StateObject var deviceLocationService = DeviceLocationService.shared
    private let liveTrackerLocation: LiveTrackerLocation = LiveTrackerLocation()
    
    // Timer to Send Coordinates to the database
    @State private var timer: Timer = Timer()
    
    @State var routeDetails: Route = Route()
    @State var tokens: Set<AnyCancellable> = []
    @State var userCoordinates: [Coordinates] = [Coordinates(lat: 0.0, lon: 0.0, elv: 0.0)] // Do not need the inside Coordinate
    @State var markerComments: [MarkerComment] = []
    @State var coordinateCounter: Int = 0
    
    // Variables to control the view
    @State private var trackerTitle: String = "Start Tracking"
    @State private var trackerOn: Bool = false
    @State private var isProcessing: Bool = false
    
    
    var body: some View {
        // Create a login screen
        VStack {
            Text("Distance: \(routeDetails.getDistance())")
            Text(routeDetails.getDate())
                .font(.largeTitle)
        }
        .onAppear {
            observeCoordinateUpdates()
            observeLocationAccessDenied()
        }
        
        VStack {
            if isProcessing {
                ZStack {
                    ProgressView()
                }
                .onAppear {
                    postUserRouteData()
                }.padding()
            }
            else {
                Button(trackerTitle) {
                    if trackerOn {
                        trackerOn = false
                        trackerTitle = "Start Tracking"
                        isProcessing = true
                    }
                    else {
                        trackerOn = true
                        trackerTitle = "Finish Ride"
                    }
                    deviceLocationService.requestLocationServices(trackerOn)
                }
                .padding()
                .border(Color.cyan, width: 2)
                .cornerRadius(5.0)
            }
        }.onAppear {
            if networkMonitor.isConnected {
                fetchRouteData()
            }
            else {
                // TODO
                // Grab from storage on device
                //  else alert user to be connected to internet
            }
        }
        
        MapOfRoute(
            routeCoordinates: routeDetails.getCLLocationCoordinates2D(),
            routeDetail: routeDetails.getRouteDetail(),
            userCoordinates: $userCoordinates,
            markerComments: $markerComments)
    }
    
    func observeCoordinateUpdates() {
        deviceLocationService.coordinatesPublisher
            .receive(on: DispatchQueue.main)
            .sink { completion in
                if case .failure(let error) = completion {
                    print(error)
                }
            } receiveValue: { coordinates in
                self.userCoordinates.append(Coordinates(lat: coordinates.latitude, lon: coordinates.longitude, elv: Double.nan))
                self.coordinateCounter += 1
            }
            .store(in: &tokens)
    }
    
    func observeLocationAccessDenied() {
        deviceLocationService.deniedLocationAccessPublisher
            .receive(on: DispatchQueue.main)
            .sink {
                print("Alert")
            }
            .store(in: &tokens)
    }
    
    func startSending() {
        timer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { _ in
            liveTrackerLocation.postCurrentCoordinate(userCurrentCoordinate: userCoordinates.last!)
        }
    }
    
    func stopSending() {
        timer.invalidate()
    }
    
    func fetchRouteData() {
        guard let url = URL(string: "https://jsonplaceholder.typicode.com/posts") else { return }
//        guard let url = URL(string: "https://www.sfucycling.ca/api/grab/route/") else { return }
        
        liveTrackerLocation.networkSession().dataTask(with: url) { data, response, error in
            guard let data = data else { return }
            do {
                print(data)
                let routeInfoObject = try JSONDecoder().decode(RouteInfo.self, from: data)
                DispatchQueue.main.async {
                    self.routeDetails = Route(routeInfo: routeInfoObject)
                }
            } catch {
                print(error.localizedDescription)
            }
        }.resume()
        
//        var apiRoute: RouteInfo = RouteInfo()
//        guard let url = URL(string: "https://jsonplaceholder.typicode.com/posts") else { return RouteInfo() }
//
//        URLSession.shared.dataTask(with: url) { data, response, error in
//            guard let data = data else { return }
//            do {
//                let routeInfoObject = try JSONDecoder().decode(RouteInfo.self, from: data)
//                DispatchQueue.main.async {
//                    apiRoute = routeInfoObject
//                    self.routeInfo = routeInfoObject
//                }
//            } catch {
//                print(error.localizedDescription)
//            }
//        }.resume()
//        print("Printing Fetch \(apiRoute)")
//
//        return apiRoute
    }
    
    func postUserRouteData() {
        guard let url = URL(string: "https://jsonplaceholder.typicode.com/posts") else { return }
//        guard let url = URL(string: "https://www.sfucycling.ca/api/post/route") else { return }
        if userCoordinates.isEmpty || userCoordinates.count < 300 {
            return
        }
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpMethod = "POST"
        request.httpBody = try! JSONEncoder().encode(coordinateEncoder(coordinates: userCoordinates, markerCoordinates: markerComments))
        
        
        liveTrackerLocation.networkSession().dataTask(with: request) { _, response, error in
            guard
                let _ = response as? HTTPURLResponse,
                error == nil
            else {
                isProcessing = false
                print("error", error ?? URLError(.badServerResponse))
                return
            }
            
        }.resume()
    }
}

#Preview {
    ContentView()
        .environment(NetworkMonitor())
}
