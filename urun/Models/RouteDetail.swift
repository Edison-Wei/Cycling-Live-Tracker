//
//  RouteDetail.swift
//  CyclingLiveTracker
//
//  Created by Edison Wei on 2025-03-21.
//

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
