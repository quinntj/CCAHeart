//
//  ViewController.swift
//  CCA-CollectiveHeartProject
//
//  Created by Tom Quinn on 9/23/16.
//  Copyright © 2016 Tom Quinn. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController, UITextFieldDelegate, AVAudioRecorderDelegate, AVAudioPlayerDelegate{
    // MARK: Properties
    
    @IBOutlet weak var logoHolder: UIImageView!
    @IBOutlet weak var promptTextArea: UILabel!
    @IBOutlet weak var responseTextArea: UITextField!
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var stopButton: UIButton!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var submitButton: UIButton!
    
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
                print("Something went wrong! Can't play audio.")
            }
            
            
            audioPlayer?.delegate = self
            
            if let err = error {
                print("audioPlayer error: \(err.localizedDescription)")
            } else {
                audioPlayer?.play()
            }
        }
    }

    
    var audioPlayer: AVAudioPlayer?
    var audioRecorder: AVAudioRecorder?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
        
        
        

        
        // Handle the text field’s user input through delegate callbacks.
        responseTextArea?.delegate = self
        
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
            print("Something went wrong! can't setup recording.")
        }
        
        
        
        if let err = error {
            print("audioSession error: \(err.localizedDescription)")
        }
        do {
        try audioRecorder = AVAudioRecorder(url: soundFileURL, settings: recordSettings)
        } catch {
            print("Something went wrong! Can't Record!")
        }
        if let err = error {
            print("audioSession error: \(err.localizedDescription)")
        } else {
            audioRecorder?.prepareToRecord()
        }
        
     }

//----------------------------------------------------------------------------------------
    
    
    // MARK: UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        recordButton.isEnabled = true
        stopButton.isEnabled = false
    }
    
    func audioPlayerDecodeErrorDidOccur(player: AVAudioPlayer!) {
        print("Audio Play Decode Error")
    }
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
    }
    
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        print("Audio Record Encode Error")
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }
    
    
    func saveThings() {
    
        var now = NSDate()
        var formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH-mm-ss"
        formatter.timeZone = NSTimeZone.local
        print(formatter.string(from: now as Date))
        var submitDate = formatter.string(from: now as Date)
        
        let audioFilePath = getDocumentsDirectory().appendingPathComponent("recording.m4a")
        let saveAudioPath = getDocumentsDirectory().appendingPathComponent("saved\(submitDate).m4a")
        let fileManager = FileManager.default
        do {
            try fileManager.copyItem(at: audioFilePath, to: saveAudioPath)
            try fileManager.removeItem(at: audioFilePath)
        }
        catch let error as NSError {
            print("Ooops! Something went wrong: \(error)")
        }
        
        stopButton.isEnabled = false
        playButton.isEnabled = false
        
        // Save data to file
        
        let fileURL = getDocumentsDirectory().appendingPathComponent("saved\(submitDate).txt")
        print("FilePath: \(fileURL.path)")
        
        let writeString = responseTextArea.text
        do {
            // Write to the file
            try writeString?.write(to: fileURL, atomically: true, encoding: String.Encoding.utf8)
        } catch let error as NSError {
            print("Failed writing to URL: \(fileURL), Error: " + error.localizedDescription)
        }
        
 //       var readString = "" // Used to store the file contents
 //       do {
 //           // Read the file contents
 //           readString = try String(contentsOfURL: fileURL)
 //       } catch let error as NSError {
 //           print("Failed reading from URL: \(fileURL), Error: " + error.localizedDescription)
 //       }
 //       print("File Text: \(readString)")
        
        
        
        responseTextArea.text = "Tap Here to type a response"
        
    }
    
}
