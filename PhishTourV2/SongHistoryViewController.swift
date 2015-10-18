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
                println( "The song was played at: \( history! )" )
            }
        }
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
