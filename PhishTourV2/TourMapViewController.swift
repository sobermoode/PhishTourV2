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
    var firstTime: Bool = true
    var years: [ String ]?
    var selectedYear: String?
    var tours: [ PhishTour ]?
    var selectedTour: PhishTour?
    var didDropPins: Bool = false
    var isZoomedOut: Bool = true
    var didStartTour: Bool = false
    
    // MARK: everything else
    // var selectedTour: String?
    // var geocoder = CLGeocoder()
    // var showCoordinates = [ CLLocationCoordinate2D ]()
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
    // var currentTour = [ ShowAnnotation ]() // TODO: Re-instate?
    let defaultRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(
            latitude: 39.8282,
            longitude: -98.5795
        ),
        span: MKCoordinateSpan(
            latitudeDelta: 35.0,
            longitudeDelta: 35.0
        )
    )
    
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
            // showCoordinates.removeAll( keepCapacity: false )
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
        
        if firstTime
        {
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
                    
                    PhishinClient.sharedInstance().requestToursForYear( self.selectedYear!.toInt()! )
                    {
                        tourRequestError, tours in
                        
                        if tourRequestError != nil
                        {
                            println( "There was an error requesting the tours for \( self.selectedYear! ): \( tourRequestError.localizedDescription )" )
                        }
                        else
                        {
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
            }
            
            firstTime = false
        }
        
        
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
            // showCoordinates.removeAll( keepCapacity: false )
            
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
            // at this point i should already have all the shows for a tour in the PhishTour object
            let shows = theTour.shows
            
            let mapquestBaseURL = "http://www.mapquestapi.com/geocoding/v1/batch?key=sFvGlJbu43uE3lAkJFxj5gEAE1nUpjhM&maxResults=1&thumbMaps=false"
            var mapquestRequestString = mapquestBaseURL
            
            // var cities = [ String ]()
            // var dates = [ String ]()
            // var venueNames = [ String ]()
            
            // i might need to enumerate a ( index, show ) here, so i can get the indices of nuremberg and lyon, to delete them from the shows array,
            // so that this doesnt crash later, when assigning the geocoded coordinates to the shows in the array
            let showsArray = shows as NSArray
            let mutableShows: AnyObject = showsArray.mutableCopy()
            for ( index, show ) in enumerate( mutableShows as! [ PhishShow ] )
            {
                // let theShow = show as PhishShow
                var location = show.city
                // cities.append( location )
                
                location = location.stringByReplacingOccurrencesOfString(" ", withString: "")
                
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
                    
                    default:
                        break
                }
                
                /*
                if location == "Nüremberg,Germany" || location == "Lyon/Villeurbanne,France" || location == "Montréal,Québec,Canada" || location == "Düsseldorf,Germany"
                {
                    mutableShows.removeObjectAtIndex( index )
                    continue
                }
                println( "location: \( location )" )
                */
                
//                let tempURLString = mapquestRequestString + "&location=\( location )"
//                let tempURL = NSURL( string: tempURLString )!
//                if isValidURL( tempURL )
//                {
//                    mapquestRequestString += "&location=\( location )"
//                }
                
                mapquestRequestString += "&location=\( location )"
                
                // let date = show[ "date" ] as! String
                // dates.append( date )
                
                // let venueName = show[ "venue_name" ] as! String
                // venueNames.append( venueName )
            }
            
            // theTour.shows = mutableShows as! [ PhishShow ]
            
            println( "Mapquest request string: \( mapquestRequestString )" )
            
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
                    var mapquestJSONificationError: NSErrorPointer = nil
                    if let jsonMapquestData = NSJSONSerialization.JSONObjectWithData(
                        mapquestData,
                        options: nil,
                        error: mapquestJSONificationError
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
                            
                            theTour.shows[ counter ].showLatitude = geocodedLatitude
                            theTour.shows[ counter ].showLongitude = geocodedLongitude
                            
                            println( "\( theTour.shows[ counter ].city ): \( geocodedLatitude ), \( geocodedLongitude )" )
                            
                            /*
                            let showCoordinate = CLLocationCoordinate2D(
                                latitude: geocodedLatitude,
                                longitude: geocodedLongitude
                            )
                            self.showCoordinates.append( showCoordinate )
                            */
                            
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
                            var delayTime: dispatch_time_t
                            
                            self.zoomOut()
                            
                            delayTime = dispatch_time( DISPATCH_TIME_NOW, Int64( 2 * Double( NSEC_PER_SEC ) ) )
                            dispatch_after( delayTime, dispatch_get_main_queue() )
                            {
                                self.tourMap.addAnnotations( theTour.shows ) // TODO: Re-instate?
                                // self.makeTourTrail()
                            }
                            
                            delayTime = dispatch_time( DISPATCH_TIME_NOW, Int64( 2.5 * Double( NSEC_PER_SEC ) ) )
                            dispatch_after( delayTime, dispatch_get_main_queue() )
                                {
                                    // self.tourMap.addAnnotations( theTour.shows ) // TODO: Re-instate?
                                    self.makeTourTrail()
                            }
                            
//                            if !self.isZoomedOut
//                            {
//                                self.zoomOut()
//                                
//                                let delayTime = dispatch_time( DISPATCH_TIME_NOW, Int64( 2 * Double( NSEC_PER_SEC ) ) )
//                                dispatch_after( delayTime, dispatch_get_main_queue() )
//                                {
//                                    self.centerOnFirstShow()
//                                }
//                            }
//                            else
//                            {
//                                self.tourMap.addAnnotations( theTour.shows ) // TODO: Re-instate?
//                                self.makeTourTrail()
//                            }
                            
                            delayTime = dispatch_time( DISPATCH_TIME_NOW, Int64( 3 * Double( NSEC_PER_SEC ) ) )
                            dispatch_after( delayTime, dispatch_get_main_queue() )
                            {
                                self.centerOnFirstShow()
                            }
                            // self.tourNavControls.hidden = false
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
            println( "One of the parameters wasn't set." )
        }
    }
    
//    func isValidURL( url: NSURL ) -> Bool
//    {
//        let request = NSURLRequest( URL: url )
//        
//        return NSURLConnection.canHandleRequest( request )
//    }
    
    func makeTourTrail()
    {
        if let theTour = selectedTour
        {
            var showCoordinates = [ CLLocationCoordinate2D ]()
            for index in indices( theTour.showCoordinates )
            {
                showCoordinates.append( theTour.showCoordinates[ index ] )
            }
            
            var tourTrail = MKPolyline(
                coordinates: &showCoordinates,
                count: showCoordinates.count
            )
            tourMap.addOverlay( tourTrail )
        }
    }
    
    func zoomOut()
    {
        tourMap.setRegion(defaultRegion, animated: true)
        isZoomedOut = true
    }
    
    func centerOnFirstShow()
    {
        if let theTour = selectedTour
        {
            let firstShowRegion = MKCoordinateRegion(
                center: theTour.showCoordinates.first!,
                span: MKCoordinateSpan(
                    latitudeDelta: 20.0,
                    longitudeDelta: 20.0
                )
            )
            tourMap.setRegion( firstShowRegion, animated: true )
        }
    }
    
    func startTour()
    {
        tourNavControls.setTitle( "⬅︎", forSegmentAtIndex: 0 )
        tourNavControls.setEnabled( true, forSegmentAtIndex: 1 )
        tourNavControls.setEnabled( true, forSegmentAtIndex: 2 )
        tourNavControls.setEnabled( true, forSegmentAtIndex: 3 )
        
        // zoomInOnFirstShow()
        didStartTour = true
    }
    
    /*
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
    */
    
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
    
    // the trick for using this method came from http://stackoverflow.com/a/7185460
    func pickerView(
        pickerView: UIPickerView,
        viewForRow row: Int,
        forComponent component: Int,
        reusingView view: UIView!
    ) -> UIView
    {
        var label = view as? UILabel
        
        if label == nil
        {
            label = UILabel()
            
            // label?.font = UIFont(name: "Apple SD Gothic Neo", size: 14)
            label?.textAlignment = .Center
        }
        
        switch pickerView.tag
        {
            case 1:
                if let theYears = years
                {
                    label?.font = UIFont(name: "Apple SD Gothic Neo", size: 20)
                    label?.text = theYears[ row ]
                }
                else
                {
                    label?.text =  ". . ."
                }
                
            case 2:
                // return tourSelections[ row ]
                if let theTours = tours
                {
                    label?.font = UIFont(name: "Apple SD Gothic Neo", size: 12)
                    // TODO: FIX
                    /*
                    the problem here is that the row index are 0-n, while the dictionary is keys by the tourID, which is like,
                    91, 97, or 24, etc. i think i should just consruct some Tour objects and then retrieve the names from it.
                    */
                    label?.text =  theTours[ row ].name
                }
                else
                {
                    label?.text =  ". . ."
                }
                
            default:
                label?.text =  ". . ."
        }
        
        return label!
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
                if row == ( years!.count ) - 1
                {
                    let years = [ 1983, 1984, 1985, 1986, 1987 ]
                    PhishinClient.sharedInstance().requestToursForYears( years )
                    {
                        toursRequestError, tours in
                        
                        println( "requestToursForYears was successful..." )
                        if toursRequestError != nil
                        {
                            println( "There was an error requesting the tours for \( years ): \( toursRequestError.localizedDescription )" )
                        }
                        else
                        {
                            println( "tours: \( tours )" )
                            self.selectedYear = self.years?[ row ]
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
                    if let theYear = years?[ row ].toInt()!
                    {
                        PhishinClient.sharedInstance().requestToursForYear( theYear )
                        {
                            toursRequestError, tours in
                            
                            if toursRequestError != nil
                            {
                                // TODO: create an alert for this
                                println( "There was an error requesting the tours for \( theYear ): \( toursRequestError.localizedDescription )" )
                            }
                            else
                            {
                                println( "Finished the request: tours: \( tours )" )
                                self.selectedYear = self.years?[ row ]
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
                }
                
            case 2:
                // selectedTour = tourIDs[ row ]
                selectedTour = tours?[ row ]
                println( "Selected \( selectedTour )" )
                return
                
            default:
                selectedYear = nil
                selectedTour = nil
                // selectedSeason = nil
        }
    }
}
