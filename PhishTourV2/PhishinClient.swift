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
    let fileManager: NSFileManager = NSFileManager.defaultManager()
    
    let endpoint: String = "http://phish.in/api/v1"
    let notPartOfATour: Int = 71
    
    struct Routes
    {
        static let Years = "/years"
        static let Tours = "/tours"
    }
    
    class func sharedInstance() -> PhishinClient
    {
        struct Singleton
        {
            static var sharedInstance = PhishinClient()
        }
        
        return Singleton.sharedInstance
    }
    
    func requestYears( completionHandler: ( yearsRequestError: NSError!, years: [ String ]! ) -> Void )
    {
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
                    let theYears = yearsResults[ "data" ] as! [ String ]
                    
                    completionHandler(
                        yearsRequestError: nil,
                        years: theYears
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
    
    func requestTourInfoForYear(
        year: Int,
        completionHandler: ( toursRequestError: NSError!, tours: [ PhishTour ]! ) -> Void
    )
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
                    
                    // self.tourIDs.removeAll( keepCapacity: false )
                    // self.tourSelections.removeAll( keepCapacity: false )
                    
                    var tourIDs = [ Int ]()
                    var tourInfo = [ Int : String ]()
                    for show in showsForTheYear
                    {
                        let tourID = show[ "tour_id" ] as! Int
                        if !contains( tourIDs, tourID ) && tourID != self.notPartOfATour
                        {
                            tourIDs.append( tourID )
                            /*
                            self.requestTourNameForID( tourID )
                            {
                                tourNameRequestError, tourName in
                                
                                if tourNameRequestError != nil
                                {
                                    completionHandler(
                                        toursRequestError: tourNameRequestError,
                                        tourInfo: nil
                                    )
                                }
                                else
                                {
                                    println( "tourID \( tourID ): \( tourName )" )
                                    tourInfo.updateValue( tourName, forKey: tourID )
                                }
                            }
                            */
                        }
                    }
                    
                    self.requestTourNamesForIDs( tourIDs, year: year )
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
                    
                    /*
                    completionHandler(
                        toursRequestError: nil,
                        tourInfo: tourInfo
                    )
                    */
                    
                    /*
                    self.requestToursForTourIDs( tourIDs )
                    {
                        tourIDRequestError, tourNames in
                        
                        if tourIDRequestError != nil
                        {
                            completionHandler(
                                toursRequestError: tourIDRequestError,
                                tourInfo: nil
                            )
                        }
                        else
                        {
                            completionHandler(
                                toursRequestError: nil,
                                tours: tourNames
                            )
                        }
                    }
                    */
                }
                else
                {
                    println( "There was a problem processing the tours results: \( toursJSONificationError )" )
                }
            }
        }
        toursRequestTask.resume()
    }
    
    func requestTourNamesForIDs(
        tourIDs: [ Int ],
        year: Int,
        completionHandler: ( tourNamesRequestError: NSError!, tours: [ PhishTour ]! ) -> Void
    )
    {
        // var tourInfo = [ Int : String ]()
        var tours = [ PhishTour ]()
        
        for tourID in tourIDs
        {
            println( "requestTourNameForID: \( tourID )" )
            // var tourNames = [ String ]()
            let tourIDRequestString = endpoint + Routes.Tours + "/\( tourID )"
            println( tourIDRequestString )
            let tourIDRequestURL = NSURL( string: tourIDRequestString )!
            let tourIDRequestTask = session.dataTaskWithURL( tourIDRequestURL )
            {
                tourData, tourResponse, tourError in
                
                if tourError != nil
                {
                    println( tourError )
                    completionHandler(
                        tourNamesRequestError: tourError,
                        tours: nil
                    )
                }
                else
                {
                    println( "got this far..." )
                    var tourJSONificationError: NSErrorPointer = nil
                    if let tourResults = NSJSONSerialization.JSONObjectWithData(
                        tourData,
                        options: nil,
                        error: tourJSONificationError
                    ) as? [ String : AnyObject ]
                    {
                        let theTourData = tourResults[ "data" ] as! [ String : AnyObject ]
                        let tourName = theTourData[ "name" ] as! String
                        println( "tourName: \( tourName )" )
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
                        let newTour = PhishTour(year: year, name: tourName, tourID: tourID)
                        tours.append( newTour )
                        self.saveTour( newTour )
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
                
                completionHandler(tourNamesRequestError: nil, tours: tours)
            }
            tourIDRequestTask.resume()
        }
    }
    
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
}
