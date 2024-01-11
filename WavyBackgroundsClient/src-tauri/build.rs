extern crate os_type;

fn main() {

    let os = os_type::current_platform();
    match os.os_type {
        os_type::OSType::OSX => {},
        _ => {
            panic!("This app will not compile on non-macOS host systems. Special Apple frameworks are required for proper linkage.");
        }
    };
    
    tauri_build::build()
}
