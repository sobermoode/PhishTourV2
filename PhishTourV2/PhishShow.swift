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
    var tour: PhishTour?  // being set in PhishTour.associateShows()
    var setlist: [ Int : [ PhishSong ] ]?
    
    // keeps track of shows by their ID
    static var showDictionary = [ Int : PhishShow ]()
    
    // static let fileManager: NSFileManager = NSFileManager.defaultManager()
    static let documentsPath = NSSearchPathForDirectoriesInDomains(
        .DocumentDirectory,
        .UserDomainMask,
        true
    )[ 0 ] as! String
    // var setlistPath: String
    var showPath: String
    
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
        // self.setlistPath = PhishShow.documentsPath + "setlist" + "\( showID )"
        // println( "setlistPath: \( self.setlistPath )" )
        // self.showPath = PhishShow.documentsPath + "/shows/Phish-show-" + "\( showID )"
        self.showPath = PhishShow.documentsPath.stringByAppendingPathComponent( "show\( self.showID )" )
    }
    
    required init( coder aDecoder: NSCoder )
    {
        self.date = aDecoder.decodeObjectForKey( "date" ) as! String
        self.year = aDecoder.decodeIntegerForKey( "year" )
        self.venue = aDecoder.decodeObjectForKey( "venue" ) as! String
        self.city = aDecoder.decodeObjectForKey( "city" ) as! String
        self.showID = aDecoder.decodeIntegerForKey( "showID" )
        self.consecutiveNights = aDecoder.decodeIntegerForKey( "consecutiveNights" )
        self.tour = aDecoder.decodeObjectForKey( "tour" ) as? PhishTour
        self.setlist = aDecoder.decodeObjectForKey( "setlist" ) as? [ Int : [ PhishSong ] ]
        // PhishShow.showDictionary = aDecoder.decodeObjectForKey( "showDictionary" ) as! [ Int : PhishShow ]
        self.showPath = aDecoder.decodeObjectForKey( "showPath" ) as! String
    }
    
    func encodeWithCoder( aCoder: NSCoder )
    {
        aCoder.encodeObject( self.date, forKey: "date" )
        aCoder.encodeInteger( self.year, forKey: "year" )
        aCoder.encodeObject( self.venue, forKey: "venue" )
        aCoder.encodeObject( self.city, forKey: "city" )
        aCoder.encodeInteger( self.showID, forKey: "showID" )
        aCoder.encodeInteger( self.consecutiveNights, forKey: "consecutiveNights" )
        aCoder.encodeObject( self.tour, forKey: "tour" )
        aCoder.encodeObject( self.setlist, forKey: "setlist" )
        // aCoder.encodeObject( PhishShow.showDictionary, forKey: "showDictionary" )
        aCoder.encodeObject( self.showPath, forKey: "showPath" )
    }
    
    func updateShowDictionary()
    {
        PhishShow.showDictionary.updateValue( self, forKey: self.showID )
    }
    
    func save()
    {
        println( "Saving show: \( self.date ) \( self.year ) to \( self.showPath )" )
        
        if NSFileManager.defaultManager().fileExistsAtPath( self.showPath )
        {
            println( "Show file already exists at \( self.showPath )." )
            
            if NSKeyedArchiver.archiveRootObject( self, toFile: self.showPath )
            {
                // return
                println( "Replaced \( self.date ) \( self.year )." )
            }
            else
            {
                println( "There was an error replacing \( self.date ) \( self.year )." )
            }
            
            /*
            // var showURL = NSURL(string: self.showPath)
            var showURL = NSURL(fileURLWithPath: self.showPath)
            let tempShowPath = self.showPath + "temp"
            // let tempShowURL = NSURL(string: tempShowPath)!
            let tempShowURL = NSURL(fileURLWithPath: tempShowPath)!
            var resultingURL: NSURL?
            var showReplacementError: NSErrorPointer = nil
            // var showReplacementError: NSError? = nil
            if NSFileManager.defaultManager().replaceItemAtURL(showURL!, withItemAtURL: tempShowURL, backupItemName: nil, options: NSFileManagerItemReplacementOptions.UsingNewMetadataOnly, resultingItemURL: &showURL, error: showReplacementError)
            {
                println( "Successfully replaced the show at \( self.showPath )" )
            }
            else
            {
                println( "Could not replace the show at \( self.showPath )" )
            }
            */
        }
        else
        {
            if NSKeyedArchiver.archiveRootObject( self, toFile: self.showPath )
            {
                return
            }
            else
            {
                println( "There was an error saving \( self.date ) \( self.year ) to the device." )
            }
        }
    }
}
