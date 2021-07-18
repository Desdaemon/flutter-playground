# flutter_playground

Flutter Playground.

## Building native libraries (Android)

    # Setup toolchain
    cargo install cargo-ndk
    rustup target add \
        aarch64-linux-android \
        armv7-linux-androideabi \
        x86_64-linux-android \
        i686-linux-android
    # Emit JNI libraries
    cargo ndk -t armeabi-v7a -t arm64-v8a -o android/app/src/main/jniLibs build --release
