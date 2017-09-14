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
        self.presentScene(BackgroundScene(size: self.frame.size))
        
        print("BACKGROUND SCENE OPENED")
    }
}

class BackgroundScene: SKScene {
    public override init(size: CGSize) {
        super.init(size: size)
        
        self.backgroundColor = .red
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
