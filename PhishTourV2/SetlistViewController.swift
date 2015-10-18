//
//  SetlistViewController.swift
//  PhishTourV2
//
//  Created by Aaron Justman on 10/13/15.
//  Copyright (c) 2015 AaronJ. All rights reserved.
//

import UIKit

class SetlistViewController: UIViewController,
    UITableViewDataSource , UITableViewDelegate
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
        
        let backButton = UIButton()
        backButton.layer.cornerRadius = 8
        backButton.backgroundColor = UIColor.redColor()
        backButton.titleLabel?.textColor = UIColor.whiteColor()
        backButton.titleLabel?.font = UIFont( name: "AppleSDGothicNeo-Bold", size: 14 )
        backButton.setTitle( "Back", forState: .Normal )
        backButton.titleLabel?.sizeToFit()
        backButton.sizeToFit()
        
        
        view.addSubview( dateLabel )
        view.addSubview( yearLabel )
        view.addSubview( venueLabel )
        view.addSubview( cityLabel )
        // view.addSubview( cancelButton )venueLabel.frame.origin.y + venueLabel.frame.size.height + 20
        
        let remainingHeight = view.bounds.height - (( dateLabel.frame.origin.x + dateLabel.frame.size.height ) + ( venueLabel.frame.size.height + 5 ) + ( backButton.frame.size.height ) + 50)
        let setlistTableView = UITableView(frame: CGRect(x: venueLabel.frame.origin.x, y: venueLabel.frame.origin.y + venueLabel.frame.size.height + 20, width: CGRectGetMaxX(view.bounds) - 50, height: remainingHeight - 75), style: .Plain)
        setlistTableView.tag = 600
        setlistTableView.dataSource = self
        setlistTableView.delegate = self
        
        // register the table view's cell class and header class
        setlistTableView.registerClass(
            SongCell.self,
            forCellReuseIdentifier: "songCell"
        )
        setlistTableView.registerClass(
            UITableViewHeaderFooterView.self,
            forHeaderFooterViewReuseIdentifier: "SetHeader"
        )
        
        backButton.frame = CGRect(x: CGRectGetMidX( view.bounds ) - ( backButton.frame.size.width / 2 ), y: setlistTableView.frame.origin.y + setlistTableView.frame.size.height + 20, width: backButton.frame.size.width + 10, height: backButton.frame.size.height )
        backButton.addTarget(self, action: "cancel:", forControlEvents: .TouchUpInside)
        setlistTableView.separatorStyle = .None
        view.addSubview( setlistTableView )
        view.addSubview( backButton )
        
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
    
    // MARK: UITableViewDataSource methods
    
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
    
    // custom header view
    func tableView(
        tableView: UITableView,
        viewForHeaderInSection section: Int
    ) -> UIView?
    {
        let headerView = tableView.dequeueReusableHeaderFooterViewWithIdentifier( "SetHeader" ) as! UITableViewHeaderFooterView
        
        if setlist != nil
        {
            if tableView.numberOfSections() == 1
            {
                headerView.textLabel.text = ""
            }
            else
            {
                if section == tableView.numberOfSections() - 1
                {
                    headerView.textLabel.text = "Encore"
                }
                else
                {
                    headerView.textLabel.text = "Set \( section + 1 )"
                }
            }
        }
        else
        {
            headerView.textLabel.text = ""
        }
        
        return headerView
    }
    
    // customize the header view before it is displayed
    func tableView(
        tableView: UITableView,
        willDisplayHeaderView view: UIView,
        forSection section: Int
    )
    {
        let headerView = view as! UITableViewHeaderFooterView
        
        headerView.layer.borderColor = UIColor.orangeColor().CGColor
        headerView.layer.borderWidth = 1
        headerView.textLabel.font = UIFont( name: "AppleSDGothicNeo-Bold", size: 14 )
    }
    
    func tableView(
        tableView: UITableView,
        heightForHeaderInSection section: Int
    ) -> CGFloat
    {
        return 30
    }
    
    func tableView(
        tableView: UITableView,
        heightForRowAtIndexPath indexPath: NSIndexPath
    ) -> CGFloat
    {
        return 25
    }
    
    func tableView(
        tableView: UITableView,
        cellForRowAtIndexPath indexPath: NSIndexPath
    ) -> UITableViewCell
    {
        // dequeue a cell
        let cell = tableView.dequeueReusableCellWithIdentifier( "songCell", forIndexPath: indexPath ) as! SongCell
        
        // make sure the request was successful, and we have info to give to the table view
        if setlist != nil
        {
            var set: Int = indexPath.section + 1
            var song: PhishSong
            
            // get the songs for the given set
            if let songs: [ PhishSong ] = setlist![ set ]
            {
                song = songs[ indexPath.row ]
            }
            // the encore
            else
            {
                set = 10
                let songs: [ PhishSong ] = setlist![ set ]!
                song = songs[ indexPath.row ]
            }
            
            // set the cell properties
            cell.song = song
            
            cell.textLabel?.font = UIFont( name: "Apple SD Gothic Neo", size: 14 )
            cell.textLabel?.text = song.name
            
            cell.detailTextLabel?.font = UIFont( name: "Apple SD Gothic Neo", size: 14 )
            cell.detailTextLabel?.text = song.duration
        }
        // no table info yet, just keep the cell blank for the time being
        else
        {
            cell.textLabel?.text = ""
            cell.detailTextLabel?.text = ""
        }
        
        return cell
    }
    
    func tableView(
        tableView: UITableView,
        didSelectRowAtIndexPath indexPath: NSIndexPath
    )
    {
        let cell = tableView.cellForRowAtIndexPath( indexPath ) as! SongCell
        
        // let song: PhishSong = cell.song
        // println( "Gonna show the history for \( song.name )" )
        
        let songHistory = SongHistoryViewController()
        songHistory.song = cell.song
        
        presentViewController( songHistory, animated: true, completion: nil )
        
        /*
        PhishinClient.sharedInstance().requestHistoryForSong( song )
        {
            historyError, success in
            
            if historyError != nil
            {
                println( "There was an error requesting the song history: \( historyError?.localizedDescription )" )
            }
            else if success!
            {
                // println( "The song was played at: \( song.history! )" )
                // let songHistory = self.storyboard?.instantiateViewControllerWithIdentifier( "SongHistory" ) as! SongHistoryViewController
                let songHistory = SongHistoryViewController()
                songHistory.song = song
                
                self.presentViewController( songHistory, animated: true, completion: nil )
            }
        }
        */
    }
}
