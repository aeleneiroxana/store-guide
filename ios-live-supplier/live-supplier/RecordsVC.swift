//
//  RecordsVc.swift
//  live-supplier
//
//  Created by Andreea Grigore on 13/05/2020.
//  Copyright © 2020 Andreea Grigore. All rights reserved.
//

import UIKit
import AVFoundation
import Speech

class RecordsVC: UIViewController, AVAudioRecorderDelegate, UITableViewDelegate, UITableViewDataSource {
    
    var recordinSession: AVAudioSession!
    var audioRecorder: AVAudioRecorder!
    var audioPlayer: AVAudioPlayer!
    var gameInput : Any = []
    @IBOutlet weak var buttonLabel: UIButton!
    @IBOutlet weak var myTableView: UITableView!
    @IBOutlet weak var transcriptionTextField: UITextView!
    
    @IBAction func sendToGameButton(_ sender: Any) {
        
        performSegue(withIdentifier: "GoToGame", sender: self)
    }
    var numberOfRecords = 0;
    var textToSend = "";
    
    @IBAction func record(_ sender: Any) {
        //Check if we have an active recorder
        if audioRecorder == nil {
            numberOfRecords += 1
            let fileName = getDirectory().appendingPathComponent("\(numberOfRecords).m4a")
            
            let settings = [AVFormatIDKey: Int(kAudioFormatMPEG4AAC), AVSampleRateKey: 12000, AVNumberOfChannelsKey: 1, AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue]
        
            //Start audio recording
            do {
                audioRecorder = try AVAudioRecorder(url: fileName, settings: settings)
                audioRecorder.delegate = self
                audioRecorder.record()
                
                buttonLabel.setTitle("Stop Recording", for: .normal)
            }
            catch {
                displayAlert(title: "Ups!", message: "Recording failed!")
            }
        }
        else {
            
            //Stopping audio recording
            audioRecorder.stop()
            audioRecorder = nil
            
            UserDefaults.standard.set(numberOfRecords, forKey: "myNumber")
            myTableView.reloadData()
            
            buttonLabel.setTitle("Start Recording", for: .normal)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
       let destVC : GameVC = segue.destination as! GameVC
        destVC.inputList = gameInput
    }
    
    override func viewDidLoad() {
       super.viewDidLoad()
       // Do any additional setup after loading the view.
        
       //Setting up session
       recordinSession = AVAudioSession.sharedInstance()
       
       if let number:Int = UserDefaults.standard.object(forKey: "myNumber") as? Int {
           numberOfRecords = number
       }

       AVAudioSession.sharedInstance().requestRecordPermission { (hasPermission) in
           if hasPermission{
               print("Accepted!")
           }
           
       }
    }
    
    //Function that gets path to directory
    func getDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentDirectory = paths[0]
        return documentDirectory
    }
    
    
    //Function that display an alert
    func displayAlert(title: String, message: String){
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "dismiss", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    //SETTING UP TABLE VIEW//
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return numberOfRecords
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = String(indexPath.row + 1)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let path = getDirectory().appendingPathComponent("\(indexPath.row + 1).m4a")

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: path)
            audioPlayer.play()
        }
        catch {

        }

        let recognizer = SFSpeechRecognizer()
        let request = SFSpeechURLRecognitionRequest(url: path)
        recognizer?.recognitionTask(with: request) { (result, error) in
            if let error = error {
                print("There was an error: \(error)")
            } else {
                self.transcriptionTextField.text = result?.bestTranscription.formattedString
                self.textToSend = (result?.bestTranscription.formattedString ?? "") as String
            }
        }
    }
    
    
    @IBAction func removeAllData(_ sender: Any) {
        UserDefaults.standard.removeObject(forKey: "myNumber")

        myTableView.reloadData()
        gameInput = []
    }
    
    @IBAction func startGame(_ sender: Any) {
        print(self.textToSend);
        let arrayOfWords = self.textToSend.components(separatedBy: " ")
        
        let url = URL(string: "http://localhost:3000/home")!
        

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = [
            "Content-Type": "application/json",
            "Accept": "application/json"
        ]
        
        let jsonDictionary: [String: [String]] = [
            "list": arrayOfWords,
        ]

        let data = try! JSONSerialization.data(withJSONObject: jsonDictionary, options: .prettyPrinted)
        URLSession.shared.uploadTask(with: request, from: data) { (responseData, response, error) in
            if let error = error {
                print("Error making PUT request: \(error.localizedDescription)")
                return
            }
            
            if let responseCode = (response as? HTTPURLResponse)?.statusCode, let responseData = responseData {

                
                if let responseJSONData = try? JSONSerialization.jsonObject(with: responseData, options: .allowFragments) as? [String:Any] {
                    print("Response JSON data = \(responseJSONData)")

                    
                    self.gameInput = responseJSONData["list"]!
                }
                
            }
        }.resume()
        
    }
}
