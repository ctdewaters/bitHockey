//
//  GoalViewController.swift
//  Bit Hockey (iOS)
//
//  Created by Collin DeWaters on 9/20/17.
//  Copyright © 2017 Collin DeWaters. All rights reserved.
//

import UIKit

class GoalViewController: UIViewController {
    @IBOutlet weak var blur: UIVisualEffectView!
    @IBOutlet weak var scoreboardView: UIView!
    @IBOutlet weak var awayScoreLabel: UILabel!
    @IBOutlet weak var homeScoreLabel: UILabel!
    @IBOutlet weak var goalLabel: UILabel!
    @IBOutlet weak var timeScoreLabel: UILabel!
    @IBOutlet weak var goalLabelTopConstraint: NSLayoutConstraint!
    
    var tapCompletion: (() -> Void)!
    
    var dismissing = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.scoreboardView.setCornerRadius(toValue: 25)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        
        self.dismiss {
            self.tapCompletion()
        }
    }
    
    func prepareForEntry() {
        //Goal label setup.
        self.goalLabelTopConstraint.constant = 175
        self.view.layoutIfNeeded()
        self.goalLabel.alpha = 0
        
        //Scoreboard setup.
        self.awayScoreLabel.text = "\(Score.shared.cpuScore)"
        self.homeScoreLabel.text = "\(Score.shared.userScore)"
        self.timeScoreLabel.text = Scoreboard.shared.clockView.timeLabel.text!
        
        self.blur.effect = nil
        self.blur.contentView.transform = CGAffineTransform(scaleX: 0.75, y: 0.75)
        self.blur.contentView.alpha = 0
    }
    
    func add(toView view: UIView, withCompletion completion: @escaping ()->Void) {
        self.dismissing = false
        self.view.frame = view.frame
        view.addSubview(self.view)
        self.prepareForEntry()
        UIView.animate(withDuration: 0.3, animations: {
            self.goalLabelTopConstraint.constant = 75
            self.view.layoutIfNeeded()
            self.goalLabel.alpha = 1
            self.blur.contentView.transform = .identity
            self.blur.contentView.alpha = 1
            self.blur.effect = UIBlurEffect(style: .light)
            
        }) { (complete) in
            if complete {
                //Add blinking to goal label.
                let animation = CABasicAnimation(keyPath: "opacity")
                animation.fromValue = 1
                animation.toValue = 0.1
                animation.duration = 0.35
                animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
                animation.autoreverses = true
                animation.repeatCount = 500
                self.goalLabel.layer.add(animation, forKey: "blinking")
                
                let transform = CABasicAnimation(keyPath: "transform.scale")
                transform.fromValue = self.goalLabel.layer.value(forKeyPath: "transform.scale")
                transform.toValue = 2.5
                transform.duration = 0.35
                transform.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
                transform.autoreverses = true
                transform.repeatCount = 500
                self.goalLabel.layer.add(transform, forKey: "transform")

                completion()
            }
        }
    }
    
    func dismiss(withCompletion completion: @escaping ()->Void) {
        self.dismissing = true
        UIView.animate(withDuration: 0.3, animations: {
            self.blur.effect = nil
            self.blur.contentView.transform = CGAffineTransform(scaleX: 0.75, y: 0.75)
            self.blur.contentView.alpha = 0
        }) { (complete) in
            if complete {
                self.goalLabel.layer.removeAllAnimations()
                self.view.removeFromSuperview()
                completion()
            }
        }
    }
    
    func updateScore(forUserTeam userTeam: Bool) {
        if userTeam {
            UIView.animate(withDuration: 0.1, animations: {
                self.homeScoreLabel.alpha = 0
            }) { (complete) in
                if complete {
                    self.homeScoreLabel.text = "\(Score.shared.userScore)"
                    UIView.animate(withDuration: 0.1, animations: {
                        self.homeScoreLabel.alpha = 1
                    })
                }
            }
            return
        }
        //CPU Team
        UIView.animate(withDuration: 0.1, animations: {
            self.awayScoreLabel.alpha = 0
        }) { (complete) in
            if complete {
                self.awayScoreLabel.text = "\(Score.shared.cpuScore)"
                UIView.animate(withDuration: 0.1, animations: {
                    self.awayScoreLabel.alpha = 1
                })
            }
        }
    }
    
}
