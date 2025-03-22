//
//  Route.swift
//  CyclingLiveTracker
//
//  Created by Edison Wei on 2025-03-09.
//

import MapKit

class Route {
    private var routeInfo: RouteInfo = RouteInfo()
    private var routeDetail: RouteDetail = RouteDetail()
    
    init() {
        // Do something or handle or nothing
    }
    
    init(routeInfo: RouteInfo) {
        self.routeInfo = routeInfo
        // Check routeInfo if:
        //      1. URL Connection failed
        //      2. Data request failed
        if routeInfo.isEmpty() {
            return
        }
        self.routeDetail = calculateGeojson(GeoJSON: routeInfo.gpx!)
    }
    
    func getCLLocationCoordinates2D() -> [CLLocationCoordinate2D] {
//        let newCoord2D = routeInfo.gpx.map{ (point: Coordinates) -> CLLocationCoordinate2D in
//            return CLLocationCoordinate2D(latitude: point.lat, longitude: point.lon)
//        }
//        return newCoord2D
//        return routeInfo.gpx.map{ point in
//            return CLLocationCoordinate2D(latitude: point.lat, longitude: point.lon)
//        }
        return routeInfo.gpx?.map { point in
            return CLLocationCoordinate2D(latitude: point.lat, longitude: point.lon) } ?? []
    }
 
    /**
     * Refactored code from sfu_cycling to comform to swift types
     * Calculates the given GeoJSON object with type "LineString" on Distance (in km), Center of start and end point, and Zoom (to fit the route)
     *
     * @param GeoJSON A JSON object to contain information in GeoJSON format
     * @returns an object containing { "totalDistance": distance, "latitude": lat1, "longitude": lng1, "zoom": zoom }
     * @returns null for all errors
     */
    func calculateGeojson(GeoJSON: [Coordinates]) -> RouteDetail {
        var points = [
            "right": GeoJSON[0].lat,
            "left": GeoJSON[0].lat,
            "top": GeoJSON[0].lon,
            "bottom": GeoJSON[0].lon
        ]
        let Radius: Double = 6371; // Radius of Earth in km

        var totalElevation: Double = 0.0;
        var totalDistance: Double = 0.0 // in km
        var zoom: Double = 13 // 0 space - 11 cities

        var lng1: Double
        var lat1: Double
        var prevElev: Double;

        lng1 = GeoJSON[0].lon * (Double.pi / 180);
        lat1 = GeoJSON[0].lat * (Double.pi / 180);
        prevElev = GeoJSON[0].elv;

        for coordinate:Coordinates in GeoJSON {

            // Check RightLngCoords
            if (points["right"]! < coordinate.lon) {
                points["right"] = coordinate.lon
            }
            // Check LeftLngCoords
            if (points["left"]! > coordinate.lon) {
                points["left"] = coordinate.lon;
            }
            // Check TopLatCoords
            if (points["top"]! < coordinate.lat) {
                points["top"] = coordinate.lat;
            }
            // Check BottomLatCoords
            if (points["bottom"]! > coordinate.lat) {
                points["bottom"] = coordinate.lat;
            }

            // Calculate Elevation gain/loss point to point
            totalElevation += coordinate.elv - prevElev;
            prevElev = coordinate.elv;

            // Used to calculate totalDistance from previous point to current point
            let lng2 = coordinate.lon * (Double.pi / 180);
            let lat2 = coordinate.lat * (Double.pi / 180);

            let x = (lng2 - lng1) * cos((lat1 + lat2) / 2)
            let y = lat2 - lat1;
            totalDistance = totalDistance + sqrt(x * x + y * y) * Radius;
            lng1 = lng2;
            lat1 = lat2;
        }
        
        totalDistance = round(totalDistance * 100) / 100;

        // Calculate zoom distance (in metres)
        zoom = zoom - log10(totalDistance);


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
        let startDate = Date(timeIntervalSince1970: routeInfo.start_date!)
        guard let startTime = routeInfo.start_time?.stringFromTimeInterval() else { return "00:00:00"}
        guard let endTime = routeInfo.end_time?.stringFromTimeInterval() else { return "00:00:00" }
        
        return ("Ride Date: \(startDate): \(startTime) - \(endTime)")
    }
}

extension TimeInterval{

        func stringFromTimeInterval() -> String {

            let time = NSInteger(self)

            let seconds = time % 60
            let minutes = (time / 60) % 60
            let hours = (time / 3600)

            return String(format: "%0.2d:%0.2d:%0.2d",hours,minutes,seconds)
        }
}
