//
//  PhishTour.swift
//  PhishTourV2
//
//  Created by Aaron Justman on 9/30/15.
//  Copyright (c) 2015 AaronJ. All rights reserved.
//

import UIKit

class PhishTour: NSObject,
    NSCoding
{
    var year: Int
    var name: String
    var tourID: Int
    var shows: [ PhishShow ]
    
    var filePath: String
    {
        return "\( year )"
    }
    
    init(
        year: Int,
        name: String,
        tourID: Int,
        shows: [ PhishShow ]
    )
    {
        self.year = year
        self.name = name
        self.tourID = tourID
        self.shows = shows
    }
    
    required init( coder aDecoder: NSCoder )
    {
        // super.init()
        
        self.year = aDecoder.decodeIntegerForKey( "year" )
        self.name = aDecoder.decodeObjectForKey( "name" ) as! String
        self.tourID = aDecoder.decodeIntegerForKey( "tourID" )
        self.shows = aDecoder.decodeObjectForKey( "shows" ) as! [ PhishShow ]
    }
    
    func encodeWithCoder( aCoder: NSCoder )
    {
        aCoder.encodeInteger( year, forKey: "year" )
        aCoder.encodeObject( name, forKey: "name" )
        aCoder.encodeInteger( tourID, forKey: "tourID" )
        aCoder.encodeObject( shows, forKey: "shows" )
    }
}
