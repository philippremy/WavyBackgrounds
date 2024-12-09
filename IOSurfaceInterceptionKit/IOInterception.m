//
//  IOInterception.m
//  IOSurfaceInterceptionKit
//
//  Created by Philipp Remy on 13.11.24.
//

#import <IOSurfaceInterceptionKit-Swift.h>
#import "IOInterception.h"

IOSurfaceRef IOSurfaceLookupFromMachPortIntercepted(mach_port_t port) {
    IOSurfaceRef ioSurface = IOSurfaceLookupFromMachPort(port);
    CFRetain(ioSurface);
    NSNumber* spaceID = [[[NSThread currentThread] threadDictionary] valueForKey:@"spaceID"];
    if (spaceID == NULL) {
        CFRelease(ioSurface);
        return ioSurface;
    }
    [[IOInterceptionManager sharedInstance] addIOSurfaceForSpaceIDWithSpaceID:[spaceID intValue] ioSurface:ioSurface];
    // Make sure to release the IOSurface, so WindowServer does not explode.
    CFRelease(ioSurface);
    return ioSurface;
}
