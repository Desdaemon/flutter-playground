main:
	cargo build --release
	wasm-pack build --release -t no-modules
	cbindgen --config cbindgen.toml --output bindings.h
bindings:
	dart pub get
	dart run ffigen
	# Disabled for now, since it is not aware of nullable types which causes
	# wrong runtime behavior.
	# npx -y dart_js_facade_gen --destination=lib/bindings pkg/flutter_playground.d.ts
ndk:
	cargo ndk -t armeabi-v7a -t arm64-v8a -o android/app/src/main/jniLibs build --release
build: main bindings ndk
coverage:
	RUSTFLAGS="-Z instrument-coverage" cargo +nightly build --bins
	./target/debug/flutter_playground
	llvm-profdata merge -sparse default.profraw -o flutter_playground.profdata && \
	llvm-cov show -Xdemangler=rustfilt target/debug/flutter_playground \
		--instr-profile=flutter_playground.profdata \
		--show-line-counts-or-regions \
		--show-instantiations \
		--name=parse \
		--format=html > coverage-report.html
init:
	cargo install cargo-ndk wasm-pack
	rustup target add \
		aarch64-linux-android \
		armv7-linux-androideabi \
		x86_64-linux-android \
		i686-linux-android
init-coverage:
	rustup toolchain install nightly
	cargo install rustfilt
