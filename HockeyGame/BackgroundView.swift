//
//  BackgroundView.swift
//  Hockey Game
//
//  Created by Collin DeWaters on 9/14/17.
//  Copyright © 2017 Collin DeWaters. All rights reserved.
//

import SpriteKit

class BackgroundView: SKView {
    
    #if os(OSX)
    //macOS implementation.
    override func viewDidMoveToSuperview() {
        super.viewDidMoveToSuperview()
        
        
    }
    
    #elseif os(iOS)
    //iOS implementation.
    
    #endif
    
    func setup() {
        let rink = Rink(size: self.frame.size)
        rink.backgroundNode.size = CGSize(width: 728 * 2, height: 1024 * 2)
        
        opposingTeam = Team()
        //Generate team.
        for i in 0..<5 {
            let player = Player(withColor: .white, andPosition: PlayerPosition(rawValue: i)!)
            player.isOnOpposingTeam = true
            opposingTeam?.append(player)
        }
        
        rink.add(opposingTeam!)
        
        rink.positionPlayers(atFaceoffLocation: .centerIce, withDuration: 0.5) {
            for player in opposingTeam! {
                player.addWander()
            }
        }

    
        self.presentScene(rink)
        
        print("BACKGROUND SCENE OPENED")
    }
}

class BackgroundScene: SKScene {
    public override init(size: CGSize) {
        super.init(size: size)
        
        self.backgroundColor = .red
        self.scaleMode = .aspectFill
        
        let backgroundImage = #imageLiteral(resourceName: "rinkBackground")
        let backgroundNode = SKSpriteNode()
        backgroundNode.size = CGSize(width: 728 * 2, height: 1024 * 2)
        backgroundNode.position = CGPoint(x: self.frame.width / 2, y: self.frame.height / 2 - 35)
        
        backgroundNode.texture = SKTexture(image: backgroundImage)
        
        //Add players.
        for i in 0..<5 {
            let newPlayer = Player(withColor: .red, andPosition: .center)
            newPlayer.position = CGPoint(x: self.frame.width / 2, y: self.frame.height / 2)
            self.addChild(newPlayer.node!)
            newPlayer.addWander()
        }
        
        self.addChild(backgroundNode)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
