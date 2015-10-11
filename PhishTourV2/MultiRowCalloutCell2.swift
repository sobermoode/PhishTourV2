//
//  MultiRowCalloutCell2.swift
//  SMCalloutViewTest
//
//  Created by Aaron Justman on 9/27/15.
//  Copyright (c) 2015 AaronJ. All rights reserved.
//

import UIKit

class MultiRowCalloutCell2: UITableViewCell
{
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var yearLabel: UILabel!
    @IBOutlet weak var venueLabel: UILabel!
    @IBOutlet weak var cityLabel: UILabel!
    @IBOutlet weak var seeSetlistButton: UIButton!
    
    // var cellNumber: Int!
    var cellNumber: CGFloat!
    
    // var cellWidth: Int = 250
    // var cellHeight: Int = 45
    var cellWidth: CGFloat = 0
    var cellHeight: CGFloat = 0
    var isTableViewCell: Bool = false
    var extraHeight: CGFloat = 0
    
    var venueLabelIsTooLarge: Bool = false
    var cityLabelIsTooLarge: Bool = false
    
    static var maxWidth: CGFloat = 0
    
    func setup( #cellNumber: Int, date: String, year: String, venue: String, city: String )
    {
        // self.frame = CGRect( x: 0, y: 0, width: 250, height: 45 )
        self.cellNumber = CGFloat( cellNumber )
        
        // self.setFrame()
        self.setBackgroundColor()
        
        self.dateLabel.text = date
//        self.dateLabel.layer.borderColor = UIColor.redColor().CGColor
//        self.dateLabel.layer.borderWidth = 1
//        self.dateLabel.backgroundColor = UIColor.blueColor()
        // self.dateLabel.sizeToFit()
        
        self.yearLabel.text = year
//        self.yearLabel.layer.borderColor = UIColor.redColor().CGColor
//        self.yearLabel.layer.borderWidth = 1
//        self.yearLabel.backgroundColor = UIColor.blueColor()
        // self.yearLabel.sizeToFit()
        
        self.venueLabel.text = venue
        // self.venueLabel.sizeToFit()
        
        self.cityLabel.text = city
        // self.cityLabel.sizeThatFits( self.cityLabel.frame.size )
        // self.cityLabel.sizeToFit()
        
        self.layoutIfNeeded()
    }
    
    func setFrame()
    {
        // self.frame = CGRect(x: 0.0, y: cellHeight * cellNumber, width: cellWidth, height: cellHeight)
        // println( "Setting cell frame, cellHeight: \( cellHeight )" )
        self.frame = CGRect(
            x: 0.0, y: cellHeight * cellNumber,
            width: cellWidth, height: cellHeight
        )
    }
    
    func setFrameForCellNumberWithWidth( cellNumber: Int,  width: CGFloat )
    {
        println( "Setting cell \( cellNumber )'s frame with width \( width )" )
        self.contentView.frame = CGRect(x: 0.0, y: 0.0, width: width, height: cellHeight)
        self.frame = CGRect(x: 0.0, y: cellHeight * CGFloat( cellNumber ), width: width, height: cellHeight)
    }
    
    func setBackgroundColor()
    {
        let grayFactor = CGFloat( 0.05 * Double( cellNumber ) )
        let bgColor = UIColor(red: 1.0 - grayFactor, green: 1.0 - grayFactor, blue: 1.0 - grayFactor, alpha: 1.0 )
        self.backgroundColor = bgColor
    }
    
    override func layoutSubviews()
    {
        // println( "layoutSubviews..." )
        // var cellBecameTaller: Bool = false
        // var extraHeight: CGFloat = 0
        
        dateLabel.sizeToFit()
        dateLabel.frame.origin = CGPoint(x: 7, y: 7)
        
        yearLabel.sizeToFit()
        yearLabel.frame.origin = CGPoint(x: 7 + dateLabel.frame.size.width + 4, y: dateLabel.frame.origin.y - 1)
        
        venueLabel.sizeToFit()
        venueLabel.frame.size.width = ( venueLabel.frame.size.width > 145 ) ? 145 : venueLabel.frame.size.width
        // venueLabel.frame.size.width = ( venueLabel.frame.size.width > 145 ) ? 145 : venueLabel.frame.size.width
        /*
        if venueLabelIsTooLarge
        {
            extraHeight += 0
        }
        else
        {
            if venueLabel.frame.size.width > 145
            {
                extraHeight += venueLabel.frame.size.height - 13.5
                
                venueLabel.frame.size.width = 145
                
                venueLabelIsTooLarge = true
                
                // heightFactor = venueLabel.frame.size.height / 13.5
                // cellHeight = venueLabel.frame.size.height * heightFactor
            }
        }
        */
        venueLabel.frame.origin = CGPoint(x: dateLabel.frame.origin.x, y: dateLabel.frame.size.height + 7)
        
        // TODO: re-instate for SMCalloutView?
        // cityLabel.sizeToFit()
        // cityLabel.frame.size.width = ( cityLabel.frame.size.width > 145 ) ? 145 : cityLabel.frame.size.width
        
        // cityLabel.frame.size.width = ( cityLabel.frame.size.width > 145 ) ? 145 : cityLabel.frame.size.width
        /*
        if cityLabelIsTooLarge
        {
            extraHeight += 0
        }
        else
        {
            if cityLabel.frame.size.width > 145
            {
                extraHeight += cityLabel.frame.size.height - 13.5
                
                cityLabel.frame.size.width = 145
                
                cityLabelIsTooLarge = true
                
                // heightFactor = cityLabel.frame.size.height / 13.5
                // cellHeight = venueLabel.frame.size.height * heightFactor
            }
        }
        */
        cityLabel.frame.origin = CGPoint(x: 7 + venueLabel.frame.size.width + 15, y: venueLabel.frame.origin.y)
        
        // TODO: re-instate for SMCalloutView?
        // seeSetlistButton.sizeToFit()
        // seeSetlistButton.frame.origin = CGPoint(x: cityLabel.frame.origin.x + cityLabel.frame.size.width + 10, y: CGRectGetMidY(self.bounds) - 17)
        seeSetlistButton.frame.origin = CGPoint(x: CGRectGetMaxX(self.bounds) - seeSetlistButton.frame.size.width, y: CGRectGetMidY(self.bounds) - 17)
        
        // self.sizeToFit()
        
        // println( "extraHeight: \( extraHeight )" )
        cellWidth = self.frame.size.width
        cellHeight = self.frame.size.height
        // cellHeight = self.frame.size.height + extraHeight
        // cellHeight += extraHeight
        if !isTableViewCell
        {
            setFrame()
        }
    }
    
    /*
    override func layoutSubviews()
    {
        // println( "layoutSubviews..." )
        
        NSLayoutConstraint.deactivateConstraints( self.constraints() )
        
        dateLabel.sizeToFit()
        dateLabel.frame.origin = CGPoint(x: 7, y: 6)
        // println( "datelLabel alignmentRectInsets: \( dateLabel.alignmentRectForFrame( dateLabel.frame ) )" )
        
        yearLabel.sizeToFit()
        yearLabel.frame = CGRect(x: 7 + dateLabel.frame.size.width + 2, y: dateLabel.frame.origin.y + 5, width: yearLabel.frame.size.width, height: dateLabel.frame.size.height)
        // println( "yearLabel alignmentRectInsets: \( yearLabel.alignmentRectForFrame( yearLabel.frame ) )" )
        // yearLabel.frame.origin = CGPoint(x: 7 + dateLabel.frame.size.width + 2, y: dateLabel.frame.origin.y)
        
        venueLabel.sizeToFit()
        venueLabel.frame.origin = CGPoint(x: dateLabel.frame.origin.x, y: yearLabel.frame.size.height + 7)
        
        cityLabel.sizeToFit()
        cityLabel.frame.origin = CGPoint(x: 7 + venueLabel.frame.size.width + 15, y: venueLabel.frame.origin.y + 3 )
        
        self.sizeToFit()
        
        cellWidth = self.frame.size.width
        cellHeight = self.frame.size.height
        setFrame()
    }
    */
    
    override func sizeThatFits( size: CGSize ) -> CGSize
    {
        // var newSize: CGSize = CGSizeZero
        
        // let width = self.frame.size.width
        // let width: CGFloat = ( venueLabel.frame.origin.x + venueLabel.frame.size.width ) + ( cityLabel.frame.origin.x + cityLabel.frame.size.width ) + ( seeSetlistButton.frame.origin.x + seeSetlistButton.frame.size.width ) + 28
        // let height = self.frame.size.height
        
        /* PREVIOUS CODE
        let width: CGFloat = venueLabel.frame.size.width + cityLabel.frame.size.width + seeSetlistButton.frame.size.width + 30
        let height: CGFloat = 45
        return CGSize(width: width, height: height)
        */
        
        return CGSize(width: superview!.frame.size.width, height: cellHeight)
    }
    
    func updateWithNewWidth( newWidth: CGFloat )
    {
        // println( "updateWithNewWidth..." )
        self.frame.size.width = newWidth
        
        self.layer.borderColor = UIColor.orangeColor().CGColor
        self.layer.borderWidth = 1
        
        // let calloutView = self.superview as! CalloutCellView // TODO: re-instate?
        // let superviewWidth = calloutView.bounds.width // TODO: re-instate?
        
//        self.frame = CGRect(
//            x: 0.0, y: cellHeight * cellNumber,
//            width: superviewWidth, height: cellHeight
//        )
        
        // self.contentView.frame.size.width = newWidth
        
        seeSetlistButton.frame.origin = CGPoint(x: self.frame.size.width - seeSetlistButton.frame.size.width, y: CGRectGetMidY(self.bounds) - 17)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        // println( "awakeFromNib..." )
        self.cellNumber = 0
//        self.layer.borderColor = UIColor.blueColor().CGColor
//        self.layer.borderWidth = 1
//        self.cityLabel.layer.borderColor = UIColor.redColor().CGColor
//        self.cityLabel.layer.borderWidth = 1
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
}
