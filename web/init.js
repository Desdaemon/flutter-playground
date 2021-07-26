import init from "./assets/pkg/flutter_playground.js";
import * as wasm from "./assets/pkg/flutter_playground.js";
await init();
Object.assign(window, wasm);
