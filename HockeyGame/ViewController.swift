//
//  ViewController.swift
//  HockeyGame
//
//  Created by Collin DeWaters on 4/3/17.
//  Copyright © 2017 Collin DeWaters. All rights reserved.
//

import Cocoa
import SpriteKit
import GameplayKit

protocol GameViewControllerDelegate {
    func gameDidFinishLoading()
}

class ViewController: NSViewController {

    @IBOutlet var skView: GameView!
    
    var delegate: GameViewControllerDelegate?
    
    func setUp() {
        self.view.layout()
        self.view.layoutSubtreeIfNeeded()
        if let gameView = self.skView {
            //Setting the rink
            Rink.shared.size = CGSize(width: 728, height: 1024)
            Rink.shared.scaleMode = .aspectFill
            gameView.presentScene(Rink.shared)
            
            //Generating the nets, players, and puck
            Rink.shared.generateAndAddNodes(withTeamSize: .five, andHomeTeamColor: .blue)
            
            //Adding the scoreboard
            let time = TimeInterval(withMinutes: 2, andSeconds: 0)
            Scoreboard.shared = Scoreboard(frame: NSRect(x: 20, y: gameView.frame.maxY - 50, width: 250, height: 30), withTotalTime: time)
            Scoreboard.shared.center = CGPoint(x: gameView.frame.width / 2, y: gameView.frame.height)
            gameView.addSubview(Scoreboard.shared)
            
            gameView.showsFPS = true
            gameView.showsNodeCount = true
            
            delegate?.gameDidFinishLoading()
            
            if #available(OSX 10.12.2, *) {
                windowController.update(withTouchBar: nil)
            } else {
                // Fallback on earlier versions
            }
        }
    }
}

