//
//  VirtualObjects.swift
//  ARKitBasics
//
//  Created by Abhinav Prakash on 25/10/17.
//  Copyright © 2017 Apple. All rights reserved.
//

import Foundation
import SceneKit

class VirtualObjects {
    
    private var virtualObjects = ["Cube.scn", "Sphere.scn"]
    
    var virtualObjectNodes: [SCNNode] {
        get {
            return createNodes(from: virtualObjects)
        }
    }
    
    private func createNodes(from objects: [String]) -> [SCNNode] {
        
        var objectNodes = [SCNNode]()
        
        for object in virtualObjects {
            let wrapperNode = SCNNode()
            if let virtualScene = SCNScene(named: object, inDirectory: "Assets.scnassets") {
                for child in virtualScene.rootNode.childNodes {
                    wrapperNode.addChildNode(child)
                }
            }
            
            objectNodes.append(wrapperNode)
        }
        
        return objectNodes
        
    }
    
}

