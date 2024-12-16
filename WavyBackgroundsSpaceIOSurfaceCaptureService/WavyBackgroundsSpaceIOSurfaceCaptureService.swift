//
//  main.swift
//  WavyBackgroundsSpaceIOSurfaceCaptureService
//
//  Created by Philipp Remy on 13.11.24.
//

import XPC

import WavyBackgroundsKit
import IOSurfaceInterceptionKit

@main
class WavyBackgroundsSpaceIOSurfaceCaptureService {
    
    public static func main() {
        // Set up the listener and start listening for connections.
        startListener()
    }
    
}

// Create the listener that receives incoming session requests from clients.
func startListener() {
    do {
        _ = try XPCListener(service: "de.philippremy.WavyBackgroundsSpaceIOSurfaceCaptureService") { request in
            // When a session request arrives, you must either accept or reject it.
            // The listener invokes the closure you specify every time a
            // message is received.
            request.accept(incomingMessageHandler: { (dict: XPCDictionary) in
                guard let xpc_obj = decodeRequestAndPerform(with: dict) else {
                    return encodeNonFatalError()
                }
                return encodeSuccess(xpcObj: xpc_obj)
            }, cancellationHandler: { xpcError in
                exit(0)
            })
        }
        
        // Start the main dispatch queue to begin processing messages.
        dispatchMain()
    } catch {
        print("Failed to create listener, error: \(error)")
    }
}

// The function that performs the work of the service.
func decodeRequestAndPerform(with message: XPCDictionary) -> xpc_object_t? {
    
    guard let requestObject: xpc_object_t = message["xpcRequest"] else {
        print("No value for key 'xpcRequest' found in XPCDictionary!")
        return nil
    }
    
    guard let requestObjectDecoded = decodeToSpaceIOSurfaceCaptureServiceRequest(xpcObj: requestObject) else {
        return nil
    }
    
    switch requestObjectDecoded.requestType {
    case .RequestIOSurfaceForSpaceID:
        guard let ioSurface = WavyBackgroundsSpaceCaptureService.sharedInstance.getIOSurfaceRefForSpaceID(spaceID: requestObjectDecoded.spaceID!) else {
            print("Could not find specified IOSurfaceRef!")
            return nil
        }
        let ioSurfaceObj = IOSurfaceCreateXPCObject(ioSurface)
        IOSurfaceDecrementUseCount(ioSurface)
        return ioSurfaceObj
    case .ToggleShouldIncludeOtherWindows:
        WavyBackgroundsSpaceCaptureService.sharedInstance.toggleCaptureOtherWindows(captureOtherWindows: requestObjectDecoded.shouldIncludeOtherWindows!)
        break
    case .UpdateRefreshFPS:
        WavyBackgroundsSpaceCaptureService.sharedInstance.setInternalRefreshFPS(fps: requestObjectDecoded.fps!)
        break
    case .ScheduleSpaceIDsForRemoval:
        WavyBackgroundsSpaceCaptureService.sharedInstance.handleSpaceIDRemovalRequest(spaceIDs: requestObjectDecoded.spaceIDsToBeRemoved!)
        break
    default:
        break
    }
    
    return nil
}

/*

 To use this service from an app or other process, use XPCSession to establish a connection to the service.
 
    do {
        session = try XPCSession(xpcService: "de.philippremy.WavyBackgroundsSpaceIOSurfaceCaptureService")
    } catch {
        print("Failed to connect to listener, error: \(error)")
    }

 Once you have a connection to the service, create a Codable request and send it to the service.

    do {
        let request = CalculationRequest(firstNumber: 23, secondNumber: 19)
        let reply = try session.sendSync(request)
        let response = try reply.decode(as: CalculationResponse.self)

        DispatchQueue.main.async {
            print("Received response with result: \(response.result)")
        }
    } catch {
        print("Failed to send message or decode reply: \(error.localizedDescription)")
    }

 When you're done using the connection, cancel it by doing the following:
 
    session.cancel(reason: "Done with calculation")

 */

class WavyBackgroundsSpaceCaptureService {
    
    // Shared Instance
    public static let sharedInstance = WavyBackgroundsSpaceCaptureService()

    // Internal Variables
    let mainConnection = SLSMainConnectionID()
    
    // Internal Dictionary
    private var ioSurfaceDictionary: Dictionary<SLSSpaceID, IOSurfaceRef> = [:]
    
    // Settings
    private var refreshDelaySeconds: Float =  1
    private var captureOtherWindows: Bool = true
    
    // Concurrency
    private let internalLock = NSRecursiveLock()
    private let xpcDispatchQueue = DispatchQueue(label: "XPC Queue", qos: .userInteractive, attributes: .concurrent)
    private let refreshDispatchQueue = DispatchQueue(label: "Refresh Queue", qos: .background, attributes: .concurrent)
    
    private init() {
        self.internalRefreshWithDelay()
    }
    
    public func setInternalRefreshFPS(fps: Int) {
        self.refreshDelaySeconds = Float(1) / Float(fps)
    }
    
    public func toggleCaptureOtherWindows(captureOtherWindows: Bool) {
        self.captureOtherWindows = captureOtherWindows
    }
    
}

extension WavyBackgroundsSpaceCaptureService {
    
    private func internalRefreshWithDelay() {
        let dispatchitem = DispatchWorkItem(block: {
            while true {
                {
                    let start = DispatchTime.now()
                    var temp_dict: Dictionary<SLSSpaceID, IOSurfaceRef> = [:]
                    let temp_lock = NSRecursiveLock()
                    let spaceIDs = self.fetchAllSpaceIDs()
                    DispatchQueue.concurrentPerform(iterations: spaceIDs.count, execute: { index in
                        autoreleasepool {
                            switch self.captureOtherWindows {
                            case true:
                                Thread.current.threadDictionary["spaceID"] = NSNumber(value: spaceIDs[index])
                                let cgImageArrayMustBeFreed = SLSHWCaptureSpace(self.mainConnection, spaceIDs[index], true).takeRetainedValue()
                                guard let ioSurface = IOInterceptionManager.sharedInstance.getIOSurfaceForSpaceIDAndRemove(spaceID: spaceIDs[index]) else {
                                    CFArrayRemoveAllValues((cgImageArrayMustBeFreed as! CFMutableArray))
                                    return
                                }
                                temp_lock.lock()
                                temp_dict[spaceIDs[index]] = ioSurface
                                temp_lock.unlock()
                                return
                            case false:
                                Thread.current.threadDictionary["spaceID"] = NSNumber(value: spaceIDs[index])
                                let cgImageArrayMustBeFreed = SLSHWCaptureProcessWindowsInSpaceIncludeDesktop(self.mainConnection, spaceIDs[index], true, 0).takeRetainedValue()
                                guard let ioSurface = IOInterceptionManager.sharedInstance.getIOSurfaceForSpaceIDAndRemove(spaceID: spaceIDs[index]) else {
                                    CFArrayRemoveAllValues((cgImageArrayMustBeFreed as! CFMutableArray))
                                    return
                                }
                                temp_lock.lock()
                                temp_dict[spaceIDs[index]] = ioSurface
                                temp_lock.unlock()
                                CFArrayRemoveAllValues((cgImageArrayMustBeFreed as! CFMutableArray))
                                return
                            }
                        }
                    })
                    self.internalLock.lock()
                    self.ioSurfaceDictionary = temp_dict
                    self.internalLock.unlock()
                    let end = DispatchTime.now()
                    let nanoTime = end.uptimeNanoseconds - start.uptimeNanoseconds
                    let timeInterval = Double(nanoTime) / 1_000_000_000
                    if timeInterval > Double(self.refreshDelaySeconds) {
                        
                    } else {
                        Thread.sleep(forTimeInterval: TimeInterval(Double(self.refreshDelaySeconds) - timeInterval))
                    }
                }()
            }
        })
        self.refreshDispatchQueue.async(execute: dispatchitem)
    }
    
    private func fetchAllSpaceIDs() -> [SLSSpaceID] {
        var spaceArr: [SLSSpaceID] = [];
        let spaceDictionaryArray = SLSCopyManagedDisplaySpaces(SLSMainConnectionID()).takeRetainedValue() as NSArray;
        for spaceDictionary in spaceDictionaryArray {
            let nsdict = spaceDictionary as! NSDictionary;
            let spacesArray = nsdict.value(forKey: "Spaces") as! NSArray;
            for spaceDict in spacesArray {
                spaceArr.append((spaceDict as! NSDictionary).value(forKey: "id64") as! SLSSpaceID)
            }
        }
        return spaceArr
    }
    
}

extension WavyBackgroundsSpaceCaptureService {
    
    public func getIOSurfaceRefForSpaceID(spaceID: SLSSpaceID) -> IOSurfaceRef? {
        self.xpcDispatchQueue.asyncAndWait {
            self.internalLock.lock()
            guard let ioSurface = self.ioSurfaceDictionary[spaceID] else {
                self.internalLock.unlock()
                print("Could not fetch IOSurface for SpaceID '\(spaceID)'. Either the Space does not exist or the IOSurface interception was not successful.")
                return nil
            }
            self.internalLock.unlock()
            return ioSurface
        }
    }
    
    public func handleSpaceIDRemovalRequest(spaceIDs: [SLSSpaceID]) {
        for space in spaceIDs {
            self.ioSurfaceDictionary.removeValue(forKey: space)
            IOInterceptionManager.sharedInstance.removeIOSurfaceForSpaceIDIfExists(spaceID: space)
        }
    }
    
}
