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
    @IBOutlet var gameView: GameView!
    
    var button: SwitchPlayerButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        Joystick.shared.frame = CGRect(x: 20, y: gameView.frame.maxY - joystickSize - 20, width: joystickSize, height: joystickSize)
        gameView.addSubview(Joystick.shared)
        
        self.button = SwitchPlayerButton(frame: CGRect(x: gameView.frame.maxX - buttonSize - 20 , y: gameView.frame.maxY - buttonSize - 20, width: buttonSize, height: buttonSize))
        button.center.y = Joystick.shared.center.y
        button.delegate = UserComponent.shared
        gameView.addSubview(button)

        //Setting the rink
        Rink.shared.size = CGSize(width: 728, height: 1024)
        Rink.shared.scaleMode = .aspectFill
        gameView.presentScene(Rink.shared)
        
        //Generating the nets, players, and puck
        Rink.shared.generateAndAddNodes(withTeamSize: .five, andHomeTeamColor: .blue)
        
        //Adding the scoreboard
        let time = TimeInterval(withMinutes: 2, andSeconds: 0)
        Scoreboard.shared = Scoreboard(frame: CGRect(x: 20, y: gameView.frame.maxY - 50, width: 250, height: 30), withTotalTime: time)
        Scoreboard.shared.center = CGPoint(x: gameView.frame.width / 2, y: gameView.frame.height)
        gameView.addSubview(Scoreboard.shared)

        
        gameView.showsPhysics = true
        gameView.showsFPS = true
        gameView.showsNodeCount = true
        gameView.showsDrawCount = true

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
        self.button.frame = CGRect(x: gameView.frame.maxX - buttonSize - 20 , y: gameView.frame.maxY - buttonSize - 20, width: buttonSize, height: buttonSize)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}
