//
//  ViewController.swift
//  WavyBackgrounds
//
//  Created by Philipp Remy on 10/31/23.
//

import Cocoa

class ViewController: NSViewController {
    
    @IBOutlet weak var progressIndicator: NSProgressIndicator!
    @IBOutlet weak var progressLabel: NSTextField!
    @IBOutlet weak var urlList: NSComboBox!
    @IBOutlet weak var screenList: NSComboBox!
    @IBOutlet weak var screenButton: NSComboButton!
    @IBOutlet weak var mainLabel: NSTextField!
    @IBOutlet weak var imageView: NSImageView!
    
    @IBAction func urlSelected(_ sender: NSComboBox) {
        
        let selected_vid = sender.stringValue;
        let vurl = URL(fileURLWithPath: String("/Library/Application Support/com.apple.idleassetsd/Customer/4KSDR240FPS/" + selected_vid));

            let asset = AVURLAsset(url: vurl)
            let generator = AVAssetImageGenerator(asset: asset)
            generator.appliesPreferredTrackTransform = true

            let timestamp = CMTime(seconds: 1, preferredTimescale: 60)

            do {
                let imageRef = try generator.copyCGImage(at: timestamp, actualTime: nil)
                imageView.image = NSImage(cgImage: imageRef, size: .zero);
            }
            catch let error as NSError
            {
                print("Image generation failed with error \(error)")
            }
    }
    
    @IBAction func buttonPressed(_ sender: NSButton) {
        let file = (urlList.selectedCell()?.title)!;
        let screenSelection = screenList.selectedCell()?.title;
        
        for screen in screens {
            if screen.localizedName == screenSelection {
                mainScreen = screen;
            }
        }
        
        let fileurl = URL(fileURLWithPath: String("/Library/Application Support/com.apple.idleassetsd/Customer/4KSDR240FPS/" + file));
        
        let localWindow = startScreen(mainScreen, fileurl)!;
        print(localWindow.frame);
        localWindows.append(localWindow);
    }
    
    var screens: [NSScreen] = [];
    var videoURLs: [String] = [];
    var mainScreen: NSScreen = NSScreen();
    
    func startView() {}

    override func viewDidLoad() {
        super.viewDidLoad()
        
        progressIndicator.startAnimation(self);
        
        screens = NSScreen.screens;
        
        do {
            let vurls = try FileManager.default.contentsOfDirectory(atPath: "/Library/Application Support/com.apple.idleassetsd/Customer/4KSDR240FPS");
            videoURLs = vurls;
        } catch {
            print(error);
        }
        
        for vurl in videoURLs {
            urlList.addItem(withObjectValue: vurl);
        }
        
        for screen in screens {
            screenList.addItem(withObjectValue: screen.localizedName);
        }
        
        progressIndicator.removeFromSuperview();
        progressLabel.removeFromSuperview();
        urlList.isHidden = false;
        screenButton.isHidden = false;
        screenList.isHidden = false;
        mainLabel.isHidden = false;
        
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }


}
