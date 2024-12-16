//
//  IOInterceptionManager.swift
//  IOSurfaceInterceptionKit
//
//  Created by Philipp Remy on 13.11.24.
//

import Foundation
import IOSurface

import WavyBackgroundsKit

@objc public class IOInterceptionManager : NSObject {
    
    // Singleton accessor
    // SAFETY: Concurrency-safe, because class is internally synchronized (NSLock)
    @objc nonisolated(unsafe) public static let sharedInstance = IOInterceptionManager()
    
    // Public Members
    public let instanceLock = NSLock()
    
    // Private Members
    private var ioSurfaceDictionary: Dictionary<SLSSpaceID, IOSurfaceRef> = [:]
    
    @objc public func addIOSurfaceForSpaceID(spaceID: SLSSpaceID, ioSurface: IOSurfaceRef) {
        self.instanceLock.lock()
        self.ioSurfaceDictionary[spaceID] = ioSurface
        self.instanceLock.unlock()
    }
    
    public func getIOSurfaceForSpaceIDAndRemove(spaceID: SLSSpaceID) -> IOSurfaceRef? {
        self.instanceLock.lock()
        guard let ioSurface = self.ioSurfaceDictionary.removeValue(forKey: spaceID) else {
            self.instanceLock.unlock()
            return nil
        }
        self.instanceLock.unlock()
        return ioSurface
    }
    
    public func removeIOSurfaceForSpaceIDIfExists(spaceID: SLSSpaceID) {
        self.instanceLock.lock()
        self.ioSurfaceDictionary.removeValue(forKey: spaceID)
        self.instanceLock.unlock()
    }
    
}
