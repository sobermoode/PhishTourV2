//
//  PhishShow.swift
//  PhishTourV2
//
//  Created by Aaron Justman on 9/30/15.
//  Copyright (c) 2015 AaronJ. All rights reserved.
//

import UIKit
import MapKit

class PhishShow: NSObject,
    NSCoding, MKAnnotation
{
    var date: String
    var year: Int
    var venue: String
    var city: String
    var showID: Int
    var consecutiveNights: Int = 1
    var tour: PhishTour!  // not set yet; need to do it in the PhishTour init
    var setlist: [ Int : [ PhishSong ] ]!
    
    static let fileManager: NSFileManager = NSFileManager.defaultManager()
    static let documentsPath = NSSearchPathForDirectoriesInDomains(
        .DocumentDirectory,
        .UserDomainMask,
        true
        )[ 0 ] as! String
    var setlistPath: String
    
    var showLatitude, showLongitude: Double!
    var coordinate: CLLocationCoordinate2D
    {
        return CLLocationCoordinate2D(
            latitude: showLatitude,
            longitude: showLongitude
        )
    }
    
    init(
        showInfo: [ String : AnyObject ],
        andYear year: Int
    )
    {
        // need to convert the date to a more pleasing form;
        // step 1: get the date, as returned from phish.in
        let date = showInfo[ "date" ] as! String
        
        // step 2: create a date formatter and set the input format;
        // create an NSDate object with the input format
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let formattedDate = dateFormatter.dateFromString( date )!
        
        // step 3:
        // set the output date format;
        // create a new string with the reformatted date
        dateFormatter.dateFormat = "MMM dd,"
        let formattedString = dateFormatter.stringFromDate( formattedDate )
        
        self.date = formattedString
        self.year = year
        self.venue = showInfo[ "venue_name" ] as! String
        self.city = showInfo[ "location" ] as! String
        self.showID = showInfo[ "id" ] as! Int
        self.setlistPath = PhishShow.documentsPath + "setlist" + date
        println( "setlistPath: \( self.setlistPath )" )
    }
    
    required init( coder aDecoder: NSCoder )
    {
        self.date = aDecoder.decodeObjectForKey( "date" ) as! String
        self.year = aDecoder.decodeIntegerForKey( "year" )
        self.venue = aDecoder.decodeObjectForKey( "venue" ) as! String
        self.city = aDecoder.decodeObjectForKey( "city" ) as! String
        self.showID = aDecoder.decodeIntegerForKey( "showID" )
        self.consecutiveNights = aDecoder.decodeIntegerForKey( "consecutiveNights" )
        self.setlistPath = aDecoder.decodeObjectForKey( "setlistPath" ) as! String
    }
    
    func encodeWithCoder( aCoder: NSCoder )
    {
        aCoder.encodeObject( self.date, forKey: "date" )
        aCoder.encodeInteger( self.year, forKey: "year" )
        aCoder.encodeObject( self.venue, forKey: "venue" )
        aCoder.encodeObject( self.city, forKey: "city" )
        aCoder.encodeInteger( self.showID, forKey: "showID" )
        aCoder.encodeInteger( self.consecutiveNights, forKey: "consecutiveNights" )
        aCoder.encodeObject( self.setlistPath, forKey: "setlistPath" )
    }
    
    func save()
    {
        if NSKeyedArchiver.archiveRootObject( setlist, toFile: self.setlistPath )
        {
            return
        }
        else
        {
            println( "There was an error saving \( self.date ) \( self.year ) the setlist to the device." )
        }
    }
}
