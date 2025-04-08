//
//  RouteDataModel.swift
//  CyclingLiveTracker
//
//  Created by Edison Wei on 2025-03-28.
//

import CoreData

let entityName = "RouteInfo"


class DataController: ObservableObject {
    let persistentContainer: NSPersistentContainer

    init() {
        persistentContainer = NSPersistentContainer(name: "RouteModel")
        persistentContainer.loadPersistentStores { (description, error) in
            if let error = error {
                fatalError("Failed to load Core Data: \(error.localizedDescription)")
            }
        }
    }
    
    // Check if RouteInfo data exists and the start_date in Core Data
    func checkStoredRouteDate() -> Bool {
        let todayDate = Date.now
        let context = persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<RouteInfo> = RouteInfo.fetchRequest()
        fetchRequest.fetchLimit = 1
        
        do {
            let storedRoute = try context.fetch(fetchRequest)
            if storedRoute.isEmpty {
                return false
            }
            let ifRouteShouldBeFetched = todayDate <= (storedRoute.first?.start_date)!
            return ifRouteShouldBeFetched
        }
        catch {
            print("Error fetching route data: \(error)")
            return false
        }
    }

    // Store RouteInfo in Core Data
    public func storeRouteInfo(routeInfo: NetworkRouteInfo) {
        let context = persistentContainer.viewContext

        // Delete existing data before storing new data
        deleteAllRouteInfo()

        let routeInfoEntity = RouteInfo(context: context)
        
        routeInfoEntity.distance = routeInfo.distance ?? 0.0
        routeInfoEntity.start_date = routeInfo.start_date
        routeInfoEntity.start_time = routeInfo.start_time
        routeInfoEntity.end_time = routeInfo.end_time
        
        var coordID: Int16 = 0
        for coordinatePoint in routeInfo.gpx! {
            let coordinateEntity = Coordinate(context: context)
            coordinateEntity.id = coordID
            coordinateEntity.latitude = coordinatePoint.latitude
            coordinateEntity.longitude = coordinatePoint.longitude
            coordinateEntity.elevation = coordinatePoint.elevation
            routeInfoEntity.addToGpx(coordinateEntity)
            coordID += 1
        }
        

        do {
            try context.save()
            print("RouteInfo has been successfully stored in Core Data.")
        } catch {
            print("Error saving context: \(error)")
        }
    }

    // Fetch RouteInfo from Core Data
    func fetchLocalRouteInfo() -> NetworkRouteInfo? {
        let context = persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<RouteInfo>(entityName: entityName)

        do {
            if let storedRouteInfo = try context.fetch(fetchRequest).first {
                let routeInfo = NetworkRouteInfo(storedRouteInfo: storedRouteInfo)

                return routeInfo
            }
        } catch {
            print("Failed to fetch RouteInfo from Core Data: \(error)")
        }
        return nil
    }

    // Delete all RouteInfo data from Core Data
    public func deleteAllRouteInfo() {
        let context = persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

        do {
            try persistentContainer.persistentStoreCoordinator.execute(batchDeleteRequest, with: context)
            try context.save()
        } catch {
            print("Error deleting RouteInfo data: \(error)")
        }
    }
}
