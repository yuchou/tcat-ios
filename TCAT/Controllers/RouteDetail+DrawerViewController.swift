//
//  RouteDetailViewController.swift
//  TCAT
//
//  Created by Matthew Barker on 2/11/17.
//  Copyright © 2017 cuappdev. All rights reserved.
//

import UIKit
import SwiftyJSON
import Pulley

struct RouteDetailCellSize {
    static let smallHeight: CGFloat = 60
    static let largeHeight: CGFloat = 80
    static let regularWidth: CGFloat = 120
    static let indentedWidth: CGFloat = 140
}

class RouteDetailDrawerViewController: UIViewController, UITableViewDataSource, UITableViewDelegate,
                                        UIGestureRecognizerDelegate, PulleyDrawerViewControllerDelegate {
    
    // MARK: Variables
    
    var summaryView = SummaryView()
    var tableView: UITableView!
    var safeAreaCover: UIView? = nil
    
    var route: Route!
    var directions: [Direction] = []
    
    let main = UIScreen.main.bounds
    var justLoaded: Bool = true
    
    var busDelayNetworkTimer: Timer?
    /// Number of seconds to wait before auto-refreshing bus delay network call.
    var busDelayNetworkRefreshRate: Double = 10
    
    // MARK: Initalization

    init(route: Route) {
        super.init(nibName: nil, bundle: nil)
        self.route = route
        self.directions = route.directions
    }
    
    func update(with route: Route) {
        self.route = route
        self.directions = route.directions
        tableView.reloadData()
    }
    
    required convenience init(coder aDecoder: NSCoder) {
        let route = aDecoder.decodeObject(forKey: "route") as! Route
        self.init(route: route)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        initializeDetailView()
        initializeCover()
        if let drawer = self.parent as? RouteDetailViewController {
            drawer.initialDrawerPosition = .partiallyRevealed
        }
        summaryView.setRoute()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Bus Delay Network Timer
        busDelayNetworkTimer?.invalidate()
        busDelayNetworkTimer = Timer.scheduledTimer(timeInterval: busDelayNetworkRefreshRate, target: self, selector: #selector(getDelays),
                                                    userInfo: nil, repeats: true)
        busDelayNetworkTimer?.fire()
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        busDelayNetworkTimer?.invalidate()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        removeCover()
    }
    
    // MARK: UIView Functions

    /** Create and configure detailView, summaryView, tableView */
    func initializeDetailView() {

        view.backgroundColor = .white
        
        // Create summaryView
        
        summaryView.route = route
        let summaryTapGesture = UITapGestureRecognizer(target: self, action: #selector(summaryTapped))
        summaryTapGesture.delegate = self
        summaryView.addGestureRecognizer(summaryTapGesture)
        view.addSubview(summaryView)

        // Create Detail Table View
        tableView = UITableView()
        tableView.frame.origin = CGPoint(x: 0, y: summaryView.frame.height)
        tableView.frame.size = CGSize(width: main.width, height: main.height - summaryView.frame.height)
        tableView.bounces = false
        tableView.estimatedRowHeight = RouteDetailCellSize.smallHeight
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.register(SmallDetailTableViewCell.self, forCellReuseIdentifier: Constants.Cells.smallDetailCellIdentifier)
        tableView.register(LargeDetailTableViewCell.self, forCellReuseIdentifier: Constants.Cells.largeDetailCellIdentifier)
        tableView.register(BusStopTableViewCell.self, forCellReuseIdentifier: Constants.Cells.busStopCellIdentifier)
        tableView.register(UITableViewHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: Constants.Footers.emptyFooterView)
        tableView.register(PhraseLabelFooterView.self, forHeaderFooterViewReuseIdentifier: Constants.Footers.phraseLabelFooterView)
        tableView.dataSource = self
        tableView.delegate = self
        
        view.addSubview(tableView)

    }
    
    /// Returns the currently expanded cell, if any
    var expandedCell: LargeDetailTableViewCell? {
        
        for index in 0..<tableView.numberOfRows(inSection: 0) {
            let indexPath = IndexPath(row: index, section: 0)
            if let cell = tableView.cellForRow(at: indexPath) as? LargeDetailTableViewCell {
                if cell.isExpanded {
                    return cell
                }
            }
            
        }
        return nil
    }
    
    /// Creates a temporary view to cover the drawer contents when collapsed. Hidden by default.
    func initializeCover() {
        if #available(iOS 11.0, *) {
            let bottom = UIApplication.shared.keyWindow?.rootViewController?.view.safeAreaInsets.bottom ?? 34
            safeAreaCover = UIView(frame: CGRect(x: 0, y: summaryView.frame.height, width: main.width, height: bottom))
            safeAreaCover!.backgroundColor = .summaryBackgroundColor
            safeAreaCover!.alpha = 0
            view.addSubview(safeAreaCover!)
        }
    }
    
    /// Remove cover view
    func removeCover() {
        safeAreaCover?.removeFromSuperview()
        safeAreaCover = nil
    }
    
    // MARK: Pulley Delegate
    
    func collapsedDrawerHeight(bottomSafeArea: CGFloat) -> CGFloat {
        return bottomSafeArea + summaryView.frame.height
    }
    
    func partialRevealDrawerHeight(bottomSafeArea: CGFloat) -> CGFloat {
        return main.height / 2
    }
    
    func drawerPositionDidChange(drawer: PulleyViewController, bottomSafeArea: CGFloat) {
        
        justLoaded = false
        
        // Center map on drawer change
        if drawer.drawerPosition == .collapsed || drawer.drawerPosition == .partiallyRevealed  {
            guard let contentViewController = drawer.primaryContentViewController as? RouteDetailContentViewController
                else { return }
            contentViewController.centerMap(topHalfCentered: drawer.drawerPosition == .partiallyRevealed)
        }
        
    }
    
    private var visible: Bool = false
    private var ongoing: Bool = false
    
    func drawerChangedDistanceFromBottom(drawer: PulleyViewController, distance: CGFloat, bottomSafeArea: CGFloat) {
        
        // Manage cover view hiding drawer when collapsed
        if distance - bottomSafeArea == summaryView.frame.height {
            safeAreaCover?.alpha = 1.0
            visible = true
        } else {
            if !ongoing && visible {
                UIView.animate(withDuration: 0.25, animations: {
                    self.safeAreaCover?.alpha = 0.0
                    self.visible = false
                }, completion: { (_) in
                    self.ongoing = false
                })
            }
        }
        
    }
    
    func supportedDrawerPositions() -> [PulleyPosition] {
        return [.collapsed, .partiallyRevealed, .open]
    }
    
    // MARK: Network Calls
    
    /// Fetch delay information and update table view cells.
    @objc func getDelays() {
        
        // First depart direction(s)
        guard let delayDirection = route.getFirstDepartRawDirection() else {
            return // Use rawDirection (preserves first stop metadata)
        }
        let firstDepartDirection = self.directions.first(where: { $0.type == .depart })!
        
        directions.forEach { $0.delay = nil }
        
        if let tripId = delayDirection.tripIdentifiers?.first,
            let stopId = delayDirection.stops.first?.id
        {
            
            Network.getDelay(tripId: tripId, stopId: stopId).perform(withSuccess: { (json) in
                
                if json["success"].boolValue {
                    
                    delayDirection.delay = json["data"]["delay"].int
                    firstDepartDirection.delay = json["data"]["delay"].int
                    
                    // Update delay variable of other ensuing directions
                    
                    self.directions.filter {
                        let isAfter = self.directions.index(of: firstDepartDirection)! < self.directions.index(of: $0)!
                        return isAfter && $0.type != .depart
                    }
                    
                    .forEach { (direction) in
                        if let _ = direction.delay {
                            direction.delay! += delayDirection.delay ?? 0
                        } else {
                            direction.delay = delayDirection.delay
                        }
                    }
                    
                    self.tableView.reloadData()
                    self.summaryView.setRoute()
                    
                }
                else {
                    print("getDelays success: false")
                }
            }, failure: { (error) in
                print("getDelays error: \(error.errorDescription ?? "")")
            })
        }
        
    }
    
    // MARK: TableView Data Source and Delegate Functions

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return directions.count
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {

        let direction = directions[indexPath.row]

        if direction.type == .depart || direction.type == .transfer {
            let cell = tableView.dequeueReusableCell(withIdentifier: Constants.Cells.largeDetailCellIdentifier) as? LargeDetailTableViewCell
            cell?.setCell(direction, firstStep: indexPath.row == 0)
            return cell?.height() ?? RouteDetailCellSize.largeHeight
        } else {
            return RouteDetailCellSize.smallHeight
        }

    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        
        let latitude = route.endCoords.latitude
        let longitude = route.endCoords.longitude
        
        // If the phraseFooterView should be used (because there is a message)
        if let message = LocationPhrases.generateMessage(latitude: latitude, longitude: longitude) {
            let phraseLabelFooterView = tableView.dequeueReusableHeaderFooterView(withIdentifier: Constants.Footers.phraseLabelFooterView)
                as? PhraseLabelFooterView ?? PhraseLabelFooterView(reuseIdentifier: Constants.Footers.phraseLabelFooterView)
            phraseLabelFooterView.setupView(with: message)
            return phraseLabelFooterView
        }
        
        // Empty Footer
        else {
            
            let emptyFooterView = tableView.dequeueReusableHeaderFooterView(withIdentifier: Constants.Footers.emptyFooterView) ??
                UITableViewHeaderFooterView(reuseIdentifier: Constants.Footers.emptyFooterView)
            
            let lastCellIndexPath = IndexPath(row: tableView.numberOfRows(inSection: 0) - 1, section: 0)
            var screenBottom = main.height
            if #available(iOS 11.0, *) {
                screenBottom -= view.safeAreaInsets.bottom
            }
            
            // Calculate height of space between last cell and the bottom of the screen, also accounting for summary
            var footerHeight = screenBottom - (tableView.cellForRow(at: lastCellIndexPath)?.frame.maxY ?? screenBottom) - summaryView.frame.height
            footerHeight = expandedCell != nil ? 0 : footerHeight
            
            emptyFooterView.frame.size = CGSize(width: view.frame.width, height: footerHeight)
            emptyFooterView.contentView.backgroundColor = .white
            emptyFooterView.layoutIfNeeded()
            if emptyFooterView.gestureRecognizers?.isEmpty == true {
                let tapGesture = UITapGestureRecognizer(target: self, action: #selector(summaryTapped))
                tapGesture.delegate = self
                emptyFooterView.addGestureRecognizer(tapGesture)
            }
            
            return emptyFooterView
            
        }
        
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let direction = directions[indexPath.row]
        let isBusStopCell = direction.type == .arrive && direction.startLocation.latitude == 0.0
        let cellWidth: CGFloat = RouteDetailCellSize.regularWidth

        /// Formatting, including selectionStyle, and seperator line fixes
        func format(_ cell: UITableViewCell) -> UITableViewCell {
            cell.selectionStyle = .none
            if indexPath.row == directions.count - 1 {
                // Remove seperator at end of table
                cell.layoutMargins = UIEdgeInsets(top: 0, left: main.width, bottom: 0, right: 0)
            }
            return cell
        }

        if isBusStopCell {
            let cell = tableView.dequeueReusableCell(withIdentifier: Constants.Cells.busStopCellIdentifier) as! BusStopTableViewCell
            cell.setCell(direction.name)
            cell.layoutMargins = UIEdgeInsets(top: 0, left: cellWidth + 20, bottom: 0, right: 0)
            return format(cell)
        }

        else if direction.type == .walk || direction.type == .arrive {
            let cell = tableView.dequeueReusableCell(withIdentifier: Constants.Cells.smallDetailCellIdentifier, for: indexPath) as! SmallDetailTableViewCell
            cell.setCell(direction,
                         firstStep: indexPath.row == 0,
                         lastStep: indexPath.row == directions.count - 1)
            cell.layoutMargins = UIEdgeInsets(top: 0, left: cellWidth, bottom: 0, right: 0)
            return format(cell)
        }

        else {
            let cell = tableView.dequeueReusableCell(withIdentifier: Constants.Cells.largeDetailCellIdentifier) as! LargeDetailTableViewCell
            cell.setCell(direction, firstStep: indexPath.row == 0)
            cell.layoutMargins = UIEdgeInsets(top: 0, left: cellWidth, bottom: 0, right: 0)
            return format(cell)
        }

    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        let direction = directions[indexPath.row]
        
        // Limit expandedCell to only one bus route at a time.
        if let cell = expandedCell, cell != tableView.cellForRow(at: indexPath) {
            toggleCellExpansion(at: tableView.indexPath(for: cell))
        }

        // Check if cell starts a bus direction, and should be expandable
        if direction.type == .depart || direction.type == .transfer {

            if justLoaded { summaryTapped() }

            toggleCellExpansion(at: indexPath)
            
            // tableView.scrollToRow(at: indexPath, at: .none, animated: true)
            // Adjust footer
            
            tableView.layoutIfNeeded()
            tableView.layoutSubviews()
            
        } else {
            summaryTapped()
        }

    }
    
    /// Toggle the cell expansion at the indexPath
    func toggleCellExpansion(at indexPath: IndexPath?) {
        
        guard
            let indexPath = indexPath,
            let cell = tableView.cellForRow(at: indexPath) as? LargeDetailTableViewCell
        else {
            return
        }
        
        let direction = directions[indexPath.row]
        
        // Flip arrow
        cell.chevron.layer.removeAllAnimations()
        
        cell.isExpanded = !cell.isExpanded
        
        let transitionOptionsOne: UIViewAnimationOptions = [.transitionFlipFromTop, .showHideTransitionViews]
        UIView.transition(with: cell.chevron, duration: 0.25, options: transitionOptionsOne, animations: {
            cell.chevron.isHidden = true
        })
        
        cell.chevron.transform = cell.chevron.transform.rotated(by: CGFloat.pi)
        
        let transitionOptionsTwo: UIViewAnimationOptions = [.transitionFlipFromBottom, .showHideTransitionViews]
        UIView.transition(with: cell.chevron, duration: 0.25, options: transitionOptionsTwo, animations: {
            cell.chevron.isHidden = false
        })
        
        // Prepare bus stop data to be inserted / deleted into Directions array
        var busStops = [Direction]()
        for stop in direction.stops {
            let stopAsDirection = Direction(name: stop.name)
            busStops.append(stopAsDirection)
        }
        var indexPathArray: [IndexPath] = []
        let busStopRange = (indexPath.row + 1)..<(indexPath.row + 1) + busStops.count
        for i in busStopRange {
            indexPathArray.append(IndexPath(row: i, section: 0))
        }
        
        tableView.beginUpdates()
        
        // Insert or remove bus stop data based on selection
        
        if cell.isExpanded {
            directions.insert(contentsOf: busStops, at: indexPath.row + 1)
            tableView.insertRows(at: indexPathArray, with: .middle)
        } else {
            directions.removeSubrange(busStopRange)
            tableView.deleteRows(at: indexPathArray, with: .middle)
        }
        
        tableView.endUpdates()
        
        busStops = []
        indexPathArray = []
        
    }
    
    // MARK: Gesture Recognizers and Interaction-Related Functions

    /** Animate detailTableView depending on context, centering map */
    @objc func summaryTapped(_ sender: UITapGestureRecognizer? = nil) {
        
        if let drawer = self.parent as? RouteDetailViewController {
            switch drawer.drawerPosition {
            
            case .collapsed, .partiallyRevealed:
                drawer.setDrawerPosition(position: .open, animated: true)
            
            case .open:
                drawer.setDrawerPosition(position: .collapsed, animated: true)
            
            default: break
                
            }
        }

    }

}
