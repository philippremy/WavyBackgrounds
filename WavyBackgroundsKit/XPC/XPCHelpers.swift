//
//  XPCHelpers.swift
//  WavyBackgroundsKit
//
//  Created by Philipp Remy on 16.12.24.
//

import Foundation

// MARK: SpaceIOSurfaceCaptureService Helpers

// Decoders

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

// Encoders

public func encodeSpaceIOSurfaceCaptureServiceRequest(requestType: SpaceIOSurfaceCaptureServiceRequestType, spaceID: SLSSpaceID? = nil, fps: Int? = nil, shouldIncludeOtherWindows: Bool? = nil, spaceIDsToBeRemoved: [SLSSpaceID]? = nil) -> XPCDictionary {
    let request = [
        SpaceIOSurfaceCaptureServiceRequest(requestType: requestType, spaceID: spaceID, fps: fps, shouldIncludeOtherWindows: shouldIncludeOtherWindows, spaceIDsToBeRemoved: spaceIDsToBeRemoved)
    ]
    let xpc_obj = xpc_data_create(request, MemoryLayout<SpaceIOSurfaceCaptureServiceRequest>.stride * request.count)
    var xpc_dict = XPCDictionary()
    xpc_dict["xpcRequest"] = xpc_obj
    return xpc_dict
}

public func encodeNonFatalError() -> XPCDictionary {
    let temp_arr: [SpaceIOSurfaceCaptureServiceResponse] = [
        SpaceIOSurfaceCaptureServiceResponse(requestType: .Error, error: "Non-fatal Error occured. Probably tried to fetch an IOSurface while the Manager was still initializing.")
    ]
    let xpc_obj = xpc_data_create(temp_arr, MemoryLayout<SpaceIOSurfaceCaptureServiceResponse>.stride * temp_arr.count)
    var xpc_dict = XPCDictionary()
    xpc_dict["xpcResponse"] = xpc_obj
    return xpc_dict
}

public func encodeSuccess(xpcObj: xpc_object_t) -> XPCDictionary {
    let temp_arr: [SpaceIOSurfaceCaptureServiceResponse] = [
        SpaceIOSurfaceCaptureServiceResponse(requestType: .Ok, error: nil)
    ]
    let xpc_obj = xpc_data_create(temp_arr, MemoryLayout<SpaceIOSurfaceCaptureServiceResponse>.stride * temp_arr.count)
    var xpc_dict = XPCDictionary()
    xpc_dict["xpcResponse"] = xpc_obj
    xpc_dict["ioSurfaceXPCObject"] = xpcObj
    return xpc_dict
}
