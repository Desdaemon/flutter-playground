main:
	cargo build --release
	cbindgen --config cbindgen.toml --output bindings.h
	dart run ffigen
bench:
	dart benches/node_bench.dart
init:
	cargo install cargo-ndk
	rustup target add \
        	aarch64-linux-android \
        	armv7-linux-androideabi \
		x86_64-linux-android \
		i686-linux-android
ndk:
	cargo ndk -t armeabi-v7a -t arm64-v8a -o android/app/src/main/jniLibs build --release
build: main ndk
gen-protobuf:
	protoc -I=./ --dart_out=./lib/proto ./root.proto
