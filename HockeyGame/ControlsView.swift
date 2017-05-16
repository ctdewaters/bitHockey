//
//  ControlsView.swift
//  Hockey Game
//
//  Created by Collin DeWaters on 5/9/17.
//  Copyright © 2017 Collin DeWaters. All rights reserved.
//

import Cocoa

class ControlsView: NSVisualEffectView {
    func set() {
        wantsLayer = true
        
        self.state = .followsWindowActiveState
        self.material = .light
        self.blendingMode = .withinWindow
    }
}
