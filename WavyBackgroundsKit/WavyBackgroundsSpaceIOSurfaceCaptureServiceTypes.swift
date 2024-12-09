//
//  WavyBackgroundsSpaceIOSurfaceCaptureServiceTypes.swift
//  WavyBackgroundsSpaceIOSurfaceCaptureService
//
//  Created by Philipp Remy on 13.11.24.
//

import Foundation

public enum SpaceIOSurfaceCaptureServiceRequestType : Codable, BitwiseCopyable {
    case RequestIOSurfaceForSpaceID
    case UpdateRefreshFPS
    case ToggleShouldIncludeOtherWindows
    case ScheduleSpaceIDsForRemoval
}

public enum SpaceIOSurfaceCaptureServiceResponseType : Codable, BitwiseCopyable {
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

public func prepareSpaceIOSurfaceCaptureServiceRequest(requestType: SpaceIOSurfaceCaptureServiceRequestType, spaceID: SLSSpaceID? = nil, fps: Int? = nil, shouldIncludeOtherWindows: Bool? = nil, spaceIDsToBeRemoved: [SLSSpaceID]? = nil) -> XPCDictionary {
    let request = [
        SpaceIOSurfaceCaptureServiceRequest(requestType: requestType, spaceID: spaceID, fps: fps, shouldIncludeOtherWindows: shouldIncludeOtherWindows, spaceIDsToBeRemoved: spaceIDsToBeRemoved)
    ]
    let xpc_obj = xpc_data_create(request, MemoryLayout<SpaceIOSurfaceCaptureServiceRequest>.stride * request.count)
    var xpc_dict = XPCDictionary()
    xpc_dict["xpcRequest"] = xpc_obj
    return xpc_dict
}

public func decodeToSpaceIOSurfaceCaptureServiceResponse(xpcObj: xpc_object_t) -> SpaceIOSurfaceCaptureServiceResponse? {
    guard let ptr = xpc_data_get_bytes_ptr(xpcObj) else {
        return nil
    }
    let responseObjectDecoded = ptr.load(as: SpaceIOSurfaceCaptureServiceResponse.self)
    return responseObjectDecoded
}

public func decodeToSpaceIOSurfaceCaptureServiceRequest(xpcObj: xpc_object_t) -> SpaceIOSurfaceCaptureServiceRequest? {
    guard let ptr = xpc_data_get_bytes_ptr(xpcObj) else {
        return nil
    }
    let responseObjectDecoded = ptr.load(as: SpaceIOSurfaceCaptureServiceRequest.self)
    return responseObjectDecoded
}
