//
//  ExternalTypes.h
//  WavyBackgrounds
//
//  Created by Philipp Remy on 05.11.24.
//

#ifndef ExternalTypes_h
#define ExternalTypes_h

#import <CoreFoundation/CoreFoundation.h>
#import <CoreGraphics/CoreGraphics.h>

#define SLS_EXTERN extern
#define CGS_EXTERN extern
#define HIS_EXTERN extern

typedef int SLSConnectionID;
typedef int SLSSpaceID;
typedef CFArrayRef SLSSpaceCaptureArray;
typedef CFArrayRef SLSSpaceArray;
typedef CFStringRef SLSSpaceName;
typedef CFArrayRef SLSWindowArray;
typedef int SLSSpaceType;
typedef int SLSEventID;
typedef void* SLSEventContext;
typedef void* SLSEventData;
typedef size_t SLSEventDataLength;
typedef CGError* SLSError;
typedef void (*SLSEventCallback)(SLSEventID event, SLSEventData data, SLSEventDataLength data_length, SLSEventContext context, SLSConnectionID conn);

typedef CFDictionaryRef CGSImageDataDictionary;
typedef CGError CGSError;
typedef CGRect* CGSRectInOut;
typedef CFStringRef CGSDisplayName;
typedef int CGSDisplayID;
typedef CFTypeRef CGSSpaceRegion;

#endif /* ExternalTypes_h */
