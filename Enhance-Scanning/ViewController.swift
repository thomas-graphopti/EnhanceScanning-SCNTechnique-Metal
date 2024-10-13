//
//  ViewController.swift
//  Enhance-Scanning
//
//  Created by thomas(thomas@graphopti.com) on 30/09/2024.
//

import UIKit
import SceneKit
import ARKit


class ViewController: UIViewController, ARSCNViewDelegate {
    
    @IBOutlet var sceneView: ARSCNView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        setupDepthTechnique()
    }

    
    func setupDepthTechnique() {
        guard let path = Bundle.main.path(forResource: "DepthFilteringTechnique", ofType: "plist") else {
            print("Error: NodeTechnique.plist not found in bundle")
            return
        }
        guard let dict = NSDictionary(contentsOfFile: path) as? [String: AnyObject] else {
            print("Error: Failed to load NodeTechnique.plist as dictionary")
            return
        }
        guard let technique = SCNTechnique(dictionary: dict) else {
            print("Error: Failed to create SCNTechnique from dictionary")
            return
        }
        self.sceneView.technique = technique
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        configuration.frameSemantics.insert(.sceneDepth)
        //Before starting session, put this option in configuration
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            configuration.sceneReconstruction = .mesh
        } else {
            // Handle device that doesn't support scene reconstruction
        }
        // Run the view's session
        setupDepthTechnique()
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }
    
    // MARK: - ARSCNViewDelegate
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        guard let meshAnchor = anchor as? ARMeshAnchor else {
            return nil
        }
        let geometry = createGeometryFromAnchor(meshAnchor: meshAnchor)
        let node = SCNNode(geometry: geometry)
        node.geometry?.materials = [.solid]
        return node
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let meshAnchor = anchor as? ARMeshAnchor else {
            return
        }
        let geometry = createGeometryFromAnchor(meshAnchor: meshAnchor)
        geometry.materials = [.solid]
        node.geometry = geometry
    }
    
    // Taken from https://developer.apple.com/forums/thread/130599
    func createGeometryFromAnchor(meshAnchor: ARMeshAnchor) -> SCNGeometry {
        let meshGeometry = meshAnchor.geometry
        let vertices = meshGeometry.vertices
        let normals = meshGeometry.normals
        let faces = meshGeometry.faces
        let vertexSource = SCNGeometrySource(buffer: vertices.buffer, vertexFormat: vertices.format, semantic: .vertex, vertexCount: vertices.count, dataOffset: vertices.offset, dataStride: vertices.stride)
        let normalsSource = SCNGeometrySource(buffer: normals.buffer, vertexFormat: normals.format, semantic: .normal, vertexCount: normals.count, dataOffset: normals.offset, dataStride: normals.stride)
        let faceData = Data(bytes: faces.buffer.contents(), count: faces.buffer.length)
        let geometryElement = SCNGeometryElement(data: faceData, primitiveType: primitiveType(type: faces.primitiveType), primitiveCount: faces.count, bytesPerIndex: faces.bytesPerIndex)
        return SCNGeometry(sources: [vertexSource, normalsSource], elements: [geometryElement])
    }
    
    func primitiveType(type: ARGeometryPrimitiveType) -> SCNGeometryPrimitiveType {
        switch type {
        case .line: return .line
        case .triangle: return .triangles
        default : return .triangles
        }
    }
    
}



extension SCNMaterial {
    static var solid: SCNMaterial {
        let material = SCNMaterial()
        material.lightingModel = .constant
        material.diffuse.contents = UIColor.clear.withAlphaComponent(0.0001)
        material.isDoubleSided = true
        material.fillMode = .fill // Use lines for mesh lines
        material.transparency = 0.01 // Set some transparency to see the background
        return material
    }
}


