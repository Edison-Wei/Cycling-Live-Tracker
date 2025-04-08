//
//  MarkerComment.swift
//  CyclingLiveTracker
//
//  Created by Edison Wei on 2025-03-21.
//


import MapKit

struct MarkerComment: Identifiable, Encodable {
    var id: UUID = UUID()
    let coordinate: CLLocationCoordinate2D
    let comment: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case coordinate
        case comment
    }
    
    enum CoordinateKeys: String, CodingKey {
        case latitude
        case longitude
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(comment, forKey: .comment)
        
        var coordinateContainer = container.nestedContainer(keyedBy: CoordinateKeys.self, forKey: .coordinate)
        try coordinateContainer.encode(coordinate.latitude, forKey: .latitude)
        try coordinateContainer.encode(coordinate.longitude, forKey: .longitude)
    }
}
