//
//  HomeViewController.swift
//  Bit Hockey (iOS)
//
//  Created by Collin DeWaters on 9/17/17.
//  Copyright © 2017 Collin DeWaters. All rights reserved.
//

import UIKit

protocol HomeViewControllerDelegate {
    func homeVCDidRespondToPlayButton()
    func homeVCDidRespondToControlsButton()
}

class HomeViewController: UIViewController {
    //MARK: - IBOutlets
    @IBOutlet weak var captionLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var controlsButton: UIButton!
    
    var delegate: HomeViewControllerDelegate?
    
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
    
    @IBAction func buttonPressed(_ sender: Any) {
        guard let button = sender as? UIButton else {
            return
        }
        
        if button == self.playButton {
            //Play button pressed.
            self.delegate?.homeVCDidRespondToPlayButton()
        }
        else {
            //Show controls.
            self.delegate?.homeVCDidRespondToControlsButton()
        }
    }
}


extension UIView {
    func setCornerRadius(toValue value: CGFloat) {
        self.clipsToBounds = true
        self.layer.cornerRadius = value
    }
}
