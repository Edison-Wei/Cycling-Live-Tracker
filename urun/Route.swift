//
//  Route.swift
//  CyclingLiveTracker
//
//  Created by Edison Wei on 2025-03-09.
//

import MapKit

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
            "right": GeoJSON[0].latitude,
            "left": GeoJSON[0].latitude,
            "top": GeoJSON[0].longitude,
            "bottom": GeoJSON[0].longitude
        ]
        let Radius: Double = 6371; // Radius of Earth in km

        var totalElevation: Double = 0.0;
        var totalDistance: Double = 0.0 // in km
        var zoom: Double = 13 // 0 space - 11 cities

        var lng1: Double
        var lat1: Double
        var prevElev: Double;

        lng1 = GeoJSON[0].longitude * (Double.pi / 180);
        lat1 = GeoJSON[0].latitude * (Double.pi / 180);
        prevElev = GeoJSON[0].elevation;

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
            totalElevation += coordinate.elevation - prevElev;
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

        // Calculate zoom distance (in metres)
        zoom = zoom * 10000


        // Calculate the center of pointOne and pointTwo
        let lat = (points["top"]! + points["bottom"]!) / 2;
        let lng = (points["right"]! + points["left"]!) / 2;

        return RouteDetail(totalDistance: totalDistance, latitude: lat, longitude: lng, zoom: zoom, elevation: totalElevation)
    }
    
    func getRouteDetail() -> RouteDetail {
        return routeDetail
    }
    
    func getDistance() -> Double {
        return routeDetail.totalDistance
    }
    func getElevation() -> Double {
        return routeDetail.elevation
    }
    func getDate() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM dd, yyyy"
        
        return ("Ride Date: \(dateFormatter.string(from: routeInfo.start_date!))")
    }
    func getTime() -> String {
        return ("\(routeInfo.start_time!) - \(routeInfo.end_time!)")
    }
}
