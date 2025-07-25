//
//  DeviceLocationService.swift
//  CyclingLiveTracker
//
//  Created by Edison Wei on 2025-02-19.
//

import Combine
import CoreLocation

class DeviceLocationService: NSObject, CLLocationManagerDelegate, ObservableObject {
    
    var coordinatesPublisher = PassthroughSubject<SendableCoordinates, Error>()
    var deniedLocationAccessPublisher = PassthroughSubject<Void, Never>()
    var backgroundServices = CLBackgroundActivitySession()
    
    private override init() {
        super.init()
    }
    
    static let shared = DeviceLocationService()
    
    private lazy var locationManager: CLLocationManager = {
        let manager = CLLocationManager()
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.delegate = self
        manager.allowsBackgroundLocationUpdates = true
        return manager
    } ()
    
    func requestLocationServices(_ trackerOn: Bool) {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            if trackerOn {
                locationManager.startUpdatingLocation()
            }
            else {
                locationManager.stopUpdatingLocation()
            }
        default:
            deniedLocationAccessPublisher.send()
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.startUpdatingLocation()
        default:
            manager.stopUpdatingLocation()
            deniedLocationAccessPublisher.send()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        coordinatesPublisher.send(SendableCoordinates(coordinate: location.coordinate, altitude: location.altitude))
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        coordinatesPublisher.send(completion: .failure(error))
    }
    
}

struct SendableCoordinates {
    let coordinate: CLLocationCoordinate2D
    let altitude: Double
    
    init(coordinate: CLLocationCoordinate2D, altitude: Double) {
        self.coordinate = coordinate
        self.altitude = altitude
    }
    
    init() {
        coordinate = CLLocationCoordinate2D()
        altitude = 0.0
    }
}
