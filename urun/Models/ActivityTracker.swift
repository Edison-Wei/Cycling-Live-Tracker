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
    
    private var timer: Timer?
    private var lastPauseTime: Date?
    private var lastLocation : CLLocation?
    
    func startTracking() {
        isTrackerOn = true
        startTime = Date()
        endTime = nil
        lastPauseTime = nil
        lastLocation = nil
        
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
    
    
    func formatTimeInterval(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = Int(interval) % 3600 / 60
        let seconds = Int(interval) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    func formatDistance(_ distance: Double) -> String {
        let kilometers = distance / 1000.0
        return String(format: "%.2f km", kilometers)
    }
}
