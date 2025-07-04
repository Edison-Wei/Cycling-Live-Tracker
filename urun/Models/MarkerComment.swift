//
//  MarkerComment.swift
//  CyclingLiveTracker
//
//  Created by Edison Wei on 2025-03-21.
//


import MapKit

struct MarkerComment: Identifiable, Encodable, Decodable {
    var id: UUID = UUID()
    let coordinate: CLLocationCoordinate2D
    let message: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case coordinate
        case message
    }
    
    enum CoordinateKeys: String, CodingKey {
        case latitude
        case longitude
    }
    
    init(id: UUID, coordinate: CLLocationCoordinate2D, message: String) {
        self.id = id
        self.coordinate = coordinate
        self.message = message
    }
    
    init(coordinate: CLLocationCoordinate2D, message: String) {
        self.id = UUID()
        self.coordinate = coordinate
        self.message = message
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.message = try container.decode(String.self, forKey: .message)
        let coordinateData = try container.decode([Double].self, forKey: .coordinate)
        self.coordinate = CLLocationCoordinate2D(latitude: coordinateData[1], longitude: coordinateData[0])
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(message, forKey: .message)
        
        var coordinateContainer = container.nestedContainer(keyedBy: CoordinateKeys.self, forKey: .coordinate)
        try coordinateContainer.encode(coordinate.latitude, forKey: .latitude)
        try coordinateContainer.encode(coordinate.longitude, forKey: .longitude)
    }
}
