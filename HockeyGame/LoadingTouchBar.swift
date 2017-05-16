//
//  LoadingTouchBar.swift
//  Hockey Game
//
//  Created by Collin DeWaters on 5/13/17.
//  Copyright © 2017 Collin DeWaters. All rights reserved.
//

import Cocoa

@available(OSX 10.12.2, *)
class LoadingTouchBar: NSTouchBar, NSTouchBarDelegate {
    
    override init() {
        super.init()
        
        self.defaultItemIdentifiers = [.loadingIndicator, .loadingLabel]
        self.delegate = self
        print("CREATED LOADING TOUCH BAR")
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    //MARK: - NSTouchBarDelegate
    func touchBar(_ touchBar: NSTouchBar, makeItemForIdentifier identifier: NSTouchBarItemIdentifier) -> NSTouchBarItem? {
        switch identifier {
        case NSTouchBarItemIdentifier.loadingIndicator :
            let item = NSCustomTouchBarItem(identifier: identifier)
            let progressIndicator = NSProgressIndicator()
            progressIndicator.style = .spinningStyle
            progressIndicator.controlTint = .blueControlTint
            
            item.view = progressIndicator
            return item
        case NSTouchBarItemIdentifier.loadingLabel :
            let item = NSCustomTouchBarItem(identifier: identifier)
            let label = NSTextField(labelWithString: "Loading Game...")
            label.font = NSFont(name: "Rubik", size: 17)
            item.view = label
            return item
        default :
            break
        }
        return nil
    }
}

fileprivate extension NSTouchBarItemIdentifier {
    static let loadingIndicator = NSTouchBarItemIdentifier("com.CollinDeWaters.bitHockey.loadingIndicator")
    static let loadingLabel = NSTouchBarItemIdentifier("com.CollinDeWaters.bitHockey.loadingLabel")
}
