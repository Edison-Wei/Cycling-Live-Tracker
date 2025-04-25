//
//  RouteInfo+CoreDataProperties.swift
//  CyclingLiveTracker
//
//  Created by Edison Wei on 2025-04-23.
//
//

import Foundation
import CoreData


extension RouteInfo {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<RouteInfo> {
        return NSFetchRequest<RouteInfo>(entityName: "RouteInfo")
    }

    @NSManaged public var distance: Double
    @NSManaged public var end_time: String?
    @NSManaged public var start_date: Date?
    @NSManaged public var start_time: String?
    @NSManaged public var gpx: Set<Coordinate>
    @NSManaged public var markers: Set<MarkerCoordinate>

}

// MARK: Generated accessors for gpx
extension RouteInfo {

    @objc(addGpxObject:)
    @NSManaged public func addToGpx(_ value: Coordinate)

    @objc(removeGpxObject:)
    @NSManaged public func removeFromGpx(_ value: Coordinate)

    @objc(addGpx:)
    @NSManaged public func addToGpx(_ values: NSSet)

    @objc(removeGpx:)
    @NSManaged public func removeFromGpx(_ values: NSSet)

}

// MARK: Generated accessors for markers
extension RouteInfo {

    @objc(addMarkersObject:)
    @NSManaged public func addToMarkers(_ value: MarkerCoordinate)

    @objc(removeMarkersObject:)
    @NSManaged public func removeFromMarkers(_ value: MarkerCoordinate)

    @objc(addMarkers:)
    @NSManaged public func addToMarkers(_ values: NSSet)

    @objc(removeMarkers:)
    @NSManaged public func removeFromMarkers(_ values: NSSet)

}
