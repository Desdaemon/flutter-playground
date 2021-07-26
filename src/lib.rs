#[deny(missing_docs)]

/// Exposes the implementations in [impls] to different consumers,
/// i.e. the C FFI and the WASM module.
pub mod frontends;

/// Different implementations of the same algorithm. Code inside this module
/// should aim to be 100% safe.
pub mod impls;

/// Math block parser.
pub mod math;

/// FFI-compatible adapter for a boxed [slice](https://doc.rust-lang.org/nightly/std/primitive.slice.html).
pub mod slice;

#[cfg(target_arch = "wasm32")]
pub use frontends::wasm::*;

#[cfg(not(target_arch = "wasm32"))]
pub use frontends::ffi::*;
