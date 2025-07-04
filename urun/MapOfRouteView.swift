//
//  MapOfRoute.swift
//  CyclingLiveTracker
//
//  Created by Edison Wei on 2025-03-12.
//
import SwiftUI
import MapKit

struct MapOfRouteView: View {
    @State var centerPosition: MapCameraPosition
    var routeCoordinates: [CLLocationCoordinate2D] = []
    @Binding var markerComments: [MarkerComment]
    @Binding var userCoordinates: [NetworkCoordinate]
    let markersSBE: [MarkerComment]     // Markers provided by the team indicating Start, Break, End
    
    @State var toggleMarkerComment: Bool = false
    
    @State var didMessageFailedToSend: Bool = false
    @State var message: String = ""

    
    init(route: Route, userCoordinates: Binding<[NetworkCoordinate]>, markerComments: Binding<[MarkerComment]>) {
        self._userCoordinates = userCoordinates
        self._markerComments = markerComments
        let initialCamera = route.getCameraCenterPosition()
        self._centerPosition = State(initialValue: .camera(initialCamera))
        self.routeCoordinates = route.getCLLocationCoordinates2D()
        self.markersSBE = route.getMarkerComments()
    }
    
    var body: some View {
        ZStack {
            Map(position: $centerPosition) {
                // Change how the markers are displayed and the comments (Check with exces)
                ForEach(markersSBE) { (marker: MarkerComment) in
                    Marker(coordinate: marker.coordinate) {
                        Label(marker.message, systemImage: "mappin")
                    }
                }
                MapPolyline(coordinates: self.routeCoordinates).stroke(.red, lineWidth: 2)
                ForEach(markerComments) { ( markerComment: MarkerComment ) in
                    Marker(coordinate: markerComment.coordinate) {
                        Label(markerComment.message, systemImage: "mappin")
                    }
                }
            }
            .mapControls {
                MapUserLocationButton()
            }
            
            Button {
                toggleMarkerComment.toggle()
            } label: {
                Image(systemName: "plus.app")
                    .padding()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            
            if toggleMarkerComment {
                VStack(spacing: 5) {
                    Text("Marker")
                        .font(.title2)
                    Text("A marker will be placed at your current location along with your message")
                        .font(.caption)
                        .padding(EdgeInsets(top: 10, leading: 30, bottom: 10, trailing: 30))
                        .multilineTextAlignment(.center)
                    if didMessageFailedToSend {
                        Text("Message failed to send. Try again.")
                            .font(.caption2)
                            .foregroundStyle(.red)
                    }
                    TextField("Enter a message", text: $message)
                        .padding(.horizontal)
                    HStack {
                        Spacer()
                        Button("Close") {
                            toggleMarkerComment.toggle()
                            didMessageFailedToSend = false
                            message = ""
                        }
                        Spacer().border(.gray, width: 0.5)
                        Button("Submit") {
                            postMarkerComment()
                        }
                        Spacer()
                    }
                    .padding()
                    .font(.callout)
                    .border(.gray, width: 0.5)
                }
            .padding(.top, 10)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 20)) // Use RoundedRectangle directly
            .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(.black, lineWidth: 1.5) )
            .padding(EdgeInsets(top: 0, leading: 25, bottom: 2, trailing: 25))
            .shadow(radius: 2)
            }
        }
    }
        
    // This function can be removed if battery and data usage is heavily impacted
    func postMarkerComment() {
        if message == "" {
            didMessageFailedToSend = true
            return
        }
        if userCoordinates.isEmpty {
            message = "Tracking has to be started"
            return
        }
        
        let userCurrentCoordinate: NetworkCoordinate = userCoordinates.last!
        let newMarkerComment = MarkerComment(coordinate: CLLocationCoordinate2D(latitude: userCurrentCoordinate.latitude, longitude: userCurrentCoordinate.longitude), message: message)
        
        guard let url = URL(string: "https://www.sfucycling.ca/api/ClubActivity/CommentMarker") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.setValue("bearer: \(ProcessInfo.processInfo.environment["LiveTrackerID"]!)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 60
        request.httpBody = try! JSONEncoder().encode(newMarkerComment)
        
        URLSession.shared.dataTask(with: request) { _, response, error in
            guard
                let response = response as? HTTPURLResponse,
                error == nil
            else {
                print("error", error ?? URLError(.badServerResponse))
                didMessageFailedToSend = true
                return
            }
            if (200...299).contains(response.statusCode) {
                markerComments.append(newMarkerComment)
                message = ""
                didMessageFailedToSend = false
                toggleMarkerComment.toggle()
            }
        }.resume()
    }
}
