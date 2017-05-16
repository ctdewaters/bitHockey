//
//  WindowController.swift
//  Hockey Game
//
//  Created by Collin DeWaters on 5/10/17.
//  Copyright © 2017 Collin DeWaters. All rights reserved.
//

import Cocoa

class WindowController: NSWindowController, NSTouchBarDelegate {
    
    override func windowDidLoad() {
        super.windowDidLoad()
        print("WINDOW LOADED\n\n\n")
        
    }

    //MARK: - NSTouchBar
    
    @available(OSX 10.12.2, *)
    func update(withTouchBar touchBar: NSTouchBar?) {
        self.touchBar = touchBar
    }
}
