//
//  AppDelegate.swift
//  HockeyGame
//
//  Created by Collin DeWaters on 4/3/17.
//  Copyright © 2017 Collin DeWaters. All rights reserved.
//


import Cocoa

let storyboard = NSStoryboard(name: NSStoryboard.Name(rawValue: "Main"), bundle: nil)
let gameVC = storyboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier(rawValue: "gameVC")) as! ViewController
let menuVC = storyboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier(rawValue: "menuVC")) as! MenuViewController

var windowController: WindowController!

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        
        windowController = storyboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier(rawValue: "WC")) as! WindowController
        windowController.showWindow(self)
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
    
}
