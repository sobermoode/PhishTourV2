//
//  SongHistoryViewController.swift
//  PhishTourV2
//
//  Created by Aaron Justman on 10/17/15.
//  Copyright (c) 2015 AaronJ. All rights reserved.
//

import UIKit

class SongHistoryViewController: UIViewController
{
    var song: PhishSong!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        println( "SongHistoryViewController... \( song.name )" )
        view.backgroundColor = UIColor.whiteColor()
        
        createTitle()
        createHistory()
        addBackButton()
    }
    
    func createTitle()
    {
        println( "createTitle..." )
        let songLabel = UILabel()
        songLabel.backgroundColor = UIColor.blueColor()
        songLabel.font = UIFont( name: "AppleSDGothicNeo-Bold", size: 20 )
        songLabel.textColor = UIColor.orangeColor()
        songLabel.text = song.name
        songLabel.sizeToFit()
        
        songLabel.frame = CGRect(x: 25, y: 75, width: songLabel.frame.size.width, height: songLabel.frame.size.height)
        
        view.addSubview( songLabel )
    }
    
    func createHistory()
    {
        PhishinClient.sharedInstance().requestHistoryForSong( song )
        {
            historyError, history in
            
            if historyError != nil
            {
                println( "There was an error requesting the song history: \( historyError?.localizedDescription )" )
            }
            else
            {
                // self.song.history = history!
                // self.song.save()
                
                // println( "The song was played at: \( history! )" )
                /*
                for showID in history!
                {
                    println( "showID: \( showID )" )
                    
                    
                    
                    /*
                    let show = PhishShow.showDictionary[ showID ]!
                    let tour = show.tour
                    println( "\( self.song.name ) was played on \( show.date ) \( show.year ), \( tour.name )" )
                    */
                }
                */
            }
        }
    }
    
    func addBackButton()
    {
        let backButton = UIButton()
        backButton.layer.cornerRadius = 8
        backButton.backgroundColor = UIColor.redColor()
        backButton.titleLabel?.textColor = UIColor.whiteColor()
        backButton.titleLabel?.font = UIFont( name: "AppleSDGothicNeo-Bold", size: 14 )
        backButton.setTitle( "Back", forState: .Normal )
        backButton.titleLabel?.sizeToFit()
        backButton.sizeToFit()
        
        backButton.addTarget(self, action: "cancel:", forControlEvents: .TouchUpInside)
        
        view.addSubview( backButton )
    }
    
    func cancel( sender: UIButton )
    {
        dismissViewControllerAnimated( true, completion: nil )
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
