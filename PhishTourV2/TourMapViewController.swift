//
//  TourMapViewController.swift
//  PhishTour
//
//  Created by Aaron Justman on 9/14/15.
//  Copyright (c) 2015 AaronJ. All rights reserved.
//

import UIKit
import MapKit

class TourMapViewController: UIViewController,
    MKMapViewDelegate, UIPickerViewDataSource, UIPickerViewDelegate
{
    @IBOutlet weak var resetButton: UIBarButtonItem!
    @IBOutlet weak var selectTourButton: UIBarButtonItem!
    @IBOutlet weak var tourMap: MKMapView!
    @IBOutlet weak var blurEffectView: UIVisualEffectView!
    @IBOutlet weak var yearPicker: UIPickerView!
    @IBOutlet weak var seasonPicker: UIPickerView!
    @IBOutlet weak var tourNavControls: UISegmentedControl!
    
    // MARK: actually using these
    var years: [ String ]?
    var selectedYear: String?
    var tours: [ PhishTour ]?
    var selectedTour: PhishTour?
    
    // MARK: everything else
    // var selectedTour: String?
    var geocoder = CLGeocoder()
    var shows: [[ String : AnyObject ]]?
    var coordinates = [ CLLocationCoordinate2D ]()
    var locations = [ String ]()
    
    // var years = [ "Select Year", "2015", "2014", "2013", "2012", "2011", "2010", "2009", "2004", "2003", "2002", "2000", "1999", "1998", "1997", "1996", "1995", "1994", "1993", "1992", "1991", "1990", "1989", "1988", "1987", "1986", "1985", "1984", "1983" ]
    
    var tourSelections = [ ". . ." ]
    // var seasons = [ "Winter", "Spring", "Summer", "Fall" ]
    
    // = "2015"
    
    var selectedSeason: String? // = "winter"
    let tour: String = "tour"
    var tourIDs = [ Int ]()
    var showCoordinates = [ CLLocationCoordinate2D ]()
    // var currentTour = [ ShowAnnotation ]() // TODO: Re-instate?
    let defaultRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(
            latitude: 39.8282,
            longitude: -98.5795
        ),
        span: MKCoordinateSpan(
            latitudeDelta: 25.0,
            longitudeDelta: 25.0
        )
    )
    
    var didDropPins = false
    var didStartTour = false
    
    override func viewDidLoad()
    {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        resetButton.enabled = false
        
        tourNavControls.addTarget(
            self,
            action: "selectTourNavigationOption:",
            forControlEvents: UIControlEvents.ValueChanged
        )
        tourNavControls.setEnabled( false, forSegmentAtIndex: 1 )
        tourNavControls.setEnabled( false, forSegmentAtIndex: 2 )
        tourNavControls.setEnabled( false, forSegmentAtIndex: 3 )
        
        tourMap.delegate = self
        
        yearPicker.dataSource = self
        yearPicker.delegate = self
        seasonPicker.dataSource = self
        seasonPicker.delegate = self
        
        PhishinClient.sharedInstance().requestYears()
        {
            yearsRequestError, years in
            
            if yearsRequestError != nil
            {
                // TODO: use an alert for this
                println( "There was an error requesting the years: \( yearsRequestError.localizedDescription )" )
            }
            else
            {
                self.years = years.reverse()
                self.selectedYear = self.years?.first
                
                dispatch_async( dispatch_get_main_queue() )
                {
                    self.yearPicker.reloadAllComponents()
                }
            }
        }
    }
    
    @IBAction func resetMap( sender: UIBarButtonItem )
    {
        if !blurEffectView.hidden
        {
            showTourPicker( nil )
        }
        
        if !tourNavControls.hidden
        {
            tourNavControls.hidden = true
            resetTourNavControls()
        }
        
        if !tourMap.annotations.isEmpty
        {
            tourMap.removeAnnotations( tourMap.annotations )
            tourMap.removeOverlays( tourMap.overlays )
            showCoordinates.removeAll( keepCapacity: false )
            didDropPins = false
        }
        
        tourMap.setRegion( defaultRegion, animated: true )
        
        resetButton.enabled = false
    }
    
    func resetTourNavControls()
    {
        tourNavControls.setTitle( "Start", forSegmentAtIndex: 0 )
        tourNavControls.setEnabled( false, forSegmentAtIndex: 1 )
        tourNavControls.setEnabled( false, forSegmentAtIndex: 2 )
        tourNavControls.setEnabled( false, forSegmentAtIndex: 3 )
        
        didStartTour = false
    }
    
    func selectTourNavigationOption( sender: UISegmentedControl )
    {
        switch sender.selectedSegmentIndex
        {
            case 0:
                if !didStartTour
                {
                    startTour()
                }
                else
                {
                    println( "Pressed the PreviousShow button." )
                }
                
            case 1:
                println( "Pressed the ZoomOut button." )
                
            case 2:
                println( "Pressed the List button." )
                
            case 3:
                println( "Pressed the NextShow button." )
                
            default:
                println( "I don't know what button was pressed!!!" )
        }
    }
    
    @IBAction func showTourPicker( sender: UIBarButtonItem? )
    {
        blurEffectView.hidden = !blurEffectView.hidden
        
        selectTourButton.title = blurEffectView.hidden ? "Select Tour" : "Cancel"
        selectTourButton.tintColor = blurEffectView.hidden ? UIColor.blueColor() : UIColor.redColor()
        
        if !blurEffectView.hidden
        {
            tourNavControls.hidden = true
        }
        else if blurEffectView.hidden && didDropPins
        {
            tourNavControls.hidden = false
        }
    }
    
    func requestToursForYear( year: Int )
    {
        let yearRequestString = "http://phish.in/api/v1/years/\( year )"
        let yearRequestURL = NSURL( string: yearRequestString )!
        let yearRequestTask = NSURLSession.sharedSession().dataTaskWithURL( yearRequestURL )
        {
            yearData, yearResponse, yearError in
            
            if yearError != nil
            {
                println( "There was an error requesting tours for \( year ): \( yearError.localizedDescription )" )
            }
            else
            {
                var jsonificationError: NSErrorPointer = nil
                if let yearResults = NSJSONSerialization.JSONObjectWithData(
                    yearData,
                    options: nil,
                    error: jsonificationError
                ) as? [ String : AnyObject ]
                {
                    let yearData = yearResults[ "data" ] as! [[ String : AnyObject ]]
                    
                    self.tourIDs.removeAll( keepCapacity: false )
                    self.tourSelections.removeAll( keepCapacity: false )
                    
                    for show in yearData
                    {
                        let tourID = show[ "tour_id" ] as! Int
                        if !contains( self.tourIDs, tourID ) && tourID != 71
                        {
                            self.tourIDs.append( tourID )
                        }
                    }
                    
                    println( "\( self.selectedYear ): \( self.tourIDs )" )
                    
                    for tourID in self.tourIDs
                    {
                        let tourIDRequestString = "http://phish.in/api/v1/tours/\( tourID )"
                        let tourIDRequestURL = NSURL( string: tourIDRequestString )!
                        let tourIDRequestTask = NSURLSession.sharedSession().dataTaskWithURL( tourIDRequestURL )
                        {
                            tourData, tourResponse, tourError in
                            
                            if tourError != nil
                            {
                                println( "There was an error requesting detailed info for tour ID \( tourID )" )
                            }
                            else
                            {
                                if let tourResults = NSJSONSerialization.JSONObjectWithData(
                                    tourData,
                                    options: nil,
                                    error: jsonificationError
                                ) as? [ String : AnyObject ]
                                {
                                    let theTourData = tourResults[ "data" ] as! [ String : AnyObject ]
                                    let tourName = theTourData[ "name" ] as! String
                                    if !contains( self.tourSelections, tourName )
                                    {
                                        self.tourSelections.append( tourName )
                                    }
                                    
                                    dispatch_async( dispatch_get_main_queue() )
                                    {
                                        self.seasonPicker.reloadAllComponents()
                                        if !self.tourIDs.isEmpty
                                        {
                                            // self.selectedTour = self.tourIDs.first
                                        }
                                        
                                    }
                                }
                                else
                                {
                                    println( "There was an error parsing the data for \( year ): \( jsonificationError )" )
                                }
                            }
                        }
                        tourIDRequestTask.resume()
                    }
                }
                else
                {
                    println( "There was an error parsing the data for \( year ): \( jsonificationError )" )
                }
            }
        }
        yearRequestTask.resume()
    }
    
    @IBAction func selectTour( sender: UIButton )
    {
        resetButton.enabled = true
        
        showTourPicker( nil )
        
        if didDropPins
        {
            tourMap.removeAnnotations( tourMap.annotations )
            tourMap.removeOverlays( tourMap.overlays )
            showCoordinates.removeAll( keepCapacity: false )
            
            didDropPins = false
        }
        
        if didStartTour
        {
            tourMap.setRegion( defaultRegion, animated: true )
            
            resetTourNavControls()
            
            didStartTour = false
        }
        
        if let theTour = selectedTour
        {
            let tourRequestURLString = "http://phish.in/api/v1/tours/\( theTour )"
            let tourRequestURL = NSURL( string: tourRequestURLString )!
            let tourRequestTask = NSURLSession.sharedSession().dataTaskWithURL( tourRequestURL )
            {
                tourData, requestResponse, requestError in
                
                if requestError != nil
                {
                    println( "There was an error requesting the tour data." )
                }
                else
                {
                    var jsonificationError: NSErrorPointer = nil
                    if let jsonTourData = NSJSONSerialization.JSONObjectWithData(
                        tourData,
                        options: nil,
                        error: jsonificationError
                    ) as? [ String : AnyObject ]
                    {
                        if let data = jsonTourData[ "data" ] as? [ String : AnyObject ]
                        {
                            let shows = data[ "shows" ] as! [[ String : AnyObject ]]
                            
                            let mapquestBaseURL = "http://www.mapquestapi.com/geocoding/v1/batch?key=sFvGlJbu43uE3lAkJFxj5gEAE1nUpjhM&maxResults=1&thumbMaps=false"
                            var mapquestRequestString = mapquestBaseURL
                            
                            var cities = [ String ]()
                            var dates = [ String ]()
                            var venueNames = [ String ]()
                            for show in shows
                            {
                                var location = show[ "location" ] as! String
                                cities.append( location )
                                
                                location = location.stringByReplacingOccurrencesOfString(" ", withString: "")
                                mapquestRequestString += "&location=\( location )"
                                
                                let date = show[ "date" ] as! String
                                dates.append( date )
                                
                                let venueName = show[ "venue_name" ] as! String
                                venueNames.append( venueName )
                            }
                            
                            let mapquestRequestURL = NSURL( string: mapquestRequestString )!
                            let mapquestGeocodeRequest = NSURLSession.sharedSession().dataTaskWithURL( mapquestRequestURL )
                            {
                                mapquestData, mapquestResponse, mapquestError in
                                
                                if mapquestError != nil
                                {
                                    println( "There was an error geocoding the location with Mapquest." )
                                }
                                else
                                {
                                    if let jsonMapquestData = NSJSONSerialization.JSONObjectWithData(
                                        mapquestData,
                                        options: nil,
                                        error: jsonificationError
                                    ) as? [ String : AnyObject ]
                                    {
                                        let geocodeResults = jsonMapquestData[ "results" ] as! [[ String : AnyObject ]]
                                        
                                        // self.currentTour.removeAll( keepCapacity: false ) // TODO: Re-instate?
                                        var counter = 0
                                        for result in geocodeResults
                                        {
                                            let locations = result[ "locations" ] as! [ AnyObject ]
                                            let innerLocations = locations[ 0 ] as! [ String : AnyObject ]
                                            let latLong = innerLocations[ "latLng" ] as! [ String : Double ]
                                            let geocodedLatitude = latLong[ "lat" ]!
                                            let geocodedLongitude = latLong[ "lng" ]!
                                            
                                            let showCoordinate = CLLocationCoordinate2D(
                                                latitude: geocodedLatitude,
                                                longitude: geocodedLongitude
                                            )
                                            self.showCoordinates.append( showCoordinate )
                                            
                                            // TODO: Re-instate?
                                            /*
                                            let newShowAnnotation = ShowAnnotation(
                                                coordinate: showCoordinate,
                                                city: cities[ counter ],
                                                date: dates[ counter ],
                                                venue: venueNames[ counter ]
                                            )
                                            */
                                            
                                            // self.currentTour.append( newShowAnnotation ) // TODO: Re-instate?
                                            
                                            counter++
                                        }
                                        
                                        dispatch_async( dispatch_get_main_queue() )
                                        {
                                            // self.tourMap.addAnnotations( self.currentTour ) // TODO: Re-instate?
                                            self.makeTourTrail()
                                            self.centerOnFirstShow()
                                            self.tourNavControls.hidden = false
                                        }
                                    }
                                    else
                                    {
                                        println( "There was a problem parsing the geocoding data from mapquest.com" )
                                    }
                                }
                            }
                            mapquestGeocodeRequest.resume()
                            
                            self.didDropPins = true
                        }
                        else
                        {
                            println( "That tour doesn't exist." )
                        }
                    }
                    else
                    {
                        println( "There was a problem parsing the data from phish.in." )
                    }
                }
            }
            tourRequestTask.resume()
        }
        else
        {
            println( "One of the parameters wasn't set." )
        }
    }
    
    func makeTourTrail()
    {
        let tourTrail = MKPolyline(
            coordinates: &showCoordinates,
            count: showCoordinates.count
        )
        
        tourMap.addOverlay( tourTrail )
    }
    
    func centerOnFirstShow()
    {
        let firstShowRegion = MKCoordinateRegion(
            center: showCoordinates.first!,
            span: MKCoordinateSpan(
                latitudeDelta: 20.0,
                longitudeDelta: 20.0
            )
        )
        tourMap.setRegion( firstShowRegion, animated: true )
    }
    
    func startTour()
    {
        tourNavControls.setTitle( "⬅︎", forSegmentAtIndex: 0 )
        tourNavControls.setEnabled( true, forSegmentAtIndex: 1 )
        tourNavControls.setEnabled( true, forSegmentAtIndex: 2 )
        tourNavControls.setEnabled( true, forSegmentAtIndex: 3 )
        
        zoomInOnFirstShow()
        didStartTour = true
    }
    
    func zoomInOnFirstShow()
    {
        let zoomedRegion = MKCoordinateRegion(
            center: showCoordinates.first!,
            span: MKCoordinateSpan(
                latitudeDelta: 0.2,
                longitudeDelta: 0.2
            )
        )
        tourMap.setRegion( zoomedRegion, animated: true )
    }
    
    func mapView(
        mapView: MKMapView!,
        rendererForOverlay overlay: MKOverlay!
    ) -> MKOverlayRenderer!
    {
        let trail = overlay as! MKPolyline
        let trailRenderer = MKPolylineRenderer( polyline: trail )
        
        trailRenderer.strokeColor = UIColor.blueColor()
        trailRenderer.lineWidth = 2
        
        return trailRenderer
    }
    
    func mapView(
        mapView: MKMapView!,
        viewForAnnotation annotation: MKAnnotation!
    ) -> MKAnnotationView!
    {
        // let theAnnotation = annotation as! ShowAnnotation // TODO: Re-instate?
        
        if let reusedAnnotationView = mapView.dequeueReusableAnnotationViewWithIdentifier( "mapPin" ) as? MKPinAnnotationView
        {
            reusedAnnotationView.annotation = annotation
            reusedAnnotationView.animatesDrop = true
            reusedAnnotationView.canShowCallout = true
            
            return reusedAnnotationView
        }
        else
        {
            var newAnnotationView = MKPinAnnotationView(
                annotation: annotation,
                reuseIdentifier: "mapPin"
            )
            newAnnotationView.animatesDrop = true
            newAnnotationView.canShowCallout = true
            
            return newAnnotationView
        }
    }
    
    func numberOfComponentsInPickerView( pickerView: UIPickerView ) -> Int
    {
        switch pickerView.tag
        {
            case 1:
                return 1
            
            case 2:
                return 1
            
            default:
                return 0
        }
    }
    
    func pickerView(
        pickerView: UIPickerView,
        numberOfRowsInComponent component: Int
    ) -> Int
    {
        switch pickerView.tag
        {
            case 1:
                if let theYears = years
                {
                    // return years!.count
                    return theYears.count
                }
                else
                {
                    return 0
                }
            
            case 2:
                // return tourSelections.count
                if let theTours = tours
                {
                    return theTours.count
                }
                else
                {
                    return 0
                }
            
            default:
                return 0
        }
    }
    
    func pickerView(
        pickerView: UIPickerView,
        titleForRow row: Int,
        forComponent component: Int
    ) -> String!
    {
        switch pickerView.tag
        {
            case 1:
                if let theYears = years
                {
                    return theYears[ row ]
                }
                else
                {
                    return ". . ."
                }
            
            case 2:
                // return tourSelections[ row ]
                if let theTours = tours
                {
                    // TODO: FIX
                    /*
                    the problem here is that the row index are 0-n, while the dictionary is keys by the tourID, which is like,
                    91, 97, or 24, etc. i think i should just consruct some Tour objects and then retrieve the names from it.
                    */
                    return theTours[ row ].name
                }
                else
                {
                    return ". . ."
                }
                
            default:
                return ". . ."
        }
    }
    
    func pickerView(
        pickerView: UIPickerView,
        didSelectRow row: Int,
        inComponent component: Int
    )
    {
        switch pickerView.tag
        {
            case 1:
                if let theYear = years?[ row ].toInt()!
                {
                    // requestToursForYear( theYear )
                    PhishinClient.sharedInstance().requestTourInfoForYear( theYear )
                    {
                        tourRequestError, tours in
                        
                        if tourRequestError != nil
                        {
                            // TODO: create an alert for this
                            println( "There was an error requesting the tours for \( theYear ): \( tourRequestError.localizedDescription )" )
                        }
                        else
                        {
                            println( "Finished the request: tours: \( tours )" )
                            self.tours = tours
                            if let firstTour = self.tours?.first!
                            {
                                self.selectedTour = firstTour
                            }
                            
                            
                            dispatch_async( dispatch_get_main_queue() )
                            {
                                println( "Reloading the season picker..." )
                                self.seasonPicker.reloadAllComponents()
                            }
                        }
                    }
                }
                else
                {
                    return
                }
                
            case 2:
                // selectedTour = tourIDs[ row ]
                selectedTour = tours?[ row ]
                
            default:
                selectedYear = nil
                selectedTour = nil
                // selectedSeason = nil
        }
    }
}
