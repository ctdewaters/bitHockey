//
//  GoalView.swift
//  Hockey Game
//
//  Created by Collin DeWaters on 3/19/17.
//  Copyright © 2017 Collin DeWaters. All rights reserved.
//

#if os(OSX)
import Cocoa
#elseif os(iOS)
import UIKit
#endif

class GoalPresentation: NSObject {
    
    static let shared = GoalPresentation()
    
    #if os(OSX)
    fileprivate var presentationView: NSView!
    fileprivate var goalLabel: NSTextField!
    fileprivate var scoreLabel: NSTextField!
    fileprivate var promptLabel: NSTextField!
    #elseif os(iOS)
    fileprivate var presentationView: UIView!
    fileprivate var goalLabel: UILabel!
    fileprivate var scoreLabel: UILabel!
    fileprivate var promptLabel: UILabel!
    #endif
    
    fileprivate var dismissTimer: Timer!
    
    public var isPresented = false
    
    override init() {
        super.init()
    }
    
    open func present(toView view: Any, withCompletion completion: (()->Void)? = nil) {
        if self.presentationView == nil {
            #if os(OSX)
                let view = view as! NSView
                
                self.presentationView = NSView(frame: NSRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height))
                self.presentationView.wantsLayer = true
                self.presentationView.layer?.backgroundColor = NSColor.black.withAlphaComponent(0.4).cgColor
                self.presentationView.alphaValue = 0
                
                goalLabel = NSTextField(labelWithString: "GOAL!!!")
                goalLabel.frame = NSRect(x: 0, y: (view.frame.height / 2) + 50, width: presentationView.frame.width, height: 100)
                goalLabel.font = NSFont.systemFont(ofSize: 90, weight: NSFontWeightBlack)
                goalLabel.alignment = .center
                self.presentationView.addSubview(goalLabel)
                
                promptLabel = NSTextField(labelWithString: "Press space to skip.")
                promptLabel.frame = NSRect(x: 0, y: presentationView.frame.minY + 30, width: presentationView.frame.width, height: 30)
                promptLabel.font = NSFont.systemFont(ofSize: 15, weight: NSFontWeightBold)
                promptLabel.alignment = .center
                promptLabel.textColor = NSColor.black.withAlphaComponent(0.7)
                self.presentationView.addSubview(promptLabel)
                
                view.addSubview(self.presentationView, positioned: .below, relativeTo: Scoreboard.shared)
                
                self.animateScoreboard(toPoint: CGPoint(x: (view.frame.width / 2) - (Scoreboard.shared.frame.width * 0.75), y: view.frame.maxY - 80))
                
            #elseif os(iOS)
                let view = view as! UIView
                
                self.presentationView = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height))
                self.presentationView.backgroundColor = UIColor.black.withAlphaComponent(0.4)
                self.presentationView.alpha = 0
                
                goalLabel = UILabel(frame: CGRect(x: 0, y: (view.frame.height / 2) + 50, width: presentationView.frame.width, height: 100))
                goalLabel.text = "GOAL!!!"
                goalLabel.textAlignment = .center
                goalLabel.font = UIFont.systemFont(ofSize: 90, weight: UIFont.Weight.black)
                self.presentationView.addSubview(goalLabel)
                
                promptLabel = UILabel(frame: CGRect(x: 0, y: presentationView.frame.minY + 30, width: presentationView.frame.width, height: 30))
                promptLabel.text = "Tap the screen to skip."
                promptLabel.font = UIFont.systemFont(ofSize: 15, weight: UIFont.Weight.bold)
                promptLabel.textColor = UIColor.blue.withAlphaComponent(0.7)
                promptLabel.textAlignment = .center
                self.presentationView.addSubview(promptLabel)
                
                view.addSubview(self.presentationView)
                view.bringSubview(toFront: Scoreboard.shared)
            #endif
            
            self.presentationView.fadeIn(withDuration: 0.5, andCompletionBlock: completion)
            
            goalLabel.textColor = .red
            self.isPresented = true
            self.dismissTimer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(dismissPresentationView), userInfo: nil, repeats: false)
        }
    }
    
    fileprivate func animateScoreboard(toPoint point: CGPoint) {
        #if os(OSX)
            NSAnimationContext.runAnimationGroup({
                context in
                context.duration = 0.3
                Scoreboard.shared.animator().frame.origin = point
                Scoreboard.shared.animator().layer?.setAffineTransform(CGAffineTransform(scaleX: 1.5, y: 1.5))
            }, completionHandler: nil)
        #elseif os(iOS)
            UIView.animate(withDuration: 0.3, animations: {
                Scoreboard.shared.frame.origin = point
                Scoreboard.shared.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
            })
        #endif
    }
        
    fileprivate func returnScoreboard() {
        #if os(OSX)
            NSAnimationContext.runAnimationGroup({
                context in
                context.duration = 0.3
                let superview = Scoreboard.shared.superview!
                Scoreboard.shared.animator().frame.origin = CGPoint(x: 20, y: superview.frame.maxY - 50)
                Scoreboard.shared.animator().layer?.setAffineTransform(CGAffineTransform(scaleX: 1, y: 1))
            }, completionHandler: nil)
        #elseif os(iOS)
            UIView.animate(withDuration: 0.3, animations: {
                let superview = Scoreboard.shared.superview!
                Scoreboard.shared.frame.origin = CGPoint(x: 20, y: superview.frame.maxY - 50)
                Scoreboard.shared.transform = CGAffineTransform(scaleX: 1, y: 1)
            })
        #endif
    }
    
    @objc public func dismissPresentationView() {
        if dismissTimer != nil {
           self.dismissTimer.invalidate()
        }
        
        self.returnScoreboard()
        self.isPresented = false
        
        self.presentationView.fadeOut(withDuration: 0.3, andCompletionBlock: {            
            NotificationCenter.default.post(name: .didReturnToPlay, object: nil)
            self.dismissTimer = nil
            self.presentationView.removeFromSuperview()
            for view in self.presentationView.subviews {
                view.removeFromSuperview()
            }
            self.presentationView = nil
        })
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

#if os(OSX)
    public extension NSView {
        var center: CGPoint {
            set {
                self.frame.origin = CGPoint(x: newValue.x - (self.bounds.width / 2), y: newValue.y - (self.bounds.height / 2))
            }
            get {
                return CGPoint(x: self.frame.origin.x + (self.bounds.width / 2), y: self.frame.origin.y + (self.bounds.height / 2))
            }
        }
        
        func fadeIn(withDuration duration: TimeInterval, andCompletionBlock completion: (()->Void)? = nil) {
            self.wantsLayer = true
            NSAnimationContext.runAnimationGroup({
                context in
                self.isHidden = false
                context.duration = duration
                self.animator().alphaValue = 1
            }, completionHandler: completion)
        }
    
        func fadeOut(withDuration duration: TimeInterval, andCompletionBlock completion: (()->Void)? = nil) {
            self.wantsLayer = true
            NSAnimationContext.runAnimationGroup({
                context in
                self.isHidden = false
                context.duration = duration
                self.animator().alphaValue = 0
            }, completionHandler: completion)
        }
    }
    
#elseif os(iOS)
    public extension UIView {
        func fadeIn(withDuration duration: TimeInterval, andCompletionBlock completion: (()->Void)? = nil) {
            UIView.animate(withDuration: duration, animations: {
                self.isHidden = false
                self.alpha = 1
            })
        }
        
        func fadeOut(withDuration duration: TimeInterval, andCompletionBlock completion: (()->Void)? = nil) {
            UIView.animate(withDuration: duration, animations: {
                self.isHidden = false
                self.alpha = 0
            })
        }
    }
    
#endif
