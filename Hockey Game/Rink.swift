import SpriteKit
import UIKit
import GameplayKit

public let rinkSize = CGSize(width: 513, height: 1024)
public let rinkCenterCircleWidth: CGFloat = 155

public let sceneBackgroundColor = UIColor(red:0.13, green:0.13, blue:0.13, alpha:1.0)

public struct PhysicsCategory {
    static let none : UInt32 = 0
    static let all : UInt32 = UInt32.max
    static let puck : UInt32 = 1
    static let player: UInt32 = 2
    static let rink: UInt32 = 3
    static let puckCarrier: UInt32 = 4
    static let goalLine: UInt32 = 5
    static let net: UInt32 = 6
}

public typealias Team = [Player]

public var userTeam: Team?
public var opposingTeam: Team?

open class Rink: SKScene, SwitchPlayerButtonDelegate, SKPhysicsContactDelegate, UIGestureRecognizerDelegate {
    
    open var puck: PuckNode?
    
    fileprivate var panGesture: UIPanGestureRecognizer!
    
    fileprivate var latestJoystickData: JoystickData?
    
    open var entities = Set<GKEntity>()
    open var entitiesToRemove = Set<GKEntity>()
    
    lazy var componentSystems: [GKComponentSystem] = {
        let playerSystem = GKComponentSystem(componentClass: PlayerComponent.self)
        let moveSystem = GKComponentSystem(componentClass: MoveComponent.self)
        let userSystem = GKComponentSystem(componentClass: UserComponent.self)
        let netSystem = GKComponentSystem(componentClass: NetComponent.self)
        return [playerSystem, moveSystem, userSystem, netSystem]
    }()
    
    
    //Returns the selected player on the user controlled team
    open var selectedPlayer: UnsafeMutablePointer<Player>? {
        if let userTeam = userTeam {
            for player in userTeam {
                if player.isSelected {
                    let pointer = UnsafeMutablePointer<Player>.allocate(capacity: 1)
                    pointer.pointee = player
                    return pointer
                }
            }
        }
        return nil
    }
    
    //Returns the player on either team that is currently carrying the puck
    fileprivate var puckCarrier: UnsafeMutablePointer<Player>? {
        if let userTeam = userTeam {
            for player in userTeam {
                if player.hasPuck {
                    let pointer = UnsafeMutablePointer<Player>.allocate(capacity: 1)
                    pointer.pointee = player
                    return pointer
                }
            }
        }
        return nil
    }
    
    fileprivate var puckInNet: Net? {
        if Net.topNet.frame.contains(self.puck!.position) {
            return Net.topNet
        }
        else if Net.bottomNet.frame.contains(self.puck!.position) {
            return Net.bottomNet
        }
        return nil
    }

    //The camera for the scene
    let cameraNode: SKCameraNode = SKCameraNode()
    
    fileprivate var backgroundNode: SKSpriteNode!
        
    public override init(size: CGSize) {
        super.init(size: size)
        //Setting anchor point in the center
        self.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        
        self.backgroundNode = SKSpriteNode(imageNamed: "rinkBackground")
        self.backgroundNode.size = size
        self.addChild(self.backgroundNode)
        
        self.backgroundColor = sceneBackgroundColor
        
        //Adding the camera
        self.addChild(cameraNode)
        camera = cameraNode
        
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open override func didMove(to view: SKView) {
        super.didMove(to: view)
        
        self.setPhysicsWorld()
        self.generateAndAddNodes(withTeamSize: TeamSize.five, andHomeTeamColor: SKColor.red)
        self.puck?.position = FaceoffLocation.centerIce.coordinate
        self.positionPlayers(atFaceoffLocation: .centerIce)
        self.selectPlayerClosestToPuck()
        
        //Setting pan gesture recognizer
        self.panGesture = UIPanGestureRecognizer(target: self, action: #selector(self.pan(_:)))
        self.panGesture.delegate = self
        view.addGestureRecognizer(self.panGesture)
    }
    
    //Sets the physics body shape, gravity, and contact properties
    open func setPhysicsWorld() {
        self.physicsWorld.gravity = CGVector.zero
        self.position = CGPoint(x: 0, y: 0)
        self.physicsWorld.contactDelegate = self
        
        let pathFrame = CGRect(x: (self.frame.origin.y + rinkSize.width / 4) - 16, y: self.frame.origin.y - 143, width: rinkSize.width, height: rinkSize.height)
        let bezierPath = UIBezierPath(roundedRect: pathFrame, cornerRadius: rinkSize.width / 4)
        
        self.physicsBody = SKPhysicsBody(edgeLoopFrom: bezierPath.cgPath)
        self.physicsBody?.friction = 0.8
        self.physicsBody?.categoryBitMask = PhysicsCategory.rink
        self.physicsBody?.collisionBitMask = PhysicsCategory.all
        self.physicsBody?.contactTestBitMask =  PhysicsCategory.puck
        self.physicsBody?.usesPreciseCollisionDetection = true
    }
    
    //MARK: - GameplayKit
    //Handling adding and removing GKEntities
    func add(entity: GKEntity) {
        entities.insert(entity)
        
        if let playerEntity = entity as? Player {
            self.addChild(playerEntity.node!)
        }
        
        if let netEntity = entity as? Net {
            self.addChild(netEntity.node)
        }
        
        for componentSystem in componentSystems {
            componentSystem.addComponent(foundIn: entity)
        }
    }
    
    func remove(entity: GKEntity) {
        if let playerEntity = entity as? Player {
            playerEntity.node!.removeFromParent()
        }
        entities.remove(entity)
        
        self.entitiesToRemove.insert(entity)
    }
    
    open func bringNetsToFront() {
        Net.topNet.zPosition = 1
        Net.bottomNet.zPosition = 1
    }
    
    //Generates and adds nodes for both teams, the puck, and the rink
    open func generateAndAddNodes(withTeamSize teamSize: TeamSize = .five, andHomeTeamColor homeColor: SKColor = .red) {
        generateTeams(withPlayers: teamSize.intVal, andHomeTeamColor: homeColor)
        add(userTeam!)
        add(opposingTeam!)
        generateAndAddPuck()
        generateAndAddNets()
    }
    
    fileprivate func generateTeams(withPlayers playerCount: Int, andHomeTeamColor homeColor: SKColor) {
        userTeam = Team()
        opposingTeam = Team()
        
        //Generate team 1 (user team)
        for i in 0..<playerCount {
            let player = Player(withColor: homeColor, andRinkReference: self, andPosition: PlayerPosition(rawValue: i)!)
            player.isOnOpposingTeam = false
            userTeam?.append(player)
        }
        
        //Generate team 2 (opposing team)
        for i in 0..<playerCount {
            let player = Player(withColor: .white, andRinkReference: self, andPosition: PlayerPosition(rawValue: i)!)
            player.isOnOpposingTeam = true
            opposingTeam?.append(player)
        }
    }
    
    ///Adds a teams players to the ice
    fileprivate func add(_ team: Team) {
        for player in team {
            player.node?.position = self.position(forPlayer: player, atFaceoffLocation: .centerIce)
            self.add(entity: player)
        }
    }
    
    fileprivate func generateAndAddPuck() {
        self.puck = PuckNode()
        self.puck?.position = CGPoint(x: 0, y: 0)
        self.addChild(puck!)
        
        self.cameraNode.position = (self.puck?.position)!
    }
    
    fileprivate func generateAndAddNets() {
        self.add(entity: Net.topNet)
        self.add(entity: Net.bottomNet)
    }
    
    public func positionPlayers(atFaceoffLocation location: FaceoffLocation) {
        for player in userTeam! {
            player.playerComponent?.pointee.setPhysicsBody(withTexture: PlayerTexture.faceoff)
            player.position(atFaceoffLocation: location)
            player.addMovement()
        }
        for player in opposingTeam! {
            player.playerComponent?.pointee.setPhysicsBody(withTexture: PlayerTexture.faceoff)
            player.position(atFaceoffLocation: location)
            player.addMovement()
        }
    }
    
    //Computes position to set player for a faceoff location
    fileprivate func position(forPlayer player: Player, atFaceoffLocation location: FaceoffLocation) -> CGPoint {
        return location.playerPosition(forPlayer: player)
    }
    
    //Causes user controlled player to shoot the puck
    @objc fileprivate func selectedPlayerShootPuck() {
        if let selectedPlayer = selectedPlayer {
            if selectedPlayer.pointee.hasPuck {
                selectedPlayer.pointee.playerComponent?.pointee.shootPuck(atPoint: RinkEnd.top.point)
            }
        }
    }
    
    //Selects the player closest to the puck, or passes it to the next closest player
    open func selectPlayerClosestToPuck() {
        if var userTeam = userTeam {
            userTeam = userTeam.sorted(by: {
                player1, player2 in
                return player1.distance(fromNode: self.puck!) < player2.distance(fromNode: self.puck!)
            })
            
            var previousSelection: Player?
            //Deselect currently selected player
            if let selectedPlayer = selectedPlayer {
                previousSelection = selectedPlayer.pointee
                selectedPlayer.pointee.deselect()
            }
            
            //Select the player
            if !userTeam[0].isSelected && userTeam[0] != previousSelection {
                userTeam[0].select()
            }
            else {
                userTeam[1].select()
            }
            
            if let previousSelection = previousSelection {
                if previousSelection.hasPuck {
                    previousSelection.passPuck(toPlayer: (selectedPlayer?.pointee)!)
                }
            }
        }
    }
    
    var lastUpdate: TimeInterval = 0
    
    open override func update(_ currentTime: TimeInterval) {
        super.update(currentTime)
        
        if lastUpdate == 0 {
            lastUpdate = currentTime
        }
        
        //Finding delta time
        let deltaTime = currentTime - lastUpdate
        lastUpdate = currentTime

        //GameplayKit
        for componentSystem in componentSystems {
            componentSystem.update(deltaTime: deltaTime)
        }
        
        //Removing entities in entitiesToRemove
        for remove in entitiesToRemove {
            for componentSystem in componentSystems {
                componentSystem.removeComponent(foundIn: remove)
            }
        }
        entitiesToRemove.removeAll()

        
        if let puckInNet = puckInNet {
            //Goal scored
            if puckInNet == Net.topNet {
                GoalPresentation.shared.present(toView: self.view!, withCompletion: {
                    self.puck?.removeAllActions()
                    self.puck?.physicsBody = nil
                    self.puck?.setPhysicsBody()
                    self.puck?.position = FaceoffLocation.centerIce.coordinate
                    self.positionPlayers(atFaceoffLocation: .centerIce)
                })
            }
            else {
                print("Goal in bottom net!")
            }
        }
        
        userTeam?.moveComponentSystem.update(deltaTime: deltaTime)
        opposingTeam?.moveComponentSystem.update(deltaTime: deltaTime)
    
        //Follow puck location
        updateCameraPosition()
    }
    
    fileprivate func updateCameraPosition(toPosition position: CGPoint? = nil) {
        var point: CGPoint!
        if let position = position {
            point = position
        }
        else if let puckCarrier = puckCarrier {
            point = puckCarrier.pointee.position
        }
        else if let puck = puck {
            //calculate point to move camera to
            point = puck.position
        }
        
        //Keeping view on the ice
        if point.x < -180 {
            point.x = -180
        }
        else if point.x > 180 {
            point.x = 180
        }
        if point.y > 380 {
            point.y = 380
        }
        else if point.y < -380 {
            point.y = -380
        }

        let action = SKAction.move(to: point, duration: 0.25)
        cameraNode.run(action)

    }
    
    public func faceoffDotCoordinate(forLocation location: FaceoffLocation) -> CGPoint {
        return location.coordinate
    }
    
    //MARK: - SKPhysicsContactDelegate
    public func didBegin(_ contact: SKPhysicsContact) {
        let bodyA = contact.bodyA
        let bodyB = contact.bodyB
        
        if bodyA.categoryBitMask == PhysicsCategory.rink && bodyB.categoryBitMask == PhysicsCategory.puck {
            //Puck hit the boards
            //SoundEffectPlayer.boards.play(soundEffect: .puckHitBoards)
        }
        
        if bodyA.categoryBitMask == PhysicsCategory.player && bodyB.categoryBitMask == PhysicsCategory.puck {
            //Puck hit player
            if let playerNode = bodyA.node as? PlayerNode {
                if !playerNode.component!.isOnOpposingTeam {
                    playerNode.component!.pickUp(puck: &self.puck!)
                }
            }
        }
        if bodyA.categoryBitMask == PhysicsCategory.player && bodyB.categoryBitMask == PhysicsCategory.player {
            //Both are players
            self.playerNodeBodiesCollided(bodyA: bodyA, bodyB: bodyB, withContact: contact)
        }
    }
    
    fileprivate func physicsBodyToPlayerNode(_ body: SKPhysicsBody) -> PlayerNode? {
        return body.node as? PlayerNode
    }
    
    fileprivate func playerNodeBodiesCollided(bodyA: SKPhysicsBody, bodyB: SKPhysicsBody, withContact contact: SKPhysicsContact) {
//        if let player1 = physicsBodyToPlayerNode(bodyA) {
//            if let uPlayerNode = physicsBodyToPlayerNode(bodyB) {
//                let player2 = uPlayerNode
//                
//            }
//        }
//        if let uPlayerNode = physicsBodyToPlayerNode(bodyA) {
//            if let player2 = physicsBodyToPlayerNode(bodyB) {
//                let player1 = uPlayerNode
//            }
//        }
    }
    
    //MARK: - SwitchPlayerButtonDelegate
    
    public func buttonDidRecieveUserInput(switchPlayerButton button: SwitchPlayerButton) {
        self.selectPlayerClosestToPuck()
    }
    
    //MARK: - Panning
    func pan(_ sender: UIPanGestureRecognizer) {
        if let selectedPlayer = selectedPlayer {
            if selectedPlayer.pointee.hasPuck {
                if sender.state == .changed {
                    selectedPlayer.pointee.texture = PlayerTexture.texture(forTranslation: sender.translation(in: self.view!))
                    
                    if sender.translation(in: self.view!).y < -75 {
                        selectedPlayerShootPuck()
                    }
                }
                if sender.state == .ended {
                    selectedPlayer.pointee.texture = PlayerTexture.faceoff
                }
            }
        }
    }
    
//    //MARK: - UIGestureRecognizerDelegate
//    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
//        return true
//    }
//    
//    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
//        if touch.view is Joystick {
//            return false
//        }
//        return true
//    }

}

//Pair of SKPhysicsBodies
fileprivate class PhysicsBodyPair {
    var bodyA, bodyB: SKPhysicsBody!
    
    init(a: SKPhysicsBody, andB b: SKPhysicsBody) {
        self.bodyA = a
        self.bodyB = b
    }
}

//Faceoff locations on the playing surface
public enum FaceoffLocation {
    case offsideTopRight, offsideTopLeft, offsideBottomRight, offsideBottomLeft, centerIce
    
    public var coordinate: CGPoint {
        switch self {
        case .offsideTopRight :
            return CGPoint(x: 126, y: 147)
        case .offsideTopLeft :
            return CGPoint(x: -126, y: 147)
        case .offsideBottomRight :
            return CGPoint(x: 126, y: -147)
        case .offsideBottomLeft :
            return CGPoint(x: -126, y: -147)
        case .centerIce :
            return CGPoint(x: 0, y: 0)
        }
    }
    
    public var isOffsideLocation: Bool {
        switch self {
        case .offsideTopLeft, .offsideTopRight, .offsideBottomLeft, .offsideBottomRight :
            return true
        default :
            return false
        }
    }
    
    public func playerPosition(forPlayer player: Player) -> CGPoint {
        var point = self.coordinate
        
        //Check if player is on opposing team
        if player.isOnOpposingTeam == true {
            if player.pPosition.isForward {
                point.y += playerNodeSize.height / 1.9
                
                if player.pPosition == .leftWing {
                    point.x += rinkCenterCircleWidth / 2
                }
                else if player.pPosition == .rightWing {
                    point.x -= rinkCenterCircleWidth / 2
                }
            }
            else if player.pPosition.isDefenseman {
                point.y += rinkCenterCircleWidth / 2
                if player.pPosition == .leftDefense {
                    point.x -= rinkCenterCircleWidth / 3
                }
                else {
                    point.x += rinkCenterCircleWidth / 3
                }
            }
            
            return point
        }
        
        //Player is on the user controlled team
        
        if player.pPosition.isForward {
            point.y -= playerNodeSize.height / 1.9
            
            if player.pPosition == .leftWing {
                point.x -= rinkCenterCircleWidth / 2
            }
            else if player.pPosition == .rightWing {
                point.x += rinkCenterCircleWidth / 2
            }
        }
        else if player.pPosition.isDefenseman {
            point.y -= rinkCenterCircleWidth / 2
            if player.pPosition == .leftDefense {
                point.x -= rinkCenterCircleWidth / 3
            }
            else {
                point.x += rinkCenterCircleWidth / 3
            }
        }
        
        return point
    }
}

extension Notification.Name {
    static let shootPuckNotification = Notification.Name("shootPuckNotification")
    static let userGoalScoredNotification = Notification.Name("userGoalScoredNotification")
    static let cpuGoalScoredNotification = Notification.Name("cpuGoalScoredNotification")

}
