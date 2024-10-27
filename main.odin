package main

import "core:fmt"
import gl "vendor:wasm/WebGL"

CTX_NAME :: "canvas"

main :: proc() {
	_ = gl.CreateCurrentContextById(CTX_NAME, {})
	_ = gl.SetCurrentContextById(CTX_NAME)

	gl.ClearColor(0.0, 0.0, 0.0, 1.0)
	gl.Clear(gl.COLOR_BUFFER_BIT)
}
