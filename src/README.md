# The Rust side
This is a Markdown parser library intended to be used by the Dart side via
either C or WASM interop. This library is split into two parts.

## Implementations
Inside the `impls` module are the different implementations of the same algorithm,
which are platform agnostic. Code inside this module should aim to be 100% safe.

## Frontends
Modules inside the `frontends` module exposes the implementations to different consumers,
i.e. the C FFI and the WASM module.
