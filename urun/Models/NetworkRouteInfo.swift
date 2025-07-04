//
//  NetworkRouteInfo.swift
//  CyclingLiveTracker
//
//  Created by Edison Wei on 2025-03-31.
//

import SwiftUI
import MapKit

struct NetworkRouteInfo: Codable {
    let gpx: [NetworkCoordinate]?
    let markerCoordinates: [MarkerComment]
    let distance: Double?
    let start_date: Date?
    let start_time: String?
    let end_time: String?
    
    enum CodingKeys: String, CodingKey{
        case gpx, markerCoordinates, distance, start_date, start_time, end_time
    }
    
    init() {
        let dateFormatter = ISO8601DateFormatter()
        
        self.gpx = []
        self.markerCoordinates = []
        self.distance = Double.nan
        self.start_date = dateFormatter.date(from: "1965-09-09T07:00:00Z")
        self.start_time = "00:00"
        self.end_time = "00:00"
    }
    
    init(storedRouteInfo: RouteInfo) {
        self.distance = storedRouteInfo.distance
        self.start_date = storedRouteInfo.start_date
        self.start_time = storedRouteInfo.start_time
        self.end_time = storedRouteInfo.end_time
        let sortedGPX = storedRouteInfo.gpx.sorted()
        self.gpx = sortedGPX.map {
            NetworkCoordinate(latitude: $0.latitude, longitude: $0.longitude, elevation: $0.elevation)
        }
        self.markerCoordinates = storedRouteInfo.markers.map {
            MarkerComment(id: $0.id!, coordinate: CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude), message: $0.message!)
        }
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Decode and parse the date to correct format
        let dateString = try? container.decode(String.self, forKey: .start_date)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        self.start_date = dateFormatter.date(from: dateString!)
        
        // Decode distance, start_time, and end_time
        let stringDistance = try? container.decode(String.self, forKey: .distance)
        self.distance = Double(stringDistance!)
        self.start_time = try? container.decode(String.self, forKey: .start_time)
        self.end_time = try? container.decode(String.self, forKey: .end_time)
        
        // Decode a 2xn array (double array) with double values of [lat,lng]
        if let coordinatePairs = try? container.decode([[Double]].self, forKey: .gpx) {
            self.gpx = coordinatePairs.map { NetworkCoordinate(latitude: $0[1], longitude: $0[0], elevation: $0[2]) }
        } else {
            self.gpx = []
        }
        
        // Decode an array of Markers and there messages
        if let markers = try? container.decode([MarkerComment].self, forKey: .markerCoordinates) {
            
            // Map to MarkerComment
            self.markerCoordinates = markers.map { MarkerComment(coordinate: $0.coordinate, message: $0.message)}
        } else {
            self.markerCoordinates = []
        }
    }
    
    func isEmpty() -> Bool {
        return (self.gpx?.isEmpty == true)
    }
}

struct decodeMarkerComment: Decodable {
    let message: String
    let coordinate: [Double]
    
    enum CodingKeys: CodingKey {
        case message
        case coordinate
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.message = try container.decode(String.self, forKey: .message)
        self.coordinate = try container.decode([Double].self, forKey: .coordinate)
    }
}


