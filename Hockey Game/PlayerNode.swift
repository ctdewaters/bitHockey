import SpriteKit
import GameplayKit

public typealias Team = [PlayerNode]

public let playerNodeSize = CGSize(width: 25, height: 50)

protocol PlayerNodeDelegate {
    func playerNodeDidPickUpPuck(_ node: PlayerNode)
    func playerNodeDidStartSkating(_ node: PlayerNode)
    func playerNodeDidStopSkating(_ node: PlayerNode)
    func playerNodeDidReleasePuck(_ node: PlayerNode)
}

open class PlayerNode: SKNode {
    fileprivate var playerNode: PlayerSpriteNode!
    var selectionNode = SKShapeNode()
    
    fileprivate var skatingAction: SKAction?
    
    open var pSpeed: CGFloat = 3
    
    open var playerPosition: PlayerPosition!
    open var isOnOpposingTeam = false
    open var hasPuck = false
    open var isSelected = false
    
    open var rinkReference: UnsafeMutablePointer<Rink>?
    
    fileprivate var delegate: PlayerNodeDelegate?
    
    //The point at the front tip of the node
    public var frontPoint: CGPoint {
        let startPoint = self.position // center of node
        let angle = self.zRotation
        let halfLength = self.frame.height / 2
        
        let xDiff = halfLength * cos(angle)
        let yDiff = halfLength * cos(angle)
        
        return CGPoint(x: startPoint.x + xDiff, y: startPoint.y + yDiff)
    }
    
    fileprivate var facingNorth: Bool {
        let rotation = self.zRotation + (CGFloat.pi / 2)
        
        if rotation < 0 || rotation > CGFloat.pi {
            return false
        }
        return true
    }

    fileprivate var shootingPoint: CGPoint {
        let startPoint = self.position // center of node
        let angle = self.zRotation
        let length = self.frame.height * 2
        
        let xDiff = length * cos(angle)
        let yDiff = length * cos(angle)
        
        return CGPoint(x: startPoint.x + xDiff, y: startPoint.y + yDiff)
    }
    
    fileprivate var puck: PuckNode? {
        for child in children {
            if let puck = child as? PuckNode {
                return puck
            }
        }
        return nil
    }
    
    public var size: CGSize {
        set {
            self.playerNode.size = newValue
        }
        get {
            return self.playerNode.size
        }
    }
    
    public var texture: SKTexture? {
        set {
            self.playerNode.texture = newValue
        }
        get {
            return self.playerNode.texture
        }
    }
    
    public init(withColor color: SKColor = .white, rinkReference rink: Rink, andPosition playerPosition: PlayerPosition) {
        //Load textures
        super.init()
        
        self.playerNode = PlayerSpriteNode(texture: nil, color: color, size: playerNodeSize)
        self.playerPosition = playerPosition
        self.playerNode.texture = PlayerTexture.faceoff
        self.playerNode.colorBlendFactor = 0.5
        self.playerNode.zPosition = 1
        self.addChild(self.playerNode)
        
        self.zPosition = 0
        
        self.rinkReference = UnsafeMutablePointer<Rink>.allocate(capacity: 1)
        self.rinkReference?.pointee = rink
        
        //Setting physics body
        self.setPhysicsBody()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //Taking control of the puck
    public func pickUp(puck: inout PuckNode) {
        puck.removeAllActions()
        puck.removeFromParent()
        puck.physicsBody = nil
        puck.position = CGPoint(x: -9, y: 17)
        self.addChild(puck)
        self.hasPuck = true
        
        delegate?.playerNodeDidPickUpPuck(self)
    }
    
    //Sets the physics body for the node
    open func setPhysicsBody(withTexture texture: SKTexture? = nil) {
        if let texture = texture {
            self.playerNode.texture = texture
        }
        self.playerNode.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        let physicsBody = SKPhysicsBody(texture: self.texture!, size: self.size)
        self.physicsBody = physicsBody
        self.physicsBody?.isDynamic = true
        self.physicsBody?.mass = 1
        self.physicsBody?.categoryBitMask = PhysicsCategory.player
        self.physicsBody?.collisionBitMask = PhysicsCategory.all
        self.physicsBody?.contactTestBitMask = PhysicsCategory.puck | PhysicsCategory.player
        self.physicsBody?.affectedByGravity = false
    }
    
    //Remove puck and add it to the rink at its current position
    fileprivate func addPuckBackToRink() -> UnsafeMutablePointer<PuckNode> {
        
        //Convert position of puck in this node to the rink's coordinate system
        let puckPosition = rinkReference?.pointee.convert((rinkReference?.pointee.puck?.position)!, from: self)
        
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
    
    //Moves puck to a point with an enterd magnitude
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
        self.run(shootingAction)
        
        delegate?.playerNodeDidReleasePuck(self)
        
        Timer.scheduledTimer(withTimeInterval: 0.35, repeats: false, block: {
            timer in
            
            DispatchQueue.main.async {
                self.physicsBody?.categoryBitMask = PhysicsCategory.player
                self.physicsBody?.collisionBitMask = PhysicsCategory.all
            }
        })
    }
    
    //Applies a force to the node after user input has ceased
    open func applySkatingImpulse() {
        //Remove previous physics
        self.physicsBody = nil
        self.setPhysicsBody()
        
        let vector = CGVector(withMagnitude: self.playerNode.speed * 35, andDirectionAngle: self.zRotation)
        let impulseAction = SKAction.applyImpulse(vector, duration: 0.35)
        self.run(impulseAction, withKey: "skatingImpulse")
    }

    
    //Rotates node to face a point (with an entered duration)
    open func rotate(toFacePoint point: CGPoint, withDuration duration: TimeInterval) {
        self.run(SKAction.rotateAction(toFacePoint: point, currentPoint: self.position, withDuration: duration))
    }
    
    //Animates the skating textures
    open func animateSkatingTextures() {
        self.skatingAction = SKAction.repeatForever(SKAction.animate(with: PlayerTexture.skatingTextures, timePerFrame: 0.05))
        self.playerNode.run(self.skatingAction!, withKey: "skatingAction")
        
        delegate?.playerNodeDidStartSkating(self)
        
        if let puck = puck {
            let moveAction = SKAction.moveTo(x: -4, duration: 0.15)
            puck.run(moveAction)
        }
    }
    
    //Stops skating texture animation
    open func stopSkatingAction() {
        self.playerNode.removeAction(forKey: "skatingAction")
        self.skatingAction = nil
        
        delegate?.playerNodeDidStopSkating(self)
        
        if let puck = puck {
            let moveAction = SKAction.moveTo(x: -9, duration: 0.15)
            puck.run(moveAction)
        }
    }

    open func passPuck(toPlayer player: PlayerNode) {
        self.movePuck(withForceMagnitude: 2, toPoint: player.frontPoint)
    }
    
    open func shootPuck(atPoint point: CGPoint) {
        print(facingNorth)
        if !facingNorth {
            let rotateAction = SKAction.rotateAction(toFacePoint: point, currentPoint: self.position, withDuration: 0.22)
            self.run(rotateAction, completion: {
                self.removeAllActions()
                self.movePuck(withForceMagnitude: 10, toPoint: point)
            })
        }
        else {
            self.movePuck(withForceMagnitude: 10, toPoint: point)
        }
    }
    
    //Calculates distance from another node
    open func distance(fromNode node: SKNode) -> CGFloat {
        let xDiff = self.position.x - node.position.x
        let yDiff = self.position.y - node.position.y
        
        return sqrt(pow(xDiff, 2) + pow(yDiff, 2))
    }
    
    //MARK: - User Controlled Player methods
    //Selects player
    open func select() {
        self.isSelected = true
        self.selectionNode = SKShapeNode(circleOfRadius: playerNodeSize.width / 2)
        self.selectionNode.fillColor = SKColor.blue.withAlphaComponent(0.3)
        self.selectionNode.strokeColor = SKColor.blue
        self.selectionNode.position = CGPoint(x: 0, y: -10)
        self.selectionNode.zPosition = 0
        
        self.addChild(self.selectionNode)
    }
    //Deselects player
    open func deselect() {
        self.isSelected = false
        self.selectionNode.removeFromParent()
        self.stopSkatingAction()
    }
    //Moves with entered data generated by the joystick
    open func move(withJoystickData data: JoystickData) {
        self.removeAction(forKey: "skatingImpulse")
        
        self.run(SKAction.rotateAction(toAngle: data.angle))
        
        let length = sqrt(pow(data.x, 2) + pow(data.y, 2))
        let normalizedPoint = CGPoint(x: data.x / length, y: data.y / length)
        
        let playerSpeed = self.pSpeed
        
        self.position.x += normalizedPoint.x * playerSpeed
        self.position.y += normalizedPoint.y * playerSpeed
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

public class PlayerSpriteNode: SKSpriteNode {
    var parentNode: PlayerNode {
        return self.parent as! PlayerNode
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
        
        return SKAction.rotate(toAngle: angle, duration: duration, shortestUnitArc: true)
    }
    
    class func rotateAction(toAngle angle: CGFloat) -> SKAction {
        let angle = angle - (CGFloat.pi / 2)
        return SKAction.rotate(toAngle: angle, duration: 0.1, shortestUnitArc: true)
    }
}
