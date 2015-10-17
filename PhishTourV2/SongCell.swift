//
//  SongCell.swift
//  PhishTourV2
//
//  Created by Aaron Justman on 10/16/15.
//  Copyright (c) 2015 AaronJ. All rights reserved.
//

import UIKit

class SongCell: UITableViewCell
{
    var song: PhishSong!
    
    override init(
        style: UITableViewCellStyle,
        reuseIdentifier: String?
    )
    {
        super.init(
            style: .Value1,
            reuseIdentifier: "songCell"
        )
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
