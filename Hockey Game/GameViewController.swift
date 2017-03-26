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

class GameViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let rink = Rink(size: CGSize(width: 728, height: 1024))
        rink.scaleMode = .resizeFill
            
        if let skView = self.view as! SKView? {
            skView.presentScene(rink)
            
            let joystick = Joystick.shared
            joystick.frame = CGRect(x: 20, y: skView.frame.maxY - joystickSize - 20, width: joystickSize, height: joystickSize)
            skView.addSubview(joystick)
            
            let button = SwitchPlayerButton(frame: CGRect(x: skView.frame.maxX - buttonSize - 20 , y: skView.frame.maxY - buttonSize - 20, width: buttonSize, height: buttonSize))
            button.center.y = joystick.center.y
            button.delegate = rink
            skView.addSubview(button)
            
           skView.showsPhysics = true
        }

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
        return true
    }
}
