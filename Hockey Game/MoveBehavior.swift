//
//  MoveBehavior.swift
//  Hockey Game
//
//  Created by Collin DeWaters on 3/26/17.
//  Copyright © 2017 Collin DeWaters. All rights reserved.
//

import SpriteKit
import GameplayKit

class MoveBehavior: GKBehavior {

    init(forPlayerOnTeam team: Team, withPlayerPosition pPosition: PlayerPosition, withTargetSpeed targetSpeed: Float) {
        super.init()
        
        if targetSpeed > 0 {
            //Target speed goal
            let targetSpeedGoal = GKGoal(toReachTargetSpeed: targetSpeed / 2)
            self.setWeight(0.3, for: targetSpeedGoal)
            
            if pPosition.isDefenseman {
                let alignWithDefensemen = GKGoal(toAlignWith: team.defensemen.moveComponents, maxDistance: 200 / 3, maxAngle: Float.pi / 3)
                self.setWeight(0.6, for: alignWithDefensemen)
            }
            
            if pPosition.isForward {
                let alignWithForwards = GKGoal(toAlignWith: team.forwards.moveComponents, maxDistance: 200 / 3, maxAngle: Float.pi / 3)
                self.setWeight(0.6, for: alignWithForwards)
            }
            
            if team.isUserControlled {
                let netGoal = GKGoal(toSeekAgent: Net.topNet.netComponent)
                self.setWeight(1, for: netGoal)
            }
            else {
                let netGoal = GKGoal(toSeekAgent: Net.bottomNet.netComponent)
                self.setWeight(0.8, for: netGoal)
            }
            
            let avoidGoal = GKGoal(toAvoid: team.oppositeTeam.moveComponents, maxPredictionTime: 0.3)
            
            self.setWeight(1, for: avoidGoal)
                        
//            let goal = GKGoal(toWander: targetSpeed / 2)
//            self.setWeight(0.7, for: goal)
        }
    }

}

//Extending Array's functionality when it is a Team
extension Array where Element:Player {
    var isUserControlled: Bool {
        if self.count > 0 {
            return !self[0].isOnOpposingTeam
        }
        return false
    }
    
    var oppositeTeam: Team {
        if self.isUserControlled {
            return opposingTeam!
        }
        return userTeam!
    }
    
    var forwards: Team {
        var array = Team()
        for player: Player in self {
            if player.pPosition.isForward {
                array.append(player)
            }
        }
        return array
    }
    
    var defensemen: Team {
        var array = Team()
        for player: Player in self {
            if player.pPosition.isDefenseman {
                array.append(player)
            }
        }
        return array
    }
    
    var goalie: Player? {
        for player: Player in self {
            if player.pPosition == PlayerPosition.goalie {
                return player
            }
        }
        return nil
    }
    
    var moveComponents: [MoveComponent] {
        var components = [MoveComponent]()
        for player: Player in self {
            if let moveComponent = player.moveComponent {
                components.append(moveComponent)
            }
        }
        return components
    }
    
    var moveComponentSystem: GKComponentSystem<MoveComponent> {
        let componentSystem = GKComponentSystem(componentClass: MoveComponent.self)
        for component in self.moveComponents {
            componentSystem.addComponent(component)
        }
        return componentSystem as! GKComponentSystem<MoveComponent>
    }
    
    func player(withPosition pPosition: PlayerPosition) -> Player? {
        for player: Player in self {
            if player.pPosition == pPosition {
                return player
            }
        }
        return nil
    }
}
