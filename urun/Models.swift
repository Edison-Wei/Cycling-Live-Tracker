//
//  Models.swift
//  CyclingLiveTracker
//
//  Created by Edison Wei on 2025-03-21.
//

import Foundation
import MapKit

struct MarkerComment: Identifiable, Encodable {
    var id: UUID = UUID()
    let coordinate: CLLocationCoordinate2D
    let comment: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case latitude
        case longitude
        case comment
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(coordinate.latitude, forKey: .latitude)
        try container.encode(coordinate.longitude, forKey: .longitude)
        try container.encode(comment, forKey: .comment)
    }
}


struct Coordinates: Codable {
    let lat: Double
    let lon: Double
    let elv: Double
}

struct coordinateEncoder: Encodable {
    let coordinates: [Coordinates]
    let markerCoordinates: [MarkerComment]
}


struct RouteInfo: Codable {
    
    let gpx: [Coordinates]?
    let distance: Double?
    let start_date: TimeInterval?
    let start_time: TimeInterval?
    let end_time: TimeInterval?
    
    init() {
        self.gpx = []
        self.distance = Double.nan
        self.start_date = nil
        self.start_time = nil
        self.end_time = nil
    }
    
    init(gpx: [Coordinates], distance: Double, start_date: TimeInterval, start_time: TimeInterval, end_time: TimeInterval) {
        self.gpx = gpx
        self.distance = distance
        self.start_date = start_date
        self.start_time = start_time
        self.end_time = end_time
    }
    
    func isEmpty() -> Bool {
        return (self.gpx?.isEmpty == true)
    }
    
}

struct RouteDetail {
    let totalDistance: Double
    let latitude: Double
    let longitude: Double
    let zoom: Double
    let elevation: Double
    
    init() {
        self.totalDistance = Double.nan
        self.latitude = Double.nan
        self.longitude = Double.nan
        self.zoom = Double.nan
        self.elevation = Double.nan
    }
    
    init(totalDistance: Double, latitude: Double, longitude: Double, zoom: Double, elevation: Double) {
        self.totalDistance = totalDistance
        self.latitude = latitude
        self.longitude = longitude
        self.zoom = zoom
        self.elevation = elevation
    }
}

//struct Route: Codable {
//    let gpx: [Coordinates]
//    let distance: Double
//    "totalDistance": totalDistance,
//    "latitude": lat,
//    "longitude": lng,
//    "zoom": zoom,
//    "elevation": totalElevation
//    let start_date: String
//    let start_time: String
//    let end_time: String
//}

//struct RouteInfo: Codable {
//    let rid: Int
//    let title: String
//    let description: String
//    let gpx: String
//    let difficulty: String
//    let distance: Float
//    let start_date: Date
//    let start_time: TimeInterval
//    let end_time: TimeInterval
//    let date_created: Date
//}
