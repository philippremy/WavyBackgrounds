//
//  WavyBackgrounds.h
//  WavyBackgrounds
//
//  Created by Philipp Remy on 10/31/23.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <AVFoundation/AVFoundation.h>

@interface WavyBackgrounds : NSObject

NSWindow* startScreen(NSScreen *screen, NSURL *videoURL);

@end
