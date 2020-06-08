//
//  GameVC.swift
//  live-supplier
//
//  Created by Roxana Aelenei on 07/06/2020.
//  Copyright © 2020 Andreea Grigore. All rights reserved.
//

import UIKit
import AVFoundation
import Vision

class GameVC: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    private let captureSession = AVCaptureSession()
    
    private lazy var previewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
    
    private let videoDataOutput = AVCaptureVideoDataOutput()
    
    private var drawings: [CAShapeLayer] = []
    
    private var word1 = "C"
    private var word2 = "C"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(changeWords), userInfo: nil, repeats: true)
        
        self.addCameraInput()
        self.showCameraFeed()
        self.getCameraFrames()
        self.captureSession.startRunning()//should be the last thing to call
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.previewLayer.frame = self.view.frame
    }
    
    @objc func changeWords() {
        word1 = word1 + "W"
        word2 = word2 + "G"
    }
    
    private func addCameraInput() {
        guard let device = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera, .builtInDualCamera, .builtInTrueDepthCamera],
            mediaType: .video,
            position: .front).devices.first else {
                fatalError("No back camera device found, help me pls!!")
        }
        let cameraInput = try! AVCaptureDeviceInput(device: device)
        self.captureSession.addInput(cameraInput)
    }
    
    private func showCameraFeed() {
        self.previewLayer.videoGravity = .resizeAspectFill
        self.view.layer.addSublayer(self.previewLayer)
        self.previewLayer.frame = self.view.frame
    }
    
    private func getCameraFrames() {
        self.videoDataOutput.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as NSString) : NSNumber(value: kCVPixelFormatType_32BGRA)] as [String : Any]
        self.videoDataOutput.alwaysDiscardsLateVideoFrames = true
        self.videoDataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "camera_frame_processing_queue"))
        self.captureSession.addOutput(self.videoDataOutput)
        guard let connection = self.videoDataOutput.connection(with: AVMediaType.video),
            connection.isVideoOrientationSupported else { return }
        connection.videoOrientation = .portrait
    }
    
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        guard let frame = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            debugPrint("unable to get image from sample buffer")
            return
        }
        self.detectFace(in: frame)
    }
    
    private func detectFace(in image: CVPixelBuffer) {
        let faceDetectionRequest = VNDetectFaceLandmarksRequest(completionHandler: { (request: VNRequest, error: Error?) in
            DispatchQueue.main.async {
                if let results = request.results as? [VNFaceObservation] {
                    self.handleFaceDetectionResults(results)
                } else {
                    self.clearDrawings()
                }
            }
        })
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: image, orientation: .leftMirrored, options: [:])
        try? imageRequestHandler.perform([faceDetectionRequest])
    }
    
    private func handleFaceDetectionResults(_ observedFaces: [VNFaceObservation]) {
        
        self.clearDrawings()
        let facesBoundingBoxes: [CAShapeLayer] = observedFaces.flatMap({ (observedFace: VNFaceObservation) -> [CAShapeLayer] in
            let faceBoundingBoxOnScreen = self.previewLayer.layerRectConverted(fromMetadataOutputRect: observedFace.boundingBox)
            var newDrawings = [CAShapeLayer]()
            if let landmarks = observedFace.landmarks {
                newDrawings = newDrawings + self.drawFaceFeatures(landmarks, screenBoundingBox: faceBoundingBoxOnScreen)
            }
            return newDrawings
        })
        facesBoundingBoxes.forEach({ faceBoundingBox in self.view.layer.addSublayer(faceBoundingBox) })
        self.drawings = facesBoundingBoxes
    }
    
    private func clearDrawings() {
        self.drawings.forEach({ drawing in drawing.removeFromSuperlayer() })
    }
    
    private func drawFaceFeatures(_ landmarks: VNFaceLandmarks2D, screenBoundingBox: CGRect) -> [CAShapeLayer] {
        var faceFeaturesDrawings: [CAShapeLayer] = []
        if let leftEye = landmarks.leftEye {
            let eyeDrawing = self.drawEye(leftEye, screenBoundingBox: screenBoundingBox, word: word1, isLeft:true)
            faceFeaturesDrawings.append(eyeDrawing)
        }
        if let rightEye = landmarks.rightEye {
            let eyeDrawing = self.drawEye(rightEye, screenBoundingBox: screenBoundingBox, word:word2, isLeft:false)
            faceFeaturesDrawings.append(eyeDrawing)
        }
        // draw other face features here
        return faceFeaturesDrawings
    }
    
    private func drawEye(_ eye: VNFaceLandmarkRegion2D, screenBoundingBox: CGRect, word: String, isLeft: Bool) -> CAShapeLayer {
        let eyeMaxX = eye.normalizedPoints.max{$0.x < $1.x}!.x
        let eyeMinX = eye.normalizedPoints.min{$0.x < $1.x}!.x
        let eyeMaxY = eye.normalizedPoints.max{$0.y < $1.y}!.y
        let eyeMinY = eye.normalizedPoints.min{$0.y < $1.y}!.y
        
        let leftUpX = eyeMaxY * screenBoundingBox.height + screenBoundingBox.origin.x
        
        let leftUpY = eyeMinX * screenBoundingBox.width + screenBoundingBox.origin.y
        
        let rightDownX = eyeMinY * screenBoundingBox.height + screenBoundingBox.origin.x
        
        let rightDownY = eyeMaxX * screenBoundingBox.width + screenBoundingBox.origin.y
        
        let wordLen = word.count
        let eyeWidth = leftUpX-rightDownX
        let eyeHeight = rightDownY-leftUpY
        let bias = -25
        
        let fontSize = eyeWidth / CGFloat(Double(wordLen) / 1.6)
        
        let customRect = CGRect(x:rightDownX + CGFloat(bias), y:leftUpY + CGFloat(bias), width :  eyeWidth * 2, height : eyeHeight * 4)
        
        let eyeRectangle = UIBezierPath(rect: customRect)
        
        let eyeDrawing = CAShapeLayer()
        eyeDrawing.path = eyeRectangle.cgPath
        eyeDrawing.fillColor = UIColor.white.cgColor
        eyeDrawing.strokeColor = UIColor.black.cgColor
        
        let label = CATextLayer()
        
        let customRect2 = CGRect(x:rightDownX + CGFloat(bias), y:leftUpY + CGFloat(bias) + eyeHeight, width : eyeWidth * 2, height : eyeHeight * 4)
        
        
        label.frame = customRect2
        label.string = word
        label.fontSize = fontSize
        label.foregroundColor = UIColor.black.cgColor
        label.isHidden = false
        label.alignmentMode = CATextLayerAlignmentMode.center
        label.isWrapped = true
        eyeDrawing.addSublayer(label)
        return eyeDrawing
    }
}
