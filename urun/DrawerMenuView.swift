//
//  DrawerMenu.swift
//  CyclingLiveTracker
//
//  Created by Edison Wei on 2025-04-24.
//

import SwiftUI
import Combine

struct DrawerMenuView: View {
    @EnvironmentObject var activityTracker: ActivityTracker
    @Binding var userCoordinates: [NetworkCoordinate]
    @Binding var markerComments: [MarkerComment]
    private let liveTrackerLocation: LiveTrackerLocation = LiveTrackerLocation()
    
    @State var isProcessing: Bool = false
    @State var discardRoute: Bool = false
    @State var finishedProcessing: Bool = false
    
    // Timer to Send Coordinates to the server
    private var timer = Timer.publish(every: 300.0, on: .main, in: .common).autoconnect()
    @State private var timerSubscription: Cancellable? = nil
    
    let route: Route
    
    init(route: Route, userCoordinate: Binding<[NetworkCoordinate]>, markerComments: Binding<[MarkerComment]>) {
        self.route = route
        self._userCoordinates = userCoordinate
        self._markerComments = markerComments
    }
    
    var body: some View {
        VStack {
            RoundedRectangle(cornerRadius: 5)
                .frame(width: 50, height: 6)
                .foregroundStyle(.gray)
                .padding(.vertical)
            
            
            VStack(spacing: 20) {
                if activityTracker.isTrackerOn {
                    VStack(spacing: 10) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Time:")
                                    .font(.subheadline)
                                Text(activityTracker.formatTimeInterval(activityTracker.timeElapsed))
                                    .font(.title2)
                            }
                            Spacer()
                            VStack(alignment: .leading) {
                                Text("Distance:")
                                    .font(.subheadline)
                                Text(activityTracker.formatDistance(activityTracker.distanceTravelled))
                                    .font(.title2)
                            }
                        }
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Elevation:")
                                    .font(.subheadline)
                                Text(activityTracker.formatDistance(activityTracker.totalElevation))
                                    .font(.title2)
                            }
                            Spacer()
                        }
                        if finishedProcessing {
                            Text("Finished Procesing")
                                .font(.title2)
                                .onAppear {
                                    DeviceLocationService.shared.requestLocationServices(false)
                                }
                        }
                        else {
                            if isProcessing {
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(.gray)
                                    .frame(width: 50, height: 25)
                                    .overlay {
                                        ProgressView()
                                    }
                                    .onAppear {
                                        postUserRouteData()
                                    }
                            }
                            else {
                                HStack(spacing: 10) {
                                    Button {
                                        activityTracker.finishTracking()
                                        isProcessing = true
                                        stopSendingLocationData()
                                    } label: {
                                        Label("Finish", systemImage: "stop.circle")
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .tint(.red)
                                    
                                    if activityTracker.isPaused {
                                        Button {
                                            activityTracker.resumeTracking()
                                        } label: {
                                            Label("Resume", systemImage: "play.circle")
                                        }
                                        .buttonStyle(.borderedProminent)
                                        .tint(.green)
                                    } else {
                                        Button {
                                            activityTracker.pauseTracking()
                                        } label: {
                                            Label("Pause", systemImage: "pause.circle")
                                        }
                                        .buttonStyle(.borderedProminent)
                                        .tint(.orange)
                                    }
                                }
                            }
                        }
                    }
                    .padding(EdgeInsets(top: 0, leading: 20, bottom: 50, trailing: 20))
                    Spacer()
                }
                
                if route.isRouteReceived() {
                    VStack(spacing: 10) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Ride Date:")
                                    .font(.subheadline)
                                Text(route.getDate())
                                    .font(.title3)
                            }
                            Spacer()
                            VStack(alignment: .leading) {
                                Text("Time:")
                                    .font(.subheadline)
                                Text(route.getTime())
                                    .font(.title3)
                            }
                        }
                        
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Distance:")
                                    .font(.subheadline)
                                Text(route.formatDistance())
                                    .font(.title3)
                            }
                            Spacer()
                            VStack(alignment: .leading) {
                                Text("Elevation:")
                                    .font(.subheadline)
                                HStack(spacing: 5) {
                                    (Text(String(format: "%.2f", route.getElevationGain()))
                                        .font(.title3)
                                    +
                                    Text(Image(systemName: "arrow.up")))
                                    (Text(String(format: "%.2f", route.getElevationDecline()))
                                        .font(.title3)
                                    +
                                    Text(Image(systemName: "arrow.down")))
                                }
                            }
                        }
                        
                        if !activityTracker.isTrackerOn {
                            Button {
                                activityTracker.startTracking()
                                DeviceLocationService.shared.requestLocationServices(activityTracker.isTrackerOn)
                                startSendingLocationData()
                            } label: {
                                Label("Start Tracking", systemImage: "play.circle.fill")
                                    .font(.title2)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.blue)
                            .padding(.top, 10)
                        }
                    }
                    .padding(.horizontal, 20)
                }
                
                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.bottom, 50)
        }
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .circular))
        .ignoresSafeArea()
        
        if discardRoute {
            RoundedRectangle(cornerRadius: 5)
                .background(.gray)
                .shadow(radius: 2.0)
                .padding(5)
                .overlay {
                    VStack(spacing: 10) {
                        Text("Discard Route?")
                            .font(.title2)
                        Button {
                            DeviceLocationService.shared.requestLocationServices(false)
                            discardRoute = false
                        } label: {
                            Label("Discard", systemImage: "trash")
                        }
                        Button {
                            activityTracker.resumeTracking()
                            discardRoute = false
                        } label: {
                            Label("Cancel", systemImage: "xmark")
                        }
                    }
                }
        }
    }
    
    func startSendingLocationData() {
        timerSubscription = timer.sink { _ in
            if !userCoordinates.isEmpty {
                liveTrackerLocation.postCurrentCoordinate(userCurrentCoordinate: userCoordinates.last!)
            }
        }
    }
    
    func stopSendingLocationData() {
        timerSubscription?.cancel()
    }
    
    func postUserRouteData() {
        guard let url = URL(string: "https://www.sfucycling.ca/api/ClubActivity/RouteInformation") else { return }
        if userCoordinates.isEmpty || userCoordinates.count < 300 {
            isProcessing = false
            discardRoute = true
            return
        }
        
        var sending: [NetworkCoordinate] = []
        for _ in (0...240) {
            for coordinate in userCoordinates {
                sending.append(coordinate)
            }
        }
        
        // Push the Route Start and end markers aswell
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.setValue("bearer: \(ProcessInfo.processInfo.environment["LiveTrackerID"]!)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 60
        request.httpBody = try! JSONEncoder().encode(RouteEncoder(coordinates: sending, markerCoordinates: markerComments, elapsedTime: activityTracker.formatTimeInterval(activityTracker.timeElapsed)))

        URLSession.shared.dataTask(with: request) { _, response, error in
            guard error == nil else { isProcessing = false; discardRoute = true; return}
            if let _ = response as? HTTPURLResponse {
                isProcessing = false
                finishedProcessing = true
            }
            
        }.resume()
    }
}
