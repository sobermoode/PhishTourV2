//
//  PhishTour.swift
//  PhishTourV2
//
//  Created by Aaron Justman on 9/30/15.
//  Copyright (c) 2015 AaronJ. All rights reserved.
//

import UIKit

class PhishTour: NSObject
{
    var year: Int
    var name: String
    var tourID: Int
    var shows: [ PhishShow ]!
    
    init(
        year: Int,
        name: String,
        tourID: Int
    )
    {
        self.year = year
        self.name = name
        self.tourID = tourID
    }
}
