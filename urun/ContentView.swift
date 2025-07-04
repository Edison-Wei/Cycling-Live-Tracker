//
//  ContentView.swift
//  CyclingLiveTracker
//
//  Created by Edison Wei on 2025-02-18.
//

import Combine
import SwiftUI

// TODO
// 1. (Done) Figure out data being retrieved from sfucycling.ca
//      Most likely like:
//                    let gpx: [Coordinates]
//                    let distance: Double
//                    let start_date: Date
//                    let start_time: TimeInterval
//                    let end_time: TimeInterval
// 2. (Done) Create a parser for the geojson data or gpx im not 100% which (if needed)
// 3. (Done) display data on the map and have a userCurrentPosition
// 4. (Done) Find out how to send the data to the server
// 5. (Done) Have a cache system that stores the routeinfo to reduce calculation time and data usage
// 6. (X) Create a login screen (For the executives to use only)


struct ContentView: View {
    @Environment(NetworkMonitor.self) private var networkMonitor
    @StateObject var activityTracker: ActivityTracker = ActivityTracker()
    @StateObject var deviceLocationService = DeviceLocationService.shared
    private let dataController: DataController = DataController()
    let liveTrackerID = ProcessInfo.processInfo.environment["LiveTrackerID"] ?? ""
    
    @State var routeDetail: Route = Route()
    @State var tokens: Set<AnyCancellable> = []
    @State var userCoordinates: [NetworkCoordinate] = []
    @State var markerComments: [MarkerComment] = []
    
    // Variables to control the view
    @State private var trackerTitle: String = "Start Tracking"
    @State private var isTrackerOn: Bool = false
    @State private var isProcessing: Bool = false
    
    @State private var showRetryFetch: Bool = false
    @State private var messageFromServer: String = ""
    
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
                if routeDetail.isRouteReceived() {
                    MapOfRouteView(
                        route: routeDetail,
                        userCoordinates: $userCoordinates,
                        markerComments: $markerComments)
                }
                
                
                DrawerMenuView(route: routeDetail, userCoordinate: $userCoordinates , markerComments: $markerComments)
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
                                self.routeDetail = Route(routeInfo: routeInfo!)
                            }
                            else {
                                drawerOffset = snapPosition(geometry: geometry, position: .full)
                                showRetryFetch = true
                            }
                        }
                        observeCoordinateUpdates()
                        observeLocationAccessDenied()
                    }
                
                if showRetryFetch {
                    VStack(spacing: 10) {
                        Text(messageFromServer)
                            .font(.title)
                            .padding(.bottom, 10)
                        Button {
                            fetchRouteData()
                            showRetryFetch = false
                        } label: {
                            VStack(spacing: 5) {
                                Image(systemName: "arrow.circlepath")
                                Text("Try agian")
                                    .font(.title2)
                            }
                        }
                        .font(.title)
                    }
                    .frame(height: geometry.size.height)
                    .offset(y: drawerOffset == geometry.size.height ? drawerOffset : drawerOffset * 0.5)
                }
            }
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
                self.userCoordinates.append(NetworkCoordinate(latitude: coordinates.coordinate.latitude, longitude: coordinates.coordinate.longitude, elevation: coordinates.altitude))
                self.activityTracker.calculateDistance(NetworkCoordinate(latitude: coordinates.coordinate.latitude, longitude: coordinates.coordinate.longitude, elevation: coordinates.altitude))
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
        
        guard let url = URL(string: "https://www.sfucycling.ca/api/ClubActivity/RouteInformation?id=\(liveTrackerID)&route_date=\(routeDate.ISO8601Format())") else { return }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Network Error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    messageFromServer = error.localizedDescription
                    showRetryFetch = true
                    drawerOffset = 0.0
                }
                return
            }
            guard let response = response as? HTTPURLResponse,
                  (200...299).contains(response.statusCode)
            else {
                print("error", error ?? URLError(.badServerResponse))
                return
            }
            guard let data = data 
            else {
                messageFromServer = "Route could not be fetched"
                showRetryFetch = true
                drawerOffset = 0
                return
            }
            
            if response.statusCode == 202 {
                DispatchQueue.main.async {
                    let routeInfo = dataController.fetchLocalRouteInfo()
                    self.routeDetail = Route(routeInfo: routeInfo!)
                }
                return
            } else if response.statusCode == 203 {
                do {
                    let routeMessageObject = try JSONDecoder().decode(NetworkMessage.self, from: data)
                    DispatchQueue.main.async {
                        messageFromServer = routeMessageObject.message
                        showRetryFetch = true
                        drawerOffset = 0.0
                    }
                    return
                } catch {
                    print("routeMessage was not decoded properly")
                    print(error.localizedDescription)
                }
            }
            else if response.statusCode == 501 {
                do {
                    let routeMessageObject = try JSONDecoder().decode(NetworkMessage.self, from: data)
                    DispatchQueue.main.async {
                        messageFromServer = routeMessageObject.message
                        showRetryFetch = true
                        drawerOffset = 0.0
                    }
                    return
                } catch {
                    print("routeMessage was not decoded properly")
                    print(error.localizedDescription)
                }
            }
            
            do {
                let routeInfoObject = try JSONDecoder().decode(NetworkRouteInfo.self, from: data)
                if routeInfoObject.isEmpty() {
                    return
                }
                DispatchQueue.main.async {
                    dataController.storeRouteInfo(routeInfo: routeInfoObject)
                    self.routeDetail = Route(routeInfo: routeInfoObject)
                }
            } catch {
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
