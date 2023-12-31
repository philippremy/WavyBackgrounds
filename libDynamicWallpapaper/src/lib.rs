#![allow(non_snake_case)]
#![feature(const_async_blocks)]
#![feature(type_alias_impl_trait)]

use icrate::AppKit::{NSBackingStoreBuffered, NSScreen, NSView, NSWindow, NSWindowStyleMaskUnifiedTitleAndToolbar, NSUserInterfaceItemIdentification, NSApp};
use icrate::objc2::{class, ClassType, msg_send};
use icrate::objc2::rc::Id;
use std::borrow::Borrow;
use std::ptr::NonNull;
use icrate::Foundation::{NSString, NSURL};
use icrate::objc2::runtime::AnyObject;

unsafe fn get_current_screen() -> Id<NSScreen> {
    return NSScreen::mainScreen().unwrap();
}

pub fn close_window(window_identifier: String) {
    unsafe {
        let nsapp = NSApp.unwrap();
        for open_window in nsapp.windows() {
            match open_window.identifier() {
                Some(ident) => {
                    println!("{}", ident.to_string());
                    if ident.to_string() == window_identifier {
                        open_window.close();
                    }
                },
                None => {},
            }
        }
    }
}

pub fn close_window_on_screen(window_identifier: String) -> bool {
    unsafe {
        let mut remove = true;
        let nsapp = NSApp.unwrap();
        for open_window in nsapp.windows() {
            match open_window.identifier() {
                Some(ident) => {
                    println!("{}", ident.to_string());
                    if ident.to_string() == window_identifier {
                        if open_window.isOnActiveSpace() {
                            remove = false;
                            open_window.close();
                            return remove;
                        }
                    }
                },
                None => {},
            }
        }
        return remove;
    }
}

static mut FRAME_COUNT: u64 = 0;

pub fn apply_to_screen(identifier: String) -> String {

    let file_path = libResourceManager::get_file_path(identifier.clone());

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
        // BRUDER FUCKING FINALLY! WAS SOLL DAS DIGGA SIEHE ZEILE DRUNTER BRUDIIIII
        background_window.setReleasedWhenClosed(false);
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

        // We successfully created a Window, lets increase this.
        FRAME_COUNT += 1;

        let mut window_identfier = FRAME_COUNT.to_string();
        window_identfier.push_str("_");
        window_identfier.push_str(identifier.clone().as_str());
        let non_null_str = window_identfier.as_mut_ptr() as *mut i8;
        let identifier_alloc = NSString::alloc().unwrap();
        let identifier_ns_str = NSString::initWithUTF8String(Some(identifier_alloc), NonNull::new(non_null_str).unwrap()).unwrap();
        
        // Set a unique identifier!
        background_window.setIdentifier(Some(&identifier_ns_str));

        return window_identfier;
    };
}