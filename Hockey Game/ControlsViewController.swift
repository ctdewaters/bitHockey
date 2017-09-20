//
//  ControlsViewController.swift
//  Bit Hockey (iOS)
//
//  Created by Collin DeWaters on 9/19/17.
//  Copyright © 2017 Collin DeWaters. All rights reserved.
//

import UIKit

class ControlsViewController: UIViewController {
    @IBOutlet weak var blur: UIVisualEffectView!
    @IBOutlet weak var image: UIImageView!
    @IBOutlet weak var closeButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.closeButton.setCornerRadius(toValue: 15)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
