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
        println( "Setlist for \( currentShow.date ) \( currentShow.year )" )
        
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
                println( "Got setlist: \( setlist )" )
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
