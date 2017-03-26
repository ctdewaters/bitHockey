//
//  PlayerComponent.swift
//  Hockey Game
//
//  Created by Collin DeWaters on 3/25/17.
//  Copyright © 2017 Collin DeWaters. All rights reserved.
//

import SpriteKit
import GameplayKit

public let playerNodeSize = CGSize(width: 25, height: 50)

public class PlayerComponent: GKComponent {

    open var node: PlayerNode!
    open var playerNode: PlayerSpriteNode!
    open var selectionNode: SKShapeNode!
    open var pSpeed: CGFloat = 3

    fileprivate var rinkReference: UnsafeMutablePointer<Rink>!
    
    var hasPuck = false
    
    init(withColor color: SKColor = .white, andTexture texture: SKTexture? = nil, andRinkReference rink: Rink) {
        super.init()
        
        node = PlayerNode(toComponent: self)
        
        self.playerNode = PlayerSpriteNode(texture: texture, color: color, size: playerNodeSize)
        self.playerNode.texture = PlayerTexture.faceoff
        self.playerNode.colorBlendFactor = 0.75
        self.playerNode.zPosition = 1
        self.node.addChild(self.playerNode)
        
        self.node.zPosition = 0
        
        self.setPhysicsBody()
        
        rinkReference = UnsafeMutablePointer<Rink>.allocate(capacity: 1)
        rinkReference.pointee = rink
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open func setPhysicsBody(withTexture texture: SKTexture? = nil) {
        if let texture = texture {
            self.playerNode.texture = texture
        }
        self.playerNode.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        let physicsBody = SKPhysicsBody(texture: self.texture!, size: self.size)
        self.physicsBody = physicsBody
        self.physicsBody?.isDynamic = true
        self.physicsBody?.mass = 0.25
        self.physicsBody?.categoryBitMask = PhysicsCategory.player
        self.physicsBody?.collisionBitMask = PhysicsCategory.all
        self.physicsBody?.contactTestBitMask = PhysicsCategory.puck | PhysicsCategory.player
        self.physicsBody?.affectedByGravity = false
    }
    
    open func passPuck(toPlayer player: Player) {
        self.movePuck(withForceMagnitude: 2, toPoint: player.playerComponent!.pointee.frontPoint)
    }
    
    
    //MARK: - Picking up and releasing the puck
    
    //Taking control of the puck
    public func pickUp(puck: inout PuckNode) {
        puck.removeAllActions()
        puck.removeFromParent()
        puck.physicsBody = nil
        puck.position = CGPoint(x: -9, y: 17)
        node.addChild(puck)
        self.hasPuck = true
    }
    
    //Remove puck and add it to the rink at its current position
    fileprivate func addPuckBackToRink() -> UnsafeMutablePointer<PuckNode> {
        
        //Convert position of puck in this node to the rink's coordinate system
        let puckPosition = rinkReference?.pointee.convert((rinkReference?.pointee.puck?.position)!, from: self.node)
        
        let puck = rinkReference?.pointee.puck
        puck?.removeFromParent()
        puck?.position = puckPosition!
        rinkReference?.pointee.addChild(puck!)
        
        rinkReference?.pointee.bringNetsToFront()
        
        self.hasPuck = false
        
        let ptr = UnsafeMutablePointer<PuckNode>.allocate(capacity: 1)
        ptr.pointee = puck!
        
        return ptr
    }
    
    //Shoots the puck at a point
    open func shootPuck(atPoint point: CGPoint) {
        print(facingNorth)
        if !facingNorth {
            let rotateAction = SKAction.rotateAction(toFacePoint: point, currentPoint: node.position, withDuration: 0.22)
            node.run(rotateAction, completion: {
                self.node.removeAllActions()
                self.movePuck(withForceMagnitude: 10, toPoint: point)
            })
        }
        else {
            self.movePuck(withForceMagnitude: 10, toPoint: point)
        }
    }
    
    //Moves puck to a point with an entered magnitude
    fileprivate func movePuck(withForceMagnitude magnitude: CGFloat, toPoint point: CGPoint, withPreliminaryActions actions: [SKAction]? = nil) {
        let puck = addPuckBackToRink()
        
        puck.pointee.position.x += 3
        puck.pointee.position.y += 3
        
        let action = SKAction.vectorAction(withPointA: point, andPointB: puck.pointee.position, withMagnitude: magnitude, andDuration: 3.5 / Double(magnitude))
        
        var seqAction: SKAction!
        if var actions = actions {
            actions.append(action)
            seqAction = SKAction.sequence(actions)
        }
        else {
            seqAction = action
        }
        
        puck.pointee.setPhysicsBody()
        
        puck.pointee.run(seqAction)
        
        let shootingAction = SKAction.animate(with: PlayerTexture.shootingTextures, timePerFrame: 0.1, resize: false, restore: true)
        node.run(shootingAction)
        
        Timer.scheduledTimer(withTimeInterval: 0.35, repeats: false, block: {
            timer in
            
            DispatchQueue.main.async {
                self.physicsBody?.categoryBitMask = PhysicsCategory.player
                self.physicsBody?.collisionBitMask = PhysicsCategory.all
            }
        })
    }
    

    //MARK: - Selection methods
    
    //Selects player
    open func select() {
        self.selectionNode = SKShapeNode(circleOfRadius: playerNodeSize.width / 2)
        self.selectionNode.fillColor = SKColor.blue.withAlphaComponent(0.3)
        self.selectionNode.strokeColor = SKColor.blue
        self.selectionNode.position = self.playerNode.position
        self.selectionNode.zPosition = 0
        
        self.node.addChild(self.selectionNode)
    }
    
    //Deselects player
    open func deselect() {
        self.selectionNode.removeFromParent()
    }
    
    //MARK: - Movement functions
    
    //Rotates node to face a point (with an entered duration)
    open func rotate(toFacePoint point: CGPoint, withDuration duration: TimeInterval) {
        self.node.run(SKAction.rotateAction(toFacePoint: point, currentPoint: self.node.position, withDuration: duration))
    }
    
    //Applies a force to the node after user input has ceased
    open func applySkatingImpulse() {
        //Remove previous physics
        self.physicsBody = nil
        self.setPhysicsBody()
        
        let vector = CGVector(withMagnitude: self.playerNode.speed * 35, andDirectionAngle: self.node.zRotation)
        let impulseAction = SKAction.applyImpulse(vector, duration: 0.35)
        self.node.run(impulseAction, withKey: "skatingImpulse")
    }
    
    //Animates the skating textures
    open func animateSkatingTextures() {
        self.setPhysicsBody(withTexture: PlayerTexture.skatingTextures[0])
        let skatingAction = SKAction.repeatForever(SKAction.animate(with: PlayerTexture.skatingTextures, timePerFrame: 0.05))
        self.playerNode.run(skatingAction, withKey: "skatingAction")
        
        
        if let puck = puck {
            let moveAction = SKAction.moveTo(x: -4, duration: 0.15)
            puck.run(moveAction)
        }
    }
    
    //Stops skating texture animation
    open func stopSkatingAction() {
        self.playerNode.removeAction(forKey: "skatingAction")
        
        if let puck = puck {
            let moveAction = SKAction.moveTo(x: -9, duration: 0.15)
            puck.run(moveAction)
        }
    }
    
    //Moves with entered data generated by the joystick
    open func move(withJoystickData data: JoystickData) {
        self.node.removeAction(forKey: "skatingImpulse")
        
        self.node.run(SKAction.rotateAction(toAngle: data.angle))
        
        let length = sqrt(pow(data.x, 2) + pow(data.y, 2))
        let normalizedPoint = CGPoint(x: data.x / length, y: data.y / length)
        
        let playerSpeed = self.pSpeed
        
        self.node.position.x += normalizedPoint.x * playerSpeed
        self.node.position.y += normalizedPoint.y * playerSpeed
    }
    
    //Returns the player to idle. (No joystick data).
    open func returnToIdle() {
        self.stopSkatingAction()
        self.playerNode.texture = PlayerTexture.faceoff
        self.applySkatingImpulse()
    }

    
    //MARK: - Calculated variables
    
    //The player entity
    public var playerEntity: Player? {
        return self.entity as? Player
    }
    
    public var isOnOpposingTeam: Bool {
        return self.playerEntity!.isOnOpposingTeam
    }
        
    //Texture of the player node
    fileprivate var texture: SKTexture? {
        return self.playerNode.texture
    }
    
    //Size of the player node
    fileprivate var size: CGSize {
        return self.playerNode.size
    }
    
    //Physics body of the player node
    fileprivate var physicsBody: SKPhysicsBody? {
        set {
            self.node.physicsBody = newValue
        }
        get {
            return self.node.physicsBody
        }
    }
    
    //The point at the front tip of the node
    public var frontPoint: CGPoint {
        let startPoint = node.position // center of node
        let angle = node.zRotation
        let halfLength = node.frame.height / 2
        
        let xDiff = halfLength * cos(angle)
        let yDiff = halfLength * cos(angle)
        
        return CGPoint(x: startPoint.x + xDiff, y: startPoint.y + yDiff)
    }
    
    //Is the player facing north?
    fileprivate var facingNorth: Bool {
        let rotation = node.zRotation + (CGFloat.pi / 2)
        
        if rotation < 0 || rotation > CGFloat.pi {
            return false
        }
        return true
    }
    
    //The point to shoot the puck from
    fileprivate var shootingPoint: CGPoint {
        let startPoint = node.position // center of node
        let angle = node.zRotation
        let length = node.frame.height * 2
        
        let xDiff = length * cos(angle)
        let yDiff = length * cos(angle)
        
        return CGPoint(x: startPoint.x + xDiff, y: startPoint.y + yDiff)
    }
    
    //The puck (if this player has it)
    fileprivate var puck: PuckNode? {
        for child in node.children {
            if let puck = child as? PuckNode {
                return puck
            }
        }
        return nil
    }
    
    
}


fileprivate extension CGVector {
    init(withMagnitude magnitude: CGFloat, andDirectionAngle angle: CGFloat) {
        var angle = angle
        angle += (CGFloat.pi / 1.9)
        if angle < 0 {
            angle = (2 * CGFloat.pi) + angle
        }
        self.dx = (magnitude * cos(angle))
        self.dy = (magnitude * sin(angle))
    }
}

public extension SKAction {
    class func vectorAction(withPointA a: CGPoint, andPointB b: CGPoint, withMagnitude magnitude: CGFloat, andDuration duration: TimeInterval) -> SKAction {
        let origin = CGPoint(x: b.x - a.x, y: b.y - a.y)
        let angle = -atan2(origin.y, origin.x)
        
        let dx = magnitude * cos(angle)
        let dy = magnitude * sin(angle)
        
        let vector = CGVector(dx: -dx, dy: dy)
        
        return SKAction.applyImpulse(vector, duration: 0.35)
    }
    
    class func rotateAction(toFacePoint point: CGPoint, currentPoint: CGPoint, withDuration duration: TimeInterval) -> SKAction {
        let xDiff = currentPoint.x - point.x
        let yDiff = currentPoint.y - point.y
        
        let angle = atan2(yDiff, xDiff) + (90 / 180 * CGFloat.pi)
        
        print(angle)
        
        return SKAction.rotate(toAngle: angle, duration: duration, shortestUnitArc: true)
    }
    
    class func rotateAction(toAngle angle: CGFloat) -> SKAction {
        let angle = angle - (CGFloat.pi / 2)
        return SKAction.rotate(toAngle: angle, duration: 0.1, shortestUnitArc: true)
    }
}
