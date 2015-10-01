//
//  PhishSong.swift
//  PhishTourV2
//
//  Created by Aaron Justman on 9/30/15.
//  Copyright (c) 2015 AaronJ. All rights reserved.
//

import UIKit

class PhishSong: NSObject
{
    var name: String
    var duration: Float
    var songID: Int
    var show: PhishShow!
    
    init(
        name: String,
        duration: Float,
        songID: Int,
        show: PhishShow
    )
    {
        self.name = name
        self.duration = duration
        self.songID = songID
        self.show = show
    }
}
