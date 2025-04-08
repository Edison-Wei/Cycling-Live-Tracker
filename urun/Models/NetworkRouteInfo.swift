//
//  NetworkRouteInfo.swift
//  CyclingLiveTracker
//
//  Created by Edison Wei on 2025-03-31.
//

import SwiftUI

struct NetworkRouteInfo: Codable {
    let gpx: [NetworkCoordinate]?
    let distance: Double?
    let start_date: Date?
    let start_time: String?
    let end_time: String?
    
    enum CodingKeys: String, CodingKey{
        case gpx, distance, start_date, start_time, end_time
    }
    
    init() {
        let dateFormatter = ISO8601DateFormatter()
        
        self.gpx = []
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
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Decode and parse the date properly
        let dateString = try? container.decode(String.self, forKey: .start_date)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        self.start_date = dateFormatter.date(from: dateString!)
        
        // Decode distance, start_time, and end_time normally
        let stringDistance = try? container.decode(String.self, forKey: .distance)
        self.distance = Double(stringDistance!)
        self.start_time = try? container.decode(String.self, forKey: .start_time)
        self.end_time = try? container.decode(String.self, forKey: .end_time)

        // Decode `gpx` as a string then parse it as a JSON array
        if let gpxString = try? container.decode(String.self, forKey: .gpx),
           let gpxData = gpxString.data(using: .utf8),
           let pairs = try? JSONDecoder().decode([[Double]].self, from: gpxData) {
            
            // Map to Coordinates struct with `elv` defaulting to 0.0
            self.gpx = pairs.map { NetworkCoordinate(latitude: $0[1], longitude: $0[0], elevation: $0[2]) }
        } else {
            self.gpx = []
        }
    }
    
    func isEmpty() -> Bool {
        return (self.gpx?.isEmpty == true)
    }
}
