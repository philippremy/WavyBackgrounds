//
//  WavyBackgroundsKit.h
//  WavyBackgroundsKit
//
//  Created by Philipp Remy on 13.11.24.
//

#import <Foundation/Foundation.h>
#import <CoreFoundation/CoreFoundation.h>
#import <IOSurface/IOSurface.h>

//! Project version number for WavyBackgroundsKit.
FOUNDATION_EXPORT double WavyBackgroundsKitVersionNumber;

//! Project version string for WavyBackgroundsKit.
FOUNDATION_EXPORT const unsigned char WavyBackgroundsKitVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <WavyBackgroundsKit/PublicHeader.h>

#include <WavyBackgroundsKit/CoreGraphicsPrivate.h>
#include <WavyBackgroundsKit/HIServices.h>
#include <WavyBackgroundsKit/SkyLight.h>

// Cheat! We need to release the IOSurface, but Swift is dumb
void unsafelyReleaseIOSurface(IOSurfaceRef ioSurface) {
    CFRelease(ioSurface);
}
