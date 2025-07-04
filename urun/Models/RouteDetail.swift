//
//  RouteDetail.swift
//  CyclingLiveTracker
//
//  Created by Edison Wei on 2025-03-21.
//
import CoreLocation

struct RouteDetail {
    let totalDistance: Double   // Distance of route in km
    let latitude: Double        // The center latitude position of a route
    let longitude: Double       // The center longitude position of a route
    let zoom: Double            // Zoom distance from 0m - 1000000m
    let elevationGain: Double       // Elevation gain
    let elevationDecline: Double       // Elevation decline
    
    init() {
        self.totalDistance = Double.nan
        self.latitude = Double.nan
        self.longitude = Double.nan
        self.zoom = Double.nan
        self.elevationGain = Double.nan
        self.elevationDecline = Double.nan
    }
    
    init(totalDistance: Double, latitude: Double, longitude: Double, zoom: Double, elevationGain: Double, elevationDecline: Double) {
        self.totalDistance = totalDistance
        self.latitude = latitude
        self.longitude = longitude
        self.zoom = zoom
        self.elevationGain = elevationGain
        self.elevationDecline = elevationDecline
    }
    
    func isEmpty() -> Bool {
        return latitude == Double.nan && longitude == Double.nan
    }
    
    func getCenterCoordinates() -> CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }    
}
