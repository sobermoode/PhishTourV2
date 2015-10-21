//
//  MapquestClient.swift
//  PhishTourV2
//
//  Created by Aaron Justman on 10/4/15.
//  Copyright (c) 2015 AaronJ. All rights reserved.
//

import UIKit

class MapquestClient: NSObject
{
    let session: NSURLSession = NSURLSession.sharedSession()
    
    let mapquestBaseURL: String = "http://www.mapquestapi.com/"
    let apiKey: String = "sFvGlJbu43uE3lAkJFxj5gEAE1nUpjhM"
    
    // NOTE:
    // will add more functionality for other services
    struct Services
    {
        struct Geocoding
        {
            static let GeocodingURL = "geocoding/v1/"
            
            enum GeocodingType: String
            {
                case Address = "address?"
                case Reverse = "reverse?"
                case Batch = "batch?"
            }
            
//            static let Address = "geocoding/v1/address?"
//            static let Reverse = "geocoding/v1/reverse?"
//            static let Batch = "geocoding/v1/batch?"
        }
    }
    
    // NOTE:
    // will add more functionality for other versions
    struct Versions
    {
        static let Version1 = "v1"
    }
    
    // NOTE:
    // will add more functionality for other options
    struct Options
    {
        static let MaxResults = "1"
        static let MapThumbnails = "false"
    }
    
    // let mapquestBaseURL = "http://www.mapquestapi.com/geocoding/v1/batch?" key=sFvGlJbu43uE3lAkJFxj5gEAE1nUpjhM&maxResults=1&thumbMaps=false"
    
    class func sharedInstance() -> MapquestClient
    {
        struct Singleton
        {
            static var sharedInstance = MapquestClient()
        }
        
        return Singleton.sharedInstance
    }
    
    func geocodeShowsForTour(
        var tour: PhishTour,
        withType type: Services.Geocoding.GeocodingType,
        completionHandler: ( geocodingError: NSError!, success: Bool! ) -> Void
    )
    {
        var counter: Int = 0
        for ( index, show ) in enumerate( tour.shows )
        {
            if show.showLatitude != nil && show.showLongitude != nil
            {
                counter++
                
                if counter == tour.shows.count - 1
                {
                    println( "Don't need to geocode the locations!!!" )
                    completionHandler(geocodingError: nil, success: true)
                }
                else
                {
                    continue
                }
            }
            else
            {
                println( "\( show.city ) needs to be geocoded." )
            }
        }
        // construct the request URL;
        // starting with the base
        var mapquestRequestString = mapquestBaseURL + Services.Geocoding.GeocodingURL + type.rawValue
        mapquestRequestString += "key=\( apiKey )"
        mapquestRequestString += "&maxResults=\( Options.MaxResults )&thumbMaps=\( Options.MapThumbnails )"
        
        // append each city to be geocoded onto the URL string
        for show in tour.shows
        {
            // get the city and remove the space
            var location = show.city
            location = location.stringByReplacingOccurrencesOfString(" ", withString: "")
            
            // testing revealed several special cases that need to be dealt with
            location = fixSpecialCities( location )
            
            // append the correct city name
            mapquestRequestString += "&location=\( location )"
        }
        
        // create the URL and start the task
        let mapquestRequestURL = NSURL( string: mapquestRequestString )!
        let mapquestGeocodeRequest = session.dataTaskWithURL( mapquestRequestURL )
        {
            mapquestData, mapquestResponse, mapquestError in
            
            // there was an error geocoding the locations
            if mapquestError != nil
            {
                // println( "There was an error geocoding the location with Mapquest." )
                completionHandler(
                    geocodingError: mapquestError,
                    success: nil
                )
            }
            else
            {
                var mapquestJSONificationError: NSErrorPointer = nil
                if let jsonMapquestData = NSJSONSerialization.JSONObjectWithData(
                    mapquestData,
                    options: nil,
                    error: mapquestJSONificationError
                ) as? [ String : AnyObject ]
                {
                    let geocodeResults = jsonMapquestData[ "results" ] as! [[ String : AnyObject ]]
                    
                    // extract the latitude/longitude coordinates for each location and set the values on each PhishShow object
                    var counter = 0
                    for result in geocodeResults
                    {
                        let currentShow = tour.shows[ counter ]
                        
                        let locations = result[ "locations" ] as! [ AnyObject ]
                        let innerLocations = locations[ 0 ] as! [ String : AnyObject ]
                        let latLong = innerLocations[ "latLng" ] as! [ String : Double ]
                        let geocodedLatitude = latLong[ "lat" ]!
                        let geocodedLongitude = latLong[ "lng" ]!
                        
                        // tour.shows[ counter ].showLatitude = geocodedLatitude
                        // tour.shows[ counter ].showLongitude = geocodedLongitude
                        currentShow.showLatitude = geocodedLatitude
                        currentShow.showLongitude = geocodedLongitude
                        currentShow.save()
                        currentShow.tour?.save()
                        
                        // println( "\( tour.shows[ counter ].city ): \( geocodedLatitude ), \( geocodedLongitude )" )
                        
                        counter++
                    }
                    
                    completionHandler(
                        geocodingError: nil,
                        success: true
                    )
                }
                else
                {
                    println( "There was a problem parsing the geocoding data from mapquest.com" )
                }
            }
        }
        mapquestGeocodeRequest.resume()
    }
    
    func fixSpecialCities( var location: String ) -> String
    {
        switch location
        {
            case "Nüremberg,Germany":
                location = "Nuremberg,Germany"
                
            case "Lyon/Villeurbanne,France":
                location = "Lyon,France"
                
            case "Montréal,Québec,Canada":
                location = "Montreal,Quebec,Canada"
                
            case "Düsseldorf,Germany":
                location = "Dusseldorf,Germany"
                
            case "OrangeBeach,ALUS":
                location = "OrangeBeach,AL"
                
            default:
                break
        }
        
        return location
    }
}
