//
//  AppDelegate.swift
//  WavyBackgrounds
//
//  Created by Philipp Remy on 10/31/23.
//

import Cocoa

var localWindows: [NSWindow] = [];

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    
    @IBAction func closeAllBackgroundViews(_ sender: AnyObject?) {
        print("Invoked!");
        print(localWindows);
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }


}

