//
//  CoordinateEncoder.swift
//  CyclingLiveTracker
//
//  Created by Edison Wei on 2025-03-21.
//
import Foundation

struct RouteEncoder: Encodable {
    let coordinates: [NetworkCoordinate]
    let markerCoordinates: [MarkerComment]
    let elapsedTime: String
    
    enum CodingKeys: String, CodingKey {
        case coordinates
        case marker_Coordinates
        case elapsed_Time
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(coordinates, forKey: .coordinates)
        try container.encode(markerCoordinates, forKey: .marker_Coordinates)
        try container.encode(elapsedTime, forKey: .elapsed_Time)
    }
}
