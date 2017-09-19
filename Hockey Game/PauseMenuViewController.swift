//
//  PauseMenuViewController.swift
//  Bit Hockey (iOS)
//
//  Created by Collin DeWaters on 9/19/17.
//  Copyright © 2017 Collin DeWaters. All rights reserved.
//

import UIKit

class PauseMenuViewController: UIViewController {
    @IBOutlet weak var scoreboardView: UIView!
    @IBOutlet weak var roadScoreLabel: UILabel!
    @IBOutlet weak var homeScoreLabel: UILabel!
    @IBOutlet weak var timeRemainingLabel: UILabel!
    @IBOutlet weak var resumeButton: UIButton!
    @IBOutlet weak var quitButton: UIButton!
    @IBOutlet weak var blur: UIVisualEffectView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        self.scoreboardView.setCornerRadius(toValue: 25)
        self.resumeButton.setCornerRadius(toValue: self.resumeButton.frame.height / 3)
        self.quitButton.setCornerRadius(toValue: self.quitButton.frame.height / 3)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
