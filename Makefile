main:
	cargo build --release
	wasm-pack build
	cbindgen --config cbindgen.toml --output bindings.h
gen-ffi:
	@echo ffigen sometimes can't find the needed package in the cache, so this is needed.
	dart pub get
	dart run ffigen
	npx -y dart_js_facade_gen --destination=lib/bindings pkg/flutter_playground.d.ts
ndk:
	cargo ndk -t armeabi-v7a -t arm64-v8a -o android/app/src/main/jniLibs build --release
build: main gen-ffi ndk
init:
	cargo install cargo-ndk wasm-pack
	rustup target add \
		aarch64-linux-android \
		armv7-linux-androideabi \
		x86_64-linux-android \
		i686-linux-android
