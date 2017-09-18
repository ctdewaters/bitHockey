//
//  GameViewController.swift
//  Hockey Game
//
//  Created by Collin DeWaters on 3/18/17.
//  Copyright © 2017 Collin DeWaters. All rights reserved.
//

import UIKit
import SpriteKit
import GameplayKit

class GameViewController: UIViewController, HomeViewControllerDelegate {
    @IBOutlet var gameView: GameView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Setup home view.
        self.presentHomeView(animated: true)
        homeVC.delegate = self
        
        
        //Setting the rink
        Rink.shared.size = CGSize(width: 728, height: 1024)
        Rink.shared.scaleMode = .aspectFill
        gameView.presentScene(Rink.shared)
        
        Rink.shared.animateCameraScale(toValue: 0.25, withDuration: 0.3)
    }

    override var shouldAutorotate: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        Joystick.shared.frame = CGRect(x: 20, y: gameView.frame.maxY - joystickSize - 20, width: joystickSize, height: joystickSize)
        SwitchPlayerButton.shared?.frame = CGRect(x: gameView.frame.maxX - buttonSize - 20 , y: 0, width: buttonSize, height: buttonSize)
        SwitchPlayerButton.shared?.center.y = Joystick.shared.center.y
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

    override var prefersStatusBarHidden: Bool {
        return false
    }
    
    //MARK: - Home view presentation.
    ///Presents the home view.
    func presentHomeView(animated: Bool) {
        //Add homeVC's view.
        homeVC.view.frame = self.view.frame
        self.view.addSubview(homeVC.view)
        if animated {
            homeVC.view.alpha = 0
            homeVC.view.frame.origin.y = self.view.frame.maxY
            UIView.animate(withDuration: 0.5, animations: {
                homeVC.view.alpha = 1
                homeVC.view.frame.origin.y = 0
            }, completion: nil)
        }
    }
    
    ///Dismisses the home view.
    func dismissHomeView(completion: @escaping ()->Void) {
        Rink.shared.animateCameraScale(toValue: 0.6, withDuration: 0.3)
        UIView.animate(withDuration: 0.3, animations: {
            homeVC.view.frame.origin.y = self.view.frame.maxY
            homeVC.view.alpha = 0
        }) { (completed) in
            if completed {
                homeVC.view.removeFromSuperview()
                completion()
            }
        }
    }
    
    ///Ends the game.
    func endGame() {
        Rink.shared.deactivate()
        self.removeGameUI()
        self.presentHomeView(animated: true)
    }
    
    func addGameUI () {
        //Joystick.
        if #available(iOS 11.0, *) {
            Joystick.shared.frame = CGRect(x: 20, y: gameView.safeAreaInsets.bottom - joystickSize - 20, width: joystickSize, height: joystickSize)
        } else {
            // Fallback on earlier versions
            Joystick.shared.frame = CGRect(x: 20, y: gameView.frame.maxY - joystickSize - 20, width: joystickSize, height: joystickSize)
        }
        self.view.addSubview(Joystick.shared)
        Joystick.shared.delegate = UserComponent.shared
        
        //Pass / change player button.
        SwitchPlayerButton.shared = SwitchPlayerButton(frame: CGRect(x: gameView.frame.maxX - buttonSize - 20 , y: 0, width: buttonSize, height: buttonSize))
        SwitchPlayerButton.shared?.center.y = Joystick.shared.center.y
        SwitchPlayerButton.shared?.delegate = UserComponent.shared
        self.view.addSubview(SwitchPlayerButton.shared!)
        
        //Scoreboard.
        let time = TimeInterval(withMinutes: 2, andSeconds: 0)
        if #available(iOS 11.0, *) {
            Scoreboard.shared = Scoreboard(frame: CGRect(x: 20, y: gameView.frame.minY + gameView.safeAreaInsets.top + 15, width: 250, height: 30), withTotalTime: time)
        } else {
            // Fallback on earlier versions
            Scoreboard.shared = Scoreboard(frame: CGRect(x: 20, y: gameView.frame.minY + 50, width: 250, height: 30), withTotalTime: time)
        }
        self.view.addSubview(Scoreboard.shared)
    }
    
    func removeGameUI () {
        Joystick.shared.removeFromSuperview()
        SwitchPlayerButton.shared?.removeFromSuperview()
        Scoreboard.shared.removeFromSuperview()
    }
    
    //MARK: - Home view controller delegate.
    func homeVCDidRespondToPlayButton() {
        //Dismiss the home view controller.
        self.dismissHomeView {
            self.addGameUI()
            Rink.shared.activate()
        }
    }
}
