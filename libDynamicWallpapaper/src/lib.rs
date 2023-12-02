#![allow(non_snake_case)]

use icrate::AppKit::{NSBackingStoreBuffered, NSScreen, NSView, NSWindow, NSWindowStyleMaskUnifiedTitleAndToolbar};
use icrate::objc2::{class, ClassType, msg_send};
use icrate::objc2::rc::Id;
use std::borrow::Borrow;
use icrate::Foundation::{NSString, NSURL};
use icrate::objc2::runtime::AnyObject;

unsafe fn get_current_screen() -> Id<NSScreen> {
    return NSScreen::mainScreen().unwrap();
}

pub fn close_window(window: Id<NSWindow>) {
    unsafe { window.close(); };
}

/* Currently producing a segfault.
pub fn close_window_on_screen(window: Id<NSWindow>) -> bool {
    let mut remove = false;
    unsafe {
        if window.isOnActiveSpace() {
            remove = true;
            window.close();
        }
    }
    return remove;
}
*/

pub fn apply_to_screen(identifier: String) -> Id<NSWindow> {

    let file_path = libResourceManager::get_file_path(identifier);

    unsafe {
        let screen = get_current_screen();
        let frame = screen.frame();
        let background_window_alloc = NSWindow::alloc().unwrap();
        let background_window = NSWindow::initWithContentRect_styleMask_backing_defer(
            Some(background_window_alloc),
            frame,
            NSWindowStyleMaskUnifiedTitleAndToolbar,
            NSBackingStoreBuffered,
            false
        );
        background_window.makeKeyAndOrderFront(None);
        background_window.setLevel(-2147483628 + 15);
        let view_alloc = NSView::alloc().unwrap();
        let view = NSView::initWithFrame(Some(view_alloc), frame);
        background_window.setContentView(Some(view.borrow()));

        let video_url_alloc = NSURL::alloc().unwrap();
        let file_ns_string = NSString::from_str(file_path.as_str());
        let video_url = NSURL::initFileURLWithPath(Some(video_url_alloc), &*file_ns_string);

        let video_gravity_string = NSString::from_str("AVLayerVideoGravityResizeAspectFill");

        let av_player_class = class!(AVPlayer);
        let av_player: &AnyObject = msg_send![av_player_class, playerWithURL: &*video_url];
        let av_playerlayer_class = class!(AVPlayerLayer);
        let av_playerlayer: &AnyObject = msg_send![av_playerlayer_class, playerLayerWithPlayer: av_player];
        let _: () = msg_send![av_playerlayer, setVideoGravity: &*video_gravity_string];
        let _: () = msg_send![&view, setLayer: av_playerlayer];
        let _: () = msg_send![&view, setWantsLayer: true];
        let _: () = msg_send![&*av_player, play];
        background_window.setCollectionBehavior(16);

        return background_window;
    };
}