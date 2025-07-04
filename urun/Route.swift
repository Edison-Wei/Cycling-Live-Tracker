//
//  Route.swift
//  CyclingLiveTracker
//
//  Created by Edison Wei on 2025-03-09.
//

import MapKit
import SwiftUI

class Route {
    private var routeInfo: NetworkRouteInfo = NetworkRouteInfo()
    private var routeDetail: RouteDetail = RouteDetail()
    
    init() {
    }
    
    init(routeInfo: NetworkRouteInfo) {
        self.routeInfo = routeInfo
        if routeInfo.isEmpty() {
            return
        }
        self.routeDetail = calculateGeojson(GeoJSON: routeInfo.gpx!)
    }
    
    func getCLLocationCoordinates2D() -> [CLLocationCoordinate2D] {
        return routeInfo.gpx?.map { point in
            return CLLocationCoordinate2D(latitude: point.latitude, longitude: point.longitude) } ?? []
    }
 
    /**
     * Refactored code from sfu_cycling to comform to swift types
     * Calculates the given GeoJSON object with type "LineString" on Distance (in km), Center of start and end point, and Zoom (to fit the route)
     *
     * @param GeoJSON A JSON object to contain information in GeoJSON format
     * @returns an object containing { "totalDistance": distance, "latitude": lat1, "longitude": lng1, "zoom": zoom }
     * @returns null for all errors
     */
    func calculateGeojson(GeoJSON: [NetworkCoordinate]) -> RouteDetail {
        var points = [
            "right": GeoJSON[0].longitude,
            "left": GeoJSON[0].longitude,
            "top": GeoJSON[0].latitude,
            "bottom": GeoJSON[0].latitude
        ]
        let Radius: Double = 6371; // Radius of Earth in km
        let screenHeight = 2556.0
        let screenWidth = 1179.0

        var elevationGain: Double = 0.0;
        var elevationDecline: Double = 0.0;
        var totalDistance: Double = 0.0 // in km
        var zoomDistance: Double = 13 // 0 space - 11 cities

        var lng1: Double = GeoJSON[0].longitude * (Double.pi / 180);
        var lat1: Double = GeoJSON[0].latitude * (Double.pi / 180);
        var prevElev: Double = GeoJSON[0].elevation;

        for coordinate:NetworkCoordinate in GeoJSON {

            // Check RightLngCoords
            if (points["right"]! < coordinate.longitude) {
                points["right"] = coordinate.longitude
            }
            // Check LeftLngCoords
            if (points["left"]! > coordinate.longitude) {
                points["left"] = coordinate.longitude;
            }
            // Check TopLatCoords
            if (points["top"]! < coordinate.latitude) {
                points["top"] = coordinate.latitude;
            }
            // Check BottomLatCoords
            if (points["bottom"]! > coordinate.latitude) {
                points["bottom"] = coordinate.latitude;
            }

            // Calculate Elevation gain/loss point to point
            let elev = coordinate.elevation - prevElev;
            if elev > 0 {
                elevationGain += elev
            }
            else {
                elevationDecline += elev
            }
            prevElev = coordinate.elevation;

            // Used to calculate totalDistance from previous point to current point
            let lng2 = coordinate.longitude * (Double.pi / 180);
            let lat2 = coordinate.latitude * (Double.pi / 180);

            let x = (lng2 - lng1) * cos((lat1 + lat2) / 2)
            let y = lat2 - lat1;
            totalDistance = totalDistance + sqrt(x * x + y * y) * Radius;
            lng1 = lng2;
            lat1 = lat2;
        }
        
        totalDistance = round(totalDistance * 100) / 100;
        
        // Calculate the center of pointOne and pointTwo
        var lat = (points["top"]! + points["bottom"]!) / 2;
        let lng = (points["right"]! + points["left"]!) / 2;
        let latInRadians = lat * Double.pi / 180

        // Calculate zoom distance (in metres)
        var deltaLat = points["top"]! - points["bottom"]!
        var deltaLng = points["left"]! - points["right"]!
        if deltaLat < 0 {
            deltaLat *= -1
        }
        if deltaLng < 0 {
            deltaLng *= -1
        }
        
        let zoomWidth = log2((screenWidth * 360.0) / (deltaLng * 256.0))
        let zoomHeight = log2((screenHeight * 360.0 * cos(latInRadians)) / (deltaLat * 256.0))
        let z: Double = floor(min(zoomWidth, zoomHeight))
        
        zoomDistance = ((40075017.0 * cos(latInRadians)) / (pow(2, z) * 256)) * 4000.0
        
        lat = lat - 0.0025

        return RouteDetail(totalDistance: totalDistance,
                           latitude: lat,
                           longitude: lng,
                           zoom: zoomDistance,
                           elevationGain: elevationGain,
                           elevationDecline: elevationDecline)
    }
    
    func getRouteDetail() -> RouteDetail {
        return routeDetail
    }
    
    func getRouteInfo() -> NetworkRouteInfo {
        return routeInfo
    }
    func getMarkerComments() -> [MarkerComment] {
        return routeInfo.markerCoordinates
    }
    
    func getDistance() -> Double {
        return routeDetail.totalDistance
    }
    func getElevationGain() -> Double {
        return routeDetail.elevationGain
    }
    func getElevationDecline() -> Double {
        return routeDetail.elevationDecline
    }
    func getCameraCenterPosition() -> MapCamera  {
        return MapCamera(centerCoordinate: routeDetail.getCenterCoordinates(), distance: routeDetail.zoom)
    }
    
    func getDate() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM dd, yyyy"
        
        return ("\(dateFormatter.string(from: routeInfo.start_date!))")
    }
    
    func getTime() -> String {
        return ("\(routeInfo.start_time!.prefix(5)) - \(routeInfo.end_time!.prefix(5))")
    }
    
    func isRouteReceived() -> Bool {
        return !routeInfo.isEmpty()
    }
    
    func formatDistance() -> String {
        return String(format: "%.2f km", routeDetail.totalDistance)
    }
}
