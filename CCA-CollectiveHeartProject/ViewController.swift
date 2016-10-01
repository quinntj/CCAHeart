//
//  ViewController.swift
//  CCA-CollectiveHeartProject
//
//  Created by Tom Quinn on 9/23/16.
//  Copyright © 2016 Tom Quinn. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController, AVAudioRecorderDelegate, AVAudioPlayerDelegate, UITextViewDelegate{
    // MARK: Properties
    

    
    @IBOutlet weak var logoHolder: UIImageView!
    @IBOutlet weak var promptTextArea: UILabel!
    @IBOutlet weak var responseTextArea: UITextView!
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var stopButton: UIButton!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var submitButton: UIButton!
    @IBOutlet weak var ipadIdLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    
    var ipadIDPrefix = ""
    var recordTapped = false
    
    @IBAction func submitDone(sender: AnyObject) {
        print("User clicked submit!")
        saveThings()
    }
   
    @IBAction func recordAudio(sender: AnyObject) {
        if audioRecorder?.isRecording == false {
            playButton.isEnabled = false
            stopButton.isEnabled = true
            recordButton.isEnabled = false
            audioRecorder?.record()
            recordTapped = true
        }
    }
    
    @IBAction func stopAudio(sender: AnyObject) {
        stopButton.isEnabled = false
        playButton.isEnabled = true
        recordButton.isEnabled = true
        
        if audioRecorder?.isRecording == true {
            audioRecorder?.stop()
        } else {
            audioPlayer?.stop()
        }
    }
    
    @IBAction func playAudio(sender: AnyObject) {
        if audioRecorder?.isRecording == false {
            stopButton.isEnabled = true
            recordButton.isEnabled = false
            
            var error: NSError?
            
            do {
                try audioPlayer = AVAudioPlayer(contentsOf: (audioRecorder?.url)!)
            } catch {
                statusLabel.text = "Something went wrong! Can't play audio."
            }
            
            
            audioPlayer?.delegate = self
            
            if let err = error {
                statusLabel.text = "audioPlayer error: \(err.localizedDescription)"
            } else {
                audioPlayer?.play()
            }
        }
    }

    
    var audioPlayer: AVAudioPlayer?
    var audioRecorder: AVAudioRecorder?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        registerSettingsBundle()
        updateDisplayFromDefaults()
        self.responseTextArea.delegate = self;
        
        //MARK: fix up the buttons
        let sdwRadius = 10
        let btnRadius = 25
        let bdrWidth = 2
        recordButton.layer.shadowColor = UIColor.black.cgColor
        recordButton.layer.shadowOffset = CGSize(width: 5, height: 5)
        recordButton.layer.shadowRadius = CGFloat(sdwRadius)
        recordButton.backgroundColor = UIColor.red
        recordButton.layer.cornerRadius = CGFloat(btnRadius)
        recordButton.layer.borderWidth = CGFloat(bdrWidth)
        recordButton.layer.borderColor = UIColor.black.cgColor
        stopButton.layer.shadowColor = UIColor.black.cgColor
        stopButton.layer.shadowOffset = CGSize(width: 5, height: 5)
        stopButton.layer.shadowRadius = CGFloat(sdwRadius)
        stopButton.backgroundColor = UIColor.black
        stopButton.layer.cornerRadius = CGFloat(btnRadius)
        stopButton.layer.borderWidth = CGFloat(bdrWidth)
        stopButton.layer.borderColor = UIColor.black.cgColor
        playButton.layer.shadowColor = UIColor.black.cgColor
        playButton.layer.shadowOffset = CGSize(width: 5, height: 5)
        playButton.layer.shadowRadius = CGFloat(sdwRadius)
        playButton.backgroundColor = UIColor.blue
        playButton.layer.cornerRadius = CGFloat(btnRadius)
        playButton.layer.borderWidth = CGFloat(bdrWidth)
        playButton.layer.borderColor = UIColor.black.cgColor
        submitButton.layer.shadowColor = UIColor.black.cgColor
        submitButton.layer.shadowOffset = CGSize(width: 5, height: 5)
        submitButton.layer.shadowRadius = CGFloat(sdwRadius)
        submitButton.backgroundColor = UIColor.darkGray
        submitButton.layer.cornerRadius = CGFloat(btnRadius)
        submitButton.layer.borderWidth = CGFloat(bdrWidth)
        submitButton.layer.borderColor = UIColor.black.cgColor
        
        //done fixing buttons
        
        let appInfo = Bundle.main.infoDictionary as! Dictionary<String,AnyObject>
        let shortVersionString = appInfo["CFBundleShortVersionString"] as! String
        let bundleVersion      = appInfo["CFBundleVersion"] as! String
        let applicationVersion = shortVersionString + "." + bundleVersion
        let defaults = UserDefaults.standard
        defaults.set(applicationVersion, forKey: "application_version")
        defaults.synchronize()
        
        statusLabel.text = ""
        
        NotificationCenter.default.addObserver(self,
                                                         selector: #selector(ViewController.defaultsChanged),
                                                         name: UserDefaults.didChangeNotification,
                                                         object: nil)
    
        //----copy default prompt files
        
  
        let bundlePath:String = Bundle.main.path(forResource: "prompt", ofType: ".txt")!
        print(bundlePath, "\n") //prints the correct path
        let destPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        let fileManager = FileManager.default
        let fullDestPath = NSURL(fileURLWithPath: destPath).appendingPathComponent("prompt.txt")
        let fullDestPathString = fullDestPath?.path
       
        do{
            try fileManager.copyItem(atPath: bundlePath, toPath: fullDestPathString!)
        }catch{
            print("\n")
            print(error)
        }
        
        //---- done with default prompt files
        
        //---- setup pompt text
        
        let file = "prompt.txt" //this is the file. we will write to and read from it
        
        let text = "Coded text, if you see this something went wrong." //just a text
        promptTextArea.text = text
        
        if let dir = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.allDomainsMask, true).first,
            let path = NSURL(fileURLWithPath: dir).appendingPathComponent(file) {
            
            //reading
            do {
                let promptFileText = try NSString(contentsOf: path, encoding: String.Encoding.utf8.rawValue) as String
                promptTextArea.text = promptFileText
            }
            catch {/* error handling here */}
        }
        
        //---- done setting prompt text
        
        // Setup the audio recording stuff
        playButton.isEnabled = false
        stopButton.isEnabled = false
        let soundFileURL = getDocumentsDirectory().appendingPathComponent("recording.m4a")
        
        let recordSettings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        var error: NSError?
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
           try audioSession.setCategory(AVAudioSessionCategoryPlayAndRecord)
        } catch {
            statusLabel.text = "Something went wrong! can't setup recording."
        }
        
        if let err = error {
            statusLabel.text = "audioSession error: \(err.localizedDescription)"
        }
        do {
        try audioRecorder = AVAudioRecorder(url: soundFileURL, settings: recordSettings)
        } catch {
            statusLabel.text = "Something went wrong! Can't Record!"
        }
        if let err = error {
            statusLabel.text = "audioSession error: \(err.localizedDescription)"
        } else {
            audioRecorder?.prepareToRecord()
        }
        //done setting up audio recording stuff
        
     }

//----------------------------------------------------------------------------------------
    
    

    
    // MARK: Functions for recording audio
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        recordButton.isEnabled = true
        stopButton.isEnabled = false
    }
    
    func audioPlayerDecodeErrorDidOccur(player: AVAudioPlayer!) {
        statusLabel.text = "Audio Play Decode Error"
    }
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
    }
    
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        statusLabel.text = "Audio Record Encode Error"
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }
    // done with functions for recording audio
    
    // MARK: function to save everything to local storage
    func saveThings() {
    
        stopButton.isEnabled = false
        playButton.isEnabled = false
        recordButton.isEnabled = false
        submitButton.isEnabled = false
        var didwesave = ""
        
        let now = NSDate()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH-mm-ss"
        formatter.timeZone = NSTimeZone.local
        print(formatter.string(from: now as Date))
        let submitDate = formatter.string(from: now as Date)
        
        if recordTapped == true {
        let audioFilePath = getDocumentsDirectory().appendingPathComponent("recording.m4a")
        let saveAudioPath = getDocumentsDirectory().appendingPathComponent("\(ipadIDPrefix)-\(submitDate).m4a")
        let fileManager = FileManager.default
        do {
            try fileManager.copyItem(at: audioFilePath, to: saveAudioPath)
            try fileManager.removeItem(at: audioFilePath)
            didwesave += "Recorded Truth Saved! "
            recordTapped = false
        }
        catch let error as NSError {
            statusLabel.text = "Ooops! Something went wrong: \(error)"

        }
        } else {
            let audioFilePath = getDocumentsDirectory().appendingPathComponent("recording.m4a")
            let fileManager = FileManager.default
            do {
                try fileManager.removeItem(at: audioFilePath)
            }
            catch let error as NSError {
                statusLabel.text = "Ooops! Something went wrong: \(error)"
            }
             didwesave += "No Recorded Truth. "
           
        }
        
        // Save text field to file
        
        let fileURL = getDocumentsDirectory().appendingPathComponent("\(ipadIDPrefix)-\(submitDate).txt")
        print("FilePath: \(fileURL.path)")
     
        
        let writeString = responseTextArea.text
        
        if (writeString!.characters.count) > 10 {
            do {
                // Write to the file
                try writeString?.write(to: fileURL, atomically: true, encoding: String.Encoding.utf8)
                didwesave += "Typed Truth Saved! "
            } catch let error as NSError {
                let fileError = "Failed writing to URL: \(fileURL), Error: " + error.localizedDescription
                statusLabel.text = fileError
                print(fileError)
            }
        } else {
            didwesave += "Typed truth must be longer than 10 characters. "
        }
        statusLabel.text = didwesave
        
        
        
        // reset UI after 5 seconds
        let deadlineTime = DispatchTime.now() + .seconds(5)
        DispatchQueue.main.asyncAfter(deadline: deadlineTime) {

            self.recordButton.isEnabled = true
            self.submitButton.isEnabled = true
            self.responseTextArea.text = ""
            self.statusLabel.text = ""
        }
    }
    
    
    // MARK: functions for settings pane
    func registerSettingsBundle(){
        let appDefaults = [String:AnyObject]()
        UserDefaults.standard.register(defaults: appDefaults)
    }
    func updateDisplayFromDefaults(){
        //Get the defaults
        let defaults = UserDefaults.standard
        
        //Set the controls to the default values.
        if let ipadID = defaults.string(forKey: "ipadID"){
            if (ipadID.characters.count >= 1 ) {
                ipadIdLabel.text = ipadID
                ipadIDPrefix = ipadID
                } else {
                ipadIdLabel.text = "ID not set"
                ipadIdLabel.textColor = UIColor.red
                ipadIDPrefix = "noid"
                }
        } else{
            ipadIdLabel.text = "ID not available"
            ipadIdLabel.textColor = UIColor.red
            ipadIDPrefix = "noid"
        }
       
    }
    func defaultsChanged(){
        updateDisplayFromDefaults()
    }
    // done with settings pane
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if (text == "\n") {
            textView.resignFirstResponder()
        }
        return true
    }

}
