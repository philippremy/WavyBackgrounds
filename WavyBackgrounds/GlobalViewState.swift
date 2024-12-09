//
//  GlobalViewState.swift
//  WavyBackgrounds
//
//  Created by Philipp Remy on 13.11.24.
//

import AppKit
import Combine
import Foundation

import WavyBackgroundsKit

public class GlobalViewState : Observable, ObservableObject {
    
    // MARK: Instances
    /// Public Shared Instance
    public static let sharedInstance = GlobalViewState()
    
    // MARK: Constant Members
    public var spaceCaptureServiceConnection: XPCSession
    
    // MARK: Published Members
    @Published var spaceIDs: [SLSSpaceID] = []
    @Published var spacesViewPadding: Int = 10
    @Published var fps: Int = 1
    @Published var shouldIncludeForeignWindows = false
    
    // MARK: Published Members Settings
    @Published var selectedSettingsView: String = "General"
    @Published var hoveredSettingsView: String = "General"
    @Published var sliderValue: Float = Float()
    public let sliderValues: [Int] = [1, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50 , 55, 60]
    
    // MARK: Metal Variables
    @Published var currentBackgroundColor: NSColor = NSColor.windowBackgroundColor
    
    // MARK: Private Members and Methods
    private let internalSpaceRefresher: InternalSpaceRefreshManager
    
    private init() {
        
        // Open Session to XPC Service
        self.spaceCaptureServiceConnection = try! XPCSession(xpcService: "de.philippremy.WavyBackgroundsSpaceIOSurfaceCaptureService")
        self.internalSpaceRefresher = InternalSpaceRefreshManager()
        
    }
    
}

func spaceCaptureServiceXPCErrorHandler(xpcError: any Error) {
    print("A XPC error occured (WavyBackgroundsSpaceCpatureService): \(xpcError.localizedDescription)")
}

class InternalSpaceRefreshManager {
    
    private let refreshQueue: DispatchQueue = DispatchQueue(label: "Internal Space Refresh", qos: .background)
    private let xpcQueue: DispatchQueue = DispatchQueue(label: "Internal Refresh XPC Queue", qos: .utility)
    private var currentSpaceIDs: [SLSSpaceID] = []
    
    public init() {
        self.internalRefresh()
    }
    
    private func internalRefresh() {
        let workItem = DispatchWorkItem(block: {
            while true {
                let timeStart = DispatchTime.now()
                
                // Run internal update functions
                if self.fetchNewSpacesAndCompare() {
                    DispatchQueue.main.asyncAndWait {
                        GlobalViewState.sharedInstance.spaceIDs = self.currentSpaceIDs
                    }
                }
                
                let timeEnd = DispatchTime.now()
                let timeDiff = timeEnd.uptimeNanoseconds - timeStart.uptimeNanoseconds
                let timeDiffSecs = Double(timeDiff) / 1_000_000_000
                if timeDiffSecs > Double(1) / (Double(GlobalViewState.sharedInstance.fps) / Double(5)) {
                    continue
                }
                Thread.sleep(forTimeInterval: TimeInterval(Double(1) / (Double(GlobalViewState.sharedInstance.fps) / Double(5)) - timeDiffSecs))
            }
        })
        self.refreshQueue.async(execute: workItem)
    }
    
    private func fetchNewSpacesAndCompare() -> Bool {
        
        self.currentSpaceIDs.removeAll()
        var shouldUpdate = false
        let spaceDictionaryArray = SLSCopyManagedDisplaySpaces(SLSMainConnectionID()).takeRetainedValue() as NSArray;
        for spaceDictionary in spaceDictionaryArray {
            let nsdict = spaceDictionary as! NSDictionary;
            let spacesArray = nsdict.value(forKey: "Spaces") as! NSArray;
            for spaceDict in spacesArray {
                let spaceID = (spaceDict as! NSDictionary).value(forKey: "id64") as! SLSSpaceID
                self.currentSpaceIDs.append(spaceID)
                if GlobalViewState.sharedInstance.spaceIDs.contains(self.currentSpaceIDs) && self.currentSpaceIDs.count == GlobalViewState.sharedInstance.spaceIDs.count {
                    continue
                } else if self.currentSpaceIDs.count < GlobalViewState.sharedInstance.spaceIDs.count {
                    // Tell the XPC Service to remove and free any IOSurfaces, which were not cleaned up properly
                    // First, get the difference
                    let unmatchedSpaces = GlobalViewState.sharedInstance.spaceIDs.filter({ elem in
                        return self.currentSpaceIDs.contains(where: { elem2 in return elem2 == elem })
                    })
                    self.xpcQueue.async {
                        try! GlobalViewState.sharedInstance.spaceCaptureServiceConnection.send(message: prepareSpaceIOSurfaceCaptureServiceRequest(requestType: .ScheduleSpaceIDsForRemoval, spaceIDsToBeRemoved: unmatchedSpaces))
                    }
                }
                shouldUpdate = true
            }
        }
        return shouldUpdate
        
    }
    
}
