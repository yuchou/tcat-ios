//
//  Route.swift
//  TCAT
//
//  Description:
//      Data model to represent both route options screen (Monica) and route detail screen (Matt)
//
//  Note:
//      - routeSummary is for route options screen (Monica) and directions is for route detail screen (Matt)
//  Created by Monica Ong on 2/12/17.
//  Copyright © 2017 cuappdev. All rights reserved.
//
import UIKit
import TRON
import SwiftyJSON
import CoreLocation
import MapKit

struct Bounds {

    /// The minimum latitude value in all of the path's route.
    var minLat: Double

    /// The minimum longitude value in all of the path's route.
    var minLong: Double

    /// The maximum latitude value in all of the path's route.
    var maxLat: Double

    /// The maximum longitude value in all of the path's route.
    var maxLong: Double

    init(minLat: Double, minLong: Double, maxLat: Double, maxLong: Double) {
        self.minLat = minLat
        self.minLong = minLong
        self.maxLat = maxLat
        self.maxLong = maxLong
    }

}

struct RouteCalculationError: Swift.Error {
    let title: String
    let description: String
}

class Route: NSObject, JSONDecodable {

    /// The time a user begins their journey
    var departureTime: Date

    /// The time a user arrives at their destination.
    var arrivalTime: Date

    /// The amount of time from now until the departure
    var timeUntilDeparture: DateComponents {
        return Time.dateComponents(from: Date(), to: departureTime)
    }

    /// The starting coordinates of the route
    var startCoords: CLLocationCoordinate2D

    /// The ending coordinates of the route
    var endCoords: CLLocationCoordinate2D

    /// The distance between the start and finish location, in miles
    var travelDistance: Double = 0.0

    /// The most extreme points of the route
    var boundingBox: Bounds

    /// The number of transfers in a route. Defaults to 0
    var numberOfTransfers: Int

    /// A list of Direction objects (used for Route Detail)
    var directions: [Direction]
    
    /// Raw, untampered with directions (for RouteOptionsViewController)
    var rawDirections: [Direction]

    /** A description of the starting location of the route (e.g. Current Location, Arts Quad)
        Default assumption is Current Location.
     */
    var startName: String

    /// A description of the final destination of the route (e.g. Chipotle Mexican Grill, The Shops at Ithaca Mall)
    var endName: String

    /// The number of minutes the route will take. Returns 0 in case of error.
    var totalDuration: Int {
        return Time.dateComponents(from: departureTime, to: arrivalTime).minute ?? 0
    }

    required init(json: JSON) throws {

        // print("Route JSON", json)

        departureTime = json["departureTime"].parseDate()
        arrivalTime = json["arrivalTime"].parseDate()
        startCoords = json["startCoords"].parseCoordinates()
        endCoords = json["endCoords"].parseCoordinates()
        startName = json["startName"].stringValue
        endName = json["endName"].stringValue
        boundingBox = json["boundingBox"].parseBounds()
        numberOfTransfers = json["numberOfTransfers"].intValue
        directions = json["directions"].arrayValue.map { Direction(from: $0) }
        rawDirections = json["directions"].arrayValue.map { Direction(from: $0) }
        
        super.init()

        // Format raw directions

        let first = 0
        for (index, direction) in rawDirections.enumerated() {
            if direction.type == .walk {
                // Change walking direction name to name of location walking from
                if index == first {
                    direction.name = startName
                }
                else {
                    direction.name = rawDirections[index - 1].stops.last?.name ?? rawDirections[index - 1].name
                }
            }
        }
        
        // Append extra direction for ending location with ending destination name
        if let direction = rawDirections.last {
            // Set stayOnBusForTransfer to false b/c ending location can never have transfer
            if direction.type == .walk {
            rawDirections.append(Direction(type: .walk,
                                           name: endName,
                                           startLocation: direction.startLocation,
                                           endLocation: direction.endLocation,
                                           startTime: direction.startTime,
                                           endTime: direction.endTime,
                                           path: direction.path,
                                           travelDistance: direction.travelDistance,
                                           routeNumber: direction.routeNumber,
                                           stops: direction.stops,
                                           stayOnBusForTransfer: false,
                                           tripIdentifiers: direction.tripIdentifiers,
                                           delay: direction.delay))
            }
            else if direction.type == .depart {
                rawDirections.append(Direction(type: .arrive,
                                               name: endName,
                                               startLocation: direction.startLocation,
                                               endLocation: direction.endLocation,
                                               startTime: direction.startTime,
                                               endTime: direction.endTime,
                                               path: direction.path,
                                               travelDistance: direction.travelDistance,
                                               routeNumber: direction.routeNumber,
                                               stops: direction.stops,
                                               stayOnBusForTransfer: false,
                                               tripIdentifiers: direction.tripIdentifiers,
                                               delay: direction.delay))
            }
        }
        
        // Change all walking directions, except for first and last direction, to arrive
        let last = rawDirections.count - 1
        for (index, direction) in rawDirections.enumerated() {
            if index != last && index != first && direction.type == .walk {
                direction.type = .arrive
                direction.name = rawDirections[index - 1].endLocation.name
            }
        }
        
        calculateTravelDistance(fromRawDirections: rawDirections)
        
        // Parse and format directions
        
        // Variable to keep track of additions to direction list (Arrival Directions)
        var offset = 0

        for (index, direction) in directions.enumerated() {

            if direction.type == .depart {

                let beyondRange = index + 1 > directions.count - 1
                let isLastDepart = index == directions.count - 1
                
                if direction.stayOnBusForTransfer {
                    direction.type = .transfer
                }
                
                // If this direction doesn't have a transfer afterwards, or is depart and last
                if (!beyondRange && !directions[index+1].stayOnBusForTransfer) || isLastDepart {
                    
                    // Create Arrival Direction
                    let arriveDirection = direction.copy() as! Direction
                    arriveDirection.type = .arrive
                    arriveDirection.startTime = arriveDirection.endTime
                    arriveDirection.startLocation = arriveDirection.endLocation
                    arriveDirection.stops = []
                    arriveDirection.name = direction.stops.last?.name ?? "Nil"
                    directions.insert(arriveDirection, at: index + offset + 1)
                    offset += 1

                }

                // Remove inital bus stop and departure bus stop
                if direction.stops.count >= 2 {
                    direction.stops.removeFirst()
                    direction.stops.removeLast()
                }
            }

        }
        
    }

    // MARK: Parse JSON

    /// Handle route calculation data request.
    static func parseRoutes(in json: JSON, from: String?, to: String?,
                          _ completion: @escaping (_ routes: [Route], _ error: RouteCalculationError?) -> Void) {

        if json["success"].boolValue {
            let routes: [Route] = json["data"].arrayValue.map {
                var augmentedJSON = $0
                augmentedJSON["startName"].string = from ?? Constants.Stops.currentLocation
                augmentedJSON["endName"].string = to ?? Constants.Stops.destination
                return try! Route(json: augmentedJSON)
            }
            completion(routes, nil)
        } else {
            completion([], RouteCalculationError(title: "Route Calculation Failure", description: json["error"].stringValue))
        }

    }

    // MARK: Process routes

    func isRawWalkingRoute() -> Bool {
        return rawDirections.reduce(true) { $0 && $1.type == .walk }
    }

    func getFirstDepartRawDirection() -> Direction? {
        return rawDirections.first { $0.type == .depart }
    }

    func getLastDepartRawDirection() -> Direction? {
        return rawDirections.reversed().first { $0.type == .depart }
    }

    func getRawNumOfWalkLines() -> Int {
        var count = 0
        for (index, direction) in rawDirections.enumerated() {
            if index != rawDirections.count - 1 && direction.type == .walk {
                count += 1
            }
        }

        return count
    }

    /** Calculate travel distance from location passed in to first route summary object and updates travel distance of route
     */
    func calculateTravelDistance(fromRawDirections rawDirections: [Direction]) {

        // firstRouteOptionsStop = first bus stop in the route
        guard var stop = rawDirections.first else {
            return
        }

        // If more than just a walking route that starts with walking
        if !isRawWalkingRoute() && rawDirections.first?.type == .walk && rawDirections.count > 1 {
            stop = rawDirections[1]
        }

        let fromLocation = CLLocation(latitude: startCoords.latitude, longitude: startCoords.longitude)
        var endLocation = CLLocation(latitude: stop.startLocation.latitude, longitude: stop.startLocation.longitude)

        if isRawWalkingRoute() {
            endLocation = CLLocation(latitude: stop.endLocation.latitude, longitude: stop.endLocation.longitude)
        }

        travelDistance = fromLocation.distance(from: endLocation)

    }

    override var debugDescription: String {

        let mainDescription = """
            departtureTime: \(self.departureTime)\n
            arrivalTime: \(self.arrivalTime)\n
            startCoords: \(self.startCoords)\n
            endCoords: \(self.endCoords)\n
            startName: \(self.startName)\n
            endName: \(self.endName)\n
            timeUntilDeparture: \(self.timeUntilDeparture)\n
        """

        return mainDescription

    }

    /** Used for sharing. Return a one sentence summary of the route, based on
        the first depart or walking direction. Returns "" if no directions.
     */
    var summaryDescription: String {

        var description = "To get from \(startName) to \(endName),"
        var noDepartDirection = true

        if description.contains(Constants.Stops.currentLocation) {
            description = "To get to \(endName),"
        }

        let busDirections = directions.filter { $0.type == .depart || $0.type == .transfer }

        for (index, direction) in busDirections.enumerated() {

            noDepartDirection = false

            let number = direction.routeNumber
            let start = direction.startLocation.name
            let end = direction.endLocation.name
            var line = "take Route \(number) from \(start) to \(end). "
            
            if direction.type == .transfer {
                line = "the bus becomes Route \(number). Stay on board, and then get off at \(end)"
            }

            if index == 0 {
                description += " \(line)"
            } else {
                description += "Then, \(line)"
            }

        }
        
        description += "."

        // Walking Direction
        if noDepartDirection {
            guard let direction = directions.first else {
                return ""
            }
            let distance = direction.travelDistance.roundedString
            description = "Walk \(distance) from \(startName) to \(endName)."
        }

        return description

    }

}
