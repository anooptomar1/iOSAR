/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Main view controller for the AR experience.
*/

import UIKit
import SceneKit
import ARKit
import CoreData

/* Protocol added so that TableViewController can communicate when color of an object is chosen
 For implementation of protocol, check VirtualObjectTableViewController */
protocol ColorObjectToVCDelegate {
    func objectColor() -> UIColor
}

class ViewController: UIViewController, VCFinalDelegate, UIPopoverPresentationControllerDelegate {
    
    // MARK: - Instance Variables
    let colorOfObject = ColorOfObjects()
    
    var arrayFeaturePointDistance: [CGFloat] = []
    
    // Delegate variable used for Protocol
    var delegate: ColorObjectToVCDelegate?
    
    // Sound effect
    var sound = Sounds()
    
    // Non private to allow Extension to use
    var virtualObjectInstance = VirtualObjects()
    var tappedNode: SCNNode?
    var material: SCNMaterial?
    var screenCenter: CGPoint {
        return sceneView.center
    }
    
    private var objectOnPathToBeAdded: Int?
    private var virtualObjectColor: UIColor?
    private var pickedColor: UIColor?
    
    // Varibles for button image changes
    private var toggleState = 1
    private let imgPlay = UIImage(named: "playBtn")
    private let imgStop = UIImage(named: "stopBtn")
    
    private var colorOfObjects = ColorOfObjects()
    
    var randomCombination = (name: "", color: "")
    
    // Method to hide/ unhide set of buttons/ object depending on play mode or else
    private func inStateOfPlay(playing: Bool) {
        if playing {
            addObject.isHidden = true
            randomCombination = virtualObjectInstance.randomCombination
            startPlayGuideImage.image = UIImage(named: "\(randomCombination.name)-\(randomCombination.color)")
            startPlayGuideLabel.isHidden = false
            startPlayGuideImage.isHidden = false
            
            Timer.scheduledTimer(timeInterval: 3,
                                 target: self,
                                 selector: #selector(hideGuides),
                                 userInfo: nil,
                                 repeats: false)
            
        } else {
            startPlayGuideLabel.isHidden = true
            startPlayGuideImage.isHidden = true
            addObject.isHidden = false
        }
    }
    
    /* Implementation of ContainerTableView delegate function:
     Check ContainerTableViewController for protocol implementation */
    func passVirtualObject() -> [(name: String, scn: String, count: Int)] {
        return virtualObjectInstance.virtualObjectsNames
    }
    
    // MARK: - IBOutlets
    
    /* Segue Button at bottom right corner opens tableView (Container...) to keep score of
     swiped down objects from main view */
    // Outlet for changing background image of button depending on the object which is swiped down
    @IBOutlet weak var segueButton: UIButton!
    
    // View with Color picker buttons - hidden/ visible on selection of underlying buttons
    @IBOutlet weak var colorPicker: UIStackView!
    
    // Button for changing mode to Playing - toggling image underlying the button
    @IBOutlet weak var playButton: UIButton!
    
    // Button to add 3D objects - hidden/ visible dependent on play mode or else
    @IBOutlet weak var addObject: UIButton!
    
    // Info label and view
    // @TODO: Hide label when play mode is operational
    @IBOutlet weak var sessionInfoView: UIView!
    @IBOutlet weak var sessionInfoLabel: UILabel!
    
    
    @IBOutlet weak var startPlayGuideLabel: UILabel!
    
    @IBOutlet weak var startPlayGuideImage: UIImageView!
    
    // Main AR Scene View for rendering content
    @IBOutlet weak var sceneView: ARSCNView! {
        didSet {
            let swipeDownGesture =
                UISwipeGestureRecognizer(target: self, action: #selector(rotateObject(_:)))
            swipeDownGesture.direction = .down
            sceneView.addGestureRecognizer(swipeDownGesture)
            
            let rotationGesture = UIRotationGestureRecognizer(target: self, action: #selector(rotateObjects(_:)))
            sceneView.addGestureRecognizer(rotationGesture)
            
            let pinchGesture =
                UIPinchGestureRecognizer(target: self, action: #selector(changeScale(_:)))
            sceneView.addGestureRecognizer(pinchGesture)
            
            let longPressGesture =
                UILongPressGestureRecognizer(target: self, action: #selector(changeColorOfObject(_:)))
            sceneView.addGestureRecognizer(longPressGesture)
            
            let panGesture = UIPanGestureRecognizer(target: self, action: #selector(translateObject(_:)))
            panGesture.minimumNumberOfTouches = 2
            panGesture.maximumNumberOfTouches = 2
            sceneView.addGestureRecognizer(panGesture)
        
        }
    }
    
    // MARK: - IBActions
    
    // Reset button - top right corner resets AR rendering
    @IBAction func reset(_ sender: UIButton) {
        sender.showsTouchWhenHighlighted = true
        resetTracking()
    }
    
    /* Color picker buttons - present when object is long pressed */
    
    @IBAction func pickRedColor(_ sender: UIButton) {
        material?.diffuse.contents = virtualObjectInstance.virtualObjectsColors["red"]
//        material?.emission.contents = colorOfObjects.UIColorFromRGB(rgbValue: colorOfObjects.redColor)
        colorPicker.isHidden = true
    }
    
    @IBAction func pickGreenColor(_ sender: UIButton) {
        material?.diffuse.contents = virtualObjectInstance.virtualObjectsColors["green"]
//        material?.emission.contents = colorOfObjects.UIColorFromRGB(rgbValue: colorOfObjects.greenColor)
        colorPicker.isHidden = true
    }
    
    @IBAction func pickBlueColor(_ sender: UIButton) {
        material?.diffuse.contents = virtualObjectInstance.virtualObjectsColors["blue"]
        colorPicker.isHidden = true
    }
    
    var inStateOfPlayForGestureControl = false // Unsure whether this is the swifty way
    
    /* Button to select play mode. Under play mode:
     - Info and add buttons are hidden
     - Image underlying the button toggle play/ stop images (imgPlay and imgStop - declared in vars)*/
    @IBAction func play(_ sender: UIButton) {
        if toggleState == 1 {
            toggleState = 2
            playButton.setBackgroundImage(imgStop, for: .normal)
            inStateOfPlayForGestureControl = true // Unsure whether this is the swifty way
            inStateOfPlay(playing: true)
            
        } else {
            toggleState = 1
            playButton.setBackgroundImage(imgPlay, for: .normal)
            inStateOfPlayForGestureControl = false // Unsure whether this is the swifty way
            inStateOfPlay(playing: false)
        }
    }
    
    
    // User tap on floor node to add 3D object
    @IBAction func userTap(_ sender: UITapGestureRecognizer) {
        
        // Hide Color Picker buttons in case it is not hidden and user taps screen to remove it w/o changing color
        if !colorPicker.isHidden {
            colorPicker.isHidden = true
        }
        
        // Dipatching sounds to global queue (non-main) for no impact on UI
        DispatchQueue.global(qos: .userInteractive).async {
            self.sound.playSound(named: "thud")
        }
        
        
        let objectToBeAdded: SCNNode?
        if objectOnPathToBeAdded != nil {
            objectToBeAdded = virtualObjectInstance.createNodes(
                from: virtualObjectInstance.virtualObjectsNames[
                    objectOnPathToBeAdded!].name,
                with: delegate?.objectColor() ?? UIColor.yellow)
            } else {
            objectToBeAdded =
                virtualObjectInstance.createNodes(from: virtualObjectInstance.virtualObjectsNames[0].name,
                                                  with: virtualObjectInstance.virtualObjectsColors["blue"]!)
        }
        let touchLocation = sender.location(in: view)
        let hits = sceneView.hitTest(touchLocation, options: nil)
        
        if hits.first?.node != nil {
            if let parentNode = hits.first?.node.parent {
                if parentNode.name == "anchorNode" {
                    tappedNode = parentNode
                    objectToBeAdded?.position.z = (tappedNode?.position.z)! + 0.05
                    tappedNode?.parent?.addChildNode(objectToBeAdded!)
                    tappedNode?.isHidden = true
                }
            }
        }
    }
    
    // Segue button to segue to ContainerTableView
    @IBAction func btnPerformSeguePressed(_ sender: UIButton) {
        performSegue(withIdentifier: "ARSCNToTabView", sender: nil)
    }
    
    // Other Segue preparations
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        var destinationViewController = segue.destination
        if let navigationController = destinationViewController as? UINavigationController {
            destinationViewController = navigationController.visibleViewController
                ?? destinationViewController
        }
        
        if let TableViewController = destinationViewController as? ContainerTableViewController {
            TableViewController.delegate = self
            if let popoverPresentationController = segue.destination.popoverPresentationController {
                popoverPresentationController.delegate = self
            }
        } else if destinationViewController is VirtualObjectTableViewController {
            if let popoverPresentationController = segue.destination.popoverPresentationController {
                popoverPresentationController.sourceView = sender as! UIButton // For arrowhead in the middle
                popoverPresentationController.sourceRect = (sender as! UIButton).bounds // For arrowhead in the middle
                popoverPresentationController.delegate = self
            }
        }        
    }
    
    
    // Function so that popover doesn't adapt to cover full screen on iphones
    func adaptivePresentationStyle(for controller: UIPresentationController,
                                   traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        if traitCollection.verticalSizeClass == .compact {
            return .none
        } else {
            return .none
        }
    }
    
    /* Unwind Segue for "Done" bar button on Navigation Controller.
     Allows capture of index of Selected 3D object, which determines the object that
     will be added to the AR Scene */
    @IBAction func chooseVirtualObject(from segue: UIStoryboardSegue) {
        if let virtualObjectChosen = segue.source as? VirtualObjectTableViewController {
            if let path = virtualObjectChosen.virtualObjectSelectedIndexPath {
                objectOnPathToBeAdded = path
            }
        }
    }
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let crosshair = Crosshairs()
            
        crosshair.displayAsBillboard()
                
        // Light Node to illuminate crosshair node. @TODO: Implemented it in the class itself, if feasible
        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light?.type = .ambient
        ambientLightNode.light?.color = UIColor.white
        sceneView.pointOfView?.addChildNode(ambientLightNode)
        
        sceneView.pointOfView?.addChildNode(crosshair)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        segueButton.isHidden = true
        colorPicker.isHidden = true
        startPlayGuideImage.isHidden = true
        startPlayGuideLabel.isHidden = true
    }
    
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
            """)
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
        
        // Debug options - for showing feature points (yellow dots) and world origin axes
//        sceneView.debugOptions = [
//            ARSCNDebugOptions.showFeaturePoints,
//            ARSCNDebugOptions.showWorldOrigin
//        ]
        sceneView.autoenablesDefaultLighting = true
        
        sceneView.automaticallyUpdatesLighting = true
        
        // Taken from iOS codebase by Apple - significance?
//        if let environmentMap = UIImage(named: "Assets.scnassets/SharedImages/environment_blur.exr") {
//            print(environmentMap)
//            sceneView.scene.lightingEnvironment.contents = environmentMap
//        }
    }
    
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		
		// Pause the view's AR session. //
		sceneView.session.pause()
	}
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }
}


/// - Tag: Animation code - not useful, since object is removed before animation can take effect
// let material = result.node.geometry!.firstMaterial!
// SCNTransaction.begin()
// SCNTransaction.animationDuration = 0.5
// SCNTransaction.completionBlock = {
//    SCNTransaction.begin()
//    SCNTransaction.animationDuration = 0.5
//    material.emission.contents = UIColor.black
//    SCNTransaction.commit()
// }
// material.emission.contents = UIColor.red
// SCNTransaction.commit()


