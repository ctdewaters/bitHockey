import SpriteKit
import GameplayKit
import AVFoundation
#if os(OSX)
import Cocoa
    
public let sceneBackgroundColor = NSColor(red:0.13, green:0.13, blue:0.13, alpha:1.0)
#elseif os(iOS)
import UIKit

public let sceneBackgroundColor = UIColor(red:0.13, green:0.13, blue:0.13, alpha:1.0)
#endif

public let rinkSize = CGSize(width: 728, height: 1024)
public let rinkCenterCircleWidth: CGFloat = 155

//The physics body categories for all entities
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

//Rink delegate
protocol RinkDelegate {
    func rinkDidPause()
    func rinkDidResume()
}

public typealias Team = [Player]

public var userTeam: Team?
public var opposingTeam: Team?

public var homeTeamColor: SKColor!

var player: AVPlayer!

public class Rink: SKScene, SKPhysicsContactDelegate, PlayerDelegate {
    
    open var entities = Set<GKEntity>()
    open var entitiesToRemove = Set<GKEntity>()
    
    public static let shared = Rink(size: rinkSize)
    
    lazy var componentSystems: [GKComponentSystem] = {
        let playerSystem = GKComponentSystem(componentClass: PlayerComponent.self)
        let moveSystem = GKComponentSystem(componentClass: MoveComponent.self)
        let userSystem = GKComponentSystem(componentClass: UserComponent.self)
        let netSystem = GKComponentSystem(componentClass: NetComponent.self)
        return [playerSystem, moveSystem, userSystem, netSystem]
    }()
    
    
    //Returns the selected player on the user controlled team
    open var selectedPlayer: Player? {
        if let userTeam = userTeam {
            for player in userTeam {
                if player.isSelected {
                    return player
                }
            }
        }
        return nil
    }
    
    //Returns the player on either team that is currently carrying the puck
    public var puckCarrier: Player? {
        if let userTeam = userTeam {
            for player in userTeam {
                if player.hasPuck {
                    return player
                }
            }
        }
        if let opposingTeam = opposingTeam {
            for player in opposingTeam {
                if player.hasPuck {
                    return player
                }
            }
        }
        return nil
    }
    
    //Returns the net the puck is in (nil if no goal scored).
    fileprivate var puckInNet: Net? {
        if Net.topNet.frame.contains(Puck.shared.position) || (self.puckCarrier != nil && Net.topNet.frame.contains(puckCarrier!.position)) {
            return Net.topNet
        }
        else if Net.bottomNet.frame.contains(Puck.shared.position) || (self.puckCarrier != nil && Net.bottomNet.frame.contains(puckCarrier!.position)) {
            return Net.bottomNet
        }
        return nil
    }

    //The camera for the scene
    let cameraNode: SKCameraNode = SKCameraNode()
    
    var backgroundNode: SKSpriteNode!
        
    public override init(size: CGSize) {
        super.init(size: size)
        //Setting anchor point in the center
        self.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        
        self.backgroundNode = SKSpriteNode(imageNamed: "rinkBackground")
        self.backgroundNode.size = size
        self.backgroundNode.zPosition = -3
        self.addChild(self.backgroundNode)
        
        self.backgroundColor = sceneBackgroundColor
        
        //Adding the camera
        self.addChild(cameraNode)
        cameraNode.setScale(0.75)
        camera = cameraNode
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    ///Ends the game, and removes nodes from the rink.
    func deactivate() {
        self.resume()
        self.removeAllActions()
        
        Score.shared.reset()
        
        self.selectedPlayer?.removeComponent(ofType: UserComponent.self)
        
        for child in children {
            if child != self.backgroundNode && child != self.cameraNode {
                child.removeAllActions()
                child.removeFromParent()
            }
        }
        
        Puck.shared.node.removeFromParent()
        Puck.shared.node.removeAllActions()
        
        for entity in self.entities {
            self.remove(entity: entity)
        }
        
        //Removing entities in entitiesToRemove
        for remove in entitiesToRemove {
            for componentSystem in componentSystems {
                componentSystem.removeComponent(foundIn: remove)
            }
        }
        self.entitiesToRemove.removeAll()

        self.animateCameraScale(toValue: 0.25, center: true, withDuration: 0.25)
    }
    
    ///Adds nodes to the rink, and starts the game.
    func activate() {
        self.resume()
        //Generating the nets, players, and puck
        self.setPhysicsWorld()
        
        self.generateAndAddNodes(withTeamSize: .five, andHomeTeamColor: SKColor(red: 0.9, green: 0.09, blue: 0.22, alpha: 1))
    }
    
    func animateCameraScale(toValue value: CGFloat, center: Bool = false, withDuration duration: TimeInterval = 0.75) {
        let action = SKAction.scale(to: value, duration: duration)
        if center {
            let group = SKAction.group([action, SKAction.move(to: .zero, duration: duration)])
            self.cameraNode.run(group)
            return
        }
        cameraNode.run(action)
    }
    
    func animateCamera(toPosition position: CGPoint, withDuration duration: TimeInterval = 0.75) {
        let action = SKAction.move(to: position, duration: duration)
        action.timingMode = .easeInEaseOut
        cameraNode.run(action)
    }
    
    open override func didMove(to view: SKView) {
        super.didMove(to: view)
        
        #if os(OSX)
        if let skView = view as? GameView {
            skView.controlKeyDelegate = UserComponent.shared
        }
        #endif
        self.setPhysicsWorld()
        Puck.shared.position = FaceoffLocation.centerIce.coordinate
    }
    
    //Pause the game
    open func pause() {
        self.view?.isPaused = true
    }
    
    //Resume the game
    open func resume() {
        self.view?.isPaused = false
    }
    
    //Sets the physics body shape, gravity, and contact properties
    fileprivate func setPhysicsWorld() {
        self.physicsWorld.gravity = CGVector.zero
        self.physicsWorld.contactDelegate = self
        
        let pathFrame = CGRect(x: self.frame.origin.x + 108, y: self.frame.origin.y, width: 513, height: rinkSize.height)
        #if os(OSX)
            let bezierPath = NSBezierPath(roundedRect: pathFrame, xRadius: rinkSize.width / 6, yRadius: rinkSize.width / 6)
            self.physicsBody = SKPhysicsBody(edgeLoopFrom: bezierPath.cgPath)
        #elseif os(iOS)
            let path = UIBezierPath(roundedRect: pathFrame, cornerRadius: rinkSize.width / 6)
            self.physicsBody = SKPhysicsBody(edgeLoopFrom: path.cgPath)
        #endif
        self.physicsBody?.friction = 0.8
        self.physicsBody?.categoryBitMask = PhysicsCategory.rink
        self.physicsBody?.collisionBitMask = PhysicsCategory.all
        self.physicsBody?.contactTestBitMask =  PhysicsCategory.puck
        self.physicsBody?.usesPreciseCollisionDetection = true
    }
    
    //MARK: - GameplayKit
    //Handling adding and removing GKEntities
    fileprivate func add(entity: GKEntity) {
        entities.insert(entity)
        
        if let playerEntity = entity as? Player {
            self.addChild(playerEntity.node!)
        }
        
        if let netEntity = entity as? Net {
            self.addChild(netEntity.node)
        }
        
        if let puckEntity = entity as? Puck {
            self.addChild(puckEntity.node)
        }
        
        for componentSystem in componentSystems {
            componentSystem.addComponent(foundIn: entity)
        }
    }
    
    fileprivate func remove(entity: GKEntity) {
        if let playerEntity = entity as? Player {
            playerEntity.node!.removeFromParent()
        }
        self.entities.remove(entity)
        
        self.entitiesToRemove.insert(entity)
    }
    
    open func bringNetsToFront() {
        Net.topNet.zPosition = 1
        Net.bottomNet.zPosition = 1
    }
    
    //Generates and adds nodes for both teams, the puck, and the rink
    public func generateAndAddNodes(withTeamSize teamSize: TeamSize = .five, andHomeTeamColor homeColor: SKColor = .red) {
        userTeam = nil
        opposingTeam = nil
        homeTeamColor = homeColor
        generateTeams(withPlayers: teamSize.intVal, andHomeTeamColor: homeColor)
        add(userTeam!)
        add(opposingTeam!)
        generateAndAddPuck()
        generateAndAddNets()
        
        //Position the players at center ice for the opening faceoff.
        self.positionPlayers(atFaceoffLocation: .centerIce, withDuration: 2) {
            self.selectPlayerClosestToPuck()
            
            //Start the play clock
            Scoreboard.shared.startTimer()
            
            for player in userTeam! {
                if !player.isSelected {
                    player.addMovement()
                }
            }
            for player in opposingTeam! {
                player.addMovement()
            }
        }

    }
    
    func generateTeams(withPlayers playerCount: Int, andHomeTeamColor homeColor: SKColor) {
        userTeam = Team()
        opposingTeam = Team()
        
        //Generate team 1 (user team)
        for i in 0..<playerCount {
            let player = Player(withColor: homeColor, andPosition: PlayerPosition(rawValue: i)!)
            player.isOnOpposingTeam = false
            userTeam?.append(player)
        }
        
        //Generate team 2 (opposing team)
        for i in 0..<playerCount {
            let player = Player(withColor: .white, andPosition: PlayerPosition(rawValue: i)!)
            player.isOnOpposingTeam = true
            opposingTeam?.append(player)
        }
    }
    
    ///Adds a teams players to the ice
    func add(_ team: Team) {
        for player in team {
            var position = self.position(forPlayer: player, atFaceoffLocation: .centerIce)
            
            if player.isOnOpposingTeam {
                position.y += 150
            }
            else {
                position.y -= 150
            }
            
            player.node?.position = position
            self.add(entity: player)
        }
    }
    
    fileprivate func generateAndAddPuck() {
        Puck.shared.node.position = CGPoint(x: -1, y: 0)
        self.add(entity: Puck.shared)
        Puck.shared.puckComponent.setPhysicsBody()
        self.cameraNode.position = Puck.shared.position
    }
    
    fileprivate func generateAndAddNets() {
        self.add(entity: Net.topNet)
        self.add(entity: Net.bottomNet)
    }
    
    public func positionPlayers(atFaceoffLocation location: FaceoffLocation, withDuration duration: TimeInterval, andCompletion completion: (()->Void)? = nil) {
        if let userTeam = userTeam {
            for player in userTeam {
                player.playerComponent?.node.physicsBody = nil
                player.position(atFaceoffLocation: location, withDuration: duration)
            }
        }
        for player in opposingTeam! {
            player.playerComponent?.node.physicsBody = nil
            player.position(atFaceoffLocation: location, withDuration: duration)
        }
        Timer.scheduledTimer(withTimeInterval: duration, repeats: false, block: {
            timer in
            completion?()
            userTeam?.setPhysicsBodies()
            opposingTeam?.setPhysicsBodies()
        })
    }
    
    //Computes position to set player for a faceoff location
    fileprivate func position(forPlayer player: Player, atFaceoffLocation location: FaceoffLocation) -> CGPoint {
        return location.playerPosition(forPlayer: player)
    }
    
    //Causes user controlled player to shoot the puck
    @objc fileprivate func selectedPlayerShootPuck() {
        if let selectedPlayer = selectedPlayer {
            if selectedPlayer.hasPuck {
                selectedPlayer.playerComponent?.shootPuck(atPoint: RinkEnd.top.point)
            }
        }
    }
    
    //Selects the player closest to the puck, or passes it to the next closest player
    open func selectPlayerClosestToPuck() {
        if var userTeam = userTeam {
            if Puck.shared.node.parent == self {
                userTeam = userTeam.sorted(by: {
                    player1, player2 in
                    return player1.distance(fromNode: Puck.shared.node) < player2.distance(fromNode: Puck.shared.node)
                })
            }
            else if Puck.shared.node.parent != nil {
                userTeam = userTeam.sorted(by: {
                    player1, player2 in
                    return player1.distance(fromNode: self.puckCarrier!.node!) < player2.distance(fromNode: self.puckCarrier!.node!)
                })
            }
            
            var previousSelection: Player?
            //Deselect currently selected player
            if let selectedPlayer = selectedPlayer {
                previousSelection = selectedPlayer
                selectedPlayer.deselect()
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
                    previousSelection.passPuck(toPlayer: selectedPlayer!)
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
            #if os(iOS)
            goalVC.add(toView: self.view!) {
                //Update the score
                if puckInNet == Net.topNet {
                    Score.shared.score(forUserTeam: true)
                    goalVC.updateScore(forUserTeam: true)
                    
                    Haptics.shared.sendNotificationHaptic(withType: .success)
                }
                else {
                    Score.shared.score(forUserTeam: false)
                    goalVC.updateScore(forUserTeam: false)
                    
                    Haptics.shared.sendNotificationHaptic(withType: .error)
                }
                
                goalVC.tapCompletion = {
                    self.positionPlayers(atFaceoffLocation: .centerIce, withDuration: 0.3)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.75, execute: {
                            self.addChild(Puck.shared.node)
                            Scoreboard.shared.startTimer()
                    })
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: {
                    if !goalVC.dismissing {
                        goalVC.dismiss {}
                        
                        self.positionPlayers(atFaceoffLocation: .centerIce, withDuration: 0.3)
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
                            self.addChild(Puck.shared.node)
                            Scoreboard.shared.startTimer()
                        })
                    }
                })
            }
            #endif
            
            Puck.shared.node.removeAllActions()
            Puck.shared.node.physicsBody = nil
            Puck.shared.puckComponent.setPhysicsBody()
            Puck.shared.node.position = FaceoffLocation.centerIce.coordinate
            Puck.shared.node.removeFromParent()
            puckCarrier?.hasPuck = false
        }
        
        userTeam?.moveComponentSystem.update(deltaTime: deltaTime)
        opposingTeam?.moveComponentSystem.update(deltaTime: deltaTime)
        UserComponent.shared.update(deltaTime: deltaTime)
        Puck.shared.update(deltaTime: deltaTime)
    
        //Follow puck location
        updateCameraPosition()
    }
    
    fileprivate func updateCameraPosition(toPosition position: CGPoint? = nil) {
        var point: CGPoint!
        if let position = position {
            point = position
        }
        else if let puckCarrier = puckCarrier {
            if puckCarrier.node?.parent != nil {
                point = puckCarrier.position
            }
            else {
                point = .zero
            }
        }
        else {
            //calculate point to move camera to
            if Puck.shared.node.parent != nil {
                point = Puck.shared.position
            }
            else {
                point = .zero
            }
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
            if contact.collisionImpulse > 5 {
                
                #if os(iOS)
                Haptics.shared.sendImpactHaptic(withStyle: .heavy)
                #endif
                player = AVPlayer(url: Bundle.main.url(forResource: "thump", withExtension: "mp3")!)
                player.play()
            }
            else {
                #if os(iOS)
                Haptics.shared.sendImpactHaptic(withStyle: .light)
                #endif
            }
        }
        
        if bodyA.categoryBitMask == PhysicsCategory.player && bodyB.categoryBitMask == PhysicsCategory.puck {
            //Puck hit player
            if let playerNode = bodyA.node as? PlayerNode {
                if !playerNode.component!.isOnOpposingTeam {
                    self.selectedPlayer?.deselect()
                }
                playerNode.component!.pickUpPuck()
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
        if let player1 = physicsBodyToPlayerNode(bodyA) {
            if let uPlayerNode = physicsBodyToPlayerNode(bodyB) {
                let player2 = uPlayerNode
                
            }
        }
        if let uPlayerNode = physicsBodyToPlayerNode(bodyA) {
            if let player2 = physicsBodyToPlayerNode(bodyB) {
                let player1 = uPlayerNode
            }
        }
    }
    
    //MARK: - PlayerDelegate
    public func playerDidPickUpPuck(_ player: Player) {
        if !player.isOnOpposingTeam {
            userTeam?.updateBehaviorToOffense()
            opposingTeam?.updateBehaviorToDefense()
        }
        else {
            userTeam?.updateBehaviorToDefense()
            opposingTeam?.updateBehaviorToOffense()
        }
    }
    
    public func playerDidReleasePuck(_ player: Player) {
        userTeam!.chasePuck()
        opposingTeam!.chasePuck()
    }
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

#if os(OSX)
public extension NSBezierPath {
    public var cgPath: CGPath {
        let path = CGMutablePath()
        var points = [CGPoint](repeating: .zero, count: 3)
        for i in 0 ..< self.elementCount {
            let type = self.element(at: i, associatedPoints: &points)
            switch type {
            case .moveToBezierPathElement:
                path.move(to: points[0])
            case .lineToBezierPathElement:
                path.addLine(to: points[0])
            case .curveToBezierPathElement:
                path.addCurve(to: points[2], control1: points[0], control2: points[1])
            case .closePathBezierPathElement:
                path.closeSubpath()
            }
        }
        return path
    }
}
#endif

extension Notification.Name {
    static let shootPuckNotification = Notification.Name("shootPuckNotification")
    static let userGoalScoredNotification = Notification.Name("userGoalScoredNotification")
    static let cpuGoalScoredNotification = Notification.Name("cpuGoalScoredNotification")

}
