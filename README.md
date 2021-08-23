# flutter_playground

A demonstration of various techniques used in developing Flutter applications.

## Getting started
```
cargo build --release
flutter run
```

## Areas covered
- 🎯 Rust-Dart interop (via C FFI) 
  - Exposing Rust functions as [C functions](src/frontends/ffi.rs)
  - Using `cbindgen` and `ffigen` to create [Dart bindings](lib/ffi.dart)
- ![WASM Icon](assets/wasm-small.png) Rust-Dart interop (via WASM)
  - Exposing Rust functions as a [WASM module](src/frontends/wasm.rs)
  - Using `dart_js_facade_gen` to create Dart bindings
- [State management](lib/state/markdown.dart) with Riverpod
- [State persistence](lib/state/dark.dart) with Hive

## Notes
- `ffigen` requires an LLVM dynamic library (`libclang.so`, exact name) installed somewhere
  on your system. If `ffigen` reports the library as missing, create a symlink to the library
  under the `lib` folder as `lib/libclang.so`.
- This is a small project so the Rust project is not split into subpackages, but for
  anything more complex such a system may be necessary, e.g. to improve compile times and
  enforce separation of concerns.
