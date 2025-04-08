//
//  MapOfRoute.swift
//  CyclingLiveTracker
//
//  Created by Edison Wei on 2025-03-12.
//
import SwiftUI
import MapKit

struct MapOfRoute: View {
    @State var centerPosition: MapCameraPosition = .camera(MapCamera(centerCoordinate: CLLocationCoordinate2DMake(49.2790886,-122.9227544), distance: 25000))
    var routeCoordinates: [CLLocationCoordinate2D] = []
    @Binding var markerComments: [MarkerComment]
    @Binding var userCoordinates: [NetworkCoordinate]
    
    @State var toggleMarkerComment: Bool = false
    var triggerCamera = false
    @State var message: String = ""
    
    init(routeCoordinates: [CLLocationCoordinate2D], routeDetail: RouteDetail, userCoordinates: Binding<[NetworkCoordinate]>, markerComments: Binding<[MarkerComment]>) {
        self._userCoordinates = userCoordinates
        self._markerComments = markerComments
        self.centerPosition = .camera(MapCamera(centerCoordinate: CLLocationCoordinate2DMake(routeDetail.latitude, routeDetail.longitude), distance: routeDetail.zoom))
        self.routeCoordinates = routeCoordinates
        self.triggerCamera = true
    }
    
    var body: some View {
        ZStack {
            Map(position: $centerPosition) {
                MapPolyline(coordinates: self.routeCoordinates).stroke(.red, lineWidth: 2)
                ForEach(markerComments) { ( markerComment: MarkerComment ) in
                    Marker(coordinate: markerComment.coordinate) {
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
        let userCurrentCoordinate: NetworkCoordinate = userCoordinates.last!
        let newMarkerComment = MarkerComment(coordinate: CLLocationCoordinate2D(latitude: userCurrentCoordinate.latitude, longitude: userCurrentCoordinate.longitude), comment: message)
        
        guard let url = URL(string: "https://www.sfucycling.ca/api/ClubActivity/CommentMarker") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json; charset=utf-8", forHTTPHeaderField: "Accept")
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
