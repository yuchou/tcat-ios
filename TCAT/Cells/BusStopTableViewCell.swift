//
//  BusStopTableViewCell.swift
//  TCAT
//
//  Created by Matthew Barker on 2/12/17.
//  Copyright © 2017 cuappdev. All rights reserved.
//

import UIKit

class BusStopTableViewCell: UITableViewCell {
    
    let linePosition: CGFloat = DetailIconView.width - 16 // max of DetailIconView (114) - constant (16) = 98
    
    var titleLabel: UILabel!
    let cellHeight: CGFloat = RouteDetailCellSize.smallHeight
    let cellWidth: CGFloat = RouteDetailCellSize.indentedWidth
    
    var connectorTop: UIView!
    var connectorBottom: UIView!
    var statusCircle: Circle!
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        titleLabel = UILabel()
        titleLabel.frame = CGRect(x: cellWidth, y: 0, width: UIScreen.main.bounds.width - cellWidth - 20, height: 20)
        titleLabel.font = UIFont.systemFont(ofSize: UIFont.systemFontSize)
        titleLabel.textColor = .secondaryTextColor
        titleLabel.text = "Bus Stop Name"
        titleLabel.lineBreakMode = .byWordWrapping
        titleLabel.numberOfLines = 0
        titleLabel.sizeToFit()
        titleLabel.center.y = cellHeight / 2
        contentView.addSubview(titleLabel)
        
        connectorTop = UIView(frame: CGRect(x: linePosition, y: 0, width: 4, height: cellHeight / 2))
        connectorTop.frame.origin.x -= connectorTop.frame.width / 2
        connectorTop.backgroundColor = .tcatBlueColor
        contentView.addSubview(connectorTop)
        
        connectorBottom = UIView(frame: CGRect(x: linePosition, y: cellHeight / 2, width: 4, height: cellHeight / 2))
        connectorBottom.frame.origin.x -= connectorBottom.frame.width / 2
        connectorBottom.backgroundColor = .tcatBlueColor
        contentView.addSubview(connectorBottom)
        
        statusCircle = Circle(size: .small, style: .outline, color: .tcatBlueColor)
        statusCircle.center = self.center
        statusCircle.center.y = cellHeight / 2
        statusCircle.frame.origin.x = linePosition - (statusCircle.frame.width / 2)
        contentView.addSubview(statusCircle)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setCell(_ name: String) {
        titleLabel.text = name
        titleLabel.sizeToFit()
        titleLabel.frame.size.width = UIScreen.main.bounds.width - cellWidth - 20
        titleLabel.center.y = cellHeight / 2
    }
    
}
