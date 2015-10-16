//
//  SetlistViewController.swift
//  PhishTourV2
//
//  Created by Aaron Justman on 10/13/15.
//  Copyright (c) 2015 AaronJ. All rights reserved.
//

import UIKit

class SetlistViewController: UIViewController,
    UITableViewDataSource, UITableViewDelegate
{
    var show: PhishShow!
    var setlist: [ Int : [ PhishSong ] ]?
    
    override func viewDidLoad()
    {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        view.backgroundColor = UIColor.whiteColor()
        
        // create the header labels
        let dateLabel = UILabel()
        dateLabel.tag = 10
        dateLabel.font = UIFont( name: "AppleSDGothicNeo-SemiBold", size: 22 )
        dateLabel.text = show.date
        dateLabel.sizeToFit()
        
        let yearLabel = UILabel()
        yearLabel.tag = 11
        yearLabel.font = UIFont( name: "AppleSDGothicNeo-Bold", size: 26 )
        yearLabel.text = show.year.description
        yearLabel.sizeToFit()
        
        let venueLabel = UILabel()
        venueLabel.tag = 12
        venueLabel.font = UIFont( name: "Apple SD Gothic Neo", size: 14 )
        venueLabel.text = show.venue + "  --  "
        venueLabel.sizeToFit()
        
        let cityLabel = UILabel()
        cityLabel.tag = 13
        cityLabel.font = UIFont( name: "Apple SD Gothic Neo", size: 14 )
        cityLabel.text = show.city
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
        
        let remainingHeight = view.bounds.height - (( dateLabel.frame.origin.x + dateLabel.frame.size.height ) + ( venueLabel.frame.size.height + 5 ) + ( cancelButton.frame.size.height ) + 50)
        let setlistTableView = UITableView(frame: CGRect(x: venueLabel.frame.origin.x, y: cancelButton.frame.origin.y + cancelButton.frame.size.height + 20, width: CGRectGetMaxX(view.bounds) - 50, height: remainingHeight - 75), style: .Plain)
        setlistTableView.tag = 600
        setlistTableView.dataSource = self
        view.addSubview( setlistTableView )
        
        PhishinClient.sharedInstance().requestSetlistForShow( show )
        {
            setlistError, setlist in
            
            if setlistError != nil
            {
                println( "There was an error requesting the setlist for \( self.show.date ) \( self.show.year ): \( setlistError?.localizedDescription ) " )
            }
            else
            {                
                self.setlist = setlist!
                
                dispatch_async( dispatch_get_main_queue() )
                {
                    let setlistTable = self.view.viewWithTag( 600 ) as! UITableView
                    setlistTable.reloadData()
                }
            }
        }
    }
    
    func cancel( sender: UIButton )
    {
        dismissViewControllerAnimated( true, completion: nil )
    }
    
    func numberOfSectionsInTableView( tableView: UITableView ) -> Int
    {
        if setlist != nil
        {
            let numberOfSets: [ Int ] = setlist!.keys.array
        
            return numberOfSets.count
        }
        else
        {
            return 0
        }
    }
    
    func tableView(
        tableView: UITableView,
        numberOfRowsInSection section: Int
    ) -> Int
    {
        if setlist != nil
        {
            var set: Int = section + 1
            
            if let songs: [ PhishSong ] = setlist![ set ]
            {
                return songs.count
            }
            else
            {
                set = 10
                let songs: [ PhishSong ] = setlist![ set ]!
                
                return songs.count
            }
        }
        else
        {
            return 0
        }
    }
    
    func tableView(
        tableView: UITableView,
        titleForHeaderInSection section: Int
    ) -> String?
    {
        if section == tableView.numberOfSections() - 1
        {
            return "Encore"
        }
        else
        {
            return "Set \( section + 1 )"
        }
    }
    
    func tableView(
        tableView: UITableView,
        cellForRowAtIndexPath indexPath: NSIndexPath
    ) -> UITableViewCell
    {
        let cell = UITableViewCell(style: .Default, reuseIdentifier: "songCell")
        
        if setlist != nil
        {
            var set: Int = indexPath.section + 1
            var song: PhishSong
            
            if let songs: [ PhishSong ] = setlist![ set ]
            {
                song = songs[ indexPath.row ]
            }
            else
            {
                set = 10
                let songs: [ PhishSong ] = setlist![ set ]!
                song = songs[ indexPath.row ]
            }
            
            cell.textLabel?.text = song.name + "  " + song.duration
        }
        else
        {
            cell.textLabel?.text = ""
        }
        
        return cell
    }
}