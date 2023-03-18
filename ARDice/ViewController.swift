//
//  ViewController.swift
//  ARDice
//
//  Created by ivan cardenas on 14/03/2023.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController {

    @IBOutlet var sceneView: ARSCNView!

    var diceArray = [SCNNode]()

    override func viewDidLoad() {
        super.viewDidLoad()
//        self.sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
        
        // Set the view's delegate
        sceneView.delegate = self
        sceneView.autoenablesDefaultLighting = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()

        configuration.planeDetection = .horizontal
        // Run the view's session
        sceneView.session.run(configuration)
    }

    func roll(dice: SCNNode) {
        let randomX = Float(arc4random_uniform(4) + 1) * (Float.pi/2)
        let randomZ = Float(arc4random_uniform(4) + 1) * (Float.pi/2)

        dice.runAction(
            SCNAction.rotateBy(x: CGFloat(randomX*5), y: 0, z: CGFloat(randomZ*5), duration: 1)
        )
    }

    func rollAll() {
        if !diceArray.isEmpty {
            for dice in diceArray {
                roll(dice: dice)
            }
        }
    }

    @IBAction func rollButtonAction(_ sender: UIButton) {
        rollAll()
    }

    @IBAction func removeAllDices(_ sender: UIButton) {
        for dice in diceArray {
            dice.removeFromParentNode()
        }
    }
    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        rollAll()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let touchLocations = touch.location(in: sceneView)

            let results = sceneView.hitTest(touchLocations, types: .existingPlaneUsingExtent)

            if let hitResult = results.first {
                addDice(atLocation: hitResult)
            }
        }
    }

    func addDice(atLocation location: ARHitTestResult) {
        if let diceScene = SCNScene(named: "art.scnassets/diceCollada.scn") {

            let diceNode = diceScene.rootNode.childNode(withName: "Dice", recursively: true)!
            diceNode.position = SCNVector3(
                location.worldTransform.columns.3.x,
                location.worldTransform.columns.3.y + diceNode.boundingSphere.radius,
                location.worldTransform.columns.3.z)

            diceArray.append(diceNode)

            sceneView.scene.rootNode.addChildNode(diceNode)

            roll(dice: diceNode)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
}

//MARK: - ARSCNViewDelegate

extension ViewController: ARSCNViewDelegate {
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {

        guard let planeAnchor = anchor as? ARPlaneAnchor else {return}
        node.addChildNode(createPlane(withPlaneAnchor: planeAnchor))
    }

    func createPlane(withPlaneAnchor planeAnchor: ARPlaneAnchor) -> SCNNode {
        let plane = SCNPlane(width: CGFloat(planeAnchor.extent.x), height: CGFloat(planeAnchor.extent.z))
        let planeNode = SCNNode()
        planeNode.position = SCNVector3(planeAnchor.center.x , 0, planeAnchor.center.z)

        planeNode.transform = SCNMatrix4MakeRotation(-Float.pi/2, 1, 0, 0)

        let gridMaterial = SCNMaterial()
        gridMaterial.diffuse.contents = UIColor.clear

        plane.materials = [gridMaterial]

        planeNode.geometry = plane

        return planeNode
    }
}
