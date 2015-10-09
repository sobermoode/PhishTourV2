//
//  CalloutCellView.swift
//  MultiRowCalloutTest
//
//  Created by Aaron Justman on 9/25/15.
//  Copyright (c) 2015 AaronJ. All rights reserved.
//

import UIKit

class CalloutCellView: UIView
{
    override init( frame: CGRect )
    {
        super.init( frame: frame )
        
        self.backgroundColor = UIColor.clearColor()
    }

    required init( coder aDecoder: NSCoder )
    {
        fatalError( "init(coder:) has not been implemented" )
    }
    
    override func sizeThatFits( size: CGSize ) -> CGSize
    {
        // println( "sizeThatFits..." )
        var rowWidth: CGFloat = 0
        var totalHeight: CGFloat = 0
        var newSize: CGSize = CGSizeZero
        
        // if let aRow = subviews.first as? MultiRowCalloutCell2
        if !subviews.isEmpty
        {
            for currentCell in subviews
            {
                rowWidth = ( currentCell.frame.size.width > rowWidth ) ? currentCell.frame.size.width : rowWidth
                // let rowHeight = currentCell.frame.size.height
                // let totalHeight = CGFloat( subviews.count ) * rowHeight
                println( "currentCell.frame.size.height: \( currentCell.frame.size.height )" )
                totalHeight += currentCell.frame.size.height
            }
            
//            for currentCell in subviews
//            {
//                if currentCell.isKindOfClass(ShowCalloutView)
//                {
//                    continue
//                }
//                println( "currentCell: \( currentCell )" )
//                let theCell = currentCell as! MultiRowCalloutCell2
//                
//                rowWidth = ( theCell.frame.size.width > rowWidth ) ? theCell.frame.size.width : rowWidth
//                totalHeight += theCell.frame.size.height
//            }
            
//            for currentCell in subviews
//            {
//                let cell = currentCell as! MultiRowCalloutCell2
//                
//                cell.updateWithNewWidth( rowWidth )
//            }
            
            newSize = CGSize(
                width: rowWidth,
                height: totalHeight
            )
        }
        
        return newSize
    }
    
    override func layoutSubviews() {
        for currentCell in subviews
        {
            let cell = currentCell as! MultiRowCalloutCell2
            // let cell = currentCell as! ShowCalloutView
            // let cell = currentCell as! UIView

            // cell.updateWithNewWidth( rowWidth )
            cell.frame.size.width = self.bounds.width
        }
    }
    
    // TODO: now that sizeToFit() works, make this work, so the user has the option of adding cells
    // one at a time, or in a batch by passing an array
    func addCells( cells: [ MultiRowCalloutCell2! ] )
    {
        var rowWidth: CGFloat = 0
        // var totalHeight: CGFloat = 0
        // var newSize: CGSize = CGSizeZero
        
        for currentCell in cells
        {
            rowWidth = ( currentCell.frame.size.width > rowWidth ) ? currentCell.frame.size.width : rowWidth
            
            MultiRowCalloutCell2.maxWidth = rowWidth
            // let rowHeight = currentCell.frame.size.height
            // let totalHeight = CGFloat( subviews.count ) * rowHeight
            // totalHeight += currentCell.frame.size.height
        }
        
        for ( cellNumber, currentCell ) in enumerate( cells )
        {
            // currentCell.setFrameForCellNumberWithWidth( cellNumber, width: rowWidth )
            currentCell.setNeedsDisplay()
            
            self.addSubview( currentCell )
        }
    }
    
    func updateCellsWithNewWidth( newWidth: CGFloat )
    {
        for currentCell in subviews
        {
            let cell = currentCell as! MultiRowCalloutCell2
            
            cell.updateWithNewWidth( newWidth )
        }
        
        self.setNeedsLayout()
    }
}
