//
//  IOInterception.h
//  WavyBackgrounds
//
//  Created by Philipp Remy on 13.11.24.
//

#ifndef IOInterception_h
#define IOInterception_h

#import <IOSurface/IOSurface.h>
#import <Foundation/Foundation.h>

IOSurfaceRef IOSurfaceLookupFromMachPortIntercepted(mach_port_t port);

#define DYLD_INTERPOSE(_replacement,_replacee) \
   __attribute__((used)) static struct{ const void* replacement; const void* replacee; } _interpose_##_replacee \
            __attribute__ ((section ("__DATA,__interpose"))) = { (const void*)(unsigned long)&_replacement, (const void*)(unsigned long)&_replacee };

DYLD_INTERPOSE(IOSurfaceLookupFromMachPortIntercepted, IOSurfaceLookupFromMachPort);

#endif /* IOInterception_h */
