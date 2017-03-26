//
//  MoveComponent.swift
//  Hockey Game
//
//  Created by Collin DeWaters on 3/25/17.
//  Copyright © 2017 Collin DeWaters. All rights reserved.
//

import SpriteKit
import GameplayKit

class MoveComponent: GKAgent2D, GKAgentDelegate {
    
    var rinkReference: UnsafeMutablePointer<Rink>! = nil
    
    init(maxSpeed: Float, maxAcceleration: Float, radius: Float, mass: Float, rink: Rink) {
        self.rinkReference = UnsafeMutablePointer<Rink>.allocate(capacity: 1)
        self.rinkReference.pointee = rink
        super.init()
        
        delegate = self
        self.maxSpeed = maxSpeed
        self.maxAcceleration = maxAcceleration
        self.radius = radius
        self.mass = 0.01
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func agentWillUpdate(_ agent: GKAgent) {
        guard let playerComponent = playerComponent else {
            return
        }
        
        position = vector_float2(withCGPoint: playerComponent.pointee.node.position)
    }
    
    func agentDidUpdate(_ agent: GKAgent) {
        guard let playerComponent = playerComponent else {
            return
        }
        
        playerComponent.pointee.node.position = self.cgPosition
    }
    
    //MARK: - Movement functions
        
    //MARK: - Calculated variables
    
    //The player entity
    fileprivate var player: Player? {
        return self.entity as? Player
    }
    
    //The player component
    fileprivate var playerComponent: UnsafeMutablePointer<PlayerComponent>? {
        return self.player?.playerComponent
    }



}

extension CGPoint {
    init(x: Float, y: Float) {
        self.x = CGFloat(x)
        self.y = CGFloat(y)
    }
}

extension vector_float2 {
    init(withCGPoint point: CGPoint) {
        self.init(x: Float(point.x), y: Float(point.y))
    }
}

extension GKAgent2D {
    var cgPosition: CGPoint {
        return CGPoint(x: self.position.x, y: self.position.y)
    }
}
