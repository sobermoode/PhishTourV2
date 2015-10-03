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
    MKAnnotation
{
    var date: String
    var year: Int
    var venue: String
    var city: String
    var showID: Int
    var tour: PhishTour!
    var setlist: [ PhishSong ]!
    
    var showLatitude, showLongitude: Double!
    var coordinate: CLLocationCoordinate2D
    {
        return CLLocationCoordinate2D(
            latitude: showLatitude,
            longitude: showLongitude
        )
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
        self.venue = showInfo[ "venue" ] as! String
        self.city = showInfo[ "city" ] as! String
        self.showID = showInfo[ "showID" ] as! Int
    }
}
