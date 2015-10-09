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
    MKMapViewDelegate, UIPickerViewDataSource, UIPickerViewDelegate, UITableViewDataSource, UITableViewDelegate
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
    var currentShow: PhishShow?
    var didDropPins: Bool = false
    var isZoomedOut: Bool = true
    var didAddAnnotations: Bool = false
    var didMakeTourTrail: Bool = false
    var dontGoBack: Bool = false
    var didStartTour: Bool = false
    var isResuming: Bool = false
    var previousStatesOfTourNav: [ Int : Bool ]? = nil
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
        // bringUpInfoPane()
        
        if let showList = view.viewWithTag( 300 )
        {
            bringInShowList()
        }
        
        tourMap.setRegion( defaultRegion, animated: true )
        
        resetButton.enabled = false
    }
    
    /*
    func resetTourNavControls( resume: Bool = false, tourNav: Bool = false )
    {
        if tourNav
        {
            tourNavControls.setEnabled( false, forSegmentAtIndex: 0 )
            tourNavControls.setEnabled( false, forSegmentAtIndex: 1 )
            tourNavControls.setEnabled( true, forSegmentAtIndex: 2 )
            tourNavControls.setEnabled( false, forSegmentAtIndex: 3 )
        }
        else
        {
            let titleOption: String = ( resume ) ? "Resume" : "Start"
            println( "titleOption: \( titleOption )" )
            isResuming = resume
            
            tourNavControls.setTitle( titleOption, forSegmentAtIndex: 0 )
            tourNavControls.setEnabled( true, forSegmentAtIndex: 0 )
            tourNavControls.setEnabled( false, forSegmentAtIndex: 1 )
            tourNavControls.setEnabled( true, forSegmentAtIndex: 2 )
            // tourNavControls.setEnabled( false, forSegmentAtIndex: 3 )
            let oneShow = ( selectedTour!.shows.count == 1 ) ? false : true
            tourNavControls.setEnabled( oneShow, forSegmentAtIndex: 3 )
            
            // didStartTour = false
            // didStartTour = resume
        }
    }
    */
    
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
            println( "didStartTour" )
            tourMap.setRegion( defaultRegion, animated: true )
            
            // resetTourNavControls()
            tourNavControls.setTitle( "Start", forSegmentAtIndex: 0 )
            tourNavControls.setEnabled( true, forSegmentAtIndex: 0 )
            tourNavControls.setEnabled( false, forSegmentAtIndex: 1 )
            tourNavControls.setEnabled( true, forSegmentAtIndex: 2 )
            tourNavControls.setEnabled( false, forSegmentAtIndex: 3 )
            
            // dropInfoPane()
            // bringUpInfoPane()
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
                        self.currentShow = theTour.shows.first
                        
                        self.showTourTitle()
                        self.centerOnFirstShow()
                        
                        // NOTE: dispatch_after trick cribbed from http://stackoverflow.com/a/24034838
                        let delayTime = dispatch_time(
                            DISPATCH_TIME_NOW,
                            Int64( 2 * Double( NSEC_PER_SEC ) )
                        )
                        dispatch_after( delayTime, dispatch_get_main_queue() )
                        {
                            self.tourMap.addAnnotations( theTour.shows )
                        }
                        
                        self.tourNavControls.hidden = false
                        // self.resetTourNavControls(resume: false)
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
        
        let oneShow = ( selectedTour!.shows.count == 1 ) ? false : true
        tourNavControls.setEnabled( oneShow, forSegmentAtIndex: 3 )
        
        if currentShow != nil
        {
            tourMap.deselectAnnotation( currentShow!, animated: true )
        }
        
        currentShow = ( currentShow == nil ) ? selectedTour!.shows.first! : currentShow
        
        zoomInOnCurrentShow()
        // bringInShowList()
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
        
        let lastShow = (find( selectedTour!.shows, currentShow! ) == selectedTour!.shows.count - 1) ? false : true
        tourNavControls.setEnabled( lastShow, forSegmentAtIndex: 3 )
        
        if currentShow != nil
        {
            tourMap.deselectAnnotation( currentShow!, animated: true )
        }
        
        currentShow = ( currentShow == nil ) ? selectedTour!.shows.first! : currentShow
        
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
            center: currentShow!.coordinate,
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
            let blurEffect = UIBlurEffect( style: .Dark )
            // let vibrancyEffect = UIVibrancyEffect( forBlurEffect: blurEffect )
            let infoPane = UIVisualEffectView( effect: blurEffect )
            // let vibrancyView = UIVisualEffectView( effect: vibrancyEffect )
            
            infoPane.tag = 200
            infoPane.frame = CGRect(
                x: 0, y: CGRectGetMaxY( view.bounds ) + 1,
                width: view.bounds.size.width - 25, height: 225
            )
            infoPane.frame.origin = CGPoint(
                x: CGRectGetMidX( view.bounds ) - infoPane.frame.size.width / 2,
                y: infoPane.frame.origin.y
            )
    //        vibrancyView.frame = CGRect(
    //            x: 0, y: 0,
    //            width: infoPane.frame.size.width, height: infoPane.frame.size.height
    //        )
    //        
    //        infoPane.addSubview( vibrancyView )
            
            let dateLabel = UILabel()
            dateLabel.tag = 201
            dateLabel.textColor = UIColor.whiteColor()
            dateLabel.font = UIFont( name: "AppleSDGothicNeo-Bold", size: 24 )
            dateLabel.text = currentShow!.date + " \( currentShow!.year )"
            dateLabel.sizeToFit()
            
            let venueLabel = UILabel()
            venueLabel.tag = 202
            venueLabel.textColor = UIColor.whiteColor()
            venueLabel.font = UIFont( name: "Apple SD Gothic Neo", size: 18 )
            venueLabel.text = currentShow?.venue
            venueLabel.sizeToFit()
            
            let cityLabel = UILabel()
            cityLabel.tag = 203
            cityLabel.textColor = UIColor.whiteColor()
            cityLabel.font = UIFont( name: "Apple SD Gothic Neo", size: 18 )
            cityLabel.text = currentShow?.city
            cityLabel.sizeToFit()
            
            dateLabel.frame.origin = CGPoint(
                x: CGRectGetMidX( infoPane.contentView.bounds ) - ( dateLabel.frame.size.width / 2 ),
                y: 5
            )
            venueLabel.frame.origin = CGPoint(
                x: CGRectGetMidX( infoPane.contentView.bounds ) - ( venueLabel.frame.size.width / 2 ),
                y: dateLabel.frame.origin.y + dateLabel.frame.size.height + 5
            )
            cityLabel.frame.origin = CGPoint(
                x: CGRectGetMidX( infoPane.contentView.bounds ) - ( cityLabel.frame.size.width / 2 ),
                y: venueLabel.frame.origin.y + venueLabel.frame.size.height + 5
            )
            
            infoPane.contentView.addSubview( dateLabel )
            infoPane.contentView.addSubview( venueLabel )
            infoPane.contentView.addSubview( cityLabel )
            view.insertSubview( infoPane, belowSubview: blurEffectView )
            
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
                
                if find( selectedTour!.shows, currentShow! ) == 0
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
                        latitude: currentShow!.showLatitude,
                        longitude: currentShow!.showLongitude
                    ),
                    span: MKCoordinateSpan(
                        latitudeDelta: 50.0,
                        longitudeDelta: 50.0
                    )
                ),
                animated: true
            )
            tourMap.selectAnnotation( currentShow, animated: true )
            
            // dropInfoPane()
            bringUpInfoPane()
            
            if find( selectedTour!.shows, currentShow! ) != 0
            {
                tourNavControls.setTitle( "Resume", forSegmentAtIndex: 0 )
                // resetTourNavControls( resume: true )
            }
            else
            {
                // resetTourNavControls()
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
            
            // resetTourNavControls( tourNav: true )
//            tourNavControls.setEnabled( false, forSegmentAtIndex: 0 )
//            tourNavControls.setEnabled( false, forSegmentAtIndex: 1 )
//            tourNavControls.setEnabled( true, forSegmentAtIndex: 2 )
//            tourNavControls.setEnabled( false, forSegmentAtIndex: 3 )
            
        case 3:
            println( "Pressed the NextShow button." )
            
            goToNextShow()
            
            tourNavControls.setEnabled( true, forSegmentAtIndex: 0 )
            
            if find( selectedTour!.shows, currentShow! ) == selectedTour!.shows.count - 1
            {
                tourNavControls.setEnabled( false, forSegmentAtIndex: 3 )
            }
            
        default:
            println( "I don't know what button was pressed!!!" )
        }
    }
    
    func goBackToPreviousShow()
    {
        var showIndex = find( selectedTour!.shows, currentShow! )!
        showIndex--
        
        currentShow = selectedTour!.shows[ showIndex ]
        
        let previousShowCoordinate = currentShow!.coordinate
        tourMap.setCenterCoordinate( previousShowCoordinate, animated: true )
        
        let infoPane = view.viewWithTag( 200 )! as! UIVisualEffectView
        let dateLabel = infoPane.viewWithTag( 201 )! as! UILabel
        let venueLabel = infoPane.viewWithTag( 202 )! as! UILabel
        let cityLabel = infoPane.viewWithTag( 203 )! as! UILabel
        
        dateLabel.text = currentShow!.date + " \( currentShow!.year )"
        dateLabel.sizeToFit()
        venueLabel.text = currentShow?.venue
        venueLabel.sizeToFit()
        cityLabel.text = currentShow?.city
        cityLabel.sizeToFit()
        
        venueLabel.frame.origin = CGPoint(
            x: CGRectGetMidX( infoPane.contentView.bounds ) - ( venueLabel.frame.size.width / 2 ),
            y: dateLabel.frame.origin.y + dateLabel.frame.size.height + 5
        )
        cityLabel.frame.origin = CGPoint(
            x: CGRectGetMidX( infoPane.contentView.bounds ) - ( cityLabel.frame.size.width / 2 ),
            y: venueLabel.frame.origin.y + venueLabel.frame.size.height + 5
        )
    }
    
    func goToNextShow()
    {
        // tourNavControls.setEnabled( true, forSegmentAtIndex: 0 )
        
        var showIndex = find( selectedTour!.shows, currentShow! )!
        showIndex++
        
        currentShow = selectedTour!.shows[ showIndex ]
        
        let nextShowCoordinate = currentShow!.coordinate
        tourMap.setCenterCoordinate( nextShowCoordinate, animated: true )
        
        let infoPane = view.viewWithTag( 200 )! as! UIVisualEffectView
        let dateLabel = infoPane.viewWithTag( 201 )! as! UILabel
        let venueLabel = infoPane.viewWithTag( 202 )! as! UILabel
        let cityLabel = infoPane.viewWithTag( 203 )! as! UILabel
        
        dateLabel.text = currentShow!.date + " \( currentShow!.year )"
        dateLabel.sizeToFit()
        venueLabel.text = currentShow?.venue
        venueLabel.sizeToFit()
        cityLabel.text = currentShow?.city
        cityLabel.sizeToFit()
        
        venueLabel.frame.origin = CGPoint(
            x: CGRectGetMidX( infoPane.contentView.bounds ) - ( venueLabel.frame.size.width / 2 ),
            y: dateLabel.frame.origin.y + dateLabel.frame.size.height + 5
        )
        cityLabel.frame.origin = CGPoint(
            x: CGRectGetMidX( infoPane.contentView.bounds ) - ( cityLabel.frame.size.width / 2 ),
            y: venueLabel.frame.origin.y + venueLabel.frame.size.height + 5
        )
        
//        if isZoomedOut
//        {
//            isZoomedOut = false
//            tourNavControls.setEnabled( true, forSegmentAtIndex: 1 )
//        }
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
                        
                        
                        // self.resetTourNavControls()
                        
//                        if self.didStartTour
//                        {
//                            let tourNavControls = self.view.viewWithTag( 400 ) as! UISegmentedControl
//                            tourNavControls.setEnabled( true, forSegmentAtIndex: 0 )
//                            tourNavControls.setEnabled( true, forSegmentAtIndex: 1 )
//                            tourNavControls.setEnabled( true, forSegmentAtIndex: 2 )
//                            tourNavControls.setEnabled( true, forSegmentAtIndex: 3 )
//                        }
                    }
                }
            )
        }
        else
        {
            if didStartTour
            {
//                let tourNavControls = view.viewWithTag( 400 ) as! UISegmentedControl
//                tourNavControls.setEnabled( false, forSegmentAtIndex: 0 )
//                tourNavControls.setEnabled( false, forSegmentAtIndex: 1 )
//                tourNavControls.setEnabled( true, forSegmentAtIndex: 2 )
//                tourNavControls.setEnabled( false, forSegmentAtIndex: 3 )
                // self.resetTourNavControls()
            }
            
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
            
            // showListTable.reloadData()
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
                        self.tourNavControls.setEnabled( false, forSegmentAtIndex: 0 )
                        self.tourNavControls.setEnabled( false, forSegmentAtIndex: 1 )
                        self.tourNavControls.setEnabled( true, forSegmentAtIndex: 2 )
                        self.tourNavControls.setEnabled( false, forSegmentAtIndex: 3 )
                    }
                }
            )
        }
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
    
    func mapView(
        mapView: MKMapView!,
        didAddAnnotationViews views: [AnyObject]!
    )
    {
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
        let selectedShow = view.annotation as! PhishShow
        currentShow = selectedShow
        
        if find( selectedTour!.shows, selectedShow ) != 0
        {
            tourNavControls.setTitle( "Resume", forSegmentAtIndex: 0 )
            isResuming = true
            // resetTourNavControls( resume: true )
        }
        else
        {
            tourNavControls.setTitle( "Start", forSegmentAtIndex: 0 )
            isResuming = false
            // resetTourNavControls()
        }
        
        tourNavControls.setEnabled( true, forSegmentAtIndex: 0 )
        tourNavControls.setEnabled( false, forSegmentAtIndex: 1 )
        tourNavControls.setEnabled( true, forSegmentAtIndex: 2 )
        tourNavControls.setEnabled( false, forSegmentAtIndex: 3 )
        
        let annotationCoordinate = view.annotation.coordinate
        let viewPosition = mapView.convertCoordinate(
            annotationCoordinate,
            toPointToView: mapView
        )
        
        let callout = CalloutCellView()
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
        // let cell = UITableViewCell(style: .Default, reuseIdentifier: "showListCell")
        let cell = tableView.dequeueReusableCellWithIdentifier( "multiRowCalloutCell2", forIndexPath: indexPath ) as! MultiRowCalloutCell2
        
        // cell.textLabel?.text = "SHOW"
        cell.dateLabel.text = selectedTour?.shows[ indexPath.row ].date
        cell.yearLabel.text = selectedTour?.shows[ indexPath.row ].year.description
        cell.venueLabel.text = selectedTour?.shows[ indexPath.row ].venue
        cell.cityLabel.text = selectedTour?.shows[ indexPath.row ].city
        println( "cell \( indexPath.row ) width: \( cell.cityLabel.frame.size.width )" )
        
        // cell.contentView.sizeToFit()
        // cell.sizeToFit()
        
        return cell
    }
}
