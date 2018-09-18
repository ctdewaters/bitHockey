//
//  ARHomeViewController.swift
//  Bit Hockey (iOS)
//
//  Created by Collin DeWaters on 9/18/18.
//  Copyright © 2018 Collin DeWaters. All rights reserved.
//

import UIKit
import ARKit

///`ARHomeViewController`: a `HomeViewController` subclass which will display the AR mode of the game.
class ARHomeViewController: HomeViewController, ARSCNViewDelegate {
    //MARK: - IBOutlets.
    @IBOutlet weak var arSCNView: ARSCNView!
    
    //MARK: - Properties.
    ///The validated ARPlaneAnchor, which will be used to place experience on.
    var planeAnchor: ARPlaneAnchor?
    
    ///The root SCNNode, which all other nodes will be added to as children.
    var rootNode: SCNNode?
    
    //MARK: - `HomeViewController` Overrides.
    override var isInRetroMode: Bool {
        return false
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        //Setup the `ARSCNView`.
        self.arSCNView.delegate = self
        self.arSCNView.showsStatistics = false
        
        //Start world tracking.
        let config = ARWorldTrackingConfiguration()
        self.arSCNView.session.run(config)
    }
    
    //MARK: - ARSession functions.
    ///Runs a world tracking configuration with plane detection enabled.
    func activatePlaneDetection() {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        self.arSCNView.session.run(configuration)
    }
    
    ///Runs a world tracking configuration with no plane detection options, disabling plane detection.
    func disablePlaneDetection() {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = []
        self.arSCNView.session.run(configuration)
    }
    
    // MARK: - ARSCNViewDelegate
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        //Return if we have already found a suitable plane anchor.
        if self.planeAnchor != nil {
            return
        }
        
        // Place content only for anchors found by plane detection.
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        
        //Validate the plane anchor.
        
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        //Return if we have already found a suitable plane anchor.
        if self.planeAnchor != nil {
            return
        }
        // Update only anchors and nodes set up by `renderer(_:didAdd:for:)`.
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        
        //Validate the plane anchor.
    }
}
