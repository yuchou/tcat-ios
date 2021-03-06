//
//  Waypoint.swift
//  TCAT
//
//  Created by Annie Cheng on 2/24/17.
//  Copyright © 2017 cuappdev. All rights reserved.
//

import UIKit
import CoreLocation

enum WaypointType: String {
    /// The startLocation origin point of the trip
    case origin
    /// The endLocation destination point of the trip
    case destination
    /// Used for bus stops
    case stop
    case bus
    case walk
    case walking
    case bussing
    case none
}

class Waypoint: NSObject {
    
    let smallDiameter: CGFloat = 12
    let largeDiameter: CGFloat = 24
    
    var latitude: CLLocationDegrees = 0
    var longitude: CLLocationDegrees = 0
    var wpType: WaypointType = .origin
    var iconView: UIView = UIView()
    var busNumber: Int = 0
    
    init(lat: CLLocationDegrees, long: CLLocationDegrees, wpType: WaypointType, busNumber: Int = 0, isStop: Bool = false) {
        super.init()
        self.latitude = lat
        self.longitude = long
        self.wpType = wpType
        self.busNumber = busNumber
        
        switch wpType {
        case .origin:
            self.iconView = Circle(size: .large, style: .solid, color: isStop ? .tcatBlueColor : .mediumGrayColor)
        case .destination:
            self.iconView = Circle(size: .large, style: .bordered, color: isStop ? .tcatBlueColor : .mediumGrayColor)
        case .bus:
            self.iconView = Circle(size: .small, style: .solid, color: .tcatBlueColor)
        case .walk:
            self.iconView = Circle(size: .small, style: .solid, color: .mediumGrayColor)
        case .none, .stop, .walking, .bussing:
            self.iconView = UIView()
        }
    }
    
    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    func drawOriginIcon() -> UIView {
        return drawCircle(radius: largeDiameter / 2, innerColor: .mediumGrayColor, borderColor: .white)
    }
    
    func drawDestinationIcon() -> UIView {
        return drawCircle(radius: largeDiameter / 2, innerColor: .tcatBlueColor, borderColor: .white)
    }
    
    func drawStopIcon() -> UIView {
        return drawCircle(radius: smallDiameter / 2, innerColor: .white)
    }

    func drawBusPointIcon() -> UIView {
        return drawCircle(radius: smallDiameter / 2, innerColor: .tcatBlueColor)
    }
    
    func drawWalkPointIcon() -> UIView {
        return drawCircle(radius: smallDiameter / 2, innerColor: .mediumGrayColor)
    }
    
    // Draw waypoint meant to be placed as an iconView on map
    func drawCircle(radius: CGFloat, innerColor: UIColor, borderColor: UIColor? = nil) -> UIView {
        
        let constant: CGFloat = 1
        let dim = (radius * 2) + 4
        let base = UIView(frame: CGRect(x: 0, y: 0, width: dim, height: dim))
        
        let circleView = UIView(frame: CGRect(x: 0, y: 0, width: radius * 2, height: radius * 2))
        circleView.center = base.center
        
        circleView.layer.cornerRadius = circleView.frame.width / 2.0
        circleView.layer.masksToBounds = false
        circleView.layer.shadowColor = UIColor.black.cgColor
        circleView.layer.shadowOffset = CGSize(width: 0, height: constant)
        circleView.layer.shadowOpacity = 0.25
        circleView.layer.shadowRadius = 1
        
        circleView.backgroundColor = innerColor
        if let borderColor = borderColor {
            circleView.layer.borderWidth = 4
            circleView.layer.borderColor = borderColor.cgColor
        }
        
        base.addSubview(circleView)
        return base
        
    }
    
    func setColor(color: UIColor) {
        switch wpType {
        case .destination:
            iconView.layer.borderColor = color.cgColor
        case .origin, .stop, .bus, .walk, .bussing, .walking:
            iconView.backgroundColor = color
        case .none:
            break
        }
    }
    
}

