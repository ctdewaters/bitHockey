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
import AVFoundation

///`GameViewController`: view controller that will display the `GameView` to present the user the game.
class GameViewController: UIViewController, HomeViewControllerDelegate, UIGestureRecognizerDelegate {
    
    @IBOutlet var gameView: GameView!
    
    var panGesture: UIPanGestureRecognizer!
    var pauseButton: UIButton!
    
    //MARK: - `UIViewController` overrides.
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
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.gameEnded), name: .gameDidEnd, object: nil)
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
            }, completion: {
                completed in
            })
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
    
    //MARK: - Game over menu.
    func presentGameOverMenu() {
        //Add pauseVC's view.
        pauseVC.view.frame = self.view.frame
        //Setup pauseVC info.
        pauseVC.homeScoreLabel.text = "\(Score.shared.userScore)"
        pauseVC.roadScoreLabel.text = "\(Score.shared.cpuScore)"
        pauseVC.timeRemainingLabel.text = "0:00"
        pauseVC.blur.effect = nil
        pauseVC.blur.contentView.alpha = 0
        self.view.addSubview(pauseVC.view)
        pauseVC.quitButton.isHidden = true
        
        pauseVC.messageLabel.text = "Game Over"
        pauseVC.resumeButton.setTitle("Exit", for: .normal)
        
        pauseVC.blur.contentView.transform = CGAffineTransform(scaleX: 0.75, y: 0.75)
        
        pauseVC.resumeButton.addTarget(self, action: #selector(self.exitGame), for: .touchUpInside)
        
        //Animate in.
        UIView.animate(withDuration: 0.3, animations: {
            pauseVC.blur.effect = UIBlurEffect(style: .light)
            pauseVC.blur.contentView.alpha = 1
            pauseVC.blur.contentView.transform = .identity
        }, completion: nil)
    }
    
    //MARK: - Pause menu
    func presentPauseView() {
        Haptics.shared.playPeekHaptic()
        //Add pauseVC's view.
        pauseVC.view.frame = self.view.frame
        //Setup pauseVC info.
        pauseVC.homeScoreLabel.text = "\(Score.shared.userScore)"
        pauseVC.roadScoreLabel.text = "\(Score.shared.cpuScore)"
        pauseVC.timeRemainingLabel.text = Scoreboard.shared.clockView.timeLabel.text!
        pauseVC.blur.effect = nil
        pauseVC.blur.contentView.alpha = 0
        pauseVC.messageLabel.text = "Paused"
        self.view.addSubview(pauseVC.view)
        
        pauseVC.quitButton.isHidden = false
        
        pauseVC.resumeButton.setTitle("Resume", for: .normal)
        
        pauseVC.blur.contentView.transform = CGAffineTransform(scaleX: 0.75, y: 0.75)
        
        pauseVC.resumeButton.addTarget(self, action: #selector(self.resumeGame), for: .touchUpInside)
        pauseVC.quitButton.addTarget(self, action: #selector(self.exitGame), for: .touchUpInside)
        
        //Animate in.
        UIView.animate(withDuration: 0.3, animations: {
            pauseVC.blur.effect = UIBlurEffect(style: .light)
            pauseVC.blur.contentView.alpha = 1
            pauseVC.blur.contentView.transform = .identity
        }, completion: nil)
    }
    
    func dismissPauseView(completion: @escaping ()->Void) {
        UIView.animate(withDuration: 0.3, animations: {
            pauseVC.blur.effect = nil
            pauseVC.blur.contentView.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
            pauseVC.blur.contentView.alpha = 0
        }) { (completed) in
            if completed {
                pauseVC.view.removeFromSuperview()
                pauseVC.blur.contentView.transform = .identity
                
                completion()
            }
        }
    }
    
    func presentControlsView() {
        controlsVC.view.frame = self.view.frame
        controlsVC.blur.effect = nil
        controlsVC.image.transform = .identity
        controlsVC.image.transform = CGAffineTransform(scaleX: 0.75, y: 0.75)
        controlsVC.closeButton.alpha = 0
        controlsVC.image.alpha = 0
        controlsVC.closeButton.addTarget(self, action: #selector(self.dismissControlsView), for: .touchUpInside)
        self.view.addSubview(controlsVC.view)
        UIView.animate(withDuration: 0.3, animations: {
            controlsVC.blur.effect = UIBlurEffect(style: .light)
            controlsVC.image.transform = .identity
            controlsVC.closeButton.alpha = 1
            controlsVC.image.alpha = 1
        })
    }
    
    @objc func dismissControlsView() {
        Haptics.shared.playPopHaptic()
        UIView.animate(withDuration: 0.3, animations: {
            controlsVC.blur.effect = nil
            controlsVC.image.transform = CGAffineTransform(scaleX: 0.75, y: 0.75)
            controlsVC.closeButton.alpha = 0
        })
        
        UIView.animate(withDuration: 0.3, animations: {
            controlsVC.blur.effect = nil
            controlsVC.image.transform = CGAffineTransform(scaleX: 0.75, y: 0.75)
            controlsVC.image.alpha = 0
            controlsVC.closeButton.alpha = 0
        }) { (complete) in
            if complete {
                controlsVC.view.removeFromSuperview()
            }
        }
    }
    
    //MARK: - Game UI
    func addGameUI () {
        //Joystick.
        if #available(iOS 11.0, *) {
            Joystick.shared.frame = CGRect(x: -joystickSize - 20, y: self.gameView.frame.maxY - self.gameView.safeAreaInsets.bottom - joystickSize - 20, width: joystickSize, height: joystickSize)
        } else {
            // Fallback on earlier versions
            Joystick.shared.frame = CGRect(x: -joystickSize - 20, y: self.gameView.frame.maxY - joystickSize - 20, width: joystickSize, height: joystickSize)
        }
        self.view.addSubview(Joystick.shared)
        Joystick.shared.delegate = UserComponent.shared
        
        //Pass / change player button.
        SwitchPlayerButton.shared = SwitchPlayerButton(frame: CGRect(x: gameView.frame.maxX + buttonSize + 20 , y: 0, width: buttonSize, height: buttonSize))
        SwitchPlayerButton.shared?.center.y = Joystick.shared.center.y
        SwitchPlayerButton.shared?.delegate = UserComponent.shared
        self.view.addSubview(SwitchPlayerButton.shared!)
        
        //Scoreboard.
        let time = TimeInterval(withMinutes: 2, andSeconds: 0)
        if #available(iOS 11.0, *) {
            Scoreboard.shared = Scoreboard(frame: CGRect(x: -270, y: gameView.frame.minY + gameView.safeAreaInsets.top + 15, width: 250, height: 30), withTotalTime: time)
        } else {
            // Fallback on earlier versions
            Scoreboard.shared = Scoreboard(frame: CGRect(x: -270, y: gameView.frame.minY + 50, width: 250, height: 30), withTotalTime: time)
        }
        self.view.addSubview(Scoreboard.shared)
        
        //Pan gesture.
        self.panGesture = UIPanGestureRecognizer(target: self, action: #selector(self.pan(withGestureRecognizer:)))
        self.panGesture.delegate = self
        self.gameView.addGestureRecognizer(self.panGesture)
        
        //Pause button.
        self.pauseButton = UIButton(frame: CGRect(x: gameView.frame.maxX + (buttonSize * 0.85) + 20, y: Scoreboard.shared.frame.origin.y, width: buttonSize * 0.85, height: 30))
        let title = NSAttributedString(string: "PAUSE", attributes: [NSAttributedStringKey.font : UIFont(name: "Rubik", size: 15)!, NSAttributedStringKey.foregroundColor : UIColor.white])
        self.pauseButton.setAttributedTitle(title, for: .normal)
        self.pauseButton.clipsToBounds = true
        self.pauseButton.layer.cornerRadius = 15
        self.pauseButton.backgroundColor = UIColor.black.withAlphaComponent(0.9)
        self.pauseButton.addTarget(self, action: #selector(self.pauseGame), for: .touchUpInside)
        self.view.addSubview(self.pauseButton)
        
        UIView.animate(withDuration: 0.3) {
            Joystick.shared.frame.origin.x = 20
            Scoreboard.shared.frame.origin.x = 20
            SwitchPlayerButton.shared?.frame.origin.x = self.gameView.frame.maxX - buttonSize - 20
            self.pauseButton.frame.origin.x = self.gameView.frame.maxX - (buttonSize * 0.85) - 20
        }
    }
    
    func removeGameUI () {
        UIView.animate(withDuration: 0.3, animations: {
            Joystick.shared.frame.origin.x = -joystickSize - 20
            Scoreboard.shared.frame.origin.x = -270
            SwitchPlayerButton.shared?.frame.origin.x = self.gameView.frame.maxX + buttonSize + 20
            self.pauseButton.frame.origin.x = self.gameView.frame.maxX + (buttonSize * 0.85) + 20
        }) { (completed) in
            if completed {
                Joystick.shared.removeFromSuperview()
                SwitchPlayerButton.shared?.removeFromSuperview()
                Scoreboard.shared.removeFromSuperview()
                self.pauseButton.removeFromSuperview()
                self.gameView.removeGestureRecognizer(self.panGesture)
            }
        }
    }
 
    @objc func pan(withGestureRecognizer recognizer: UIPanGestureRecognizer) {
        guard let selectedPlayer = Rink.shared.selectedPlayer else {
            return
        }
        if selectedPlayer.hasPuck {
            switch recognizer.state {
            case .changed :
                let translation = recognizer.translation(in: self.gameView)
                let x = translation.x
                let y = translation.y
                
                if y < -75 && selectedPlayer.hasPuck {
                    //Shoot the puck.
                    let velocity = recognizer.velocity(in: self.gameView)
                    let shootPoint = CGPoint(x: selectedPlayer.position.x + velocity.x, y: selectedPlayer.position.y - velocity.y)
                    selectedPlayer.playerComponent?.shootPuck(atPoint: shootPoint)
                }
                else {
                    if x > 50 {
                        //Deke right.
                        selectedPlayer.playerComponent?.animateDeke(toRight: true)
                    }
                    else if x < -50 {
                        //Deke left.
                        selectedPlayer.playerComponent?.animateDeke(toRight: false)
                    }
                }
                
            case .ended :
                let velocity = recognizer.velocity(in: self.gameView)
                let shootPoint = CGPoint(x: selectedPlayer.position.x + velocity.x, y: selectedPlayer.position.y - velocity.y)
                if selectedPlayer.hasPuck {
                    selectedPlayer.playerComponent?.shootPuck(atPoint: shootPoint)
                }
            default :
                break
            }
        }
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if Joystick.shared.frame.contains(touch.location(in: self.gameView)) {
            return false
        }
        return true
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    //MARK: - Pause, resume, and exit.
    @objc func pauseGame() {
        //Pause the game.
        Rink.shared.pause()
        Scoreboard.shared.pauseTimer()
        //Show pause menu.
        self.presentPauseView()
    }
    
    @objc func resumeGame() {
        //Resume the game.
        
        Haptics.shared.playPopHaptic()
        self.dismissPauseView {
            Rink.shared.resume()
            Scoreboard.shared.startTimer()
        }
    }
    
    @objc func exitGame() {
        Haptics.shared.sendNotificationHaptic(withType: .warning)
        self.dismissPauseView {
            Rink.shared.deactivate()
            self.removeGameUI()
            self.presentHomeView(animated: true)
        }
    }
    
    
    //MARK: - Home view controller delegate.
    func homeVCDidRespondToPlayButton() {
        //Dismiss the home view controller.
        Haptics.shared.sendNotificationHaptic(withType: .success)
        self.dismissHomeView {
            self.addGameUI()
            Rink.shared.activate()
        }
    }
    
    func homeVCDidRespondToControlsButton() {
        Haptics.shared.playPeekHaptic()
        self.presentControlsView()
    }
    
    @objc func gameEnded() {
        //Play ending horn.
        player = AVPlayer(url: Bundle.main.url(forResource: "gameEnd", withExtension: "wav")!)
        player.play()

        self.removeGameUI()
        self.presentGameOverMenu()
         Rink.shared.deactivate()
        
        if Score.shared.userScore > Score.shared.cpuScore {
            //User won.
            Haptics.shared.sendNotificationHaptic(withType: .success)
        }
        else if Score.shared.userScore < Score.shared.cpuScore {
            //CPU won.
            Haptics.shared.sendNotificationHaptic(withType: .warning)
        }
        else {
            //Tie.
            Haptics.shared.sendNotificationHaptic(withType: .error)
        }
    }
}
