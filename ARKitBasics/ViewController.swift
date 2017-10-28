/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Main view controller for the AR experience.
*/

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate {
    
    // MARK: - Debug Purposes
    private var scale: CGFloat = 1.0
    private var objectToBeAdded: SCNNode?
    
	// MARK: - IBOutlets
    @IBAction func userTap(_ sender: UITapGestureRecognizer) {
        let objects = VirtualObjects()
        var objectNodes = objects.virtualObjectNodes
        
        switch buttonTapped {
        case "C":
            objectToBeAdded = objectNodes[0]
        case "S":
            objectToBeAdded = objectNodes[1]
        default:
            return
        }
        
        let touchLocation = sender.location(in: view)
        let hits = sceneView.hitTest(touchLocation, options: nil)
        if let tappedNode = hits.first?.node {
            if objectToBeAdded != nil {
                objectToBeAdded!.position.z = tappedNode.position.z + 0.05
                tappedNode.parent?.addChildNode(objectToBeAdded!)
            }
        }
    }
    
    @IBOutlet weak var sessionInfoView: UIView!
	@IBOutlet weak var sessionInfoLabel: UILabel!
    @IBOutlet weak var sceneView: ARSCNView! {
        didSet {
            let swipeDownGesture = UISwipeGestureRecognizer(target: self, action: #selector(highlightObject(_:)))
            swipeDownGesture.direction = .down
            sceneView.addGestureRecognizer(swipeDownGesture)
            
            let swipeUpGesture = UISwipeGestureRecognizer(target: self, action: #selector(rotateObjectUp(_:)))
            swipeUpGesture.direction = .up
            sceneView.addGestureRecognizer(swipeUpGesture)
            
            let swipeLeftGesture = UISwipeGestureRecognizer(target: self, action: #selector(rotateObjectToLeft(_:)))
            swipeLeftGesture.direction = .left
            sceneView.addGestureRecognizer(swipeLeftGesture)
            
            let swipeRightGesture = UISwipeGestureRecognizer(target: self, action: #selector(rotateObjectToRight(_:)))
            swipeRightGesture.direction = .right
            sceneView.addGestureRecognizer(swipeRightGesture)
            
            let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(changeScale(_:)))
            sceneView.addGestureRecognizer(pinchGesture)
        }
    }
    
    @IBOutlet weak var cube: UIButton!
    @IBOutlet weak var sphere: UIButton!
    
    // CollectorView variable 
    @IBOutlet weak var collector: CollectorView!
    
    private var buttonTapped: String = ""
    
    @IBAction func addCube(_ sender: UIButton) {
        sphere.backgroundColor = UIColor.clear
        cube.backgroundColor = UIColor.white
        if sender.currentTitle != nil {
            buttonTapped = sender.currentTitle!
        }
    }
    
    @IBAction func addSphere(_ sender: UIButton) {
        cube.backgroundColor = UIColor.clear
        sphere.backgroundColor = UIColor.white
        if sender.currentTitle != nil {
            buttonTapped = sender.currentTitle!
        }
    }
    
    // MARK: - View Life Cycle
	
    /// - Tag: StartARSession
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        guard ARWorldTrackingConfiguration.isSupported else {
            fatalError("""
                ARKit is not available on this device. For apps that require ARKit
                for core functionality, use the `arkit` key in the key in the
                `UIRequiredDeviceCapabilities` section of the Info.plist to prevent
                the app from installing. (If the app can't be installed, this error
                can't be triggered in a production scenario.)
                In apps where AR is an additive feature, use `isSupported` to
                determine whether to show UI for launching AR experiences.
            """) // For details, see https://developer.apple.com/documentation/arkit
        }

        /*
         Start the view's AR session with a configuration that uses the rear camera,
         device position and orientation tracking, and plane detection.
        */
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        sceneView.session.run(configuration)

        // Set a delegate to track the number of plane anchors for providing UI feedback.
        sceneView.session.delegate = self
        
        /*
         Prevent the screen from being dimmed after a while as users will likely
         have long periods of interaction without touching the screen or buttons.
        */
        UIApplication.shared.isIdleTimerDisabled = true
        
        // Show debug UI to view performance metrics (e.g. frames per second).
        sceneView.showsStatistics = true
        
//        sceneView.automaticallyUpdatesLighting = false
    }
    
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		
		// Pause the view's AR session.
		sceneView.session.pause()
	}
	
	// MARK: - ARSCNViewDelegate
    
    /// - Tag: PlaceARContent
	func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        // Place content only for anchors found by plane detection.
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        
        // Create a SceneKit plane to visualize the plane anchor using its position and extent.
//        let plane = SCNPlane(width: CGFloat(planeAnchor.extent.x), height: CGFloat(planeAnchor.extent.z))
//        let planeNode = SCNNode(geometry: plane)
//        planeNode.simdPosition = float3(planeAnchor.center.x, 0, planeAnchor.center.z)
        
        guard let virtualObject = SCNScene(named: "Floor.scn", inDirectory: "Assets.scnassets") else { return }
        let wrapperNode = SCNNode()
        for child in virtualObject.rootNode.childNodes {
            wrapperNode.addChildNode(child)
        }
        wrapperNode.simdPosition = float3(planeAnchor.center.x, 0, planeAnchor.center.z)
        wrapperNode.eulerAngles.x = -.pi / 2
        /*
         `SCNPlane` is vertically oriented in its local coordinate space, so
         rotate the plane to match the horizontal orientation of `ARPlaneAnchor`.
        */
//        planeNode.eulerAngles.x = -.pi / 2
        
        // Make the plane visualization semitransparent to clearly show real-world placement.
//        planeNode.opacity = 0.25
        
        /*
         Add the plane visualization to the ARKit-managed node so that it tracks
         changes in the plane anchor as plane estimation continues.
        */
        
        // MARK: @TODO: Streamline FocusSquare and remove floorNode
//        let focusSquare = FocusSquare()
//        let focusSquareObject = focusSquare.createFocusSquare()
//        focusSquareObject.simdPosition = float3(planeAnchor.center.x, 0, planeAnchor.center.z)
//        focusSquareObject.eulerAngles.x = -.pi / 2
//        node.addChildNode(focusSquareObject)
        
        node.addChildNode(wrapperNode)
	}
    

    /// - Tag: UpdateARContent
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        // Update content only for plane anchors and nodes matching the setup created in `renderer(_:didAdd:for:)`.
        guard let planeAnchor = anchor as?  ARPlaneAnchor,
            let planeNode = node.childNodes.first,
            let plane = planeNode.geometry as? SCNPlane
            else { return }
        
        // Plane estimation may shift the center of a plane relative to its anchor's transform.
        planeNode.simdPosition = float3(planeAnchor.center.x, 0, planeAnchor.center.z)
        
        /*
         Plane estimation may extend the size of the plane, or combine previously detected
         planes into a larger one. In the latter case, `ARSCNView` automatically deletes the
         corresponding node for one plane, then calls this method to update the size of
         the remaining plane.
        */
        plane.width = CGFloat(planeAnchor.extent.x)
        plane.height = CGFloat(planeAnchor.extent.z)
    }

    // MARK: - ARSessionDelegate

    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        guard let frame = session.currentFrame else { return }
        updateSessionInfoLabel(for: frame, trackingState: frame.camera.trackingState)
    }

    func session(_ session: ARSession, didRemove anchors: [ARAnchor]) {
        guard let frame = session.currentFrame else { return }
        updateSessionInfoLabel(for: frame, trackingState: frame.camera.trackingState)
    }

    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        updateSessionInfoLabel(for: session.currentFrame!, trackingState: camera.trackingState)
    }

    // MARK: - ARSessionObserver
	
	func sessionWasInterrupted(_ session: ARSession) {
		// Inform the user that the session has been interrupted, for example, by presenting an overlay.
		sessionInfoLabel.text = "Session was interrupted"
	}
	
	func sessionInterruptionEnded(_ session: ARSession) {
		// Reset tracking and/or remove existing anchors if consistent tracking is required.
		sessionInfoLabel.text = "Session interruption ended"
		resetTracking()
	}
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user.
        sessionInfoLabel.text = "Session failed: \(error.localizedDescription)"
        resetTracking()
    }

    // MARK: - Private methods

    private func updateSessionInfoLabel(for frame: ARFrame, trackingState: ARCamera.TrackingState) {
        // Update the UI to provide feedback on the state of the AR experience.
        let message: String

        switch trackingState {
        case .normal where frame.anchors.isEmpty:
            // No planes detected; provide instructions for this app's AR interactions.
            message = "Move the device around to detect horizontal surfaces."
            
        case .normal:
            // No feedback needed when tracking is normal and planes are visible.
            message = ""
            
        case .notAvailable:
            message = "Tracking unavailable."
            
        case .limited(.excessiveMotion):
            message = "Tracking limited - Move the device more slowly."
            
        case .limited(.insufficientFeatures):
            message = "Tracking limited - Point the device at an area with visible surface detail, or improve lighting conditions."
            
        case .limited(.initializing):
            message = "Initializing AR session."
            
        }

        sessionInfoLabel.text = message
        sessionInfoView.isHidden = message.isEmpty
    }

    private func resetTracking() {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
    
    // MARK: - Gesture Methods
    
    // Rotate an object clockwise on Swiping Left in Z plane
    @objc
    func rotateObjectToLeft(_ gestureRecognize: UIGestureRecognizer) {
        let p = gestureRecognize.location(in: sceneView)
        let hitResults = sceneView.hitTest(p, options: [:])
        if hitResults.count > 0 {
            let result = hitResults[0]
            result.node.runAction(SCNAction.rotateBy(x: 0, y: 0, z: -1, duration: 0.25))
        }
    }
    // Rotate an object anticlockwise on Swiping Left in Z plane
    @objc
    func rotateObjectToRight(_ gestureRecognize: UIGestureRecognizer) {
        let p = gestureRecognize.location(in: sceneView)
        let hitResults = sceneView.hitTest(p, options: [:])
        if hitResults.count > 0 {
            let result = hitResults[0]
            result.node.runAction(SCNAction.rotateBy(x: 0, y: 0, z: 1, duration: 0.25))
        }
    }
    // Rotate an object upwards on Swiping Left in Y plane
    @objc
    func rotateObjectUp(_ gestureRecognize: UIGestureRecognizer) {
        let p = gestureRecognize.location(in: sceneView)
        let hitResults = sceneView.hitTest(p, options: [:])
        if hitResults.count > 0 {
            let result = hitResults[0]
            result.node.runAction(SCNAction.rotateBy(x: 0, y: 1, z: 0, duration: 0.25))
        }
    }
    
    // Change the size of object on pinch
    @objc
    func changeScale(_ gestureRecognize: UIPinchGestureRecognizer) {
        let p = gestureRecognize.location(in: sceneView)
        let hitResults = sceneView.hitTest(p, options: [:])
        if hitResults.count > 0 {
            let result = hitResults[0]
            switch gestureRecognize.state {
            case .changed, .ended:
                result.node.scale = SCNVector3(gestureRecognize.scale, gestureRecognize.scale, gestureRecognize.scale)
            default:
                break
            }
        }
    }
    
    @objc
    func highlightObject(_ gestureRecognize: UIGestureRecognizer) {
        let p = gestureRecognize.location(in: sceneView)
        let hitResults = sceneView.hitTest(p, options: [:])
        if hitResults.count > 0 {
            let result = hitResults[0]
            let material = result.node.geometry!.firstMaterial!
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.5
            SCNTransaction.completionBlock = {
                SCNTransaction.begin()
                SCNTransaction.animationDuration = 0.5
                material.emission.contents = UIColor.black
                SCNTransaction.commit()
            }
            material.emission.contents = UIColor.red
            SCNTransaction.commit()
            
            // create a new scene
            let scene = SCNScene()
            
            // create and add a camera to the scene
            let cameraNode = SCNNode(); cameraNode.camera = SCNCamera(); scene.rootNode.addChildNode(cameraNode)

            // place the camera
            cameraNode.position = SCNVector3(x: 0, y: 0, z: 15)

            // create and add a light to the scene
            let lightNode = SCNNode(); lightNode.light = SCNLight(); lightNode.light!.type = .omni
            lightNode.position = SCNVector3(x: 0, y: 10, z: 10)
            scene.rootNode.addChildNode(lightNode)

            // create and add an ambient light to the scene
            let ambientLightNode = SCNNode(); ambientLightNode.light = SCNLight(); ambientLightNode.light!.type = .ambient
            ambientLightNode.light!.color = UIColor.darkGray
            scene.rootNode.addChildNode(ambientLightNode)

            // Add the result of hitTest, i.e., swiped-down node to collector view
            scene.rootNode.addChildNode(result.node)
            result.node.scale = SCNVector3(x: 70, y: 70, z: 70)
            result.node.eulerAngles.y = -.pi/4
            result.node.eulerAngles.z = -.pi/4
            
            // set the scene to the view
            collector.scene = scene
        }
    }
}
