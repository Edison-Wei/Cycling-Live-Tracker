//
//  DrawerMenu.swift
//  CyclingLiveTracker
//
//  Created by Edison Wei on 2025-04-24.
//

import Foundation

struct DrawerMenu: View {
    @EnvironmentObject var activityTracker: ActivityTracker
    
    var body: some View {
        VStack {
            RoundedRectangle(cornerRadius: 5)
                .frame(width: 50, height: 6)
                .foregroundColor(.gray)
                .padding(.vertical)
            

            VStack(spacing: 20) {
                Toggle(isOn: $activityTracker.isTracking) {
                    Text("Track Activity")
                }
                .onChange(of: activityTracker.isTracking) { isTracking in
                    if isTracking {
                        activityTracker.startTracking()
                    } else {
                        activityTracker.finishTracking()
                    }
                }
                .padding(.horizontal)
                
                if activityTracker.isTracking {
                    // Currently Tracking View
                    VStack(spacing: 10) {
                        HStack {
                            VStack {
                                Text("Time Elapsed")
                                    .font(.caption)
                                Text(activityTracker.formatTimeInterval(activityTracker.timeElapsed))
                                    .font(.title2)
                                    .monospacedDigit() // Keep digits aligned as time changes
                            }
                            Spacer()
                            VStack {
                                Text("Distance")
                                    .font(.caption)
                                Text(activityTracker.formatDistance(activityTracker.distanceTravelled))
                                    .font(.title2)
                                    .monospacedDigit() // Keep digits aligned
                            }
                        }
                        .padding(.horizontal)
                        
                        HStack {
                            Button {
                                activityTracker.finishTracking()
                            } label: {
                                Label("Finish", systemImage: "stop.circle")
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.red)
                            
                            Spacer()
                            
                            if activityTracker.isPaused {
                                Button {
                                    activityTracker.resumeTracking()
                                } label: {
                                    Label("Resume", systemImage: "play.circle")
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.green)
                            } else {
                                Button {
                                    activityTracker.pauseTracking()
                                } label: {
                                    Label("Pause", systemImage: "pause.circle")
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.orange)
                            }
                        }
                        .padding(.horizontal)
                    }
                } else {
                    // Pre-Tracking/Summary View
                    VStack(spacing: 10) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Start Date:")
                                    .font(.caption)
                                Text(activityTracker.startTime, style: .date)
                            }
                            Spacer()
                            VStack(alignment: .leading) {
                                Text("Time:")
                                    .font(.caption)
                                HStack {
                                    Text(activityTracker.startTime, style: .time)
                                    Text("-")
                                    Text(activityTracker.endTime, style: .time)
                                }
                            }
                        }
                        
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Total Distance:")
                                    .font(.caption)
                                Text(activityTracker.formatDistance(activityTracker.distanceTravelled))
                            }
                            Spacer()
                            VStack(alignment: .leading) {
                                Text("Total Elevation:")
                                    .font(.caption)
                                // Placeholder for elevation (requires more advanced tracking)
                                Text("N/A")
                            }
                        }
                        
                        Button {
                            activityTracker.startTracking()
                        } label: {
                            Label("Start Activity", systemImage: "play.circle.fill")
                                .font(.title2)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.blue)
                    }
                    .padding(.horizontal) // Add padding to the content
                }
                
                Spacer() // Push content to the top of the drawer
            }
            .frame(maxWidth: .infinity, alignment: .center) // Center the content horizontally
            .padding(.bottom, 50) // Add some bottom padding
        }
        .background(.regularMaterial) // Add a translucent background
        .cornerRadius(20) // Rounded corners for the drawer
    }
}
