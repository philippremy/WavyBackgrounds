fn main() {

    #[cfg(not(target_os = "macos"))]
    panic!("Won't compile! This is only compatible on macOS Sonoma and later.");

    tauri_build::build()
}
