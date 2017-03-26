//
//  UserComponent.swift
//  Hockey Game
//
//  Created by Collin DeWaters on 3/25/17.
//  Copyright © 2017 Collin DeWaters. All rights reserved.
//

import GameplayKit
import SpriteKit

public class UserComponent: GKComponent, JoystickDelegate {
    
    public override func didAddToEntity() {
        super.didAddToEntity()
        self.playerComponent?.pointee.select()
    }
    
    deinit {
        self.playerComponent?.pointee.deselect()
    }
    
    //MARK: - JoystickDelegate
    
    public func joystickDidExitIdle(_ joystick: Joystick) {
        self.playerComponent?.pointee.animateSkatingTextures()
    }
    
    public func joystickDidReturnToIdle(_ joystick: Joystick) {
        playerComponent?.pointee.stopSkatingAction()
        player?.texture = PlayerTexture.faceoff
        playerComponent?.pointee.applySkatingImpulse()
    }
    
    public func joystick(_ joystick: Joystick, didGenerateData joystickData: JoystickData) {
        self.playerComponent?.pointee.move(withJoystickData: joystickData)
    }
    
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
