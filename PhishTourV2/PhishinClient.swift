//
//  PhishinClient.swift
//  PhishTourV2
//
//  Created by Aaron Justman on 9/30/15.
//  Copyright (c) 2015 AaronJ. All rights reserved.
//

import UIKit

class PhishinClient: NSObject
{
    let session: NSURLSession = NSURLSession.sharedSession()
    // let fileManager: NSFileManager = NSFileManager.defaultManager()
//    let documentsPath = NSSearchPathForDirectoriesInDomains(
//        .DocumentDirectory,
//        .UserDomainMask,
//        true
//    )[ 0 ] as! String
    
    // to construct request URLs
    let endpoint: String = "http://phish.in/api/v1"
    struct Routes
    {
        static let Years = "/years"
        static let Tours = "/tours"
        static let Shows = "/shows"
        static let Songs = "/songs"
    }
    
    // phish has played a bunch of one-off shows that aren't part of any formal tour. phish.in gives all those shows the tour id 71.
    // i use it as a flag to prevent "not part of a tour" from appearing in the tour picker
    let notPartOfATour: Int = 71
    
    class func sharedInstance() -> PhishinClient
    {
        struct Singleton
        {
            static var sharedInstance = PhishinClient()
        }
        
        return Singleton.sharedInstance
    }
    
    func requestYears( completionHandler: ( yearsRequestError: NSError!, years: [ Int ]? ) -> Void )
    {
        let documentsPath = NSSearchPathForDirectoriesInDomains(
            .DocumentDirectory,
            .UserDomainMask,
            true
        )[ 0 ] as! String
        let phishYearsFilePath = documentsPath.stringByAppendingPathComponent( "phishYears.plist" )
        
        if let savedPhishYears = NSKeyedUnarchiver.unarchiveObjectWithFile( phishYearsFilePath ) as? [ PhishYear ]
        {
            println( "Got the saved phishYears!!!" )
            var intPhishYears = [ Int ]()
            for phishYear in savedPhishYears
            {
                intPhishYears.append( phishYear.year )
            }
            
            completionHandler(yearsRequestError: nil, years: intPhishYears)
        }
        else
        {
            println( "Requesting new phishYears..." )
        
            // create the URL and start the task
            let yearsRequestString = endpoint + Routes.Years
            let yearsRequestURL = NSURL( string: yearsRequestString )!
            let yearsRequestTask = session.dataTaskWithURL( yearsRequestURL )
            {
                yearsData, yearsResponse, yearsError in
                
                if yearsError != nil
                {
                    completionHandler(
                        yearsRequestError: yearsError,
                        years: nil
                    )
                }
                else
                {
                    var yearsJSONificationError: NSErrorPointer = nil
                    if let yearsResults = NSJSONSerialization.JSONObjectWithData(
                        yearsData,
                        options: nil,
                        error: yearsJSONificationError
                    ) as? [ String : AnyObject ]
                    {
                        // all three shows from 2002 are "category 71," so i'm removing from 2002 from the list of searchable years;
                        // this requires creating a mutable NSArray, removing the specified year, and then casting it back to a [ String ] array
                        let theYears = yearsResults[ "data" ] as! NSArray
                        
                        let theYearsMutable: AnyObject = theYears.mutableCopy()
                        theYearsMutable.removeObjectAtIndex( 14 )
                        
                        let years = NSArray( array: theYearsMutable as! [ AnyObject ] ) as! [ String ]
                        
                        // years.reverse()
                        
                        var intYears = [ Int ]()
                        var phishYears = [ PhishYear ]()
                        for year in years
                        {
                            println( "year: \( year )" )
                            if let intYear = year.toInt()
                            {
                                intYears.append( intYear )
                            
                                let newYear = PhishYear( year: intYear )
                                newYear.save()
                                
                                phishYears.append( newYear )
                            }
                        }
                        
                        // let phishYearsFilePath = documentsPath.stringByAppendingPathComponent( "phishYears.year" )
                        if NSKeyedArchiver.archiveRootObject( phishYears, toFile: phishYearsFilePath )
                        {
                            // break
                        }
                        else
                        {
                            println( "There was an error saving the phishYears to the device." )
                        }
                        
                        // send it back through the completion handler
                        completionHandler(
                            yearsRequestError: nil,
                            years: intYears
                        )
                    }
                    else
                    {
                        println( "There was a problem processing the years results: \( yearsJSONificationError )" )
                    }
                }
            }
            yearsRequestTask.resume()
        }
        
    }
    
    // this request has two parts:
    // the first request returns all the shows played in that year and creates arrays for each set of shows in a particular tour,
    // the second request gets a name for each unique tour ID,
    // once all the tour info is collected, a [ PhishTour ] array is returned through the completion handler
    func requestToursForYear(
        year: Int,
        completionHandler: ( toursRequestError: NSError!, tours: [ PhishTour ]! ) -> Void
    )
    {
        // let yearFilePath = documentsPath + "\( year )"
        // println( "Attempting to get saved year at \( yearFilePath )" )
        let documentsPath = NSSearchPathForDirectoriesInDomains(
            .DocumentDirectory,
            .UserDomainMask,
            true
        )[ 0 ] as! String
        let yearFilePath = documentsPath.stringByAppendingPathComponent( "year\( year ).plist" )
        
        if let savedYear = NSKeyedUnarchiver.unarchiveObjectWithFile( yearFilePath ) as? PhishYear // where savedYear.tours != nil
        {
            println( "Got a saved year: \( savedYear.year )" )
            
            if savedYear.tours != nil
            {
                println( "\( savedYear.year ) already had tours!!!" )
                completionHandler(toursRequestError: nil, tours: savedYear.tours)
            }
            else
            {
                println( "\( savedYear.year ) didn't have tours, requesting..." )
                let toursRequestString = endpoint + Routes.Years + "/\( year )"
                let toursRequestURL = NSURL( string: toursRequestString )!
                let toursRequestTask = session.dataTaskWithURL( toursRequestURL )
                {
                    toursData, toursResponse, toursError in
                    
                    if toursError != nil
                    {
                        completionHandler(
                            toursRequestError: toursError,
                            tours: nil
                        )
                    }
                    else
                    {
                        var toursJSONificationError: NSErrorPointer = nil
                        if let toursResults = NSJSONSerialization.JSONObjectWithData(
                            toursData,
                            options: nil,
                            error: toursJSONificationError
                            ) as? [ String : AnyObject ]
                        {
                            let showsForTheYear = toursResults[ "data" ] as! [[ String : AnyObject ]]
                            
                            var tourIDs = [ Int ]()
                            var showsForID = [ Int : [ PhishShow ] ]()
                            var shows = [ PhishShow ]()
                            for show in showsForTheYear
                            {
                                let newShow = PhishShow( showInfo: show, andYear: year )
                                // newShow.updateShowDictionary()
                                newShow.save()
                                
                                let tourID = show[ "tour_id" ] as! Int
                                if !contains( tourIDs, tourID ) && tourID != self.notPartOfATour
                                {
                                    tourIDs.append( tourID )
                                    showsForID.updateValue( [ PhishShow ](), forKey: tourID )
                                }
                                
                                showsForID[ tourID ]?.append( newShow )
                            }
                            
                            self.requestTourNamesForIDs( tourIDs, year: savedYear, showsForID: showsForID )
                            {
                                tourNamesRequestError, tours in
                                
                                if tourNamesRequestError != nil
                                {
                                    completionHandler(toursRequestError: tourNamesRequestError, tours: nil)
                                }
                                else
                                {
                                    completionHandler(toursRequestError: nil, tours: tours)
                                }
                            }
                        }
                        else
                        {
                            println( "There was a problem processing the tours results: \( toursJSONificationError )" )
                        }
                    }
                }
                toursRequestTask.resume()
            }
        }
        /*
        else
        {
            let toursRequestString = endpoint + Routes.Years + "/\( year )"
            let toursRequestURL = NSURL( string: toursRequestString )!
            let toursRequestTask = session.dataTaskWithURL( toursRequestURL )
            {
                toursData, toursResponse, toursError in
                
                if toursError != nil
                {
                    completionHandler(
                        toursRequestError: toursError,
                        tours: nil
                    )
                }
                else
                {
                    var toursJSONificationError: NSErrorPointer = nil
                    if let toursResults = NSJSONSerialization.JSONObjectWithData(
                        toursData,
                        options: nil,
                        error: toursJSONificationError
                    ) as? [ String : AnyObject ]
                    {
                        let showsForTheYear = toursResults[ "data" ] as! [[ String : AnyObject ]]
                        
                        var tourIDs = [ Int ]()
                        var showsForID = [ Int : [ PhishShow ] ]()
                        var shows = [ PhishShow ]()
                        for show in showsForTheYear
                        {
                            let newShow = PhishShow( showInfo: show, andYear: year )
                            // newShow.updateShowDictionary()
                            newShow.save()
                            
                            let tourID = show[ "tour_id" ] as! Int
                            if !contains( tourIDs, tourID ) && tourID != self.notPartOfATour
                            {
                                tourIDs.append( tourID )
                                showsForID.updateValue( [ PhishShow ](), forKey: tourID )
                            }
                            
                            showsForID[ tourID ]?.append( newShow )
                        }
                        
                        self.requestTourNamesForIDs( tourIDs, year: year, showsForID: showsForID )
                        {
                            tourNamesRequestError, tours in
                            
                            if tourNamesRequestError != nil
                            {
                                completionHandler(toursRequestError: tourNamesRequestError, tours: nil)
                            }
                            else
                            {
                                completionHandler(toursRequestError: nil, tours: tours)
                            }
                        }
                    }
                    else
                    {
                        println( "There was a problem processing the tours results: \( toursJSONificationError )" )
                    }
                }
            }
            toursRequestTask.resume()
        }
        */
    }
    
    func requestToursForYears(
        years: [ Int ],
        completionHandler: ( toursRequestError: NSError!, tours: [ PhishTour ]! ) -> Void
    )
    {
        // println( "requestToursForYears..." )
        var allTours = [ PhishTour ]()
        
        for year in years
        {
            requestToursForYear( year )
            {
                toursRequestError, tours in
                
                if toursRequestError != nil
                {
                    completionHandler(toursRequestError: toursRequestError, tours: nil)
                }
                else
                {
                    println( "Got tour \( tours )" )
                    allTours += tours
                }
            }
        }
        
        do
        {
            if allTours.count < 5
            {
                continue
            }
            else
            {
                completionHandler(toursRequestError: nil, tours: allTours)
            }
        }
        while allTours.count < 5
        
        // completionHandler(toursRequestError: nil, tours: allTours)
    }
    
    func requestTourNamesForIDs(
        tourIDs: [ Int ],
        // year: Int,
        year: PhishYear,
        showsForID: [ Int : [ PhishShow ] ],
        completionHandler: ( tourNamesRequestError: NSError!, tours: [ PhishTour ]! ) -> Void
    )
    {
        // var tourInfo = [ Int : String ]()
        println( "Requesting tour names for tours in \( year.year )" )
        var tours = [ PhishTour ]()
        
        for tourID in tourIDs
        {
            // println( "requestTourNameForID: \( tourID )" )
            // var tourNames = [ String ]()
            let tourIDRequestString = endpoint + Routes.Tours + "/\( tourID )"
            // println( tourIDRequestString )
            let tourIDRequestURL = NSURL( string: tourIDRequestString )!
            let tourIDRequestTask = session.dataTaskWithURL( tourIDRequestURL )
            {
                tourData, tourResponse, tourError in
                
                if tourError != nil
                {
                    // println( tourError )
                    completionHandler(
                        tourNamesRequestError: tourError,
                        tours: nil
                    )
                }
                else
                {
                    // println( "got this far..." )
                    var tourJSONificationError: NSErrorPointer = nil
                    if let tourResults = NSJSONSerialization.JSONObjectWithData(
                        tourData,
                        options: nil,
                        error: tourJSONificationError
                    ) as? [ String : AnyObject ]
                    {
                        let theTourData = tourResults[ "data" ] as! [ String : AnyObject ]
                        let tourName = theTourData[ "name" ] as! String
                        // println( "tourName: \( tourName )" )
                        /*
                        if !contains( tourNames, tourName )
                        {
                            tourNames.append( tourName )
                        }
                        */
                        
                        /*
                        completionHandler(
                            tourNameRequestError: nil,
                            tourName: tourName
                        )
                        */
                        // tourInfo.updateValue(tourName, forKey: tourID)
                        // let newTour = PhishTour(year: year, name: tourName, tourID: tourID, shows: shows)
                        let newTour = PhishTour(year: year, name: tourName, tourID: tourID, shows: showsForID[ tourID ]! )
                        newTour.associateShows()
                        newTour.createLocationDictionary()
                        newTour.save()
                        // year.save()
                        // println( "newTour.locationDictionary: \( newTour.locationDictionary )" )
                        tours.append( newTour )
//                        tours.append( PhishTour(
//                            year: year,
//                            name: tourName,
//                            tourID: tourID,
//                            shows: showsForID[ tourID ]! )
//                        )
                        
                        // self.saveTour( newTour )
                    }
                    else
                    {
                        println( "There was a problem processing the results for tour \( tourID ): \( tourJSONificationError )" )
                    }
                }
                
                tours.sort()
                {
                    tour1, tour2 in
                    
                    tour1.tourID < tour2.tourID
                }
                
                year.tours = tours
                year.save()
                
                // let newYear = PhishYear( year: year, tours: tours)
                // newYear.save()
                // self.saveYearWithTours( newYear, tours: tours )
                
                completionHandler(tourNamesRequestError: nil, tours: tours)
            }
            tourIDRequestTask.resume()
        }
    }
    
    // will request a setlist for a given show and return the result by completion handler
    func requestSetlistForShow(
        show: PhishShow,
        completionHandler: ( setlistError: NSError?, setlist: [ Int : [ PhishSong ] ]? ) -> Void
    )
    {
        println( "requestSetlistForShow..." )
        // check for a saved setlist file
        if let savedShow = NSKeyedUnarchiver.unarchiveObjectWithFile( show.showPath ) as? PhishShow where savedShow.setlist != nil
        {
            // return the saved setlist through the completion handler
            completionHandler(
                setlistError: nil,
                setlist: savedShow.setlist
            )
        }
        // no saved setlist, we need to request one
        else
        {
            // construct a URL to the setlist and start a task
            let setlistRequestString = endpoint + Routes.Shows + "/\( show.showID )"
            let setlistRequestURL = NSURL( string: setlistRequestString )!
            let setlistRequestTask = session.dataTaskWithURL( setlistRequestURL )
            {
                setlistData, setlistResponse, setlistError in
                
                // an error occurred
                if setlistError != nil
                {
                    completionHandler(
                        setlistError: setlistError,
                        setlist: nil
                    )
                }
                else
                {
                    // turn the received data into a JSON object
                    var setlistJSONificationError: NSErrorPointer = nil
                    if let setlistResults = NSJSONSerialization.JSONObjectWithData(
                        setlistData,
                        options: nil,
                        error: setlistJSONificationError
                    ) as? [ String : AnyObject ]
                    {
                        // get the songs
                        let resultsData = setlistResults[ "data" ] as! [ String : AnyObject ]
                        let tracks = resultsData[ "tracks" ] as! [[ String : AnyObject ]]
                        
                        // create the setlist by creating new PhishSong objects for each song
                        var set = [ PhishSong ]()
                        var setlist = [ Int : [ PhishSong ] ]()
                        var currentSet: Int = 1                        
                        var previousTrackSet = currentSet
                        for ( index, track ) in enumerate( tracks )
                        {
                            // the set comes back as a string;
                            // need to turn it into an int
                            var currentTrackSet: Int
                            var currentTrackSetString = track[ "set" ] as! String
                            if let theTrackSet = currentTrackSetString.toInt()
                            {
                                currentTrackSet = theTrackSet
                            }
                            else
                            {
                                // the encore comes back as "E";
                                // using 10 to avoid potential trouble with some kind of epic fifth-set madness
                                currentTrackSet = 10
                            }
                            
                            // we're still in the same set, so add a new song to the set array
                            if currentTrackSet == previousTrackSet
                            {
                                let newSong = PhishSong( songInfo: track, forShow: show )
                                set.append( newSong )
                                previousTrackSet = newSong.set
                                
                                // update the setlist if we're at the last song
                                if index == tracks.count - 1
                                {
                                    setlist.updateValue( set, forKey: currentSet )
                                }
                                
                                continue
                            }
                            // we got to the start of the next set or encore
                            else
                            {
                                // update the setlist with the previous complete set
                                setlist.updateValue( set, forKey: currentSet )
                                
                                // create a new song with the current track
                                let newSong = PhishSong( songInfo: track, forShow: show )
                                
                                // update the current set
                                currentSet = newSong.set
                                
                                // blank the set array, so we can start over with a new set
                                // and add that first song to it
                                set.removeAll( keepCapacity: false )
                                set.append( newSong )
                                
                                // update the setlist if we're at the last song
                                if index == tracks.count - 1
                                {
                                    setlist.updateValue( set, forKey: currentSet )
                                }
                                // otherwise, remember which set we're in
                                else
                                {
                                    previousTrackSet = newSong.set
                                }
                            }
                        }
                        
                        // set the show's setlist and save the setlist to the device for later retrieval
                        // TODO: when implementing Core Data, save the context here
                        show.setlist = setlist
                        show.save()
                        show.tour?.save()
                        
                        // return the setlist through the completion handler
                        completionHandler(
                            setlistError: nil,
                            setlist: setlist
                        )
                    }
                    else
                    {
                        println( "There was an error parsing the setlist data for \( show.date ) \( show.year )" )
                    }
                }
            }
            setlistRequestTask.resume()
         }
    }
    
    func requestHistoryForSong(
        song: PhishSong,
        completionHandler: ( songHistoryError: NSError?, history: [ Int ]? ) -> Void
    )
    {
        // check for a saved song history
        if let savedSong = NSKeyedUnarchiver.unarchiveObjectWithFile( song.songPath ) as? PhishSong where savedSong.history != nil
        {
            // return the saved history through the completion handler
            completionHandler(
                songHistoryError: nil,
                history: savedSong.history
            )
        }
        // no saved history, we need to request one
        else
        {
            // construct the request URL and start a task
            let songHistoryRequestString = endpoint + Routes.Songs + "/\( song.songID )"
            let songHistoryRequestURL = NSURL( string: songHistoryRequestString )!
            let songHistoryRequestTask = session.dataTaskWithURL( songHistoryRequestURL )
            {
                songHistoryData, songHistoryResponse, songHistoryError in
                
                // an error occurred
                if songHistoryError != nil
                {
                    completionHandler(
                        songHistoryError: songHistoryError,
                        history: nil
                    )
                }
                else
                {
                    // turn the received data into a JSON object
                    var songHistoryJSONificationError: NSErrorPointer = nil
                    if let songHistoryResults = NSJSONSerialization.JSONObjectWithData(
                        songHistoryData,
                        options: nil,
                        error: songHistoryJSONificationError
                    ) as? [ String : AnyObject ]
                    {
                        // get the info for every instance of the song being played
                        let resultsData = songHistoryResults[ "data" ] as! [ String : AnyObject ]
                        let tracks = resultsData[ "tracks" ] as! [[ String : AnyObject ]]
                        
                        // save the show id of all the shows where the song was played
                        var showIDs = [ Int ]()
                        for track in tracks
                        {
                            let showID = track[ "show_id" ] as! Int
                            
                            showIDs.append( showID )
                        }
                        
                        // set the song's history and save it to the device
                        song.history = showIDs
                        song.save()
                        song.show.save()
                        song.show.tour?.save()
                        
                        // return the history through the completion handler
                        completionHandler(
                            songHistoryError: nil,
                            history: showIDs
                        )
                    }
                    else
                    {
                        println( "There was a problem parsing the song history results." )
                    }
                }
            }
            songHistoryRequestTask.resume()
        }
    }
    
    /*
    func saveTour( tour: PhishTour )
    {
        let documentsPath = NSSearchPathForDirectoriesInDomains(
            .DocumentDirectory,
            .UserDomainMask,
            true
        )[ 0 ] as! String
        let tourPath = documentsPath + tour.filePath
        println( "tourPath: \( tourPath )" )
        
        if NSKeyedArchiver.archiveRootObject(tour, toFile: tourPath)
        {
            return
        }
        else
        {
            println( "There was an error saving the tour to the device." )
        }
    }
    */
    
    func saveYearWithTours( year: PhishYear, tours: [ PhishTour ] )
    {
        // TODO: use the var, as below
        let documentsPath = NSSearchPathForDirectoriesInDomains(
            .DocumentDirectory,
            .UserDomainMask,
            true
        )[ 0 ] as! String
        let yearPath = documentsPath + "\( year.year )"
        // println( "yearPath: \( yearPath )" )
        
        if NSKeyedArchiver.archiveRootObject( year, toFile: yearPath )
        {
            // println( "Writing a new file..." )
            return
        }
        else
        {
            println( "There was an error saving the tour to the device." )
        }
    }
}
