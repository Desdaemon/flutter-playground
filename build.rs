fn main() {
    protoc_rust::Codegen::new()
        .out_dir("src/protos")
        .inputs(&["root.proto"])
        .include("./")
        .run()
        .expect("protoc failed");
}
