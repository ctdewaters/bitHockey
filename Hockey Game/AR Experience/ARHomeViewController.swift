//
//  ARHomeViewController.swift
//  Bit Hockey (iOS)
//
//  Created by Collin DeWaters on 9/18/18.
//  Copyright © 2018 Collin DeWaters. All rights reserved.
//

import UIKit
import ARKit

///`ARHomeViewController`: a `HomeViewController` subclass which will display the AR mode of the game.
class ARHomeViewController: HomeViewController, ARSCNViewDelegate {
    //MARK: - Properties.
    
    //MARK: - `HomeViewController` Overrides.
    override var isInRetroMode: Bool {
        return false
    }

    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    //MARK: - `ARSCNViewDelegate`.
    
}
