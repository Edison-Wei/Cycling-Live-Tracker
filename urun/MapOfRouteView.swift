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
    let routeDetail: RouteDetail // Do not need
    let markersSBE: [MarkerComment]     // Markers provided by the team indicating Start, Break, End
    
    @State var toggleMarkerComment: Bool = false
    
    @State var messageFailedToSend: Bool = false
    @State var message: String = ""
    

    
    init(routeCoordinates: [CLLocationCoordinate2D], routeDetail: RouteDetail, markersSBE: [MarkerComment], userCoordinates: Binding<[NetworkCoordinate]>, markerComments: Binding<[MarkerComment]>) {
        self._userCoordinates = userCoordinates
        self._markerComments = markerComments
        self.routeDetail = routeDetail
        let initialCamera = MapCamera(centerCoordinate: CLLocationCoordinate2D(latitude: routeDetail.latitude, longitude: routeDetail.longitude), distance: routeDetail.zoom)
        self._centerPosition = State(initialValue: .camera(initialCamera))
        self.routeCoordinates = routeCoordinates
        self.markersSBE = markersSBE
    }
    
    var body: some View {
        ZStack {
            Map(position: $centerPosition) {
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
            .onMapCameraChange { context in
                print("\(context.camera.centerCoordinate)")
                print("\(centerPosition.camera?.centerCoordinate)")
                print("latitude: \(routeDetail.latitude)")
                print("longitude: \(routeDetail.longitude)")
                print("zoom: \(routeDetail.zoom)")
            }
            Button {
                toggleMarkerComment.toggle()
            } label: {
                Image(systemName: "plus.app")
                    .padding()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            
            if toggleMarkerComment {
                VStack {
                    Text("Marker Comment")
                        .font(.title2)
                        .padding(EdgeInsets(top: 5, leading: 0, bottom: 0, trailing: 0))
                    Text("The marker will be placed at your current location")
                        .font(.caption)
                        .padding()
                    if messageFailedToSend {
                        Text("Message failed to send. Try again.")
                            .font(.caption2)
                            .foregroundStyle(.red)
                    }
                    TextField("Enter a message", text: $message)
                        .fixedSize()
                    HStack {
                        Spacer()
                        Button("Close") {
                            toggleMarkerComment.toggle()
                        }
                        Spacer().border(.gray, width: 0.5)
                        Button("Submit") {
                            
                            postMarkerComment()
                            if message == "" {
                                toggleMarkerComment.toggle()
                            }
                            else {
                                messageFailedToSend = true
                            }
                        }
                        Spacer()
                    }
                    .padding()
                    .font(.callout)
                    .border(.gray, width: 0.5)
                }
                .overlay(RoundedRectangle(cornerRadius: 20) .strokeBorder(.black, lineWidth: 1.5) )
                .background(.white)
                .clipShape(.rect(cornerRadius: 20, style: .circular))
                .padding(EdgeInsets(top: 0, leading: 20, bottom: 2, trailing: 20))
//                .padding(.vertical) // Add vertical padding
//                .font(.callout)
//                // Consider removing the border inside HStack and applying background/overlay to VStack
//            }
//            .padding() // Add padding around the entire VStack content
//            .background(.white)
//            .clipShape(RoundedRectangle(cornerRadius: 20)) // Use RoundedRectangle directly
//            .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(.black, lineWidth: 1.5) )
//            .padding(EdgeInsets(top: 0, leading: 20, bottom: 2, trailing: 20))
//            .shadow(radius: 5) // Add a subtle shadow maybe
            }
        }
    }
        
    // This function can be removed if battery and data usage is heavily impacted
    func postMarkerComment() {
        if message == "" {
            messageFailedToSend = true
            return
        }
        let userCurrentCoordinate: NetworkCoordinate = userCoordinates.last!
        let newMarkerComment = MarkerComment(coordinate: CLLocationCoordinate2D(latitude: userCurrentCoordinate.latitude, longitude: userCurrentCoordinate.longitude), message: message)
        
        guard let url = URL(string: "https://www.sfucycling.ca/api/ClubActivity/CommentMarker") else { return }
        guard let url = URL(string: "http://localhost:3000/api/ClubActivity/CommentMarker") else { return } // Change URL
        
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
                return
            }
            if (200...299).contains(response.statusCode) {
                markerComments.append(newMarkerComment)
                message = ""
                messageFailedToSend = false
            }
        }.resume()
    }
}
