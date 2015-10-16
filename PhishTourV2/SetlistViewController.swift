//
//  SetlistViewController.swift
//  PhishTourV2
//
//  Created by Aaron Justman on 10/13/15.
//  Copyright (c) 2015 AaronJ. All rights reserved.
//

import UIKit

class SetlistViewController: UIViewController
{
    var shows: [ PhishShow ]!
    var showIndex: Int!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        view.backgroundColor = UIColor.whiteColor()
        
        let currentShow: PhishShow = shows[ showIndex ]
        // println( "Setlist for \( currentShow.date ) \( currentShow.year )" )
        
        // create the header labels
        let dateLabel = UILabel()
        dateLabel.tag = 10
        dateLabel.font = UIFont( name: "AppleSDGothicNeo-SemiBold", size: 22 )
        dateLabel.text = currentShow.date
        dateLabel.sizeToFit()
        
        let yearLabel = UILabel()
        yearLabel.tag = 11
        yearLabel.font = UIFont( name: "AppleSDGothicNeo-Bold", size: 26 )
        yearLabel.text = currentShow.year.description
        yearLabel.sizeToFit()
        
        let venueLabel = UILabel()
        venueLabel.tag = 12
        venueLabel.font = UIFont( name: "Apple SD Gothic Neo", size: 14 )
        venueLabel.text = currentShow.venue + "  --  "
        venueLabel.sizeToFit()
        
        let cityLabel = UILabel()
        cityLabel.tag = 13
        cityLabel.font = UIFont( name: "Apple SD Gothic Neo", size: 14 )
        cityLabel.text = currentShow.city
        cityLabel.sizeToFit()
        
        dateLabel.frame = CGRect(x: 25, y: 75, width: dateLabel.frame.size.width, height: dateLabel.frame.size.height)
        yearLabel.frame = CGRect(x: dateLabel.frame.origin.x + dateLabel.frame.size.width + 5, y: dateLabel.frame.origin.y - 3, width: yearLabel.frame.size.width, height: yearLabel.frame.size.height)
        venueLabel.frame = CGRect(x: dateLabel.frame.origin.x, y: dateLabel.frame.origin.y + dateLabel.frame.size.height + 5, width: venueLabel.frame.size.width, height: venueLabel.frame.size.height)
        cityLabel.frame = CGRect(x: venueLabel.frame.origin.x + venueLabel.frame.size.width + 5, y: venueLabel.frame.origin.y, width: cityLabel.frame.size.width, height: cityLabel.frame.size.height)
        
        let cancelButton = UIButton()
        cancelButton.layer.cornerRadius = 8
        cancelButton.backgroundColor = UIColor.redColor()
        cancelButton.titleLabel?.textColor = UIColor.whiteColor()
        cancelButton.titleLabel?.font = UIFont( name: "AppleSDGothicNeo-Bold", size: 14 )
        cancelButton.setTitle( "Cancel", forState: .Normal )
        cancelButton.titleLabel?.sizeToFit()
        cancelButton.sizeToFit()
        cancelButton.frame = CGRect(x: CGRectGetMidX( view.bounds ) - ( cancelButton.frame.size.width / 2 ), y: venueLabel.frame.origin.y + venueLabel.frame.size.height + 20, width: cancelButton.frame.size.width + 10, height: cancelButton.frame.size.height )
        cancelButton.addTarget(self, action: "cancel:", forControlEvents: .TouchUpInside)
        
        view.addSubview( dateLabel )
        view.addSubview( yearLabel )
        view.addSubview( venueLabel )
        view.addSubview( cityLabel )
        view.addSubview( cancelButton )
        
        PhishinClient.sharedInstance().requestSetlistForShow( currentShow )
        {
            setlistError, setlist in
            
            if setlistError != nil
            {
                println( "There was an error requesting the setlist for \( currentShow.date ) \( currentShow.year ): \( setlistError?.localizedDescription ) " )
            }
            else
            {
                // println( "Got the setlist: \( setlist )" )
                // var setNumbers: [ Int ]
                // setNumbers = Array(arrayLiteral: setlist?.keys)
                let setNumbers = setlist!.keys.array
                for setNumber in setNumbers
                {
                    let set = setlist![ setNumber ]
                    println( "Set \( setNumber ): " )
                    for song in set!
                    {
                        println( "\( song.name )  \( song.duration )" )
                    }
                }
                
                // set the setlist on the current show
                // TODO: when implementing Core Data, save the context here
                // currentShow.setlist = setlist!
                
                /*
                var songNames = [ UILabel ]()
                var songDurations = [ UILabel ]()
                var widestLabel: CGFloat = 0
                for song in setlist!
                {
                    println( "Creating a label..." )
                    let songNameLabel = UILabel()
                    songNameLabel.font = UIFont( name: "Apple SD Gothic Neo", size: 14 )
                    songNameLabel.text = song.name
                    songNameLabel.sizeToFit()
                    songNames.append( songNameLabel )
                    
                    widestLabel = ( songNameLabel.frame.size.width > widestLabel ) ? songNameLabel.frame.size.width : widestLabel
                    
                    let songDurationLabel = UILabel()
                    songDurationLabel.font = UIFont( name: "Apple SD Gothic Neo", size: 14 )
                    songDurationLabel.text = "\( song.duration )"
                    songDurationLabel.sizeToFit()
                    songDurations.append( songDurationLabel )
                }
                
                var previousLabel = UILabel(frame: CGRect(x: venueLabel.frame.origin.x, y: cancelButton.frame.origin.y + cancelButton.frame.size.height + 15, width: 0, height: 0))
                for ( index, label ) in enumerate( songNames )
                {
                    println( "Setting the frames..." )
                    label.frame = CGRect(x: previousLabel.frame.origin.x, y: previousLabel.frame.origin.y + previousLabel.frame.size.height + 5, width: widestLabel, height: label.frame.size.height)
                    
                    let durationLabel = songDurations[ index ]
                    durationLabel.frame = CGRect(x: label.frame.origin.x + label.frame.size.width + 10, y: label.frame.origin.y, width: durationLabel.frame.size.width, height: durationLabel.frame.size.height)
                    
                    previousLabel = label
                }
                
                for ( index, song ) in enumerate( songNames )
                {
                    println( "Adding the labels..." )
                    let duration = songDurations[ index ]
                    
                    dispatch_async( dispatch_get_main_queue() )
                    {
                        self.view.addSubview( song )
                        self.view.addSubview( duration )
                    }
                }
                */
                
                /*
                dispatch_async( dispatch_get_main_queue() )
                {
                    self.view.addSubview( label )
                    self.view.addSubview( durationLabel )
                }
                */
            }
        }
    }
    
    func cancel( sender: UIButton )
    {
        dismissViewControllerAnimated( true, completion: nil )
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
