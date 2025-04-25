//
//  RouteDetail.swift
//  CyclingLiveTracker
//
//  Created by Edison Wei on 2025-03-21.
//

struct RouteDetail {
    let totalDistance: Double   // Distance of route in km
    let latitude: Double        // The center latitude position of a route
    let longitude: Double       // The center longitude position of a route
    let zoom: Double            // Zoom distance from 0m - 1000000m
    let elevation: Double       // Elevation
    
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
    
    func isEmpty() -> Bool {
        return latitude == Double.nan && longitude == Double.nan
    }
}
