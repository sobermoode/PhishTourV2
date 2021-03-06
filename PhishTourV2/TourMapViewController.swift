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
    MKMapViewDelegate, UIPickerViewDataSource, UIPickerViewDelegate, UITableViewDataSource, UITableViewDelegate, MultiRowCalloutCell2ShowSetlist
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
    // var years: [ String ]?
    var years: [ Int ]?
    // var selectedYear: String?
    var selectedYear: Int?
    var tours: [ PhishTour ]?
    var selectedTour: PhishTour?
    var currentShow: PhishShow? // TODO: not sure this is used anymore; now using currentLocation
    var didDropPins: Bool = false
    var isZoomedOut: Bool = true // TODO: never check for this anywhere
    var didAddAnnotations: Bool = false
    var didMakeTourTrail: Bool = false
    var dontGoBack: Bool = false
    var didStartTour: Bool = false
    var isResuming: Bool = false
    var previousStatesOfTourNav: [ Int : Bool ]? = nil
    var multiRowCalloutCell2Nib: UINib!
    var currentCallout: SMCalloutView?
    // var currentLocation: String?
    var currentLocation: PhishShow?
    var currentHighlight: NSIndexPath?
    let defaultRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(
            latitude: 39.8282,
            longitude: -98.5795
        ),
        span: MKCoordinateSpan(
            latitudeDelta: 50.0,
            longitudeDelta: 50.0
        )
    )
    
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
    // var currentTour = [ ShowAnnotation ]() // Re-instate? prolly not
    
    
    override func viewDidLoad()
    {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        resetButton.enabled = false
        
        tourNavControls.tag = 400
        tourNavControls.addTarget(
            self,
            action: "selectTourNavigationOption:",
            forControlEvents: UIControlEvents.ValueChanged
        )
        tourNavControls.setEnabled( false, forSegmentAtIndex: 1 )
        tourNavControls.setEnabled( true, forSegmentAtIndex: 2 )
        tourNavControls.setEnabled( false, forSegmentAtIndex: 3 )
        
        multiRowCalloutCell2Nib = UINib(nibName: "MultiRowCalloutCell2", bundle: nil)
        
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
            // resetTourNavControls()
            tourNavControls.setTitle( "Start", forSegmentAtIndex: 0 )
            tourNavControls.setEnabled( true, forSegmentAtIndex: 0 )
            tourNavControls.setEnabled( false, forSegmentAtIndex: 1 )
            tourNavControls.setEnabled( true, forSegmentAtIndex: 2 )
            tourNavControls.setEnabled( false, forSegmentAtIndex: 3 )
        }
        
        if !tourMap.annotations.isEmpty
        {
            tourMap.removeAnnotations( tourMap.annotations )
            tourMap.removeOverlays( tourMap.overlays )
            
            didDropPins = false
            dontGoBack = false
        }
        
        if let tourTitleLable = view.viewWithTag( 100 )
        {
            tourTitleLable.removeFromSuperview()
        }
        
        if let infoPane = view.viewWithTag( 200 )
        {
            dropInfoPane()
        }
        
        if let showList = view.viewWithTag( 300 )
        {
            bringInShowList()
        }
        
        tourMap.setRegion( defaultRegion, animated: true )
        
        resetButton.enabled = false
    }
    
    @IBAction func showTourPicker( sender: UIBarButtonItem? )
    {
        blurEffectView.hidden = !blurEffectView.hidden
        
        selectTourButton.title = blurEffectView.hidden ? "Select Tour" : "Cancel"
        selectTourButton.tintColor = blurEffectView.hidden ? UIColor.blueColor() : UIColor.redColor()
        
        if let tourTitleLable = view.viewWithTag( 100 )
        {
            tourTitleLable.hidden = !tourTitleLable.hidden
        }
        
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
                    // self.years = years.reverse()
                    self.years = years
                    self.selectedYear = self.years?.first
                    
                    dispatch_async( dispatch_get_main_queue() )
                    {
                        self.yearPicker.reloadAllComponents()
                    }
                    
                    PhishinClient.sharedInstance().requestToursForYear( self.selectedYear! )
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
    
    @IBAction func selectTour( sender: UIButton )
    {
        resetButton.enabled = true
        
        showTourPicker( nil )
        
        if didDropPins
        {
            tourMap.removeAnnotations( tourMap.annotations )
            tourMap.removeOverlays( tourMap.overlays )
            
            didAddAnnotations = false
            didMakeTourTrail = false
            didDropPins = false
            dontGoBack = false
        }
        
        if didStartTour
        {
            tourMap.setRegion( defaultRegion, animated: true )
            
            tourNavControls.setTitle( "Start", forSegmentAtIndex: 0 )
            tourNavControls.setEnabled( true, forSegmentAtIndex: 0 )
            tourNavControls.setEnabled( false, forSegmentAtIndex: 1 )
            tourNavControls.setEnabled( true, forSegmentAtIndex: 2 )
            tourNavControls.setEnabled( false, forSegmentAtIndex: 3 )
            
            if view.viewWithTag( 200 ) != nil
            {
                bringUpInfoPane()
            }
            if view.viewWithTag( 300 ) != nil
            {
                bringInShowList()
            }
            
            didStartTour = false
        }
        
        if let theTour = selectedTour
        {
            MapquestClient.sharedInstance().geocodeShowsForTour(
                theTour,
                withType: .Batch
            )
            {
                geocodingError, success in
                
                if geocodingError != nil
                {
                    println( "There was an error geocoding the tour locations: \( geocodingError.localizedDescription )" )
                }
                else if success!
                {
                    dispatch_async( dispatch_get_main_queue() )
                    {
                        self.currentLocation = theTour.uniqueLocations.first
                        
                        self.showTourTitle()
                        self.centerOnFirstShow()
                        
                        // NOTE: dispatch_after trick cribbed from http://stackoverflow.com/a/24034838
                        let delayTime = dispatch_time(
                            DISPATCH_TIME_NOW,
                            Int64( 2 * Double( NSEC_PER_SEC ) )
                        )
                        dispatch_after( delayTime, dispatch_get_main_queue() )
                        {
                            self.tourMap.addAnnotations( theTour.uniqueLocations )
                        }
                        
                        self.tourNavControls.hidden = false
                    }
                }
            }
            
            self.didDropPins = true
        }
        else
        {
            println( "One of the parameters wasn't set." )
        }
    }
    
    func showTourTitle()
    {
        // remove the old label if one is already onscreen
        if let tourTitleLable = view.viewWithTag( 100 )
        {
            tourTitleLable.removeFromSuperview()
        }
        
        if let theTour = selectedTour
        {
            // create the label with a particular look
            let tourTitleLabelWidth: CGFloat = view.bounds.width - 50
            let tourTitleLabelHeight: CGFloat = 25
            let tourTitleLabel = UILabel(
                frame: CGRect(
                    x: CGRectGetMidX( view.bounds ) - ( tourTitleLabelWidth / 2 ), y: 64,
                    width: tourTitleLabelWidth, height: tourTitleLabelHeight
                )
            )
            tourTitleLabel.backgroundColor = UIColor.orangeColor()
            tourTitleLabel.font = UIFont( name: "AppleSDGothicNeo-Bold", size: 16 )
            tourTitleLabel.textColor = UIColor.whiteColor()
            tourTitleLabel.textAlignment = .Center
            tourTitleLabel.text = theTour.name
            tourTitleLabel.tag = 100
            
            // resize the label, because the names of tours are sometimes long, or short;
            // center the label at the top of the screen
            tourTitleLabel.sizeToFit()
            tourTitleLabel.frame.size.width += 20
            tourTitleLabel.frame.origin = CGPoint(
                x: CGRectGetMidX( view.bounds ) - ( tourTitleLabel.frame.size.width / 2 ),
                y: 64
            )
            
            // add the label to the view
            view.addSubview( tourTitleLabel )
        }
    }
    
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
    
    func centerOnFirstShow()
    {
        if let theTour = selectedTour
        {
            let firstShowRegion = MKCoordinateRegion(
                center: theTour.showCoordinates.first!,
                span: MKCoordinateSpan(
                    latitudeDelta: 50.0,
                    longitudeDelta: 50.0
                )
            )
            tourMap.setRegion( firstShowRegion, animated: true )
            
            isZoomedOut = true
        }
    }
    
    // MARK: Tour navigation controls
    
    func startTour()
    {
        tourNavControls.setTitle( "⬅︎", forSegmentAtIndex: 0 )
        tourNavControls.setEnabled( false, forSegmentAtIndex: 0 )
        tourNavControls.setEnabled( true, forSegmentAtIndex: 1 )
        tourNavControls.setEnabled( true, forSegmentAtIndex: 2 )
        
        let oneLocation = ( selectedTour!.uniqueLocations.count == 1 ) ? true : false
        tourNavControls.setEnabled( !oneLocation, forSegmentAtIndex: 3 )
        
        if currentLocation != nil
        {
            tourMap.deselectAnnotation( currentLocation!, animated: true )
        }
        
        zoomInOnCurrentShow()
        
        if view.viewWithTag( 300 ) != nil
        {
            bringInShowList()
        }
        
        bringUpInfoPane()
        
        didStartTour = true
    }
    
    func resumeTour()
    {
        tourNavControls.setTitle( "⬅︎", forSegmentAtIndex: 0 )
        tourNavControls.setEnabled( true, forSegmentAtIndex: 0 )
        tourNavControls.setEnabled( true, forSegmentAtIndex: 1 )
        tourNavControls.setEnabled( true, forSegmentAtIndex: 2 )
        
        let lastShow = ( find( selectedTour!.uniqueLocations, currentLocation! ) == selectedTour!.uniqueLocations.count - 1) ? false : true
        tourNavControls.setEnabled( lastShow, forSegmentAtIndex: 3 )
        
        if currentLocation != nil
        {
            tourMap.deselectAnnotation( currentLocation!, animated: true )
        }
        
        currentLocation = ( currentLocation == nil ) ? selectedTour!.uniqueLocations.first! : currentLocation
        
        zoomInOnCurrentShow()
        
        if view.viewWithTag( 300 ) != nil
        {
            bringInShowList()
        }
        
        bringUpInfoPane()
        
        didStartTour = true
        isResuming = false
    }
    
    func zoomInOnCurrentShow()
    {
        let zoomedRegion = MKCoordinateRegion(
            center: currentLocation!.coordinate,
            span: MKCoordinateSpan(
                latitudeDelta: 0.2,
                longitudeDelta: 0.2
            )
        )
        tourMap.setRegion( zoomedRegion, animated: true )
    }
    
    func bringUpInfoPane()
    {
        if let infoPane = view.viewWithTag( 200 ) as? UIVisualEffectView
        {
            UIView.animateWithDuration(
                0.4,
                delay: 0.5,
                options: UIViewAnimationOptions.CurveLinear,
                animations:
                {
                    infoPane.frame.origin.y += 275
                },
                completion:
                {
                    finished in
                    
                    if finished
                    {
                        infoPane.removeFromSuperview()
                    }
                }
            )
        }
        else
        {
            // create the info pane
            let blurEffect = UIBlurEffect( style: .Dark )
            let infoPane = UIVisualEffectView( effect: blurEffect )
            infoPane.tag = 200
            infoPane.frame = CGRect(
                x: 0, y: CGRectGetMaxY( view.bounds ) + 1,
                width: view.bounds.size.width - 25, height: 225
            )
            infoPane.frame.origin = CGPoint(
                x: CGRectGetMidX( view.bounds ) - infoPane.frame.size.width / 2,
                y: infoPane.frame.origin.y
            )

            // create labels and buttons for each show at the location
            var dateLabels = [ UILabel ]()
            var setlistButtons = [ UIButton ]()
            var labelTag: Int = 201
            var setlistButtonTag: Int = 251
            let currentVenue = currentLocation!.venue
            let showsAtVenue = selectedTour!.locationDictionary[ currentVenue ]!
            for show in showsAtVenue
            {
                let dateLabel = UILabel()
                dateLabel.tag = labelTag++
                dateLabel.textColor = UIColor.whiteColor()
                dateLabel.font = UIFont( name: "AppleSDGothicNeo-Bold", size: 22 )
                dateLabel.text = show.date + " \( show.year )"
                dateLabel.sizeToFit()
                dateLabels.append( dateLabel )
                
                let setlistButton = UIButton()
                setlistButton.tag = setlistButtonTag++
                setlistButton.titleLabel?.font = UIFont( name: "AppleSDGothicNeo-Bold", size: 14 )
                setlistButton.setTitle( "🎵", forState: .Normal )
                setlistButton.sizeToFit()
                setlistButton.addTarget(
                    self,
                    action: "showSetlist:",
                    forControlEvents: .TouchUpInside
                )
                setlistButtons.append( setlistButton )
            }
            
            // create the venue label
            let venueLabel = UILabel()
            venueLabel.tag = 210
            venueLabel.textColor = UIColor.whiteColor()
            venueLabel.font = UIFont( name: "Apple SD Gothic Neo", size: 18 )
            venueLabel.text = currentVenue
            venueLabel.sizeToFit()
            
            // create the city label
            let cityLabel = UILabel()
            cityLabel.tag = 211
            cityLabel.textColor = UIColor.whiteColor()
            cityLabel.font = UIFont( name: "Apple SD Gothic Neo", size: 18 )
            cityLabel.text = currentLocation?.city
            cityLabel.sizeToFit()
            
            // the number of labels and setlist buttons are the same
            let viewElements: Int = dateLabels.count
            
            // we need to remember where the last date label is placed to correctly place the venue label
            var lastDateLabel = UILabel()
            
            // set the origins of the date labels and the setlist buttons
            for viewIndex in 0..<viewElements
            {
                let dateLabel: UILabel = dateLabels[ viewIndex ]
                let labelHeight: CGFloat = dateLabel.frame.size.height
                dateLabel.frame.origin = CGPoint(
                    x: CGRectGetMidX( infoPane.contentView.bounds ) - ( dateLabel.frame.size.width / 2 ),
                    y: ( labelHeight * ( CGFloat( viewIndex ) + 1 ) + 1 )
                )
                lastDateLabel = dateLabel
                
                let setlistButton: UIButton = setlistButtons[ viewIndex ]
                setlistButton.center = CGPoint(
                    x: dateLabel.center.x + ( dateLabel.frame.size.width / 2 ) + 20,
                    y: dateLabel.center.y
                )
            }
            
            // set the venue label origin
            venueLabel.frame.origin = CGPoint(
                x: CGRectGetMidX( infoPane.contentView.bounds ) - ( venueLabel.frame.size.width / 2 ),
                y: lastDateLabel.frame.origin.y + lastDateLabel.frame.size.height + 5
            )
            
            // set the city label origin
            cityLabel.frame.origin = CGPoint(
                x: CGRectGetMidX( infoPane.contentView.bounds ) - ( cityLabel.frame.size.width / 2 ),
                y: venueLabel.frame.origin.y + venueLabel.frame.size.height + 5
            )
            
            // add all the views to the info pane and add the info pane to the main view
            for viewIndex in 0..<viewElements
            {
                let dateLabel: UILabel = dateLabels[ viewIndex ]
                let setlistButton: UIButton = setlistButtons[ viewIndex ]
                
                infoPane.contentView.addSubview( dateLabel )
                infoPane.contentView.addSubview( setlistButton )
            }
            infoPane.contentView.addSubview( venueLabel )
            infoPane.contentView.addSubview( cityLabel )
            view.insertSubview( infoPane, belowSubview: blurEffectView )
            
            // slide the info pane up from the bottom of the screen
            UIView.animateWithDuration(
                0.4,
                delay: 0.5,
                options: UIViewAnimationOptions.CurveLinear,
                animations:
                {
                    infoPane.frame.origin.y -= 275
                },
                completion: nil
            )
        }
    }
    
    func dropInfoPane()
    {
        let infoPane = view.viewWithTag( 200 ) as! UIVisualEffectView
        
        UIView.animateWithDuration(
            0.4,
            delay: 0.0,
            options: UIViewAnimationOptions.CurveLinear,
            animations:
            {
                infoPane.frame.origin.y += 275
            },
            completion:
            {
                finished in
                
                if finished
                {
                    infoPane.removeFromSuperview()
                }
            }
        )
    }
    
    func selectTourNavigationOption( sender: UISegmentedControl )
    {
        switch sender.selectedSegmentIndex
        {
        case 0:
            if isResuming
            {
                resumeTour()
            }
            else if !didStartTour
            {
                startTour()
            }
            else
            {
                println( "Pressed the PreviousShow button." )
                
                goBackToPreviousShow()
                
                if find( selectedTour!.uniqueLocations, currentLocation! ) == 0
                {
                    tourNavControls.setEnabled( false, forSegmentAtIndex: 0 )
                }
                
                if !tourNavControls.isEnabledForSegmentAtIndex( 3 )
                {
                    tourNavControls.setEnabled( true, forSegmentAtIndex: 3 )
                }
            }
            
        case 1:
            println( "Pressed the ZoomOut button." )
            
            tourMap.setRegion(
                MKCoordinateRegion(
                    center: CLLocationCoordinate2D(
                        latitude: currentLocation!.showLatitude!,
                        longitude: currentLocation!.showLongitude!
                    ),
                    span: MKCoordinateSpan(
                        latitudeDelta: 50.0,
                        longitudeDelta: 50.0
                    )
                ),
                animated: true
            )
            
            tourMap.selectAnnotation( currentLocation, animated: true )
            
            bringUpInfoPane()
            
            if find( selectedTour!.uniqueLocations, currentLocation! ) != 0
            {
                tourNavControls.setTitle( "Resume", forSegmentAtIndex: 0 )
                isResuming = true
            }
            else
            {
                tourNavControls.setTitle( "Start", forSegmentAtIndex: 0 )
                didStartTour = false
            }
            
            tourNavControls.setEnabled( true, forSegmentAtIndex: 0 )
            tourNavControls.setEnabled( false, forSegmentAtIndex: 1 )
            tourNavControls.setEnabled( true, forSegmentAtIndex: 2 )
            tourNavControls.setEnabled( false, forSegmentAtIndex: 3 )
            
            isZoomedOut = true
            
        case 2:
            println( "Pressed the List button." )
            
            if previousStatesOfTourNav != nil
            {
                bringInShowList(previousStates: previousStatesOfTourNav)
                previousStatesOfTourNav = nil
            }
            else
            {
                previousStatesOfTourNav = [ Int : Bool ]()
                previousStatesOfTourNav!.updateValue( tourNavControls.isEnabledForSegmentAtIndex( 0 ), forKey: 0 )
                previousStatesOfTourNav!.updateValue( tourNavControls.isEnabledForSegmentAtIndex( 1 ), forKey: 1 )
                previousStatesOfTourNav!.updateValue( tourNavControls.isEnabledForSegmentAtIndex( 2 ), forKey: 2 )
                previousStatesOfTourNav!.updateValue( tourNavControls.isEnabledForSegmentAtIndex( 3 ), forKey: 3 )
                bringInShowList()
            }
            
        case 3:
            println( "Pressed the NextShow button." )
            
            goToNextShow()
            
            tourNavControls.setEnabled( true, forSegmentAtIndex: 0 )
            
            if find( selectedTour!.uniqueLocations, currentLocation! ) == selectedTour!.uniqueLocations.count - 1
            {
                tourNavControls.setEnabled( false, forSegmentAtIndex: 3 )
            }
            
        default:
            println( "I don't know what button was pressed!!!" )
        }
    }
    
    func goBackToPreviousShow()
    {
        let infoPane = view.viewWithTag( 200 )! as! UIVisualEffectView
        
        // remove the current date labels and setlist buttons before we figure out which new ones to add
        var currentVenue = currentLocation!.venue
        var showsAtVenue = selectedTour!.locationDictionary[ currentVenue ]!
        var labelTags = 201...( 201 + ( showsAtVenue.count - 1 ) )
        for labelTag in labelTags
        {
            let dateLabel = infoPane.viewWithTag( labelTag )!
            dateLabel.removeFromSuperview()
        }
        var setlistButtonTags = 251...( 251 + ( showsAtVenue.count - 1 ) )
        for setlistButtonTag in setlistButtonTags
        {
            let setlistButton = infoPane.viewWithTag( setlistButtonTag )!
            setlistButton.removeFromSuperview()
        }
        
        // get previous show
        var locationIndex = find( selectedTour!.uniqueLocations, currentLocation! )!
        locationIndex--
        currentLocation = selectedTour!.uniqueLocations[ locationIndex ]
        
        // reset the current venue and shows
        currentVenue = currentLocation!.venue
        showsAtVenue = selectedTour!.locationDictionary[ currentVenue ]!
        
        // set the map on the new location
        let previousShowCoordinate = currentLocation!.coordinate
        tourMap.setCenterCoordinate( previousShowCoordinate, animated: true )
        
        // create labels and buttons for each show at the location
        var dateLabels = [ UILabel ]()
        var setlistButtons = [ UIButton ]()
        var labelTag: Int = 201
        var setlistButtonTag: Int = 251
        for show in showsAtVenue
        {
            let dateLabel = UILabel()
            dateLabel.tag = labelTag++
            dateLabel.textColor = UIColor.whiteColor()
            dateLabel.font = UIFont( name: "AppleSDGothicNeo-Bold", size: 22 )
            dateLabel.text = show.date + " \( show.year )"
            dateLabel.sizeToFit()
            dateLabels.append( dateLabel )
            
            let setlistButton = UIButton()
            setlistButton.tag = setlistButtonTag++
            setlistButton.titleLabel?.font = UIFont( name: "AppleSDGothicNeo-Bold", size: 14 )
            setlistButton.setTitle( "🎵", forState: .Normal )
            setlistButton.sizeToFit()
            setlistButton.addTarget(
                self,
                action: "showSetlist:",
                forControlEvents: .TouchUpInside
            )
            setlistButtons.append( setlistButton )
        }
        
        // the number of labels and setlist buttons are the same
        let viewElements: Int = dateLabels.count
        
        // we need to remember where the last date label is placed to correctly place the venue label
        var lastDateLabel = UILabel()
        
        // set the origins of the date labels and the setlist buttons
        for viewIndex in 0..<viewElements
        {
            let dateLabel: UILabel = dateLabels[ viewIndex ]
            let labelHeight: CGFloat = dateLabel.frame.size.height
            dateLabel.frame.origin = CGPoint(
                x: CGRectGetMidX( infoPane.contentView.bounds ) - ( dateLabel.frame.size.width / 2 ),
                y: ( labelHeight * ( CGFloat( viewIndex ) + 1 ) + 1 )
            )
            lastDateLabel = dateLabel
            
            let setlistButton: UIButton = setlistButtons[ viewIndex ]
            setlistButton.center = CGPoint(
                x: dateLabel.center.x + ( dateLabel.frame.size.width / 2 ) + 20,
                y: dateLabel.center.y
            )
        }
        
        // add new date labels and setlist buttons to the info pane
        for viewIndex in 0..<viewElements
        {
            let dateLabel: UILabel = dateLabels[ viewIndex ]
            let setlistButton: UIButton = setlistButtons[ viewIndex ]
            
            infoPane.contentView.addSubview( dateLabel )
            infoPane.contentView.addSubview( setlistButton )
        }
        
        // set the venue and city labels
        let venueLabel = infoPane.viewWithTag( 210 ) as! UILabel
        let cityLabel = infoPane.viewWithTag( 211 ) as! UILabel
        venueLabel.text = currentLocation?.venue
        venueLabel.sizeToFit()
        cityLabel.text = currentLocation?.city
        cityLabel.sizeToFit()
        venueLabel.frame.origin = CGPoint(
            x: CGRectGetMidX( infoPane.contentView.bounds ) - ( venueLabel.frame.size.width / 2 ),
            y: lastDateLabel.frame.origin.y + lastDateLabel.frame.size.height + 5
        )
        cityLabel.frame.origin = CGPoint(
            x: CGRectGetMidX( infoPane.contentView.bounds ) - ( cityLabel.frame.size.width / 2 ),
            y: venueLabel.frame.origin.y + venueLabel.frame.size.height + 5
        )
    }
    
    func goToNextShow()
    {
        let infoPane = view.viewWithTag( 200 )! as! UIVisualEffectView
        
        // remove the current date labels and setlist buttons before we figure out which new ones to add
        var currentVenue = currentLocation!.venue
        var showsAtVenue = selectedTour!.locationDictionary[ currentVenue ]!
        var labelTags = 201...( 201 + ( showsAtVenue.count - 1 ) )
        for labelTag in labelTags
        {
            let dateLabel = infoPane.viewWithTag( labelTag )!
            dateLabel.removeFromSuperview()
        }
        var setlistButtonTags = 251...( 251 + ( showsAtVenue.count - 1 ) )
        for setlistButtonTag in setlistButtonTags
        {
            let setlistButton = infoPane.viewWithTag( setlistButtonTag )!
            setlistButton.removeFromSuperview()
        }
        
        // get the next show
        var locationIndex = find( selectedTour!.uniqueLocations, currentLocation! )!
        locationIndex++
        currentLocation = selectedTour!.uniqueLocations[ locationIndex ]
        
        // set the map on the new location
        let nextShowCoordinate = currentLocation!.coordinate
        tourMap.setCenterCoordinate( nextShowCoordinate, animated: true )
        
        // reset the current venue and shows
        currentVenue = currentLocation!.venue
        showsAtVenue = selectedTour!.locationDictionary[ currentVenue ]!
        
        // create labels and buttons for each show at the location
        var dateLabels = [ UILabel ]()
        var setlistButtons = [ UIButton ]()
        var labelTag: Int = 201
        var setlistButtonTag: Int = 251
        for show in showsAtVenue
        {
            let dateLabel = UILabel()
            dateLabel.tag = labelTag++
            dateLabel.textColor = UIColor.whiteColor()
            dateLabel.font = UIFont( name: "AppleSDGothicNeo-Bold", size: 22 )
            dateLabel.text = show.date + " \( show.year )"
            dateLabel.sizeToFit()
            dateLabels.append( dateLabel )
            
            let setlistButton = UIButton()
            setlistButton.tag = setlistButtonTag++
            setlistButton.titleLabel?.font = UIFont( name: "AppleSDGothicNeo-Bold", size: 14 )
            setlistButton.setTitle( "🎵", forState: .Normal )
            setlistButton.sizeToFit()
            setlistButton.addTarget(
                self,
                action: "showSetlist:",
                forControlEvents: .TouchUpInside
            )
            setlistButtons.append( setlistButton )
        }
        
        // the number of labels and setlist buttons are the same
        let viewElements: Int = dateLabels.count
        
        // we need to remember where the last date label is placed to correctly place the venue label
        var lastDateLabel = UILabel()
        
        // set the origins of the date labels and the setlist buttons
        for viewIndex in 0..<viewElements
        {
            let dateLabel: UILabel = dateLabels[ viewIndex ]
            let labelHeight: CGFloat = dateLabel.frame.size.height
            dateLabel.frame.origin = CGPoint(
                x: CGRectGetMidX( infoPane.contentView.bounds ) - ( dateLabel.frame.size.width / 2 ),
                y: ( labelHeight * ( CGFloat( viewIndex ) + 1 ) + 1 )
            )
            lastDateLabel = dateLabel
            
            let setlistButton: UIButton = setlistButtons[ viewIndex ]
            setlistButton.center = CGPoint(
                x: dateLabel.center.x + ( dateLabel.frame.size.width / 2 ) + 20,
                y: dateLabel.center.y
            )
        }
        
        // add new date labels and setlist buttons to the info pane
        for viewIndex in 0..<viewElements
        {
            let dateLabel: UILabel = dateLabels[ viewIndex ]
            let setlistButton: UIButton = setlistButtons[ viewIndex ]
            
            infoPane.contentView.addSubview( dateLabel )
            infoPane.contentView.addSubview( setlistButton )
        }
        
        // set the venue and city labels
        let venueLabel = infoPane.viewWithTag( 210 ) as! UILabel
        let cityLabel = infoPane.viewWithTag( 211 ) as! UILabel
        venueLabel.text = currentLocation?.venue
        venueLabel.sizeToFit()
        cityLabel.text = currentLocation?.city
        cityLabel.sizeToFit()
        venueLabel.frame.origin = CGPoint(
            x: CGRectGetMidX( infoPane.contentView.bounds ) - ( venueLabel.frame.size.width / 2 ),
            y: lastDateLabel.frame.origin.y + lastDateLabel.frame.size.height + 5
        )
        cityLabel.frame.origin = CGPoint(
            x: CGRectGetMidX( infoPane.contentView.bounds ) - ( cityLabel.frame.size.width / 2 ),
            y: venueLabel.frame.origin.y + venueLabel.frame.size.height + 5
        )
    }
    
    func bringInShowList( previousStates: [ Int : Bool ]? = nil )
    {
        if let showList = view.viewWithTag( 300 ) as? UIVisualEffectView
        {
            UIView.animateWithDuration(
                0.4,
                delay: 0.5,
                options: UIViewAnimationOptions.CurveLinear,
                animations:
                {
                    let stoppingPoint: CGFloat = CGRectGetMinX( self.view.bounds ) - ( showList.frame.size.width )
                    showList.frame.origin.x = stoppingPoint
                },
                completion:
                {
                    finished in
                    
                    if finished
                    {
                        showList.removeFromSuperview()
                        
                        if previousStates != nil
                        {
                            self.tourNavControls.setEnabled( previousStates![ 0 ]!, forSegmentAtIndex: 0 )
                            self.tourNavControls.setEnabled( previousStates![ 1 ]!, forSegmentAtIndex: 1 )
                            self.tourNavControls.setEnabled( previousStates![ 2 ]!, forSegmentAtIndex: 2 )
                            self.tourNavControls.setEnabled( previousStates![ 3 ]!, forSegmentAtIndex: 3 )
                        }
                    }
                }
            )
        }
        else
        {
            let blurEffect = UIBlurEffect( style: .Dark )
            let showList = UIVisualEffectView( effect: blurEffect )
            
            showList.tag = 300
            showList.frame = CGRect(
                x: 1, y: 100,
                width: view.bounds.size.width - 25, height: view.bounds.size.height - 148
            )
            showList.frame.origin = CGPoint(
                x: CGRectGetMinX( view.bounds ) - ( showList.frame.size.width + 1 ),
                y: showList.frame.origin.y
            )
            
            let showListTable = UITableView(frame: CGRect(x: 10, y: 10, width: showList.frame.size.width - 20, height: showList.frame.size.height - 20), style: .Plain)
            showListTable.tag = 301
            showListTable.dataSource = self
            showListTable.delegate = self
            
            showListTable.sizeToFit()
            
            let multiRowCalloutCell2Nib = UINib(nibName: "MultiRowCalloutCell2", bundle: nil)
            showListTable.registerNib( multiRowCalloutCell2Nib, forCellReuseIdentifier: "multiRowCalloutCell2" )
            
            showList.contentView.addSubview( showListTable )
            view.insertSubview( showList, belowSubview: blurEffectView )
            
            UIView.animateWithDuration(
                0.4,
                delay: 0.5,
                options: UIViewAnimationOptions.CurveLinear,
                animations:
                {
                    let stoppingPoint: CGFloat = CGRectGetMidX( self.view.bounds ) - ( showList.frame.size.width / 2 )
                    showList.frame.origin.x = stoppingPoint
                },
                completion:
                {
                    finished in
                    
                    if finished
                    {
                        // highlight the selected show in the table
                        // get the index paths of the cells to highlight and scroll the table to
                        let ( highlightIndex, scrollToIndex ) = self.selectedTour!.showListNumberForLocation( self.currentLocation! )
                        let highlightIndexPath = NSIndexPath(
                            forRow: highlightIndex,
                            inSection: 0
                        )
                        let scrollToIndexPath = NSIndexPath(
                            forRow: scrollToIndex,
                            inSection: 0
                        )
                        
                        // scroll the table to the cell being highlighted first, otherwise cellForRowAtIndexPath will return nil
                        showListTable.scrollToRowAtIndexPath(
                            scrollToIndexPath,
                            atScrollPosition: .Top,
                            animated: false
                        )
                        
                        // highlight the cell
                        let showCell = showListTable.cellForRowAtIndexPath( highlightIndexPath )!
                        showCell.setHighlighted( true, animated: true )
                        self.currentHighlight = highlightIndexPath
                        
                        self.tourNavControls.setEnabled( false, forSegmentAtIndex: 0 )
                        self.tourNavControls.setEnabled( false, forSegmentAtIndex: 1 )
                        self.tourNavControls.setEnabled( true, forSegmentAtIndex: 2 )
                        self.tourNavControls.setEnabled( false, forSegmentAtIndex: 3 )
                    }
                }
            )
        }
    }
    
    func showSetlist( sender: UIButton )
    {
        // get an accessor to the setlist info
        let buttonIndex: Int = sender.tag - 251
        
        // get all the shows at the location and then the specific show that was selected
        let shows: [ PhishShow ] = selectedTour!.locationDictionary[ currentLocation!.venue ]!
        let show: PhishShow = shows[ buttonIndex ]
        
        println( "Seeing setlist for \( show.date ), \( show.year )" )
    }
    
    // MARK: MKMapViewDelegate methods
    
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
        // cast the annotation to a PhishShow to get at the consecutiveNights property
        let theShow = annotation as! PhishShow
        
        // re-use an annotation view, if possible
        if let reusedAnnotationView = mapView.dequeueReusableAnnotationViewWithIdentifier( "mapPin" ) as? MKPinAnnotationView
        {
            // remove the number image view it came with
            // (the annotation view being re-used might not be the same one that was associated with the annotation last time)
            if let previousNumberImageView = reusedAnnotationView.viewWithTag( 5 )
            {
                previousNumberImageView.removeFromSuperview()
            }
            
            reusedAnnotationView.annotation = theShow
            
            // add a new number image view with the correct number
            let numberImageView = UIImageView( image: UIImage( named: "\( theShow.consecutiveNights )" ) )
            numberImageView.frame = CGRect(
                x: CGRectGetMidX( reusedAnnotationView.bounds ) - ( numberImageView.frame.size.width / 2 ) - 1,
                y: CGRectGetMaxY( reusedAnnotationView.bounds ) - ( numberImageView.frame.size.height ),
                width: numberImageView.frame.size.width,
                height: numberImageView.frame.size.height
            )
            numberImageView.tag = 5
            reusedAnnotationView.addSubview( numberImageView )
            
            return reusedAnnotationView
        }
        else
        {
            var newAnnotationView = MKPinAnnotationView(
                annotation: theShow,
                reuseIdentifier: "mapPin"
            )
            
            // use the consecutiveNights to add a number to the pin indicating the number of nights played at that location
            let numberImageView = UIImageView( image: UIImage( named: "\( theShow.consecutiveNights )" ) )
            numberImageView.frame = CGRect(
                x: CGRectGetMidX( newAnnotationView.bounds ) - ( numberImageView.frame.size.width / 2 ) - 1,
                y: CGRectGetMaxY( newAnnotationView.bounds ) - ( numberImageView.frame.size.height ),
                width: numberImageView.frame.size.width,
                height: numberImageView.frame.size.height
            )
            numberImageView.tag = 5
            newAnnotationView.addSubview( numberImageView )
            
            newAnnotationView.animatesDrop = true
            newAnnotationView.canShowCallout = false
            
            return newAnnotationView
        }
    }
    
    func mapView(
        mapView: MKMapView!,
        didAddAnnotationViews views: [AnyObject]!
    )
    {        
        // draw the tour trail a short delay after the pins drop
        if !dontGoBack
        {
            dontGoBack = true
            
            let delayTime = dispatch_time(
                DISPATCH_TIME_NOW,
                Int64( 1.5 * Double( NSEC_PER_SEC ) )
            )
            dispatch_after( delayTime, dispatch_get_main_queue() )
            {
                self.makeTourTrail()
            }
        }
    }
    
    func mapView(
        mapView: MKMapView!,
        didSelectAnnotationView view: MKAnnotationView!
    )
    {
        if currentCallout != nil
        {
            currentCallout?.dismissCalloutAnimated( true )
        }
        
        let selectedLocation = view.annotation as! PhishShow
        currentLocation = selectedLocation
        
        let callout = CalloutCellView()
        
        let venue = currentLocation!.venue
        let showsAtVenue = selectedTour!.locationDictionary[ venue ]!
        var dateCells = [ MultiRowCalloutCell2 ]()
        for ( index, show ) in enumerate( showsAtVenue )
        {
            let newDateCell = multiRowCalloutCell2Nib.instantiateWithOwner(self, options: nil)[0] as! MultiRowCalloutCell2
            newDateCell.dateLabel.text = show.date
            newDateCell.yearLabel.text = show.year.description
            newDateCell.venueLabel.text = show.venue
            newDateCell.cityLabel.text = show.city
            newDateCell.cellNumber = CGFloat( index )
            newDateCell.setBackgroundColor()
            newDateCell.show = show
            newDateCell.delegate = self
            // callout.addSubview( newDateCell )
            dateCells.append( newDateCell )
        }
        callout.addCells( dateCells )
        
        for cell in callout.subviews
        {
            let currentCell = cell as! MultiRowCalloutCell2
            
            currentCell.setNeedsDisplay()
        }
        callout.sizeToFit()
        
        let calloutView = SMCalloutView()
        calloutView.contentView = callout
        let bgView: SMCalloutMaskedBackgroundView = calloutView.backgroundView as! SMCalloutMaskedBackgroundView
        let lastCell = callout.subviews.last as! MultiRowCalloutCell2
        bgView.arrowImageColor( lastCell.backgroundColor! )
        
        let annotationCoordinate = view.annotation.coordinate
        let viewPosition = mapView.convertCoordinate(
            annotationCoordinate,
            toPointToView: mapView
        )
        
        calloutView.presentCalloutFromRect(
            CGRect(
                x: viewPosition.x,
                y: viewPosition.y - 40,
                width: calloutView.frame.size.width,
                height: calloutView.frame.size.height
            ),
            inView: tourMap,
            constrainedToView: tourMap,
            animated: true
        )
        
        currentCallout = calloutView
        
        if find( selectedTour!.uniqueLocations, selectedLocation ) != 0
        {
            tourNavControls.setTitle( "Resume", forSegmentAtIndex: 0 )
            isResuming = true
        }
        else
        {
            tourNavControls.setTitle( "Start", forSegmentAtIndex: 0 )
            isResuming = false
            didStartTour = false
        }
    }
    
    func mapView(
        mapView: MKMapView!,
        didDeselectAnnotationView view: MKAnnotationView!
    )
    {
        // remove the current callout if one is showing
        if currentCallout != nil
        {
            currentCallout?.dismissCalloutAnimated( true )
        }
    }
    
    // MARK: UIPickerViewDataSource, UIPIckerViewDelegate methods
    
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
    
    // NOTE:
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
                    // label?.text = theYears[ row ]
                    label?.text = "\( theYears[ row ] )"
                }
                else
                {
                    label?.text =  ". . ."
                }
                
            case 2:
                // return tourSelections[ row ]
                if let theTours = tours
                {
                    label?.font = UIFont( name: "Apple SD Gothic Neo", size: 12 )
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
                        
                        // println( "requestToursForYears was successful..." )
                        if toursRequestError != nil
                        {
                            println( "There was an error requesting the tours for \( years ): \( toursRequestError.localizedDescription )" )
                        }
                        else
                        {
                            // println( "tours: \( tours )" )
                            self.selectedYear = self.years?[ row ]
                            self.tours = tours
                            if let firstTour = self.tours?.first!
                            {
                                self.selectedTour = firstTour
                            }
                            
                            dispatch_async( dispatch_get_main_queue() )
                            {
                                // println( "Reloading the season picker..." )
                                self.seasonPicker.reloadAllComponents()
                            }
                        }
                    }
                }
                else
                {
                    // if let theYear = years?[ row ].toInt()!
                    if let theYear = years?[ row ]
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
                                // println( "Finished the request: tours: \( tours )" )
                                self.selectedYear = self.years?[ row ]
                                self.tours = tours
                                if let firstTour = self.tours?.first!
                                {
                                    self.selectedTour = firstTour
                                }
                                
                                dispatch_async( dispatch_get_main_queue() )
                                {
                                    // println( "Reloading the season picker..." )
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
                // println( "Selected \( selectedTour )" )
                return
                
            default:
                selectedYear = nil
                selectedTour = nil
                // selectedSeason = nil
        }
    }
    
    // MARK: UITableViewDataSource, UITableViewDelegate methods
    
    func numberOfSectionsInTableView( tableView: UITableView ) -> Int
    {
        return 1
    }
    
    func tableView(
        tableView: UITableView,
        numberOfRowsInSection section: Int
    ) -> Int
    {
        return selectedTour!.shows.count
    }
    
    func tableView(
        tableView: UITableView,
        cellForRowAtIndexPath indexPath: NSIndexPath
    ) -> UITableViewCell
    {
        // dequeue a cell
        let cell = tableView.dequeueReusableCellWithIdentifier( "multiRowCalloutCell2", forIndexPath: indexPath ) as! MultiRowCalloutCell2
        
        // set the cell properties
        // this lets the class know not to dp anything to the cell's frame, which messes up the cell in the table view
        cell.isTableViewCell = true
        cell.dateLabel.text = selectedTour?.shows[ indexPath.row ].date
        cell.yearLabel.text = selectedTour?.shows[ indexPath.row ].year.description
        cell.venueLabel.text = selectedTour?.shows[ indexPath.row ].venue
        cell.cityLabel.text = selectedTour?.shows[ indexPath.row ].city
        
        // set the show so that the button can pass the correct show to the setlist page
        cell.show = selectedTour!.shows[ indexPath.row ]
        
        // set the MultiRowCalloutCell2ShowSetlist delegate
        cell.delegate = self
        
        // cell.contentView.sizeToFit()
        // cell.sizeToFit()
        
        return cell
    }
    
    func tableView(
        tableView: UITableView,
        didSelectRowAtIndexPath indexPath: NSIndexPath
    )
    {
        // de-select currently selected cell
        if currentHighlight != nil
        {
            let currentCell = tableView.cellForRowAtIndexPath( currentHighlight! )!
            
            currentCell.setHighlighted( false, animated: true )
            currentCell.setSelected( false, animated: false )
        }
        
        // get the venue
        let selectedCell = tableView.cellForRowAtIndexPath( indexPath ) as! MultiRowCalloutCell2
        let venue = selectedCell.venueLabel.text!
        
        // find the location associated with that venue
        if let locations = selectedTour!.locationDictionary[ venue ]
        {
            // set the current location
            currentLocation = locations.first!
            
            // if the info pane is up, drop it and zoom out
            if view.viewWithTag( 200 ) != nil
            {
                tourMap.setRegion(
                    MKCoordinateRegion(
                        center: CLLocationCoordinate2D(
                            latitude: currentLocation!.showLatitude!,
                            longitude: currentLocation!.showLongitude!
                        ),
                        span: MKCoordinateSpan(
                            latitudeDelta: 50.0,
                            longitudeDelta: 50.0
                        )
                    ),
                    animated: true
                )
                
                isZoomedOut = true
                
                bringUpInfoPane()
            }
            
            // dismiss the show list by faking pressing the tour nav controls;
            // set the states that the tour nav controls should revert to
            tourNavControls.selectedSegmentIndex = 2
            previousStatesOfTourNav = nil
            previousStatesOfTourNav = [ Int : Bool ]()
            previousStatesOfTourNav!.updateValue( true, forKey: 0 )
            previousStatesOfTourNav!.updateValue( false, forKey: 1 )
            previousStatesOfTourNav!.updateValue( true, forKey: 2 )
            previousStatesOfTourNav!.updateValue( false, forKey: 3 )
            selectTourNavigationOption( tourNavControls )
            tourNavControls.selectedSegmentIndex = -1
        
            tourMap.selectAnnotation( currentLocation!, animated: false )
        }
        else
        {
            println( "Couldn't find that location..." )
        }
    }
    
    // MARK: MultiRoeCalloutCell2ShowSetlist method
    
    func setlistButtonWasPressedInCell( cell: MultiRowCalloutCell2 )
    {
        // set the current location for the date that was selected
        currentLocation = cell.show
        
        let setlistViewController = SetlistViewController()
        setlistViewController.show = cell.show
        
        self.presentViewController(
            setlistViewController,
            animated: true,
            completion: nil
        )
        
        /*
        // get the shows at that location
        let currentVenue = currentLocation!.venue
        let showsAtVenue = selectedTour!.locationDictionary[ currentVenue ]!
        if let showIndex = find( showsAtVenue, cell.show! )
        {
            // found the show, present the setlist
            let setlistViewController = SetlistViewController()
            // setlistViewController.shows = showsAtVenue
            // setlistViewController.showIndex = showIndex
            
            self.presentViewController(
                setlistViewController,
                animated: true,
                completion: nil
            )
        }
        else
        {
            // there was an error finding the selected show
            println( "Couldn't get the showIndex..." )
        }
        */
    }
}
