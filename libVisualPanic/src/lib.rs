#![allow(non_snake_case)]

use std::fmt::Debug;
use std::process::exit;
use serde::Serialize;
use tauri::{AppHandle, Manager};

#[derive(Clone, Serialize)]
struct VisualPanicError {
    error: String,
    message: String,
    location: String,
    backtrace: String
}

pub trait ErrorHandlingResult<T, E: Debug> {
    fn expect_visual(self, message: &str, app_handle: &AppHandle) -> T where T: Default;
    fn expect_visual_no_default(self, message: &str, app_handle: &AppHandle) -> Result<T, E>;
}

pub trait ErrorHandlingOption<T> {
    fn expect_visual(self, message: &str, app_handle: &AppHandle) -> T;
}

impl<T, E: Debug> ErrorHandlingResult<T, E> for Result<T, E> {
    fn expect_visual(self, message: &str, app_handle: &AppHandle) -> T where T: Default {
        match self {
            Ok(ok) => return ok,
            Err(ref err) => {
                visual_panic(err, message, app_handle);
                let _ = app_handle.listen_global("backend_panic_final", |_handler| {
                    exit(-1);
                });
                return self.unwrap_or_default();
            }
        }
    }

    fn expect_visual_no_default(self, message: &str, app_handle: &AppHandle) -> Result<T, E> {
        match self {
            Ok(ok) => return Ok(ok),
            Err(err) => {
                visual_panic(&err, message, app_handle);
                let _ = app_handle.listen_global("backend_panic_final", |_handler| {
                    exit(-1);
                });
                return Err(err);
            }
        }
    }
}

impl<T: Default> ErrorHandlingOption<T> for Option<T> {
    fn expect_visual(self, message: &str, app_handle: &AppHandle) -> T {
        match self {
            Some(value) => return value,
            None => {
                visual_panic(Err::<(), &str>("Option: None"), message, app_handle);
                let _ = app_handle.listen_global("backend_panic_final", |_handler| {
                    exit(-1);
                });
                return self.unwrap_or_default();
            }
        }
    }
}

fn visual_panic<E: Debug>(err: E, message: &str, app_handle: &AppHandle) -> () {
    app_handle.emit_all("visual_panic", VisualPanicError{ error: format!("{:?}", err), message: message.to_string(), location: format!("{:p}", &err), backtrace: format!("{}", std::backtrace::Backtrace::force_capture()) }).expect("Failed to emit to windows. Tauri internal error...");
    let _ = app_handle.listen_global("final_panic", |_ev| {
        exit(-1);
    });
}

