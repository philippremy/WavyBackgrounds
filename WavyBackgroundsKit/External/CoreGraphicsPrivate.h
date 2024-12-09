//
//  CoreGraphicsPrivate.h
//  WavyBackgrounds
//
//  Created by Philipp Remy on 05.11.24.
//

#ifndef CoreGraphicsPrivate_h
#define CoreGraphicsPrivate_h

#include <WavyBackgroundsKit/ExternalTypes.h>

CGS_EXTERN CGSDisplayID CGSGetDisplayForUUID(CGSDisplayName uuid);
CGS_EXTERN CGSSpaceRegion CGSSpaceCopyManagedShape(SLSConnectionID conn, SLSSpaceID space);
CGS_EXTERN CGSError CGSGetRegionBounds(CGSSpaceRegion region, CGSRectInOut rect);
CGS_EXTERN CGSDisplayName CGSCopyManagedDisplayForSpace(SLSConnectionID conn, SLSSpaceID space);

#endif /* CoreGraphicsPrivate_h */
