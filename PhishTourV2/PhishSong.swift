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
    var duration: Float
    var set: Int
    var songID: Int
    var show: PhishShow!
    
    init(
        songInfo: [ String : AnyObject ],
        forShow show: PhishShow
    )
    {
        self.name = songInfo[ "title" ] as! String
        
        let milliseconds = songInfo[ "duration" ] as! Float
        let seconds = milliseconds / 1000
        self.duration = seconds / 60
        println( "\( name ) duration: \( duration )" )
        
        let setString = songInfo[ "set" ] as! String
        if setString.toInt() != nil
        {
            self.set = setString.toInt()!
        }
        else
        {
            self.set = 3
        }
        // self.set = setString.toInt()!
        
        let songIDs = songInfo[ "song_ids" ] as! [ Int ]
        self.songID = songIDs.first!
        
        self.show = show
    }
    
    required init( coder aDecoder: NSCoder )
    {
        self.name = aDecoder.decodeObjectForKey( "name" ) as! String
        self.duration = aDecoder.decodeFloatForKey( "duration" )
        self.set = aDecoder.decodeIntegerForKey( "set" )
        self.songID = aDecoder.decodeIntegerForKey( "songID" )
        self.show = aDecoder.decodeObjectForKey( "show" ) as! PhishShow
    }
    
    func encodeWithCoder( aCoder: NSCoder )
    {
        aCoder.encodeObject( self.name, forKey: "name" )
        aCoder.encodeFloat( self.duration, forKey: "duration" )
        aCoder.encodeInteger( self.set, forKey: "set" )
        aCoder.encodeInteger( self.songID, forKey: "songID" )
        aCoder.encodeObject( self.show, forKey: "show" )
    }
    
    /*
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
    */
}
