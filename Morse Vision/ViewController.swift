//
//  ViewController.swift
//  Morse Vision
//
//  Created by Alejandro Cotilla on 9/19/18.
//  Copyright © 2018 Alejandro Cotilla. All rights reserved.
//

import UIKit
import AVFoundation
import ARKit

class ViewController: UIViewController {
    
    enum EyeState {
        case closed
        case opened
    }
    
    enum InputMode {
        case touch
        case vision
    }
    
    // More about morse code timing and speeds:
    // https://en.wikipedia.org/wiki/Morse_code#Representation,_timing,_and_speeds
    struct Timing {
        static let dot = 0.3 // 0.3 is the average human blinking duration (https://en.wikipedia.org/wiki/Blinking)
        static let dash = dot * 3.0
        static let interElementGap = dot
        static let interLetterGap = dot * 3.0
        static let interWordGap = dot * 7.0
    }
    
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var timespanLabel: UILabel!
    @IBOutlet weak var transcriptionLabel: UILabel!
    @IBOutlet weak var treePositionLabel: UILabel!
    @IBOutlet weak var dashLabel: UILabel!
    @IBOutlet weak var dotLabel: UILabel!
    
    @IBOutlet weak var blinkSimulatorButton: UIButton! {
        didSet {
            if preferredInputMode == .vision && ARFaceTrackingConfiguration.isSupported {
                blinkSimulatorButton.isHidden = true
            }
        }
    }
    
    var treeNode = TreeNode.morseTree {
        didSet {
            treePositionLabel.text = treeNode.value
        }
    }
    
    var transcription = ""
    var eyeClosedInterval = DateInterval()
    var eyeOpenedInterval = DateInterval()

    var eyeState: EyeState = .opened {
        didSet {
            guard oldValue != eyeState else {
                return
            }
            
            switch eyeState {
            case .closed:
                eyeOpenedInterval.end = Date()
                eyeClosedInterval.start = Date()
                morseCodeEntryDidBegin()
            case .opened:
                eyeClosedInterval.end = Date()
                eyeOpenedInterval.start = Date()
                morseCodeEntryDidEnd()
            }
        }
    }
    
    var dotSoundID: SystemSoundID!
    var dashSoundID: SystemSoundID!
    
    var selectionTimer: Timer?
    
    let lightFeedbackGenerator = UIImpactFeedbackGenerator(style: .light)
    let mediumFeedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
    
    // InputMode.vision is only supported on devices with a TrueDepth camera.
    // If the device does not support InputMode.vision, it'll default to InputMode.touch.
    let preferredInputMode: InputMode = .vision
    
    // MARK: - View Lifecycle -
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setNeedsStatusBarAppearanceUpdate()
        
        dotSoundID = SystemSoundID.register(soundName: "dot_morse_code.caf")
        dashSoundID = SystemSoundID.register(soundName: "dash_morse_code.caf")
        
        sceneView.delegate = self

        // Use a display link instance to update label values
        let displaylink = CADisplayLink(target: self, selector: #selector(updateTimespanLabel))
        displaylink.add(to: .current, forMode: RunLoop.Mode.default)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if preferredInputMode == .vision && ARFaceTrackingConfiguration.isSupported {
            let configuration = ARFaceTrackingConfiguration()
            sceneView.session.run(configuration)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if preferredInputMode == .vision && ARFaceTrackingConfiguration.isSupported {
            sceneView.session.pause()
        }
    }
    
    // MARK: - User Actions Handling -

    func handleEyeClosureCoefficient(coefficient: Float) {
        eyeState = coefficient >= 0.85 ? .closed : .opened
    }
    
    func morseCodeEntryDidBegin() {
        cancelSelectionTimer()
        
        if eyeOpenedInterval.duration > Timing.interWordGap {
            transcription += " "
            transcriptionLabel.text = transcription
        }
    }
    
    func morseCodeEntryDidEnd() {
        dashLabel.isHidden = true
        dotLabel.isHidden = true
        
        switch eyeClosedInterval.duration {
        case 0...Timing.dot:
            treeNode = treeNode.leftChild() ?? TreeNode.morseTree
            AudioServicesPlaySystemSound(dotSoundID)
            if treeNode.parent != nil {dotLabel.isHidden = false}
            fireSelectionTimer()
        case Timing.dot.nextUp...Timing.dash:
            treeNode = treeNode.rightChild() ?? TreeNode.morseTree
            AudioServicesPlaySystemSound(dashSoundID)
            if treeNode.parent != nil {dashLabel.isHidden = false}
            fireSelectionTimer()
        default:
            break
        }
    }
    
    @objc func updateTimespanLabel(displaylink: CADisplayLink) {
        if eyeState == .opened {
            eyeOpenedInterval.end = Date()
            timespanLabel.text = String(format: "%.5f", eyeOpenedInterval.duration)
        }
    }
    
    @objc func selectTreeNodeValue() {
        // Ignore root
        guard treeNode.parent != nil else {
            return
        }
        
        transcription += treeNode.value
        treeNode = TreeNode.morseTree // reset to the tree's root
        
        transcriptionLabel.text = transcription
        
        dashLabel.isHidden = true
        dotLabel.isHidden = true
    }
    
    func fireSelectionTimer() {
        selectionTimer = Timer.scheduledTimer(timeInterval: Timing.interLetterGap, target: self, selector: #selector(selectTreeNodeValue), userInfo: nil, repeats: false)
    }
    
    func cancelSelectionTimer() {
        selectionTimer?.invalidate()
        selectionTimer = nil
    }
    
    @IBAction func transcriptionLabelDidReceiveTap(_ sender: Any) {
        transcription = ""
        transcriptionLabel.text = ""
    }
    
    @IBAction func touchUpInside(_ sender: Any) {
        handleEyeClosureCoefficient(coefficient: 0.0)
        lightFeedbackGenerator.impactOccurred()
    }
    
    @IBAction func touchDown(_ sender: Any) {
        handleEyeClosureCoefficient(coefficient: 1.0)
        mediumFeedbackGenerator.impactOccurred()
    }
}

// MARK: - Extensions -

extension ViewController: ARSCNViewDelegate {
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        #if targetEnvironment(simulator)
             return nil
        #else
            guard let device = sceneView.device else {
                return nil
            }
            
            let faceGeometry = ARSCNFaceGeometry(device: device)
            let node = SCNNode(geometry: faceGeometry)
            node.geometry?.firstMaterial?.transparency = 0.0 // Hide the mesh mask
        
            return node
        #endif
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let faceAnchor = anchor as? ARFaceAnchor,
            let faceGeometry = node.geometry as? ARSCNFaceGeometry else {
                return
        }
        
        faceGeometry.update(from: faceAnchor.geometry)
        
        let eyeClosureCoefficient = faceAnchor.blendShapes[.eyeBlinkRight]?.floatValue ?? 0.0
        
        DispatchQueue.main.async {
            self.handleEyeClosureCoefficient(coefficient: eyeClosureCoefficient)
        }
    }
}

extension SystemSoundID {
    static func register(soundName: String) -> SystemSoundID {
        var soundID: SystemSoundID = SystemSoundID()
        let mainBundle = CFBundleGetMainBundle()
        if let url = CFBundleCopyResourceURL(mainBundle, soundName as CFString, nil, nil) {
            AudioServicesCreateSystemSoundID(url, &soundID)
        }
        
        return soundID
    }
}

