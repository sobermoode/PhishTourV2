//
//  PhishSong.swift
//  PhishTourV2
//
//  Created by Aaron Justman on 9/30/15.
//  Copyright (c) 2015 AaronJ. All rights reserved.
//

import UIKit

class PhishSong: NSObject,
    NSCoding
{
    var name: String
    var duration: String
    var set: Int
    var songID: Int
    var show: PhishShow!
    
    init(
        songInfo: [ String : AnyObject ],
        forShow show: PhishShow
    )
    {
        self.name = songInfo[ "title" ] as! String
        
        // create a nicely formatted mm:ss string out of an amount of milliseconds
        let milliseconds = songInfo[ "duration" ] as! Float
        let seconds = milliseconds / 1000
        let minutes = seconds / 60
        let finalMinutes = Int( minutes )
        let remainder = minutes - Float( finalMinutes )
        let finalSeconds = Int( ceil( remainder * 60 ) )
        let finalSecondsString = ( finalSeconds < 10 ) ? "0\( finalSeconds ) " : "\( finalSeconds ) "
        self.duration = "\( finalMinutes ):" + finalSecondsString
        
        let setString = songInfo[ "set" ] as! String
        if setString.toInt() != nil
        {
            // the set is either 1, 2, 3, etc., or "E" for the encore
            self.set = setString.toInt()!
        }
        else
        {
            // for the encore;
            // we'll just make sure we don't run into a problem with a valid uber-late fifth set, or something
            self.set = 10
        }
        
        // some songs have more than one ID...
        // (i dunno, the property comes back as an array)
        let songIDs = songInfo[ "song_ids" ] as! [ Int ]
        self.songID = songIDs.first!
        
        self.show = show
    }
    
    required init( coder aDecoder: NSCoder )
    {
        self.name = aDecoder.decodeObjectForKey( "name" ) as! String
        self.duration = aDecoder.decodeObjectForKey( "duration" ) as! String
        self.set = aDecoder.decodeIntegerForKey( "set" )
        self.songID = aDecoder.decodeIntegerForKey( "songID" )
        self.show = aDecoder.decodeObjectForKey( "show" ) as! PhishShow
    }
    
    func encodeWithCoder( aCoder: NSCoder )
    {
        aCoder.encodeObject( self.name, forKey: "name" )
        aCoder.encodeObject( self.duration, forKey: "duration" )
        aCoder.encodeInteger( self.set, forKey: "set" )
        aCoder.encodeInteger( self.songID, forKey: "songID" )
        aCoder.encodeObject( self.show, forKey: "show" )
    }
}
