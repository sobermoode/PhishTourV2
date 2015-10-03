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
    var tour: PhishTour!  // not set yet; need to do it in the PhishTour init
    var setlist: [ PhishSong ]!
    
    var showLatitude, showLongitude: Double!
    var coordinate: CLLocationCoordinate2D
    {
        return CLLocationCoordinate2D(
            latitude: showLatitude,
            longitude: showLongitude
        )
    }
    var title: String
    {
        return date
    }
    var subtitle: String
    {
        return "\( venue )  --  \( city )"
    }
    
    init(
        date: String,
        year: Int,
        venue: String,
        city: String,
        showID: Int
    )
    {
        self.date = date
        self.year = year
        self.venue = venue
        self.city = city
        self.showID = showID
        // self.tour = tour
    }
    
    init( showInfo: [ String : AnyObject ], andYear year: Int )
    {
        self.date = showInfo[ "date" ] as! String
        self.year = year
        self.venue = showInfo[ "venue_name" ] as! String
        self.city = showInfo[ "location" ] as! String
        self.showID = showInfo[ "id" ] as! Int
    }
    
    required init( coder aDecoder: NSCoder )
    {
        self.date = aDecoder.decodeObjectForKey( "date" ) as! String
        self.year = aDecoder.decodeIntegerForKey( "year" )
        self.venue = aDecoder.decodeObjectForKey( "venue" ) as! String
        self.city = aDecoder.decodeObjectForKey( "city" ) as! String
        self.showID = aDecoder.decodeIntegerForKey( "showID" )
    }
    
    func encodeWithCoder( aCoder: NSCoder )
    {
        aCoder.encodeObject( self.date, forKey: "date" )
        aCoder.encodeInteger( self.year, forKey: "year" )
        aCoder.encodeObject( self.venue, forKey: "venue" )
        aCoder.encodeObject( self.city, forKey: "city" )
        aCoder.encodeInteger( self.showID, forKey: "showID" )
    }
}
