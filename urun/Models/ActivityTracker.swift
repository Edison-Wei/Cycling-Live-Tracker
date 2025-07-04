//
//  ActivityTracker.swift
//  CyclingLiveTracker
//
//  Created by Edison Wei on 2025-04-25.
//

import SwiftUI
import MapKit

class ActivityTracker: ObservableObject {
    @Published var isTrackerOn: Bool = false
    @Published var isPaused: Bool = false
    
    @Published var startTime: Date?
    @Published var endTime: Date?
    @Published var timeElapsed: TimeInterval = 0
    @Published var distanceTravelled: Double = 0.0
    @Published var totalElevation: Double = 0.0
    private var prevCoordinate: NetworkCoordinate? = nil
    
    private var timer: Timer?
    private var lastPauseTime: Date?
    
    func startTracking() {
        isTrackerOn = true
        startTime = Date()
        endTime = nil
        lastPauseTime = nil
        
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true ) { [weak self] _ in
            guard let self = self else { return }
            if !self.isPaused,
               let startTime = self.startTime {
                self.timeElapsed = Date().timeIntervalSince(startTime)
            }
        }
    }
    
    func pauseTracking() {
        isPaused = true
        lastPauseTime = Date.now
        timer?.invalidate()
    }
    
    func resumeTracking() {
        isPaused = false
        
        if let lastPauseTime = lastPauseTime {
            if let startTime = startTime {
                self.startTime = startTime + (Date().timeIntervalSince(lastPauseTime))
            }
            self.lastPauseTime = nil
        }
        
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true ) { [weak self] _ in
            guard let self = self else { return }
            if !self.isPaused,
               let startTime = self.startTime {
                self.timeElapsed = Date().timeIntervalSince(startTime)
            }
        }
    }
    
    func finishTracking() {
        endTime = Date.now
        timer?.invalidate()
        // Set pause incase of accidental finish
        isPaused = true
        lastPauseTime = Date.now
    }
    
    func calculateDistance(_ newCoordinate: NetworkCoordinate) {
        guard prevCoordinate != nil
        else {
            let lng = newCoordinate.longitude * (Double.pi / 180.0);
            let lat = newCoordinate.latitude * (Double.pi / 180.0);
            prevCoordinate = NetworkCoordinate(latitude: lat, longitude: lng, elevation: newCoordinate.elevation)
            return }
        // Calculate Elevation gain/loss point to point
        totalElevation = totalElevation + (newCoordinate.elevation - prevCoordinate!.elevation);

        // To calculate totalDistance from previous point to current point
        let lng2 = newCoordinate.longitude * (Double.pi / 180.0);
        let lat2 = newCoordinate.latitude * (Double.pi / 180.0);

        let x = (lng2 - prevCoordinate!.longitude) * cos((prevCoordinate!.latitude + lat2) / 2);
        let y = lat2 - prevCoordinate!.latitude;
        distanceTravelled = distanceTravelled + sqrt(x * x + y * y) * 6371.0;
        
        prevCoordinate?.newCoordinate(lat2, lng2, newCoordinate.elevation)
    }
    
    
    func formatTimeInterval(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = Int(interval) % 3600 / 60
        let seconds = Int(interval) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    func formatDistance(_ distance: Double) -> String {
//        let kilometers = distance / 1000.0
        return String(format: "%.2f km", distance)
        
    }
}
