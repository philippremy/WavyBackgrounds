//
//  WavyBackgrounds.m
//  WavyBackgrounds
//
//  Created by Philipp Remy on 10/31/23.
//

#import "WavyBackgrounds.h"
#import <AppKit/AppKit.h>
#import <AVFoundation/AVFoundation.h>

@implementation WavyBackgrounds

NSWindow* startScreen(NSScreen *screen, NSURL *videoURL) {
    id app = [NSApplication sharedApplication];
    [app setActivationPolicy:NSApplicationActivationPolicyRegular];

    NSRect mainFrame = [screen frame];

    id window =
    [[NSWindow alloc] initWithContentRect:mainFrame
                                styleMask:NSWindowStyleMaskUnifiedTitleAndToolbar
                                  backing:NSBackingStoreBuffered
                                    defer:NO];
    [window makeKeyAndOrderFront:nil];
    [(NSWindow*)window setLevel:kCGDesktopWindowLevel - 1];
    
    NSView *backgroundView = [[NSView alloc] initWithFrame: mainFrame];
    [window setContentView: backgroundView];

    AVPlayer *player = [AVPlayer playerWithURL:videoURL];
    AVPlayerLayer *playerLayer = [AVPlayerLayer playerLayerWithPlayer:player];
    [playerLayer setVideoGravity: AVLayerVideoGravityResizeAspectFill];
    [backgroundView setLayer: playerLayer];
    [backgroundView setWantsLayer: YES];
    [player play];

    
    [app activateIgnoringOtherApps:YES];
    [app run];
    
    return window;
    
}


@end
