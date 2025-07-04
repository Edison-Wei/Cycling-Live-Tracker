//
//  NetworkCoordinate.swift
//  CyclingLiveTracker
//
//  Created by Edison Wei on 2025-03-31.
//

struct NetworkCoordinate: Codable {
    var latitude: Double
    var longitude: Double
    var elevation: Double
    
    enum CodingKeys: String, CodingKey{
        case latitude
        case longitude
        case elevation
    }
    
    init(latitude: Double, longitude: Double, elevation: Double) {
        self.latitude = latitude
        self.longitude = longitude
        self.elevation = elevation
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.latitude = try! container.decode(Double.self, forKey: .latitude)
        self.longitude = try! container.decode(Double.self, forKey: .longitude)
        self.elevation = try! container.decode(Double.self, forKey: .elevation)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(latitude, forKey: .latitude)
        try container.encode(longitude, forKey: .longitude)
        try container.encode(elevation, forKey: .elevation)
    }
    
    public mutating func newCoordinate(_ latitude: Double, _ longitude: Double, _ elevation: Double) {
        self.latitude = latitude
        self.longitude = longitude
        self.elevation = elevation
    }
}
