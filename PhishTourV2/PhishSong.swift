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
    var history: [ Int ]!
    
    static let documentsPath = NSSearchPathForDirectoriesInDomains(
        .DocumentDirectory,
        .UserDomainMask,
        true
        )[ 0 ] as! String
    // var setlistPath: String
    var songPath: String
    
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
        let finalSeconds = Int( floor( remainder * 60 ) )
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
            // using 10 to avoid potential trouble with some kind of epic fifth-set madness
            self.set = 10
        }
        
        // some songs have more than one ID...
        // (i dunno, the property comes back as an array)
        let songIDs = songInfo[ "song_ids" ] as! [ Int ]
        self.songID = songIDs.first!
        
        self.show = show
        
        self.songPath = PhishSong.documentsPath.stringByAppendingPathComponent( "song\( self.songID )" )
    }
    
    required init( coder aDecoder: NSCoder )
    {
        self.name = aDecoder.decodeObjectForKey( "name" ) as! String
        self.duration = aDecoder.decodeObjectForKey( "duration" ) as! String
        self.set = aDecoder.decodeIntegerForKey( "set" )
        self.songID = aDecoder.decodeIntegerForKey( "songID" )
        self.show = aDecoder.decodeObjectForKey( "show" ) as! PhishShow
        self.songPath = aDecoder.decodeObjectForKey( "songPath" ) as! String
    }
    
    func encodeWithCoder( aCoder: NSCoder )
    {
        aCoder.encodeObject( self.name, forKey: "name" )
        aCoder.encodeObject( self.duration, forKey: "duration" )
        aCoder.encodeInteger( self.set, forKey: "set" )
        aCoder.encodeInteger( self.songID, forKey: "songID" )
        aCoder.encodeObject( self.show, forKey: "show" )
        aCoder.encodeObject( self.songPath, forKey: "songPath" )
    }
    
    func save()
    {
        println( "Saving song: \( self.name ) to \( self.songPath )" )
        
        if NSFileManager.defaultManager().fileExistsAtPath( self.songPath )
        {
            println( "Show file already exists at \( self.songPath )." )
            
            if NSKeyedArchiver.archiveRootObject( self, toFile: self.songPath )
            {
                // return
                println( "Replaced \( self.name )." )
            }
            else
            {
                println( "There was an error replacing \( self.name )." )
            }
        }
        else
        {
            if NSKeyedArchiver.archiveRootObject( self, toFile: self.songPath )
            {
                return
            }
            else
            {
                println( "There was an error saving \( self.name ) to the device." )
            }
        }
    }
}
