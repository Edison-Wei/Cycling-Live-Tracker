//
//  CoordinateEncoder.swift
//  CyclingLiveTracker
//
//  Created by Edison Wei on 2025-03-21.
//

struct CoordinateEncoder: Encodable {
    let coordinates: [NetworkCoordinate]
    let markerCoordinates: [MarkerComment]
    
    enum CodingKeys: String, CodingKey {
        case coordinates
        case markerCoordinates
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(coordinates, forKey: .coordinates)
        try container.encode(markerCoordinates, forKey: .markerCoordinates)
    }
}
