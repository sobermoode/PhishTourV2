//
//  PhishYear.swift
//  PhishTourV2
//
//  Created by Aaron Justman on 10/1/15.
//  Copyright (c) 2015 AaronJ. All rights reserved.
//

import UIKit

class PhishYear: NSObject,
    NSCoding
{
    var year: Int
    var tours: [ PhishTour ]
    
    init( year: Int, tours: [ PhishTour ] )
    {
        self.year = year
        self.tours = tours
    }
    
    required init( coder aDecoder: NSCoder )
    {
        self.year = aDecoder.decodeIntegerForKey( "year" )
        self.tours = aDecoder.decodeObjectForKey( "tours" ) as! [ PhishTour ]
    }
    
    func encodeWithCoder( aCoder: NSCoder )
    {
        aCoder.encodeInteger( year, forKey: "year" )
        aCoder.encodeObject( tours, forKey: "tours" )
    }
}
