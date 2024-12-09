//
//  SkyLight.h
//  WavyBackgrounds
//
//  Created by Philipp Remy on 05.11.24.
//

#ifndef SkyLight_h
#define SkyLight_h

#import <WavyBackgroundsKit/ExternalTypes.h>

SLS_EXTERN SLSConnectionID SLSMainConnectionID(void);
SLS_EXTERN SLSSpaceID SLSGetActiveSpace(SLSConnectionID conn);
SLS_EXTERN SLSSpaceCaptureArray SLSHWCaptureSpace(SLSConnectionID conn, SLSSpaceID space, bool includeDesktop);
SLS_EXTERN SLSSpaceCaptureArray SLSHWCaptureProcessWindowsInSpaceIncludeDesktop(SLSConnectionID conn, SLSSpaceID space, bool includeDesktop, int unknown);
SLS_EXTERN SLSSpaceArray SLSCopyManagedDisplaySpaces(SLSConnectionID conn);
SLS_EXTERN SLSSpaceName SLSSpaceCopyName(SLSConnectionID conn, SLSSpaceID space);
SLS_EXTERN void SLSSpaceSetName(SLSConnectionID conn, SLSSpaceID space, SLSSpaceName uuid);
SLS_EXTERN void SLSMoveWindowsToManagedSpace(SLSConnectionID conn, SLSWindowArray windowList, SLSSpaceID space);
SLS_EXTERN SLSError SLSRegisterConnectionNotifyProc(SLSConnectionID conn, SLSEventCallback callback, SLSEventID event, SLSEventContext context);

#endif /* SkyLight_h */
