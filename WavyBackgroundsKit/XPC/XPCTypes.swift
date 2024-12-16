//
//  XPCTypes.swift
//  WavyBackgroundsKit
//
//  Created by Philipp Remy on 16.12.24.
//

import Foundation

// MARK: SpaceIOSurfaceCaptureService Types

public enum SpaceIOSurfaceCaptureServiceRequestType : Codable {
    case RequestIOSurfaceForSpaceID
    case UpdateRefreshFPS
    case ToggleShouldIncludeOtherWindows
    case ScheduleSpaceIDsForRemoval
}

public enum SpaceIOSurfaceCaptureServiceResponseType : Codable {
    case Error
    case Ok
}

public struct SpaceIOSurfaceCaptureServiceRequest : Codable {
    public let requestType: SpaceIOSurfaceCaptureServiceRequestType
    public let spaceID: SLSSpaceID?
    public let fps: Int?
    public let shouldIncludeOtherWindows: Bool?
    public let spaceIDsToBeRemoved: [SLSSpaceID]?
    
    public init(requestType: SpaceIOSurfaceCaptureServiceRequestType, spaceID: SLSSpaceID?, fps: Int?, shouldIncludeOtherWindows: Bool?, spaceIDsToBeRemoved: [SLSSpaceID]?) {
        self.requestType = requestType
        self.spaceID = spaceID
        self.fps = fps
        self.shouldIncludeOtherWindows = shouldIncludeOtherWindows
        self.spaceIDsToBeRemoved = spaceIDsToBeRemoved
    }
}

public struct SpaceIOSurfaceCaptureServiceResponse : Codable {
    public let requestType: SpaceIOSurfaceCaptureServiceResponseType
    public let error: String?
    
    public init(requestType: SpaceIOSurfaceCaptureServiceResponseType, error: String?) {
        self.requestType = requestType
        self.error = error
    }
}

// MARK: WavyBackgroundsService Types

public enum WavyBackgroundsServiceRequestType : Codable {
    case AddDynamicBackgroundToSpace
}

public enum WavyBackgroundsServiceResponseType : Codable {
    case Error
    case Ok
}
