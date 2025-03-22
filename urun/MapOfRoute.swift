//
//  MapOfRoute.swift
//  CyclingLiveTracker
//
//  Created by Edison Wei on 2025-03-12.
//
import SwiftUI
import MapKit

struct MapOfRoute: View {
    @State var centerPosition: MapCameraPosition = .camera(MapCamera(centerCoordinate: CLLocationCoordinate2DMake(49.2790886,-122.9227544), distance: 1000, heading: 0, pitch: 0))
    var routeCoordinates: [CLLocationCoordinate2D] = []
    @Binding var markerComments: [MarkerComment] // Might be a @Binding Prop
    @Binding var userCoordinates: [Coordinates]
    
    @State var toggleMarkerComment: Bool = false
    @State var message: String = ""
    
    init(routeCoordinates: [CLLocationCoordinate2D], routeDetail: RouteDetail, userCoordinates: Binding<[Coordinates]>, markerComments: Binding<[MarkerComment]>) {
        self._userCoordinates = userCoordinates
        self._markerComments = markerComments
        self.centerPosition = .camera(MapCamera(centerCoordinate: CLLocationCoordinate2DMake(59.2314, -125.2452), distance: 10, heading: 0, pitch: 0))
//        self.centerPosition = .camera(MapCamera(centerCoordinate: CLLocationCoordinate2DMake(routeDetail.latitude, routeDetail.longitude), distance: routeDetail.zoom, heading: 0, pitch: 0))
        self.routeCoordinates = routeCoordinates
    }
    
    var body: some View {
        ZStack {
            Map(position: self.$centerPosition) {
                MapPolyline(coordinates: self.routeCoordinates)
                ForEach(markerComments) { ( markerComment: MarkerComment ) in
                    Marker(coordinate: CLLocationCoordinate2D(latitude: 59.2314, longitude: -125.2452)) {
                        Label(markerComment.comment, systemImage: "mappin")
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
                VStack {
                    Text("Marker Comment")
                        .font(.title2)
                        .padding(EdgeInsets(top: 5, leading: 0, bottom: 0, trailing: 0))
                    Text("The marker will be placed at your current location")
                        .font(.caption2)
                        .padding()
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
                            toggleMarkerComment.toggle()
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
            }
        }
    }
    
    // This function can be removed if battery and data usage is heavily impacted
    func postMarkerComment() {
        let userCurrentCoordinate: Coordinates = userCoordinates.last!
        let newMarkerComment = MarkerComment(coordinate: CLLocationCoordinate2D(latitude: userCurrentCoordinate.lat, longitude: userCurrentCoordinate.lon), comment: message)
        
        // Change URL
        guard let url = URL(string: "https://jsonplaceholder.typicode.com/posts") else { return }
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpMethod = "POST"
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
            }
        }.resume()
    }
}
