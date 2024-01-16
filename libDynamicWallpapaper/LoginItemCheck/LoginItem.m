//
//  LoginItem.m
//  LoginItem
//
//  Created by Philipp Remy on 1/16/24.
//

#import "LoginItem.h"
#import <Cocoa/Cocoa.h>

@implementation LoginItem

int64_t WasLaunchedAsLoginOrResumeItem(void) {
  ProcessSerialNumber psn = {0, kCurrentProcess};
  ProcessInfoRec info = {};
  info.processInfoLength = sizeof(info);

// GetProcessInformation has been deprecated since macOS 10.9, but there is no
// replacement that provides the information we need. See
// https://crbug.com/650854.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
  if (GetProcessInformation(&psn, &info) == noErr) {
#pragma clang diagnostic pop
    ProcessInfoRec parent_info = {};
    parent_info.processInfoLength = sizeof(parent_info);
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    if (GetProcessInformation(&info.processLauncher, &parent_info) == noErr) {
#pragma clang diagnostic pop
        if(parent_info.processSignature == 'lgnw') {
            return 0;
        };
    }
  }
  return 1;
}

@end
