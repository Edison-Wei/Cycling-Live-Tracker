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
    @StateObject var activityTracker: ActivityTracker = ActivityTracker()
    @StateObject var deviceLocationService = DeviceLocationService.shared
    private let dataController: DataController = DataController()
    let liveTrackerID = ProcessInfo.processInfo.environment["LiveTrackerID"] ?? ""
    
    @State var routeDetails: Route = Route()
    @State var tokens: Set<AnyCancellable> = []
    @State var userCoordinates: [NetworkCoordinate] = []
    @State var markerComments: [MarkerComment] = []
    
    // Variables to control the view
    @State private var trackerTitle: String = "Start Tracking"
    @State private var isTrackerOn: Bool = false
    @State private var isProcessing: Bool = false
    
    @State var drawerOffset: CGFloat = 0
    
    private func snapPosition(geometry: GeometryProxy, position: DrawerPosition) -> CGFloat {
        switch position {
        case .hidden:
            return geometry.size.height // Position the top of the drawer off-screen
        case .quarter:
            return geometry.size.height * 0.75 // 25% visible from the bottom
        case .full:
            return 0 // Position the top of the drawer at the top of the screen
        }
    }
    
    enum DrawerPosition {
        case hidden
        case quarter
        case full
    }
    
    @State private var currentSnapPosition: DrawerPosition = .quarter
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                if routeDetails.isRouteReceived() {
                    MapOfRouteView(
                        routeCoordinates: routeDetails.getCLLocationCoordinates2D(),
                        routeDetail: routeDetails.getRouteDetail(),
                        markersSBE: routeDetails.getMarkerComments(),
                        userCoordinates: $userCoordinates,
                        markerComments: $markerComments)
                }
                
                
                DrawerMenuView(route: routeDetails, userCoordinate: $userCoordinates , markerComments: $markerComments)
                    .environmentObject(activityTracker)
                    .frame(height: geometry.size.height)
                    .offset(y: drawerOffset)
                    .animation(.interactiveSpring(), value: drawerOffset)
                    .gesture(
                        DragGesture()
                            .onChanged { value in drawerOffset = value.translation.height + snapPosition(geometry: geometry, position: currentSnapPosition)
                            }
                            .onEnded { value in
                                let dragVelocity = value.predictedEndTranslation.height
                                let currentHeight = geometry.size.height - drawerOffset
                                
                                if dragVelocity > 500 { // Fast Swipe away
                                    currentSnapPosition = .hidden
                                }
                                else if dragVelocity < -500 { // Fast Swipe content
                                    currentSnapPosition = .full
                                }
                                else {
                                    let hiddenHeight = geometry.size.height
                                    let quarterHeight = geometry.size.height * 0.25
                                    let fullHeight = geometry.size.height

                                    let snapHeights = [hiddenHeight, quarterHeight, fullHeight]
                                    let closestSnapHeight = snapHeights.min(by: { abs($0 - currentHeight) < abs($1 - currentHeight) })!

                                    if closestSnapHeight == hiddenHeight {
                                        currentSnapPosition = .hidden
                                    } else if closestSnapHeight == quarterHeight {
                                        currentSnapPosition = .quarter
                                    } else {
                                        currentSnapPosition = .full
                                    }
                                }
                                drawerOffset = snapPosition(geometry: geometry, position: currentSnapPosition)
                            }
                    )
                    .onAppear {
                        drawerOffset = snapPosition(geometry: geometry, position: .quarter)
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
                                    // send alert to connect
                                }
                                fetchRouteData()
                            }
                        }
                        observeCoordinateUpdates()
                        observeLocationAccessDenied()
                    }
            }
        }
    }
    
    
//    var body: some View {
//        VStack {
//            Text(routeDetails.getDate())
//                .font(.largeTitle)
//            Text(routeDetails.getTime())
//            Text("Distance: \(routeDetails.getDistance()) Elev: \(routeDetails.getElevation())")
//        }
//        .onAppear {
//            observeCoordinateUpdates()
//            observeLocationAccessDenied()
//        }
//        
//        VStack {
//            if isProcessing {
//                ZStack {
//                    ProgressView()
//                }
//                .onAppear {
//                    postUserRouteData()
//                }.padding()
//            }
//            else {
//                Button(trackerTitle) {
//                    if isTrackerOn {
//                        isTrackerOn = false
//                        trackerTitle = "Start Tracking"
//                        isProcessing = true
//                        stopSendingLocationData()
//                    }
//                    else {
//                        isTrackerOn = true
//                        trackerTitle = "Finish Ride"
//                        startSendingLocationData()
//                    }
//                    deviceLocationService.requestLocationServices(isTrackerOn)
//                }
//                .padding()
//                .border(Color.cyan, width: 2)
//                .cornerRadius(5.0)
//            }
//        }.onAppear {
//            if networkMonitor.isConnected {
//                fetchRouteData()
//            }
//            else {
//                if dataController.checkStoredRouteDate() {
//                    let routeInfo = dataController.fetchLocalRouteInfo()
//                    self.routeDetails = Route(routeInfo: routeInfo!)
//                }
//                else {
//                    while !networkMonitor.isConnected {
//                        // send alert to connect then
//                    }
//                    fetchRouteData()
//                }
//            }
//            
////            if dataController.checkStoredRouteDate() {
////                let routeInfo = dataController.fetchLocalRouteInfo()
////                self.routeDetails = Route(routeInfo: routeInfo!)
////            }
////            else if networkMonitor.isConnected {
////                fetchRouteData()
////            }
////            else {
////                while !networkMonitor.isConnected {
////                    
////                }
////            }
//        }
//        
//        if routeDetails.isRouteReceived() {
//            MapOfRoute(
//                routeCoordinates: routeDetails.getCLLocationCoordinates2D(),
//                routeDetail: routeDetails.getRouteDetail(),
//                userCoordinates: $userCoordinates,
//                markerComments: $markerComments)
//        }
//    }
    
    func observeCoordinateUpdates() {
        deviceLocationService.coordinatesPublisher
            .receive(on: DispatchQueue.main)
            .sink { completion in
                if case .failure(let error) = completion {
                    print(error)
                }
            } receiveValue: { coordinates in
                print("Current coordinate: \(coordinates)")
                print("Coordinate count: \(userCoordinates.count)")
                
                self.userCoordinates.append(NetworkCoordinate(latitude: coordinates.coordinate.latitude, longitude: coordinates.coordinate.longitude, elevation: coordinates.altitude))
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
    
    func fetchRouteData() {
        let routeDate = dataController.getRouteDate()
        print(routeDate.ISO8601Format())
        
//        guard let url = URL(string: "https://www.sfucycling.ca/api/ClubActivity/RouteInformation?id=\(liveTrackerID)&route_date=\(routeDate.ISO8601Format())") else { return }
        guard let url = URL(string: "http://localhost:3000/api/ClubActivity/RouteInformation?id=\(liveTrackerID)&route_date=\(routeDate.ISO8601Format())") else { return }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
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
}

#Preview {
    ContentView()
        .environment(NetworkMonitor())
}
