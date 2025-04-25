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
// 6. Create a login screen (For the executives to use only)


struct ContentView: View {
    @Environment(NetworkMonitor.self) private var networkMonitor
    @StateObject var deviceLocationService = DeviceLocationService.shared
    private let liveTrackerLocation: LiveTrackerLocation = LiveTrackerLocation()
    private let dataController: DataController = DataController()
    let liveTrackerID = ProcessInfo.processInfo.environment["LiveTrackerID"] ?? ""
    
    // Timer to Send Coordinates to the database
    private var timer = Timer.publish(every: 300.0, on: .main, in: .common).autoconnect()
    @State private var timerSubscription: Cancellable? = nil
    
    @State var routeDetails: Route = Route()
    @State var tokens: Set<AnyCancellable> = []
    @State var userCoordinates: [NetworkCoordinate] = [] // Do not need the inside Coordinate
    @State var markerComments: [MarkerComment] = []
    
    // Variables to control the view
    @State private var trackerTitle: String = "Start Tracking"
    @State private var isTrackerOn: Bool = false
    @State private var isProcessing: Bool = false
    
    var body: some View {
        VStack {
            Text(routeDetails.getDate())
                .font(.largeTitle)
            Text(routeDetails.getTime())
            Text("Distance: \(routeDetails.getDistance()) Elev: \(routeDetails.getElevation())")
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
                    if isTrackerOn {
                        isTrackerOn = false
                        trackerTitle = "Start Tracking"
                        isProcessing = true
                        stopSendingLocationData()
                    }
                    else {
                        isTrackerOn = true
                        trackerTitle = "Finish Ride"
                        startSendingLocationData()
                    }
                    deviceLocationService.requestLocationServices(isTrackerOn)
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
                if dataController.checkStoredRouteDate() {
                    let routeInfo = dataController.fetchLocalRouteInfo()
                    self.routeDetails = Route(routeInfo: routeInfo!)
                }
                else {
                    while !networkMonitor.isConnected {
                        // send alert to connect then
                    }
                    fetchRouteData()
                }
            }
            
//            if dataController.checkStoredRouteDate() {
//                let routeInfo = dataController.fetchLocalRouteInfo()
//                self.routeDetails = Route(routeInfo: routeInfo!)
//            }
//            else if networkMonitor.isConnected {
//                fetchRouteData()
//            }
//            else {
//                while !networkMonitor.isConnected {
//                    
//                }
//            }
        }
        
        if routeDetails.isRouteReceived() {
            MapOfRoute(
                routeCoordinates: routeDetails.getCLLocationCoordinates2D(),
                routeDetail: routeDetails.getRouteDetail(),
                userCoordinates: $userCoordinates,
                markerComments: $markerComments)
        }
    }
    
    func observeCoordinateUpdates() {
        deviceLocationService.coordinatesPublisher
            .receive(on: DispatchQueue.main)
            .sink { completion in
                if case .failure(let error) = completion {
                    print(error)
                }
            } receiveValue: { coordinates in
                self.userCoordinates.append(NetworkCoordinate(latitude: coordinates.latitude, longitude: coordinates.longitude, elevation: 0.0))
            }
            .store(in: &tokens)
    }
    
    func observeLocationAccessDenied() {
        deviceLocationService.deniedLocationAccessPublisher
            .receive(on: DispatchQueue.main)
            .sink {
                print("Location Services are turned off")
            }
            .store(in: &tokens)
    }
    
    func startSendingLocationData() {
        timerSubscription = timer.sink { _ in
            if !userCoordinates.isEmpty {
                    liveTrackerLocation.postCurrentCoordinate(userCurrentCoordinate: userCoordinates.last)
            }
        }
    }
    
    func stopSendingLocationData() {
        timerSubscription?.cancel()
    }
    
    func fetchRouteData() {
        let routeDate = dataController.getRouteDate()
        print(routeDate.ISO8601Format())
        
        guard let url = URL(string: "https://www.sfucycling.ca/api/ClubActivity/RouteInformation?id=\(liveTrackerID)&route_date=\(routeDate.ISO8601Format())") else { return }
        
        liveTrackerLocation.networkSession().dataTask(with: url) { data, response, error in
            if let error = error {
                print("Network Error: \(error.localizedDescription)")
            }
            guard let response = response as? HTTPURLResponse,
                  (200...299).contains(response.statusCode)
            else {
                print("error", error ?? URLError(.badServerResponse))
                return
            }
            guard let data = data 
            else {
                print("Data was not received")
                return
            }
            
            if response.statusCode == 202 {
                DispatchQueue.main.async {
                    let routeInfo = dataController.fetchLocalRouteInfo()
                    self.routeDetails = Route(routeInfo: routeInfo!)
                }
                return
            }
            
            do {
                let routeInfoObject = try JSONDecoder().decode(NetworkRouteInfo.self, from: data)
                print("From Fetch \(routeInfoObject)")
                if routeInfoObject.isEmpty() {
                    return
                }
                DispatchQueue.main.async {
                    dataController.storeRouteInfo(routeInfo: routeInfoObject)
                    self.routeDetails = Route(routeInfo: routeInfoObject)
                }
            } catch {
                // Fix still
                print("RouteInfo was not decoded properly")
                print(error.localizedDescription)
            }
        }.resume()
    }
    
    func postUserRouteData() {
        guard let url = URL(string: "https://www.sfucycling.ca/api/ClubActivity/RouteInformation") else { return }
        if userCoordinates.isEmpty || userCoordinates.count < 10 {
            isProcessing = false
            return
        }
        // Push the Route Start and end markers aswell
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json; charset=utf-8", forHTTPHeaderField: "Accept")
        request.httpBody = try! JSONEncoder().encode(CoordinateEncoder(coordinates: userCoordinates, markerCoordinates: markerComments))
        
        let jsonEncoded = try! JSONEncoder().encode(CoordinateEncoder(coordinates: userCoordinates, markerCoordinates: markerComments))
        
        print(jsonEncoded)

        
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
