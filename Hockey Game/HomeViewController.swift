//
//  HomeViewController.swift
//  Bit Hockey (iOS)
//
//  Created by Collin DeWaters on 9/18/18.
//  Copyright © 2018 Collin DeWaters. All rights reserved.
//

import UIKit

///`HomeViewControllerDelegate`: contains callback functions for the view controller's buttons.
protocol HomeViewControllerDelegate {
    func homeVCDidRespondToPlayButton()
    func homeVCDidRespondToControlsButton()
}

///`HomeViewController`: super class for home view controllers.
class HomeViewController: UIViewController {
    //MARK: - IBOutlets.
    ///The caption label, which tells the user what game mode they are currently in.
    @IBOutlet weak var captionLabel: UILabel!
    
    ///The title label, which displays "Bit Hockey".
    @IBOutlet weak var titleLabel: UILabel!
    
    ///The play button, which will call the appropriate delegate function to start gameplay.
    @IBOutlet weak var playButton: UIButton!
    
    ///The controls button, which will call the appropriate delegate function to show the controls to the user.
    @IBOutlet weak var controlsButton: UIButton!
    
    ///The switch button, which will switch the current game mode.
    @IBOutlet weak var switchButton: UIButton!
    
    ///If true, this view controller is set for retro mode.
    public var isInRetroMode: Bool {
        return true
    }

    //MARK: - Properties.
    ///The home vc delegate instance.
    public var delegate: HomeViewControllerDelegate?
    
    //MARK: - IBActions.
    @IBAction func buttonPressed(_ sender: Any) {
        guard let button = sender as? UIButton else {
            return
        }
        if button == self.playButton {
            //Play button pressed.
            self.delegate?.homeVCDidRespondToPlayButton()
            return
        }
        else if button == self.switchButton {
            //Switch button pressed.
            //Check if this VC is in retro mode.
            if self.isInRetroMode {
                //Go to AR experience.
                self.performSegue(withIdentifier: "retroToAR", sender: self)
            }
            else {
                //Go to retro mode.
                self.performSegue(withIdentifier: "arToRetro", sender: self)
            }
            return
        }
        //Controls button pressed.
        self.delegate?.homeVCDidRespondToControlsButton()
    }
}
