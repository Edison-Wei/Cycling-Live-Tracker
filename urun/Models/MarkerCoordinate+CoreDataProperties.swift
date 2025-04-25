//
//  MarkerCoordinate+CoreDataProperties.swift
//  CyclingLiveTracker
//
//  Created by Edison Wei on 2025-04-24.
//
//

import Foundation
import CoreData


extension MarkerCoordinate {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<MarkerCoordinate> {
        return NSFetchRequest<MarkerCoordinate>(entityName: "MarkerCoordinate")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var latitude: Double
    @NSManaged public var longitude: Double
    @NSManaged public var message: String?
    @NSManaged public var routeInfo: RouteInfo?

}
