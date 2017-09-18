//
//  UserComponent.swift
//  Hockey Game
//
//  Created by Collin DeWaters on 3/25/17.
//  Copyright © 2017 Collin DeWaters. All rights reserved.
//

import GameplayKit
import SpriteKit

public class UserComponent: GKAgent2D, GKAgentDelegate, JoystickDelegate, SwitchPlayerButtonDelegate {
    
    public static let shared = UserComponent()
    
    public override func didAddToEntity() {
        super.didAddToEntity()
        self.delegate = self
        self.playerComponent?.select()
    }

    
    deinit {
        self.playerComponent?.deselect()
    }
    
    //MARK: - JoystickDelegate
    
    public func joystickDidExitIdle(_ joystick: Joystick) {
        self.playerComponent?.animateSkatingTextures()
    }
    
    public func joystickDidReturnToIdle(_ joystick: Joystick) {
        playerComponent?.stopSkatingAction()
        player?.texture = PlayerTexture.faceoff
        playerComponent?.applySkatingImpulse()
    }
    
    public func joystick(_ joystick: Joystick, didGenerateData joystickData: JoystickData) {
        self.playerComponent?.move(withJoystickData: joystickData)
        
        print("joystickData.magnitude = \(joystickData.magnitude!), angle = \(joystickData.angle!)")
    }
    
    //MARK: - SwitchPlayerButtonDelegate
    
    public func buttonDidRecieveUserInput(switchPlayerButton button: SwitchPlayerButton) {
        Rink.shared.selectPlayerClosestToPuck()
    }
    
    //MARK: - GKAgentDelegate
    public func agentWillUpdate(_ agent: GKAgent) {
        if self.player != nil {
            if self.player!.node != nil {
                self.position = float2(withCGPoint: self.player!.node!.position)
            }
        }
    }
    
    public func agentDidUpdate(_ agent: GKAgent) {
    }

    
    //MARK: - Calculated variables
    
    //The player entity
    fileprivate var player: Player? {
        return self.entity as? Player
    }
    
    //The player component
    fileprivate var playerComponent: PlayerComponent? {
        return self.player?.playerComponent
    }

}
