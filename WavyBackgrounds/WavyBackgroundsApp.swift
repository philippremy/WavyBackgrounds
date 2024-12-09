//
//  WavyBackgroundsApp.swift
//  WavyBackgrounds
//
//  Created by Philipp Remy on 13.11.24.
//

import SwiftUI

@main
class WavyBackgroundsApp {
 
    public static func main() {
        
        let nsApp = NSApplication.shared
        let delegate = WavyBackgroundsAppDelegate()
        nsApp.delegate = delegate
        nsApp.run()
        
    }
    
}

class WavyBackgroundsAppDelegate : NSObject, NSApplicationDelegate {
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        
        // Initialize UI
        let contentView = ContentView();
        let hostingView = NSHostingView(rootView: contentView);
        let preferredSize = hostingView.intrinsicContentSize;
        let contentViewWindow = NSWindow(contentRect: NSRect(origin: .zero, size: CGSize(width: preferredSize.width, height: preferredSize.height)), styleMask: [.titled, .closable, .resizable, .miniaturizable], backing: .buffered, defer: false);
        contentViewWindow.isReleasedWhenClosed = false;
        contentViewWindow.contentView = hostingView;
        contentViewWindow.title = "";
        contentViewWindow.center();
        contentViewWindow.makeKeyAndOrderFront(self);
        contentViewWindow.makeKeyAndOrderFront(self);
        
        // Setup the App Menu
        setupMenuBar()
        
    }
    
    func setupMenuBar() {
        // Create the main menu bar
        let mainMenu = NSMenu();

        // Create an "App" menu item
        let appMenuItem = NSMenuItem();
        mainMenu.addItem(appMenuItem);
        
        // Create a "File" menu item
        let fileMenuItem = NSMenuItem();
        fileMenuItem.title = String(localized: "File");
        mainMenu.addItem(fileMenuItem);

        // Create the app's submenu
        let appMenu = NSMenu();
        let aboutMenuItem = NSMenuItem()
        aboutMenuItem.title = NSString(format: String(localized: "About %@") as NSString, (NSRunningApplication.current.localizedName ?? "App")) as String;
        aboutMenuItem.action = #selector(showAboutWindow);
        
        let quitMenuItem = NSMenuItem()
        quitMenuItem.title = NSString(format: String(localized: "Quit %@") as NSString, (NSRunningApplication.current.localizedName ?? "App")) as String;
        quitMenuItem.action = sel_registerName("terminate:");
        quitMenuItem.keyEquivalent = "q";
        
        // Settings
        let settingsMenuItem = NSMenuItem();
        settingsMenuItem.title = String(localized: "Settings...");
        settingsMenuItem.action = #selector(self.showSettingsWindowObjc)
        settingsMenuItem.keyEquivalent = ",";
        
        // Services
        let servicesMenuItem = NSMenuItem();
        servicesMenuItem.title = String(localized: "Services");
        let servicesMenu = NSMenu();
        NSApplication.shared.servicesMenu = servicesMenu;
        servicesMenuItem.submenu = servicesMenu;
        
        // Hide WavyBackgrounds
        let hideMenu = NSMenuItem();
        hideMenu.title = String(localized: "Hide WavyBackgrounds");
        hideMenu.action = sel_registerName("hide:");
        hideMenu.keyEquivalent = "h";
        
        // Hide Others
        let hideOthersMenu = NSMenuItem();
        hideOthersMenu.title = String(localized: "Hide Others");
        hideOthersMenu.action = sel_registerName("hideOtherApplications:");
        hideOthersMenu.keyEquivalentModifierMask = .option;
        hideOthersMenu.keyEquivalent = "h";
        
        // Show All
        let showAllMenu = NSMenuItem()
        showAllMenu.title = String(localized: "Show All");
        showAllMenu.action = sel_registerName("unhideAllApplications:");
        
        // Build App Menu
        appMenu.addItem(aboutMenuItem);
        appMenu.addItem(.separator());
        appMenu.addItem(settingsMenuItem);
        appMenu.addItem(.separator());
        appMenu.addItem(servicesMenuItem);
        appMenu.addItem(.separator());
        appMenu.addItem(hideMenu);
        appMenu.addItem(hideOthersMenu);
        appMenu.addItem(showAllMenu);
        appMenu.addItem(.separator());
        appMenu.addItem(quitMenuItem);
        appMenuItem.submenu = appMenu;
        
        // Create the "File" submenu
        let fileMenu = NSMenu();
        
        // Build File Menu
        fileMenuItem.submenu = fileMenu;

        // Set the menubar on the application
        NSApp.mainMenu = mainMenu
    }
    
}


extension WavyBackgroundsAppDelegate {
    
    @objc func showAboutWindow() {
        // TODO
    }
    
    @objc func showSettingsWindowObjc() {
        showSettingsWindow()
    }
    
}

public func showSettingsWindow() {
    // Check if Window exists, then bring it to front
    if NSApplication.shared.windows.contains(where: { window in return window.identifier == NSUserInterfaceItemIdentifier("settingsUIWindow") }) {
        NSApplication.shared.windows.first(where: { window in return window.identifier == NSUserInterfaceItemIdentifier("settingsUIWindow") })!.makeKeyAndOrderFront(nil);
    } else {
        // Initialize Settings UI
        let contentView = SettingsView().environment(GlobalViewState.sharedInstance);
        let hostingView = NSHostingView(rootView: contentView);
        let preferredSize = hostingView.intrinsicContentSize;
        let contentViewWindow = NSWindow(contentRect: NSRect(origin: .zero, size: CGSize(width: preferredSize.width, height: preferredSize.height)), styleMask: [.titled, .closable, .resizable, .miniaturizable], backing: .buffered, defer: false);
        contentViewWindow.isReleasedWhenClosed = false;
        contentViewWindow.contentView = hostingView;
        contentViewWindow.title = String(localized: "Settings");
        contentViewWindow.center();
        contentViewWindow.identifier = NSUserInterfaceItemIdentifier("settingsUIWindow");
        contentViewWindow.toolbarStyle = .expanded;
        contentViewWindow.makeKeyAndOrderFront(nil);
    }
}

