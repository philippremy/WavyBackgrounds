use std::path::Path;
use std::process::Command;

fn main() {

    let working_dir = std::env::var("CARGO_MANIFEST_DIR").unwrap();

    let target_triple = "arm64-apple-darwin";

    let clang = Command::new("clang")
        .current_dir(working_dir.clone())
        .args([
            "-x",
            "objective-c",
            "-std=gnu17",
            "-O0",
            "-target",
            target_triple,
            "-c",
            "LoginItemCheck/LoginItem.m",
            "-o",
            format!("LoginItem__{}.o", target_triple).as_str()
        ])
        .spawn()
        .unwrap();

    let clang_exit_code = clang.wait_with_output().unwrap();
    if !clang_exit_code.status.success() {
        panic!("Compilation of libLoginItemCheck failed: {:?}", clang_exit_code.status);
    }

    let ar = Command::new("ar")
        .current_dir(working_dir.clone())
        .args([
            "rvs",
            format!("libLoginItemCheck__{}.a", target_triple).as_str(),
            format!("LoginItem__{}.o", target_triple).as_str()
        ])
        .spawn()
        .unwrap();

    let ar_exit_code = ar.wait_with_output().unwrap();
    if !ar_exit_code.status.success() {
        panic!("Archival of libLoginItemCheck failed: {:?}", ar_exit_code.status);
    }

    println!("cargo:rustc-link-search=native={}", Path::new(&working_dir.clone()).to_str().unwrap().to_string());
    println!("cargo:rustc-link-lib=static={}", format!("LoginItemCheck__{}", target_triple));

    let target_triple = "x86_64-apple-darwin";

    let clang = Command::new("clang")
        .current_dir(working_dir.clone())
        .args([
            "-x",
            "objective-c",
            "-std=gnu17",
            "-O0",
            "-target",
            target_triple,
            "-c",
            "LoginItemCheck/LoginItem.m",
            "-o",
            format!("LoginItem__{}.o", target_triple).as_str()
        ])
        .spawn()
        .unwrap();

    let clang_exit_code = clang.wait_with_output().unwrap();
    if !clang_exit_code.status.success() {
        panic!("Compilation of libLoginItemCheck failed: {:?}", clang_exit_code.status);
    }

    let ar = Command::new("ar")
        .current_dir(working_dir.clone())
        .args([
            "rvs",
            format!("libLoginItemCheck__{}.a", target_triple).as_str(),
            format!("LoginItem__{}.o", target_triple).as_str()
        ])
        .spawn()
        .unwrap();

    let ar_exit_code = ar.wait_with_output().unwrap();
    if !ar_exit_code.status.success() {
        panic!("Archival of libLoginItemCheck failed: {:?}", ar_exit_code.status);
    }

    println!("cargo:rustc-link-search=native={}", Path::new(&working_dir.clone()).to_str().unwrap().to_string());
    println!("cargo:rustc-link-lib=static={}", format!("LoginItemCheck__{}", target_triple));
}