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
    var uniqueLocations: [ PhishShow ]
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
        self.uniqueLocations = [ PhishShow ]()
        self.locationDictionary = [ String : [ PhishShow ] ]()
    }
    
    required init( coder aDecoder: NSCoder )
    {
        // super.init()
        
        self.year = aDecoder.decodeIntegerForKey( "year" )
        self.name = aDecoder.decodeObjectForKey( "name" ) as! String
        self.tourID = aDecoder.decodeIntegerForKey( "tourID" )
        self.shows = aDecoder.decodeObjectForKey( "shows" ) as! [ PhishShow ]
        self.uniqueLocations = aDecoder.decodeObjectForKey( "uniqueLocations" ) as! [ PhishShow ]
        self.locationDictionary = aDecoder.decodeObjectForKey( "locationDictionary" ) as! [ String : [ PhishShow ] ]
    }
    
    func encodeWithCoder( aCoder: NSCoder )
    {
        // TODO: add self. to the properties
        aCoder.encodeInteger( year, forKey: "year" )
        aCoder.encodeObject( name, forKey: "name" )
        aCoder.encodeInteger( tourID, forKey: "tourID" )
        aCoder.encodeObject( shows, forKey: "shows" )
        aCoder.encodeObject( uniqueLocations, forKey: "uniqueLocations" )
        aCoder.encodeObject( locationDictionary, forKey: "locationDictionary" )
    }
    
    // this creates a dictionary keyed a venue name, which retuns an array of shows played there during a tour.
    // this is how i accomplished letting the map know when a callout for an annotation at any one location
    // should display info for more than one show
    func createLocationDictionary()
    {
        println( "There are \( shows.count ) shows in the \( name )" )
        var previousShow: PhishShow = shows.first!
        var currentVenue: String = previousShow.venue
        var multiNightRun = [ PhishShow ]()
        var locationDictionary = [ String : [ PhishShow ] ]()
        
        // go through each show and add the to an array. keep adding shows to the array if the venue continues to be the same.
        // when the next venue is reached, set the array as a value for the key of the venue.
        for ( index, show ) in enumerate( shows )
        {
            // it's possible that there's only one show for the tour
            if shows.count == 1
            {
                uniqueLocations.append( show )
                multiNightRun.append( show )
                
                locationDictionary.updateValue( multiNightRun, forKey: currentVenue )
                
                self.locationDictionary = locationDictionary
                
                return
            }
            
            // add the first show to the array
            if index == 0
            {
                uniqueLocations.append( show )
                multiNightRun.append( show )
                
                continue
            }
            else
            {
                // we're still at the current venue, so it's a multi-night run
                if show.venue == previousShow.venue
                {
                    // add the show and remember where we were
                    currentVenue = show.venue
                    multiNightRun.append( show )
                    previousShow = show
                    
                    // if we're at the last show, then add the array to the dictionary
                    if index == shows.count - 1
                    {
                        locationDictionary.updateValue( multiNightRun, forKey: currentVenue )
                    }
                    
                    continue
                }
                else
                {
                    // there's a new location
                    uniqueLocations.append( show )
                    
                    // add the show(s) to the dictionary
                    locationDictionary.updateValue( multiNightRun, forKey: currentVenue )
                    
                    // blank the current multi-night run array
                    multiNightRun.removeAll( keepCapacity: false )
                    
                    // add the current show to the empty multi-night run array and remember where we were
                    currentVenue = show.venue
                    multiNightRun.append( show )
                    previousShow = show
                }
            }
        }
        
        // set the tour's location dictionary
        self.locationDictionary = locationDictionary
    }
    
    func showListNumberForLocation( location: PhishShow ) -> ( Int, Int )
    {
        let showsAtVenue = locationDictionary[ location.venue ]!
        
        let highlightIndex = find( shows, location )!
        let scrollToIndex = highlightIndex + ( showsAtVenue.count - 1 )
        
        return ( highlightIndex, scrollToIndex )
//        let locationIndex = find( shows, location )!
//        let keys = locationDictionary.keys
//        
//        var showNumber: Int = 0
//        for key in locationDictionary.keys
//        {
//            let shows = locationDictionary[ key ]!
//            
//            showNumber += shows.count
//        }
//        
//        showNumber--
//        
//        return showNumber
    }
}
