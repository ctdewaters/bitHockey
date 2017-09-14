//
//  MenuViewController.swift
//  Hockey Game
//
//  Created by Collin DeWaters on 5/8/17.
//  Copyright © 2017 Collin DeWaters. All rights reserved.
//

import Cocoa
import SpriteKit

class MenuViewController: NSViewController, GameViewControllerDelegate {
    
    @IBOutlet weak var titleLabel: NSTextField!
    @IBOutlet weak var controlsButton: NSButton!
    @IBOutlet weak var controlsView: ControlsView!
    @IBOutlet weak var closeControlsButton: NSButton!
    @IBOutlet weak var backgroundView: BackgroundView!
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        self.backgroundView.wantsLayer = true
        self.backgroundView.setup()
        
        self.controlsView.set()
        self.controlsView.removeFromSuperview()
        self.backgroundView.addSubview(controlsView)
        
        if #available(OSX 10.12.2, *) {
            //Add NotificationCenter observers
            NotificationCenter.default.addObserver(self, selector: #selector(showControls(_:)), name: .showControls, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(closeControls(_:)), name: .closeControls, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(next(_:)), name: .startGame, object: nil)
            
            let touchBar = MenuTouchBar(withState: .controlsClosed) 
            windowController.update(withTouchBar: touchBar)

        } else {
            // Fallback on earlier versions
        }
    }
    
    @IBAction func next(_ sender: Any) {
        if #available(OSX 10.12.2, *) {
            windowController.update(withTouchBar: LoadingTouchBar())
        }
        gameVC.delegate = self
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
            gameVC.setUp()
        })
    }
    
    @IBAction func showControls(_ sender: Any) {
        NSAnimationContext.runAnimationGroup({
            context in
            context.duration = 0.35
            context.allowsImplicitAnimation = true
            self.controlsView.animator().frame.origin.y = 0
        }, completionHandler: {
            if #available(OSX 10.12.2, *) {
                let touchBar = MenuTouchBar(withState: .controlsOpen)
                windowController.update(withTouchBar: touchBar)
            }
        })
    }
    
    @IBAction func closeControls(_ sender: Any) {
        NSAnimationContext.runAnimationGroup({
            context in
            context.duration = 0.35
            context.allowsImplicitAnimation = true
            self.controlsView.animator().frame.origin.y = self.view.frame.height
        }, completionHandler: {
            if #available(OSX 10.12.2, *) {
                let touchBar = MenuTouchBar(withState: .controlsClosed)
                windowController.update(withTouchBar: touchBar)
            }
        })
    }
    
    //MARK: - GameViewControllerDelegate
    func gameDidFinishLoading() {
        print("\n\n\n\nGAME LOADED, PRESENTING NOW.\n\n\n\n\n")
        self.view.window?.contentViewController = gameVC
    }
}
