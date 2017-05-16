//
//  MenuTouchBar.swift
//  Hockey Game
//
//  Created by Collin DeWaters on 5/10/17.
//  Copyright © 2017 Collin DeWaters. All rights reserved.
//

import Cocoa

enum MenuTouchBarState {
    case controlsClosed, controlsOpen
}

@available(OSX 10.12.2, *)
class MenuTouchBar: NSTouchBar, NSTouchBarDelegate {
    
    init(withState state: MenuTouchBarState) {
        super.init()
        
        self.customizationIdentifier = .menu

        if state == .controlsClosed {
            self.defaultItemIdentifiers = [.homeTitleLabel, .startGame, .showControls]
            self.customizationAllowedItemIdentifiers = [.startGame, .showControls]
        }
        else {
            self.defaultItemIdentifiers = [.homeTitleLabel, .closeControls]
        }
        self.delegate = self
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: - NSTouchBarDelegate
    
    func touchBar(_ touchBar: NSTouchBar, makeItemForIdentifier identifier: NSTouchBarItemIdentifier) -> NSTouchBarItem? {
        switch identifier {
        case NSTouchBarItemIdentifier.homeTitleLabel :
            let item = NSCustomTouchBarItem(identifier: identifier)
            let font = NSFont(name: "Mexcellent", size: 27)!
            let label = NSTextField(labelWithAttributedString: NSAttributedString(string: "bitHockey", attributes: [NSFontAttributeName: font, NSForegroundColorAttributeName: NSColor.white]))
            item.view = label
            return item
            
        case NSTouchBarItemIdentifier.startGame :
            let startGameButtonItem = NSCustomTouchBarItem(identifier: identifier)
            let button = NSButton(title: "Play", image: NSImage(), target: self, action: #selector(self.sendStartGameNotification))
            
            //Attributed string text alignment 
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .center
            
            //Setting the button's attributed title
            button.attributedTitle = NSAttributedString(string: "Play", attributes: [NSFontAttributeName: NSFont.systemFont(ofSize: 15, weight: NSFontWeightSemibold), NSForegroundColorAttributeName: NSColor(red: 0.81, green: 1.00, blue: 0.93, alpha: 1.0), NSParagraphStyleAttributeName: paragraphStyle])
            button.alignment = .center
            startGameButtonItem.view =  button
            return startGameButtonItem
            
        case NSTouchBarItemIdentifier.showControls :
            let showControlsButtonItem = NSCustomTouchBarItem(identifier: identifier)
            let button = NSButton(title: "Show Controls", image: NSImage(), target: self, action: #selector(self.sendShowControlsNotification))
            
            //Attributed string text alignment
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .center
            
            //Setting the button's attributed title
            button.attributedTitle = NSAttributedString(string: "Show Controls", attributes: [NSFontAttributeName: NSFont.systemFont(ofSize: 15, weight: NSFontWeightRegular), NSForegroundColorAttributeName: NSColor(red: 0.81, green: 0.90, blue: 1.00, alpha: 1.0), NSParagraphStyleAttributeName: paragraphStyle])
            button.alignment = .center
            showControlsButtonItem.view =  button
            return showControlsButtonItem

        case NSTouchBarItemIdentifier.closeControls :
            let closeControlsButtonItem = NSCustomTouchBarItem(identifier: identifier)
            let button = NSButton(title: "Close Controls", image: NSImage(), target: self, action: #selector(self.sendCloseControlsNotification))
            
            //Attributed string text alignment
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .center
            
            //Setting the button's attributed title
            button.attributedTitle = NSAttributedString(string: "Close Controls", attributes: [NSFontAttributeName: NSFont.systemFont(ofSize: 15, weight: NSFontWeightRegular), NSForegroundColorAttributeName: NSColor(red: 1.00, green: 0.43, blue: 0.40, alpha: 1.0), NSParagraphStyleAttributeName: paragraphStyle])
            button.alignment = .center
            closeControlsButtonItem.view =  button
            return closeControlsButtonItem

        default :
            return nil
        }
    }
    
    //MARK: - Actions
    
    func sendStartGameNotification() {
        NotificationCenter.default.post(name: .startGame, object: nil)
    }
    
    func sendShowControlsNotification() {
        NotificationCenter.default.post(name: .showControls, object: nil)
    }
    
    func sendCloseControlsNotification() {
        NotificationCenter.default.post(name: .closeControls, object: nil)
    }

}

fileprivate extension NSTouchBarCustomizationIdentifier {
    static let menu = NSTouchBarCustomizationIdentifier("com.CollinDeWaters.bitHockey.menu")
}

fileprivate extension NSTouchBarItemIdentifier {
    static let homeTitleLabel = NSTouchBarItemIdentifier("com.CollinDeWaters.bitHockey.homeTitleLabel")
    static let startGame = NSTouchBarItemIdentifier("com.CollinDeWaters.bitHockey.startGame")
    static let showControls = NSTouchBarItemIdentifier("com.CollinDeWaters.bitHockey.showControls")
    static let closeControls = NSTouchBarItemIdentifier("com.CollinDeWaters.bitHockey.closeControls")
}

extension Notification.Name {
    static let startGame = Notification.Name("com.CollinDeWaters.bitHockey.startGame")
    static let showControls = Notification.Name("com.CollinDeWaters.bitHockey.showControls")
    static let closeControls = Notification.Name("com.CollinDeWaters.bitHockey.closeControls")
}
