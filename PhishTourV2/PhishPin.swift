//
//  PhishPin.swift
//  PhishTourV2
//
//  Created by Aaron Justman on 10/11/15.
//  Copyright (c) 2015 AaronJ. All rights reserved.
//

import UIKit
import MapKit

class PhishPin: MKAnnotationView
{
    var consecutiveNights: Int!
    
    override init!(annotation: MKAnnotation!, reuseIdentifier: String!) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        
        let show = annotation as! PhishShow
        self.consecutiveNights = show.consecutiveNights
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
//    override init!(
//        annotation: MKAnnotation!,
//        reuseIdentifier: String!
//    )
//    {
//        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
//        
//        
//    }
    
//    init()
//    {
//        // super.init(annotation: <#MKAnnotation!#>, reuseIdentifier: <#String!#>)
//    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        let show = self.annotation as! PhishShow
        self.consecutiveNights = show.consecutiveNights
    }
}
