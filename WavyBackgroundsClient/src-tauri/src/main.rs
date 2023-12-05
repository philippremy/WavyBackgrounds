#![feature(panic_info_message)]
#![feature(panic_update_hook)]
#![allow(non_snake_case)]
// Prevents additional console window on Windows in release, DO NOT REMOVE!!
#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

use icrate::AppKit::NSWindow;
use icrate::objc2::rc::Id;
use tauri::{AppHandle, CustomMenuItem, Manager, RunEvent, SystemTray, SystemTrayEvent, SystemTrayMenu, SystemTrayMenuItem, SystemTraySubmenu, WindowBuilder, WindowUrl};
use libResourceManager::{chec_for_local, delete_local_resource, get_full_database, LocalSaveCheck, WallpaperVideoEntry};
use libVisualPanic::ErrorHandlingOption;

#[tauri::command]
fn delete_local(identifier: String) -> bool {
    return delete_local_resource(identifier);
}

#[tauri::command]
fn get_full_database_command(app_handle: AppHandle) -> Vec<WallpaperVideoEntry>{
    let vec: Vec<WallpaperVideoEntry> = get_full_database(&app_handle).expect_visual("Failed to get database. Maybe the file is corrupt or we are running a non-Sonoma System?", &app_handle);
    let mwb_menu = CustomMenuItem::new("main_window_show", "Bring back Application Window");
    let mut allsubmenu_menu = SystemTrayMenu::new();
    for entry in vec.clone() {
        let saved = chec_for_local(entry.identifier.clone());
        if saved.is_saved {
            allsubmenu_menu = allsubmenu_menu.add_item(CustomMenuItem::new(entry.identifier.clone(), entry.friendly_name.clone()));
        }
    }
    let favorite_menu = SystemTrayMenu::new();
    let all_submenu = SystemTraySubmenu::new("All cached videos", allsubmenu_menu);
    let favorite_submenu = SystemTraySubmenu::new("Favourite videos", favorite_menu);

    let tray_menu = SystemTrayMenu::new()
        .add_item(mwb_menu)
        .add_native_item(SystemTrayMenuItem::Separator)
        .add_submenu(favorite_submenu)
        .add_submenu(all_submenu)
        .add_native_item(SystemTrayMenuItem::Separator)
        .add_item(CustomMenuItem::new("close_backgrounds", "Remove all dynamic wallpapers"));
        // Currently produces a segfault.
        //.add_item(CustomMenuItem::new("close_background_active_space", "Remove dynamic wallpapers on active space"))

    app_handle.tray_handle().set_menu(tray_menu).unwrap();

    return vec;
}

#[tauri::command]
async fn download_file(identifier: String, url: String, app_handle: AppHandle) -> Option<String> {
    return libResourceManager::download(identifier, url, app_handle.clone(), app_handle.clone(), app_handle.clone()).await;
}

#[tauri::command]
fn check_if_local_exists(identifier: String) -> LocalSaveCheck {
    return chec_for_local(identifier);
}

#[tauri::command]
fn apply_to_screen(identifier: String) {
    let window = libDynamicWallpapaper::apply_to_screen(identifier);
    unsafe { WINDOW_VEC.push(window); };
}

#[tauri::command]
fn remove_all() {
    unsafe {
        WINDOW_VEC.retain(|window| {
            libDynamicWallpapaper::close_window(window);
            return true;
        });
    }
}

static mut WINDOW_VEC: Vec<Id<NSWindow>> = vec![];

fn main() {

    let mwb_menu = CustomMenuItem::new("main_window_show", "Bring back Application Window");
    let allsubmenu_menu = SystemTrayMenu::new();
    let favorite_menu = SystemTrayMenu::new();
    let all_submenu = SystemTraySubmenu::new("All cached videos", allsubmenu_menu);
    let favorite_submenu = SystemTraySubmenu::new("Favourite videos", favorite_menu);

    let tray_menu = SystemTrayMenu::new()
        .add_item(mwb_menu)
        .add_native_item(SystemTrayMenuItem::Separator)
        .add_submenu(favorite_submenu)
        .add_submenu(all_submenu)
        .add_native_item(SystemTrayMenuItem::Separator)
        .add_item(CustomMenuItem::new("close_backgrounds", "Remove all dynamic wallpapers"));
        // Currently produces a segfault.
        //.add_item(CustomMenuItem::new("close_background_active_space", "Remove dynamic wallpapers on active space"));

    let tray = SystemTray::new().with_menu(tray_menu).with_tooltip("WavyBackgrounds");

    tauri::Builder::default()
        .system_tray(tray)
        .invoke_handler(tauri::generate_handler![get_full_database_command, download_file, delete_local, check_if_local_exists, apply_to_screen, remove_all])
        .setup(|_app| {
            Ok(())
        })
        .on_system_tray_event(|ah, ev| {
            match ev {
                SystemTrayEvent::MenuItemClick { id, .. } => {
                    if id.as_str() == "main_window_show" {
                        if ah.get_window("mainUI").is_none() {
                            WindowBuilder::new(ah, "mainUI", WindowUrl::App("index.html".into()))
                                .title("WavyBackgrounds")
                                .center()
                                .inner_size(700.0, 600.0)
                                .resizable(true)
                                .build()
                                .unwrap()
                                .show()
                                .unwrap();
                        }
                    }
                    else if id.as_str() == "close_backgrounds" {
                        unsafe {
                            unsafe {
                                WINDOW_VEC.retain(|window| {
                                    libDynamicWallpapaper::close_window(window);
                                    return true;
                                });
                            }
                        }
                    }
                   /* Currently produces a segfault.
                    else if id.as_str() == "close_background_active_space" {
                        unsafe {
                            WINDOW_VEC.retain(|window| {
                                return !libDynamicWallpapaper::close_window_on_screen(window.clone());
                            });
                        }
                    }
                    */
                    else {
                        apply_to_screen(id);
                    }
                }
                SystemTrayEvent::LeftClick { .. } => {}
                SystemTrayEvent::RightClick { .. } => {}
                SystemTrayEvent::DoubleClick { .. } => {}
                _ => {}
            }
        })
        .build(tauri::generate_context!())
        .expect("err")
        .run(|_ah, ev| {
            match ev {
                RunEvent::Exit => {}
                RunEvent::ExitRequested { api, .. } => {
                    api.prevent_exit();
                }
                RunEvent::WindowEvent { .. } => {}
                RunEvent::Ready => {}
                RunEvent::Resumed => {}
                RunEvent::MainEventsCleared => {}
                _ => {}
            }
        })
}
