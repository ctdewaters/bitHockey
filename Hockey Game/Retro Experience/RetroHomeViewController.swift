//
//  HomeViewController.swift
//  Bit Hockey (iOS)
//
//  Created by Collin DeWaters on 9/17/17.
//  Copyright © 2017 Collin DeWaters. All rights reserved.
//

import UIKit

///`HomeViewController`: first interface the user sees when entering the app.
class RetroHomeViewController: HomeViewController {
    
    //MARK: - `HomeViewController` overrides.
    override var isInRetroMode: Bool {
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.playButton.setCornerRadius(toValue: self.playButton.frame.height / 3)
        self.controlsButton.setCornerRadius(toValue: self.controlsButton.frame.height / 3)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}


extension UIView {
    func setCornerRadius(toValue value: CGFloat) {
        self.clipsToBounds = true
        self.layer.cornerRadius = value
    }
}
