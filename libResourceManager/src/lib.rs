#![allow(unused_variables, dead_code, non_snake_case)]

use std::fs::{OpenOptions};
use std::io::{BufReader, Cursor, Write};
use std::path::{Path, PathBuf};
use plist::Value;
use std::string::String;
use serde::Serialize;
use tauri::{AppHandle, Manager};
use libVisualPanic::ErrorHandlingResult;
use libVisualPanic::ErrorHandlingOption;

#[derive(Debug, Clone, Serialize, Default)]
pub struct LocalSaveCheck {
    pub is_saved: bool,
    save_path: String
}

#[derive(Debug, Clone, Serialize, Default)]
pub struct WallpaperVideoEntry {
    pub friendly_name: String,
    video_url_plist: Vec<u8>,
    video_url: String,
    preview_image_url: String,
    pub identifier: String,
    preview_image_save_path: Option<Box<Path>>,
    video_save_path: Option<Box<Path>>
}

const AERIAL_ROOT_DIR: &'static str = "/Library/Application Support/com.apple.idleassetsd";

pub fn get_full_database(app_handle: &AppHandle) -> Option<Vec<WallpaperVideoEntry>> {

    let aerial_db_file: PathBuf = Path::new(AERIAL_ROOT_DIR).join("Aerial.sqlite");
    assert!(aerial_db_file.exists(), "It appears we are not on a Sonoma System. Aborting... (Custom Videos are WIP!)");
    let conn = rusqlite::Connection::open_with_flags(aerial_db_file, rusqlite::OpenFlags::SQLITE_OPEN_READ_ONLY).expect_visual_no_default("Failed to read the database in read-only state.", &app_handle).unwrap();
    let mut stmt = conn.prepare("SELECT * FROM ZASSET").expect_visual_no_default("Failed to prepare the fetch statement.", &app_handle).unwrap();
    let entry_iter = stmt.query_map([], |row| {
        Ok(WallpaperVideoEntry {
            friendly_name: row.get::<usize, String>(8).expect_visual("Failed to get Friendly Name.", &app_handle).to_string(),
            video_url_plist: row.get::<usize, Vec<u8>>(15).expect_visual("Failed to get Video URL Plist.", &app_handle),
            video_url: String::new(),
            preview_image_url: row.get::<usize, String>(13).expect_visual("Failed to get Preview Image URL.", &app_handle).to_string(),
            identifier: row.get::<usize, String>(10).expect_visual("Failed to get Identifier.", &app_handle).to_string(),
            preview_image_save_path: None,
            video_save_path: None
        })
    }).expect_visual_no_default("Failed to execute the statement and fetch the results.", &app_handle).unwrap();

    let mut available_wallpaper_vec: Vec<WallpaperVideoEntry> = Vec::new();

    for entry_result in entry_iter {
        if entry_result.is_ok() {
            let mut entry = entry_result.expect_visual("Failed to get value (should never happen)", &app_handle).clone();
            let plist_vec = entry.video_url_plist.clone();
            let plist_slice = plist_vec.as_slice();
            let plist_cursor = Cursor::new(plist_slice);
            let reader = BufReader::new(plist_cursor);
            let temp_value = Value::from_reader(reader).expect_visual_no_default("Failed parse blob from reader.", &app_handle).unwrap();
            let dictionary = temp_value.into_dictionary().expect_visual("Failed to get underlying dictionary of Plist.", &app_handle);
            let dictionary_vec = dictionary.values();
            dictionary_vec.for_each(|dictionary_entry| {
                match dictionary_entry.clone().into_array() {
                    None => {},
                    Some(plist_array) => {
                        plist_array.iter().for_each(|array_entry|{
                            match array_entry.clone().into_string() {
                                None => {},
                                Some(array_string) => {
                                    if array_string.contains("https://") {
                                        entry.video_url = array_string;
                                        available_wallpaper_vec.push(entry.clone());
                                    }
                                }
                            }
                        });
                    }
                }
            });
        } else {
            panic!("Failed to get the underlying value of the executed SQL Query. This should not have happened. Error: {:?}", entry_result.err());
        }
    }
    if available_wallpaper_vec.is_empty() {
        return None;
    } else {
        return Some(available_wallpaper_vec);
    }
}

pub fn download(identifier: String, url: String, app_handle: AppHandle, app_handle2: AppHandle, app_handle3: AppHandle) -> Option<String> {
    let mut file_path = get_home_directory();
    let mut dir_path = get_home_directory();
    dir_path = dir_path.join(".WavyBackgrounds");
    file_path = file_path.join(format!(".WavyBackgrounds/{}.mov", identifier).as_str());
    let mut downloader = curl::easy::Easy::new();
    downloader.progress(true).expect_visual_no_default("Failed to apply progress flag to CURL.", &app_handle).unwrap();
    downloader.url(url.as_str()).expect_visual_no_default("Failed to parse the URL to the online Video.", &app_handle).unwrap();

    let file_path2 = file_path.clone();
    std::fs::create_dir_all(Path::new(dir_path.as_path())).expect_visual_no_default("Failed to create folders", & app_handle).unwrap();

    downloader.write_function(move |data| {
        let mut file = OpenOptions::new().create(true).write(true).append(true).read(true).open(file_path.clone()).expect_visual_no_default("Failed to open file for write access...", &app_handle).unwrap();
        file.write(data).expect_visual("Failed to write contents from the &[u8] buffer to the file.", &app_handle);
        Ok(data.len())
    }).expect_visual("CURL Write Function failed.", &app_handle2);
    downloader.progress_function(move |expected_download, current_download, _, _| {
        app_handle3.emit_all(&*format!("progress_{identifier}"), [expected_download, current_download]).expect_visual("Failed to emit progress to frontend", &app_handle3);
        return true;
    }).expect_visual_no_default("Failed to register and execute the progress callback function by CURL.", &app_handle2).unwrap();
    downloader.perform().expect_visual("CURL could not perform the requested operation.", &app_handle2);
    let file = std::fs::File::open(file_path2.clone()).expect_visual_no_default("Failed to open the File", &app_handle2).unwrap();
    if !file_path2.exists() {
        return None;
    } else {
        return Some(file_path2.to_str().unwrap().to_string());
    }
}

fn get_home_directory() -> PathBuf {
    let home_directory = directories::UserDirs::new().unwrap().home_dir().to_path_buf();
    return home_directory;
}

pub fn get_file_path(identifier: String) -> String {
    let local_res_dir = get_home_directory().join(".WavyBackgrounds");
    let file_path = local_res_dir.join(format!("{}.mov", identifier));
    if !file_path.exists() {
        panic!("Can't find video with identifier: {}\nMaybe it was not downloaded?", identifier);
    }
    return file_path.to_str().unwrap().to_string();
}

pub fn delete_local_resource(identifier: String) -> bool {
    let local_res_dir = get_home_directory().join(".WavyBackgrounds");
    let file_to_delete = local_res_dir.join(format!("{}.mov", identifier));
    if !file_to_delete.exists() {
        return true;
    } else {
        match std::fs::remove_file(file_to_delete) {
            Ok(_) => return true,
            Err(err) => return false
        }
    }
}

pub fn chec_for_local(identifier: String) -> LocalSaveCheck {
    let local_res_dir = get_home_directory().join(".WavyBackgrounds");
    let file_to_check = local_res_dir.join(format!("{}.mov", identifier));
    if file_to_check.exists() {
        return LocalSaveCheck {
            is_saved: true,
            save_path: file_to_check.to_str().unwrap().to_string()
        }
    } else {
        return LocalSaveCheck {
            is_saved: false,
            save_path: String::new()
        }
    }
}
