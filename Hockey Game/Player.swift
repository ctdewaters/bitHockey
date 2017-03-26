//
//  PlayerEntity.swift
//  Hockey Game
//
//  Created by Collin DeWaters on 3/25/17.
//  Copyright © 2017 Collin DeWaters. All rights reserved.
//

import SpriteKit
import GameplayKit

public class Player: GKEntity {
        
    var pPosition: PlayerPosition!
    var isOnOpposingTeam = false
    
    init(withColor color: SKColor = .white, andRinkReference rink: Rink, andPosition playerPosition: PlayerPosition) {
        super.init()
        
        //Setting the player's position
        self.pPosition = playerPosition
        
        let playerComponent = PlayerComponent(withColor: color, andTexture: PlayerTexture.faceoff, andRinkReference: rink)
        self.addComponent(playerComponent)
        
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func distance(fromNode node: SKNode) -> CGFloat {
        let xDiff = self.node!.position.x - node.position.x
        let yDiff = self.node!.position.y - node.position.y
        
        return sqrt(pow(xDiff, 2) + pow(yDiff, 2))
    }
    
    public func position(atFaceoffLocation faceoffLocation: FaceoffLocation) {
        playerNode?.removeAllActions()
        node?.removeAllActions()
        node?.position = faceoffLocation.playerPosition(forPlayer: self)
        //spriteNode!.setPhysicsBody(withTexture: PlayerTexture.faceoff)
        self.rotate(toFacePoint: faceoffLocation.coordinate, withDuration: 0.1)
    }
    
    public func select() {
        let userComponent = UserComponent()
        Joystick.shared.delegate = userComponent
        self.addComponent(userComponent)
    }
    
    public func deselect() {
        self.removeComponent(ofType: UserComponent.self)
        self.playerComponent?.pointee.deselect()
    }
    
    open func passPuck(toPlayer player: Player) {
        self.playerComponent?.pointee.passPuck(toPlayer: player)
    }
    
    //Rotates node to face a point (with an entered duration)
    open func rotate(toFacePoint point: CGPoint, withDuration duration: TimeInterval) {
        node?.run(SKAction.rotateAction(toFacePoint: point, currentPoint: playerNode!.position, withDuration: duration))
    }
    
    //MARK: - Calculated variables
    
    //The player component
    public var playerComponent: UnsafeMutablePointer<PlayerComponent>? {
        let ptr = UnsafeMutablePointer<PlayerComponent>.allocate(capacity: 1)
        ptr.pointee = self.component(ofType: PlayerComponent.self)!
        return ptr
    }
    
    public var node: PlayerNode? {
        set {
            self.playerComponent?.pointee.node = newValue
        }
        get {
            return self.playerComponent?.pointee.node
        }
    }
    
    public var playerNode: PlayerSpriteNode? {
        set {
            self.playerComponent?.pointee.playerNode = newValue
        }
        get {
            return self.playerComponent?.pointee.playerNode
        }
    }
    
    public var texture: SKTexture? {
        set {
            self.playerNode?.texture = newValue
        }
        get {
            return self.playerNode?.texture
        }
    }
    
    public var selectionNode: SKShapeNode? {
        set {
            self.playerComponent?.pointee.selectionNode = newValue
        }
        get {
            return self.playerComponent?.pointee.selectionNode
        }
    }
    
    public var hasPuck: Bool {
        set {
            self.playerComponent!.pointee.hasPuck = newValue
        }
        get {
            return self.playerComponent!.pointee.hasPuck
        }
    }
    
    public var position: CGPoint {
        set {
            self.node?.position = newValue
        }
        get {
            return self.node!.position
        }
    }
    
    public var userComponent: UserComponent? {
        return self.component(ofType: UserComponent.self)
    }
    
    //Is the player selected?
    public var isSelected: Bool {
        if self.userComponent != nil {
            return true
        }
        return false
    }

}

public class PlayerSpriteNode: SKSpriteNode {
    var parentNode: PlayerNode {
        return self.parent as! PlayerNode
    }
}

public class PlayerNode: SKNode {
    open var component: PlayerComponent?
    
    init(toComponent comp: PlayerComponent) {
        self.component = comp
        super.init()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

public enum TeamSize {
    case three, four, five
    
    public var intVal: Int {
        switch self {
        case .three :
            return 3
        case .four :
            return 4
        case .five :
            return 5
        }
    }
}

public enum PlayerPosition: Int {
    case leftWing, rightWing, center, leftDefense, rightDefense, goalie
    
    public var isForward: Bool {
        switch self {
        case .leftWing, .rightWing, .center :
            return true
        default :
            return false
        }
    }
    
    public var isDefenseman: Bool {
        switch self {
        case .leftDefense, .rightDefense :
            return true
        default :
            return false
        }
    }
}
