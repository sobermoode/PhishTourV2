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
    var tours: [ PhishTour ]?
    
    let documentsPath = NSSearchPathForDirectoriesInDomains(
        .DocumentDirectory,
        .UserDomainMask,
        true
    )[ 0 ] as! String
    var yearPath: String
    
    /*
    init( year: Int, tours: [ PhishTour ] )
    {
        self.year = year
        self.tours = tours
        self.yearPath = self.documentsPath.stringByAppendingPathComponent( "year\( self.year ).year" )
    }
    */
    
    init( year: Int )
    {
        self.year = year
        self.yearPath = self.documentsPath.stringByAppendingPathComponent( "year\( self.year ).plist" )
    }
    
    required init( coder aDecoder: NSCoder )
    {
        self.year = aDecoder.decodeIntegerForKey( "year" )
        self.tours = aDecoder.decodeObjectForKey( "tours" ) as? [ PhishTour ]
        self.yearPath = aDecoder.decodeObjectForKey( "yearPath" ) as! String
    }
    
    func encodeWithCoder( aCoder: NSCoder )
    {
        aCoder.encodeInteger( year, forKey: "year" )
        aCoder.encodeObject( tours, forKey: "tours" )
        aCoder.encodeObject( self.yearPath, forKey: "yearPath" )
    }
    
    func save()
    {
        println( "Saving year: \( self.year ) to \( self.yearPath )" )
        
        if NSKeyedArchiver.archiveRootObject( self, toFile: self.yearPath )
        {
            return
        }
        else
        {
            println( "There was an error saving \( self.year ) to the device." )
        }
    }
}
