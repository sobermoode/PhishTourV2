//
//  PhishTour.swift
//  PhishTourV2
//
//  Created by Aaron Justman on 9/30/15.
//  Copyright (c) 2015 AaronJ. All rights reserved.
//

import UIKit
import MapKit

class PhishTour: NSObject,
    NSCoding
{
    var year: Int
    var name: String
    var tourID: Int
    var shows: [ PhishShow ]
    var locationDictionary: [ String : [ PhishShow ] ]
    
    var showCoordinates: [ CLLocationCoordinate2D ]
    {
        var coordinates = [ CLLocationCoordinate2D ]()
        for show in shows
        {
            coordinates.append( show.coordinate )
        }
        
        return coordinates
    }
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
        self.locationDictionary = [ String : [ PhishShow ] ]()
    }
    
    required init( coder aDecoder: NSCoder )
    {
        // super.init()
        
        self.year = aDecoder.decodeIntegerForKey( "year" )
        self.name = aDecoder.decodeObjectForKey( "name" ) as! String
        self.tourID = aDecoder.decodeIntegerForKey( "tourID" )
        self.shows = aDecoder.decodeObjectForKey( "shows" ) as! [ PhishShow ]
        self.locationDictionary = aDecoder.decodeObjectForKey( "locationDictionary" ) as! [ String : [ PhishShow ] ]
    }
    
    func encodeWithCoder( aCoder: NSCoder )
    {
        // TODO: add self. to the properties
        aCoder.encodeInteger( year, forKey: "year" )
        aCoder.encodeObject( name, forKey: "name" )
        aCoder.encodeInteger( tourID, forKey: "tourID" )
        aCoder.encodeObject( shows, forKey: "shows" )
        aCoder.encodeObject( locationDictionary, forKey: "locationDictionary" )
    }
    
    func createLocationDictionary()
    {
        // var currentShow: PhishShow = shows.first!
        var previousShow: PhishShow = shows.first!
        var currentVenue: String = previousShow.venue
        var multiNightRun = [ PhishShow ]()
        var locationDictionary = [ String : [ PhishShow ] ]()
        
        for ( index, show ) in enumerate( shows )
        {
            if index == 0
            {
                continue
            }
            else
            {
                if show.venue == previousShow.venue
                {
                    currentVenue = show.venue
                    multiNightRun.append( show )
                    previousShow = show
                    continue
                }
                else
                {
                    locationDictionary.updateValue( multiNightRun, forKey: currentVenue )
                    multiNightRun.removeAll( keepCapacity: false )
                    previousShow = show
                }
            }
        }
        
        self.locationDictionary = locationDictionary
    }
}
