#![allow(non_snake_case)]
// Prevents additional console window on Windows in release, DO NOT REMOVE!!
#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

use libDynamicWallpapaper::id_matches_current_screen;
use tauri::{AppHandle, CustomMenuItem, Manager, RunEvent, SystemTray, SystemTrayEvent, SystemTrayMenu, SystemTrayMenuItem, SystemTraySubmenu, WindowBuilder, WindowUrl};
use libResourceManager::{check_for_local, delete_local_resource, get_full_database, LocalSaveCheck, WallpaperVideoEntry};

#[tauri::command]
fn delete_local(identifier: String) -> bool {
    return delete_local_resource(identifier);
}

#[tauri::command]
fn get_full_database_command(app_handle: AppHandle) -> Vec<WallpaperVideoEntry>{
    let vec: Vec<WallpaperVideoEntry> = get_full_database(&app_handle).unwrap();
    let tray_menu = build_tray_menu(app_handle.clone());
    app_handle.tray_handle().set_menu(tray_menu).unwrap();

    return vec;
}

#[tauri::command]
async fn download_file(identifier: String, url: String, app_handle: AppHandle) -> Option<String> {
    return libResourceManager::download(identifier, url, app_handle.clone(), app_handle.clone(), app_handle.clone()).await;
}

#[tauri::command]
fn check_if_local_exists(identifier: String) -> LocalSaveCheck {
    return check_for_local(identifier);
}

#[tauri::command]
fn apply_to_screen(identifier: String) {
    let window_identifier = libDynamicWallpapaper::apply_to_screen(identifier);
    unsafe { WINDOW_VEC.push(window_identifier); };
}

#[tauri::command]
fn remove_all() {
    unsafe {
        WINDOW_VEC.retain(|window_identfier| {
            libDynamicWallpapaper::close_window(window_identfier.to_string());
            return false;
        });
    }
}

#[tauri::command]
fn remove_current_space() {
    unsafe {
        WINDOW_VEC.retain(|window_identfier| {
            let remove_this = libDynamicWallpapaper::close_window_on_screen(window_identfier.to_string());
            return remove_this;
        });
    }
}

static mut WINDOW_VEC: Vec<String> = vec![];

fn main() {

    let tray = SystemTray::new().with_menu(build_tray_menu_once()).with_tooltip("WavyBackgrounds");

    tauri::Builder::default()
        .system_tray(tray)
        .invoke_handler(tauri::generate_handler![get_full_database_command, download_file, delete_local, check_if_local_exists, apply_to_screen, remove_all, remove_current_space])
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
                            WINDOW_VEC.retain(|window_identfier| {
                                libDynamicWallpapaper::close_window(window_identfier.to_string());
                                return false;
                            });
                        }
                    }
                    else if id.as_str() == "close_background_active_space" {
                        unsafe {
                            WINDOW_VEC.retain(|window_identfier| {
                                let remove_this = libDynamicWallpapaper::close_window_on_screen(window_identfier.to_string());
                                return remove_this;
                            });
                        }
                    }
                    else if id.as_str() == "pause_background_active_space" {
                        unsafe {
                            for id in &WINDOW_VEC {
                                if id_matches_current_screen(id.to_string()) {
                                    libDynamicWallpapaper::pause_video_on_screen_with_id(id.to_string());
                                }
                            }
                        }
                    }
                    else if id.as_str() == "pause_backgrounds" {
                        unsafe {
                            for id in &WINDOW_VEC {
                                libDynamicWallpapaper::pause_video_on_screen_with_id(id.to_string());
                            }
                        }
                    }
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


fn build_tray_menu(app_handle: AppHandle) -> SystemTrayMenu {
    let vec: Vec<WallpaperVideoEntry> = get_full_database(&app_handle).unwrap();
    let mwb_menu = CustomMenuItem::new("main_window_show", "Bring back Application Window");
    let mut allsubmenu_menu = SystemTrayMenu::new();
    for entry in vec.clone() {
        let saved = check_for_local(entry.identifier.clone());
        if saved.is_saved {
            allsubmenu_menu = allsubmenu_menu.add_item(CustomMenuItem::new(entry.identifier.clone(), entry.friendly_name.clone()));
        }
    }
    let favorite_menu = SystemTrayMenu::new();
    let all_submenu = SystemTraySubmenu::new("All cached videos", allsubmenu_menu);
    let favorite_submenu = SystemTraySubmenu::new("Favourite videos", favorite_menu);

    SystemTrayMenu::new()
        .add_item(mwb_menu)
        .add_native_item(SystemTrayMenuItem::Separator)
        .add_submenu(favorite_submenu)
        .add_submenu(all_submenu)
        .add_native_item(SystemTrayMenuItem::Separator)
        .add_item(CustomMenuItem::new("close_backgrounds", "Remove all dynamic wallpapers"))
        .add_item(CustomMenuItem::new("close_background_active_space", "Remove dynamic wallpapers on active space"))
        .add_native_item(SystemTrayMenuItem::Separator)
        .add_item(CustomMenuItem::new("pause_backgrounds", "Pause all dynamic wallpapers"))
        .add_item(CustomMenuItem::new("pause_background_active_space", "Pause dynamic wallpapers on active space"))
}

fn build_tray_menu_once() -> SystemTrayMenu {
    let mwb_menu = CustomMenuItem::new("main_window_show", "Bring back Application Window");
    let allsubmenu_menu = SystemTrayMenu::new();
    let favorite_menu = SystemTrayMenu::new();
    let all_submenu = SystemTraySubmenu::new("All cached videos", allsubmenu_menu);
    let favorite_submenu = SystemTraySubmenu::new("Favourite videos", favorite_menu);

    SystemTrayMenu::new()
        .add_item(mwb_menu)
        .add_native_item(SystemTrayMenuItem::Separator)
        .add_submenu(favorite_submenu)
        .add_submenu(all_submenu)
        .add_native_item(SystemTrayMenuItem::Separator)
        .add_item(CustomMenuItem::new("close_backgrounds", "Remove all dynamic wallpapers"))
        .add_item(CustomMenuItem::new("close_background_active_space", "Remove dynamic wallpapers on active space"))
}