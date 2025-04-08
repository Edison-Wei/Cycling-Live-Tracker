//
//  Coordinate+CoreDataProperties.swift
//  CyclingLiveTracker
//
//  Created by Edison Wei on 2025-04-07.
//
//

import Foundation
import CoreData


extension Coordinate {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Coordinate> {
        return NSFetchRequest<Coordinate>(entityName: "Coordinate")
    }

    @NSManaged public var latitude: Double
    @NSManaged public var longitude: Double
    @NSManaged public var elevation: Double
    @NSManaged public var id: Int16
    @NSManaged public var routeInfo: RouteInfo?

}

extension Coordinate : Identifiable {

}

extension Coordinate: Comparable {
    public static func < (lhs: Coordinate, rhs: Coordinate) -> Bool {
        return lhs.id < rhs.id
    }
}
