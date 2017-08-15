//
//  RouteDiagram.swift
//  TCAT
//
//  Created by Monica Ong on 7/2/17.
//  Copyright © 2017 cuappdev. All rights reserved.
//

import UIKit

class RouteDiagramElement: NSObject {
    
    var stopNameLabel: UILabel = UILabel()
    var stopDot: Circle = Circle(size: .small, color: .tcatBlueColor, style: .solid)
    var busIcon: BusIcon?
    var routeLine: RouteLine?
        
    override init() {
        super.init()
    }
}

class RouteDiagram: UIView{
    
    // MARK:  View vars
    
    var routeDiagramElements: [RouteDiagramElement] = []
    var travelDistanceLabel: UILabel = UILabel()
    
    // MARK: Spacing vars
    
    let stopDotLeftSpaceFromSuperview: CGFloat = 81.0
    static let routeLineHeight: CGFloat = 25.0
    let busIconLeftSpaceFromSuperview: CGFloat = 18.0
    let stopDotAndStopLabelHorizontalSpace: CGFloat = 17.5
    let stopLabelAndDistLabelHorizontalSpace: CGFloat = 5.5
    
    // MARK: Init
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK:  Reuse
    
    func prepareForReuse(){
        for routeDiagramElement in routeDiagramElements{
            routeDiagramElement.stopNameLabel.removeFromSuperview()
            routeDiagramElement.stopDot.removeFromSuperview()
            routeDiagramElement.busIcon?.removeFromSuperview()
            routeDiagramElement.routeLine?.removeFromSuperview()
        }
        travelDistanceLabel.removeFromSuperview()
        
        routeDiagramElements.removeAll()
        travelDistanceLabel = UILabel()
    }
    
    // MARK: Set Data
    
    func setRouteData(fromStopNums stopNums: [Int], fromStopNames stopNames: [String]){
        
        for i in 0...(stopNums.count - 1){
            
            let routeDiagramElement = RouteDiagramElement()
            
            routeDiagramElement.stopNameLabel = getStopNameLabel()
            routeDiagramElement.stopDot = getStopDot(fromStopNums: stopNums, atIndex: i)
            routeDiagramElement.busIcon = getBusIcon(fromStopNums: stopNums, atIndex: i)
            routeDiagramElement.routeLine = getRouteLine(fromStopNums: stopNums, atIndex: i)
            
            styleStopLabel(routeDiagramElement.stopNameLabel)
            setStopLabel(routeDiagramElement.stopNameLabel, withStopName: stopNames[i])
            
            routeDiagramElements.append(routeDiagramElement)
        }
    
    }
    
    func setTravelDistance(withDistance distance: Double){
        styleDistanceLabel()
        setDistanceLabel(withDistance: distance)
    }
    
    private func setDistanceLabel(withDistance distance: Double){
        let roundDigit = (distance >= 10.0) ? 0 : 1
        var distanceMutable = distance
        travelDistanceLabel.text = "\(distanceMutable.roundToPlaces(places: roundDigit)) mi away"
        travelDistanceLabel.sizeToFit()
    }
    
    private func setStopLabel(_ stopLabel: UILabel, withStopName stopName: String){
        stopLabel.text = stopName
        stopLabel.sizeToFit()
    }
    
    // MARK: Get data from route ojbect
    
    private func getStopNameLabel() -> UILabel{
        let stopNameLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 20))
        
        return stopNameLabel
    }
    
    private func getStopDot(fromStopNums stopNums: [Int], atIndex index: Int) -> Circle {
        let destinationDot = stopNums.count - 1
        
        let busDestination = -2
        let placeDestination = -3
        
        if(index == destinationDot){
            
            let destinationNum = stopNums[index]
            
            if(destinationNum == busDestination){
                let framedBlueCircle = Circle(size: .large, color: .tcatBlueColor, style: .bordered)
                framedBlueCircle.backgroundColor = .white

                return framedBlueCircle
            }
            else if(destinationNum == placeDestination){
                let framedGreyCircle = Circle(size: .large, color: .lineColor, style: .bordered)
                framedGreyCircle.backgroundColor = .white
                
                return framedGreyCircle
            }
            
        } else{
            
            let solidBlueCircle = Circle(size: .small, color: .tcatBlueColor, style: .solid)
            
            return solidBlueCircle
        }
        
        let errorCirlce = Circle(size: .small, color: .lineColor, style: .solid)
        print("RouteDiagram getStopDot did not return a valid direction circle")
        
        return errorCirlce
        
    }
    
    private func getBusIcon(fromStopNums stopNums: [Int], atIndex index: Int) -> BusIcon?{
        let busNum = stopNums[index]
        
        if(busNum >= 0){ //bus numbers cannot be negative
            
            let busIcon = BusIcon(size: .small, number: busNum)
            
            return busIcon
        }
        
        return nil
    }
    
    private func getRouteLine(fromStopNums stopNums: [Int], atIndex index: Int) -> RouteLine?{
        let stopNum = stopNums[index]
        
        let walk = -1
        
        if(stopNum >= 0){
            
            let solidBlueRouteLine = SolidLine(height: RouteDiagram.routeLineHeight, color: .tcatBlueColor)
            
            return solidBlueRouteLine
        }
        else if(stopNum == walk){
            
            let dashedGreyRouteLine = DashedLine(color: .mediumGrayColor)
            return dashedGreyRouteLine
        }
        else{

            return nil
        }
        
    }

    // MARK: Style
    
    private func styleStopLabel(_ stopLabel: UILabel){
        stopLabel.font = UIFont(name: "SFUIText-Regular", size: 14.0)
        stopLabel.textColor = .primaryTextColor
    }
    
    private func styleDistanceLabel(){
        travelDistanceLabel.font = UIFont(name: "SFUIText-Regular", size: 12.0)
        travelDistanceLabel.textColor = .mediumGrayColor
    }
    
    // MARK: Position
    
    func positionSubviews(){
                
        for i in 0...(routeDiagramElements.count-1){
            
            let stopDot = routeDiagramElements[i].stopDot
            let stopLabel = routeDiagramElements[i].stopNameLabel
            
            positionStopDot(stopDot, atIndex: i)
            positionStopLabel(stopLabel, usingStopDot: stopDot)
            
            if let routeLine = routeDiagramElements[i].routeLine{                positionRouteLine(routeLine, usingStopDot: stopDot)
            }
            
            if let routeLine = routeDiagramElements[i].routeLine,
               let busIcon = routeDiagramElements[i].busIcon{
                positionBusIcon(busIcon, usingRouteLine: routeLine)
            }
            
        }
        
        positionDistanceLabel(usingFirstStopLabel: routeDiagramElements[0].stopNameLabel)
        
        resizeHeight()
    }
    
    private func positionStopDot(_ stopDot: Circle, atIndex index: Int){
        let firstDot = 0
        
        if(index == firstDot){
            
            stopDot.center.x = stopDotLeftSpaceFromSuperview + (stopDot.frame.width/2)
            stopDot.center.y = (stopDot.frame.height/2)
            
        }
        else{
            
            let previousRouteLine = routeDiagramElements[index-1].routeLine
            let previousStopDot = routeDiagramElements[index-1].stopDot
            
            stopDot.center.x = previousStopDot.center.x
            stopDot.center.y = (previousRouteLine?.frame.maxY ?? (previousStopDot.frame.maxY + RouteDiagram.routeLineHeight)) + (previousStopDot.frame.height/2)
            
        }
        
    }
    
    private func positionStopLabel(_ stopLabel: UILabel, usingStopDot stopDot: Circle){
        let oldFrame = stopLabel.frame
        let newFrame = CGRect(x: stopDot.frame.maxX + stopDotAndStopLabelHorizontalSpace, y: oldFrame.minY, width: oldFrame.width, height: oldFrame.height)
        
        stopLabel.frame = newFrame
        
        stopLabel.center.y = stopDot.center.y
    }
    
    private func positionRouteLine(_ routeLine: RouteLine, usingStopDot stopDot: Circle){
        routeLine.center.x = stopDot.center.x
        
        let oldFrame = routeLine.frame
        let newFrame = CGRect(x: oldFrame.minX, y: stopDot.frame.maxY, width: oldFrame.width, height: oldFrame.height)
        
        routeLine.frame = newFrame
    }
    
    private func positionBusIcon(_ busIcon: BusIcon, usingRouteLine routeLine: RouteLine){
        busIcon.center.x = busIconLeftSpaceFromSuperview + (busIcon.frame.width/2)
        busIcon.center.y = routeLine.center.y
    }
    
    private func positionDistanceLabel(usingFirstStopLabel firstStopLabel: UILabel){
        let oldFrame = travelDistanceLabel.frame
        let newFrame = CGRect(x: firstStopLabel.frame.maxX + stopLabelAndDistLabelHorizontalSpace, y: firstStopLabel.frame.minY, width: oldFrame.width, height: oldFrame.height)
        
        travelDistanceLabel.frame = newFrame
    }
    
    
    // MARK: Add subviews
    
    func addSubviews(){
        
        for routeDiagramElement in routeDiagramElements{
            let stopDot = routeDiagramElement.stopDot
            let stopLabel = routeDiagramElement.stopNameLabel
            
            addSubview(stopDot)
            addSubview(stopLabel)
            
            if let routeLine = routeDiagramElement.routeLine{
                addSubview(routeLine)
            }
            
            if let busIcon = routeDiagramElement.busIcon{
                addSubview(busIcon)
            }
        }
        
        addSubview(travelDistanceLabel)
    }
    
    private func resizeHeight(){
        
        let firstStopDot = routeDiagramElements[0].stopDot
        let lastStopDot = routeDiagramElements[routeDiagramElements.count - 1].stopDot
        
        let resizedHeight = lastStopDot.frame.maxY - firstStopDot.frame.minY
        
        let oldFrame = frame
        let newFrame = CGRect(x: oldFrame.minX, y: oldFrame.minY, width: oldFrame.width, height: resizedHeight)
        
        frame = newFrame
    }
}
