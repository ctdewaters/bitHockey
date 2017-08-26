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
    
    func touchBar(_ touchBar: NSTouchBar, makeItemForIdentifier identifier: NSTouchBarItem.Identifier) -> NSTouchBarItem? {
        switch identifier {
        case NSTouchBarItem.Identifier.homeTitleLabel :
            let item = NSCustomTouchBarItem(identifier: identifier)
            let font = NSFont(name: "Krunch", size: 27)!
            let label = NSTextField(labelWithAttributedString: NSAttributedString(string: "Bit Hockey", attributes: [NSAttributedStringKey.font: font, NSAttributedStringKey.foregroundColor: NSColor.white]))
            item.view = label
            return item
            
        case NSTouchBarItem.Identifier.startGame :
            let startGameButtonItem = NSCustomTouchBarItem(identifier: identifier)
            let button = NSButton(title: "Play", image: NSImage(), target: self, action: #selector(self.sendStartGameNotification))
            
            //Attributed string text alignment 
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .center
            
            //Setting the button's attributed title
            button.attributedTitle = NSAttributedString(string: "Play", attributes: [NSAttributedStringKey.font: NSFont.systemFont(ofSize: 15, weight: NSFont.Weight.semibold), NSAttributedStringKey.foregroundColor: NSColor(red: 0.81, green: 1.00, blue: 0.93, alpha: 1.0), NSAttributedStringKey.paragraphStyle: paragraphStyle])
            button.alignment = .center
            startGameButtonItem.view =  button
            return startGameButtonItem
            
        case NSTouchBarItem.Identifier.showControls :
            let showControlsButtonItem = NSCustomTouchBarItem(identifier: identifier)
            let button = NSButton(title: "Show Controls", image: NSImage(), target: self, action: #selector(self.sendShowControlsNotification))
            
            //Attributed string text alignment
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .center
            
            //Setting the button's attributed title
            button.attributedTitle = NSAttributedString(string: "Show Controls", attributes: [NSAttributedStringKey.font: NSFont.systemFont(ofSize: 15, weight: NSFont.Weight.regular), NSAttributedStringKey.foregroundColor: NSColor(red: 0.81, green: 0.90, blue: 1.00, alpha: 1.0), NSAttributedStringKey.paragraphStyle: paragraphStyle])
            button.alignment = .center
            showControlsButtonItem.view =  button
            return showControlsButtonItem

        case NSTouchBarItem.Identifier.closeControls :
            let closeControlsButtonItem = NSCustomTouchBarItem(identifier: identifier)
            let button = NSButton(title: "Close Controls", image: NSImage(), target: self, action: #selector(self.sendCloseControlsNotification))
            
            //Attributed string text alignment
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .center
            
            //Setting the button's attributed title
            button.attributedTitle = NSAttributedString(string: "Close Controls", attributes: [NSAttributedStringKey.font: NSFont.systemFont(ofSize: 15, weight: NSFont.Weight.regular), NSAttributedStringKey.foregroundColor: NSColor(red: 1.00, green: 0.43, blue: 0.40, alpha: 1.0), NSAttributedStringKey.paragraphStyle: paragraphStyle])
            button.alignment = .center
            closeControlsButtonItem.view =  button
            return closeControlsButtonItem

        default :
            return nil
        }
    }
    
    //MARK: - Actions
    
    @objc func sendStartGameNotification() {
        NotificationCenter.default.post(name: .startGame, object: nil)
    }
    
    @objc func sendShowControlsNotification() {
        NotificationCenter.default.post(name: .showControls, object: nil)
    }
    
    @objc func sendCloseControlsNotification() {
        NotificationCenter.default.post(name: .closeControls, object: nil)
    }

}

@available(OSX 10.12.2, *)
fileprivate extension NSTouchBar.CustomizationIdentifier {
    static let menu = NSTouchBar.CustomizationIdentifier("com.CollinDeWaters.bitHockey.menu")
}

@available(OSX 10.12.2, *)
fileprivate extension NSTouchBarItem.Identifier {
    static let homeTitleLabel = NSTouchBarItem.Identifier("com.CollinDeWaters.bitHockey.homeTitleLabel")
    static let startGame = NSTouchBarItem.Identifier("com.CollinDeWaters.bitHockey.startGame")
    static let showControls = NSTouchBarItem.Identifier("com.CollinDeWaters.bitHockey.showControls")
    static let closeControls = NSTouchBarItem.Identifier("com.CollinDeWaters.bitHockey.closeControls")
}

extension Notification.Name {
    static let startGame = Notification.Name("com.CollinDeWaters.bitHockey.startGame")
    static let showControls = Notification.Name("com.CollinDeWaters.bitHockey.showControls")
    static let closeControls = Notification.Name("com.CollinDeWaters.bitHockey.closeControls")
}
