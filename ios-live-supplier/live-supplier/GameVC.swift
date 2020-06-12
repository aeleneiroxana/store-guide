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
    
    var inputList : Any = []
    private var roundsList : [Round] = []
    
    private var word1 = ""
    private var word2 = ""
    private var correctAns = ""
    
    private var currentScore = 0
    
    private var timer: Timer?
    private var runCount:Double = 0
    private var initialTime = 15.0
    private var ended = false
    private var userAnswer : String? = nil //nil means no answer given *yet*
    
    private var scoreLabel: UILabel?
    private var timerLabel: UILabel?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(fireTimerFunc), userInfo: nil, repeats: true)
        
        self.toRounds()
        self.addCameraInput()
        self.showCameraFeed()
        self.getCameraFrames()
        self.addGameLabels()

        self.captureSession.startRunning()//should be the last thing to call
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.previewLayer.frame = self.view.frame
    }
    
    @objc func fireTimerFunc(){
        runCount += 0.1
        
        if(runCount > initialTime){
            word1 += "DONE"
            timer?.invalidate()
            ended = true
            print("Final score: ", currentScore)
            timerLabel!.text = "Time: 0.0"
        } else {
            timerLabel!.text = "Time: " + String(format:"%.1f", initialTime - runCount)
        }
    }
    
    private func toRounds()
    {
        
        let decoder = JSONDecoder()
        do{
            roundsList = try decoder.decode([Round].self, from: inputList as! Data)
            word1 = roundsList[0].first
            word2 = roundsList[0].second
            correctAns = roundsList[0].answer
            roundsList.remove(at: 0)
        }
        catch{
            print("Wrong format wtf")
        }
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
        if let medianLine = landmarks.medianLine{
            
            let orientation = self.getFaceOrientation(medianLine: medianLine)
            
            if !self.ended{
                // if player gave an answer, process it
                self.handlePlayerResponse(orientation: orientation)
                
            } else {
                self.handleGameEnd()
            }
        }
        // draw other face features here
        return faceFeaturesDrawings
    }
    
    /**
        Gets the face orientation of the person in the frame
     
        - Parameter medianLine: the median line across the face
        - Parameter epsilon: sensitivity of the function; default: 0.05; higher value = less likely to trigger
     
        - Returns:  negative value if left,
                    positive value if right
                    0 if neutral
     */
    private func getFaceOrientation(medianLine: VNFaceLandmarkRegion2D, epsilon: Double = 0.05) -> Int{
        let eps = CGFloat(floatLiteral: epsilon)
        
        // 10 points aligned vertically across the middle of the face
        let points = medianLine.normalizedPoints
        
        let first = points[0].y             // top of head
        let last = points[points.count-1].y // bottom of chin
        let middle = points[3].y            // tip of nose
        
        if middle > first + eps && middle > last + eps{ // face oriented to the right
            return 1
        } else if middle < first - eps && middle < last - eps{ // face oriented to the left
            return -1
        }
        // no obvious orientation
        return 0
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
    
    private func updateScore(userAnswer: String)
    {
        if userAnswer == correctAns
        {
            let wordLen = word1.count
            currentScore = currentScore + wordLen
            scoreLabel!.text = "Score: " + String(currentScore)
        }
    }
    
    private func addGameLabels(){
        scoreLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 24))
        scoreLabel!.font = UIFont.preferredFont(forTextStyle: .headline)
        scoreLabel!.center = CGPoint(x: 160, y: self.view.bounds.size.height - 48)
        scoreLabel!.textAlignment = .left
        scoreLabel!.text = "Score: " + String(currentScore)
        scoreLabel!.backgroundColor = .white
        scoreLabel!.textColor = .black
        self.view.addSubview(scoreLabel!)
        
        timerLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 24))
        timerLabel!.font = UIFont.preferredFont(forTextStyle: .headline)
        timerLabel!.center = CGPoint(x: 160, y: self.view.bounds.size.height - 24)
        timerLabel!.textAlignment = .left
        timerLabel!.text = "Time: " + String(initialTime - runCount)
        timerLabel!.backgroundColor = .white
        timerLabel!.textColor = .black
        self.view.addSubview(timerLabel!)
    }
    
    private func changeWordSet(){
        // TODO
        word1 = roundsList[0].first
        word2 = roundsList[0].second
        correctAns = roundsList[0].answer
        roundsList.remove(at:0)
    }
    
    private func handlePlayerResponse(orientation: Int){
        if orientation > 0{
            userAnswer = "right"
        } else if orientation < 0{
            userAnswer = "left"
        }  else if orientation == 0 && userAnswer != nil  && ended == false{
            // add points if answer was correct
            self.updateScore(userAnswer: userAnswer!)
            // change wordSet
            self.changeWordSet()
            userAnswer = nil
        }
    }
    
    private func handleGameEnd(){
        // TODO
        // don't know what to do yet
    }
}

struct Round: Codable{
    var answer : String
    var first: String
    var original: String
    var second: String
}
