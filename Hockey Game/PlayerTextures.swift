import SpriteKit

class PlayerTexture {
    
    //MARK: - Textures
    
    //The Faceoff texture
    static let faceoff = SKTexture(imageNamed: "faceoffPosition")
    
    //Skating textures
    static let f1 = SKTexture(imageNamed: "player1")
    static let f2 = SKTexture(imageNamed: "player2")
    static let f3 = SKTexture(imageNamed: "player3")
    static let f4 = SKTexture(imageNamed: "player4")
    static let f5 = SKTexture(imageNamed: "player5")
    static let f6 = SKTexture(imageNamed: "player6")
    static let f7 = SKTexture(imageNamed: "player7")
    static let f8 = SKTexture(imageNamed: "player8")
    static let skatingTextures: [SKTexture] = [f1, f2, f3, f4, f5, f6, f7, f8, f7, f6, f5, f4, f3, f2, f1]
    
    //Shooting textures
    static let shoot1 = SKTexture(imageNamed: "shoot1")
    static let shoot2 = SKTexture(imageNamed: "shoot2")
    static let shoot3 = SKTexture(imageNamed: "shoot3")
    static let shootingTextures: [SKTexture] = [shoot1, shoot2, shoot3]
    
    //Deking textures
    static let dekeNeg2 = SKTexture(imageNamed: "playerPosition-2")
    static let dekeNeg1 = SKTexture(imageNamed: "playerPosition-1")
    static let deke0 = SKTexture(imageNamed: "playerPosition0")
    static let deke1 = SKTexture(imageNamed: "playerPosition1")
    static let deke2 = SKTexture(imageNamed: "playerPosition2")
    
    //Net physics body texture
    static let netPhysicsBody = SKTexture(imageNamed: "netPhysicsBody.png")
    
    //MARK: - Physics bodies
    
    static var skatingTexturePhysicsBodies: [SKPhysicsBody] {
        let bodies = skatingTextures.map {
            return SKPhysicsBody(texture: $0, size: playerNodeSize)
        }
        return bodies
    }
    
    static let faceoffPhysicsBody = SKPhysicsBody(texture: faceoff, size: playerNodeSize)
    
    static let boundSize: CGFloat = 100
    
    
    //MARK: - Functions
    
    //Finds correct texture for deking (UIPanGestureRecognizer translation)
    class func texture(forTranslation translation: CGPoint) -> SKTexture {
        let translation = self.bound(translationPoint: translation)
        
        let totalRange = boundSize * 2
        let sectorSize = totalRange / 5
        
        let stickHandleUpperBound = (boundSize / 5)
        let stickHandleLowerBound = -(boundSize / 5)
        
        
        if translation.y > stickHandleLowerBound && translation.y < stickHandleUpperBound {
            //Stick handling
            var lowerBound: CGFloat = -boundSize
            for i in -2..<3 {
                let upperBound = lowerBound + sectorSize
                
                if translation.x >= lowerBound && translation.x <= upperBound {
                    return SKTexture(imageNamed: "playerPosition\(i)")
                }
                
                lowerBound += sectorSize
            }
        }
        
        return faceoff
    }
    
    fileprivate class func bound(translationPoint point: CGPoint) -> CGPoint {
        var point = point
        if point.x > boundSize {
            point.x = boundSize
        }
        else if point.x < -boundSize {
            point.x = -boundSize
        }
        if point.y > boundSize {
            point.y = boundSize
        }
        else if point.y < -boundSize {
            point.y = -boundSize
        }
        point.y = -point.y
        return point
    }

}

public extension Notification.Name {
    public static let userShouldShootNotification = Notification.Name("userShouldShootNotification")
}
