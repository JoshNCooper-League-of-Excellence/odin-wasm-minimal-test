package main

import "core:fmt"
import glm "core:math/linalg/glsl"
import gl "vendor:wasm/WebGL"
vertex_source := `
  attribute vec2 position;
  void main() {
    gl_Position = vec4(position, 0.0, 1.0);
  }
`


fragment_source := `
  void main() {
    gl_FragColor = vec4(1.0, 0.0, 0.0, 1.0);
  }
`


shader_program: gl.Program
vertex_buffer: gl.Buffer
vertices: [144]f32 = {
	// Front face
	-0.5,
	-0.5,
	0.5,
	1.0,
	0.0,
	0.0, // 0
	0.5,
	-0.5,
	0.5,
	1.0,
	0.0,
	0.0, // 1
	0.5,
	0.5,
	0.5,
	1.0,
	0.0,
	0.0, // 2
	-0.5,
	0.5,
	0.5,
	1.0,
	0.0,
	0.0, // 3

	// Back face
	-0.5,
	-0.5,
	-0.5,
	0.0,
	1.0,
	0.0, // 4
	0.5,
	-0.5,
	-0.5,
	0.0,
	1.0,
	0.0, // 5
	0.5,
	0.5,
	-0.5,
	0.0,
	1.0,
	0.0, // 6
	-0.5,
	0.5,
	-0.5,
	0.0,
	1.0,
	0.0, // 7

	// Top face
	-0.5,
	0.5,
	-0.5,
	0.0,
	0.0,
	1.0, // 8
	0.5,
	0.5,
	-0.5,
	0.0,
	0.0,
	1.0, // 9
	0.5,
	0.5,
	0.5,
	0.0,
	0.0,
	1.0, // 10
	-0.5,
	0.5,
	0.5,
	0.0,
	0.0,
	1.0, // 11

	// Bottom face
	-0.5,
	-0.5,
	-0.5,
	1.0,
	1.0,
	0.0, // 12
	0.5,
	-0.5,
	-0.5,
	1.0,
	1.0,
	0.0, // 13
	0.5,
	-0.5,
	0.5,
	1.0,
	1.0,
	0.0, // 14
	-0.5,
	-0.5,
	0.5,
	1.0,
	1.0,
	0.0, // 15

	// Right face
	0.5,
	-0.5,
	-0.5,
	0.0,
	1.0,
	1.0, // 16
	0.5,
	0.5,
	-0.5,
	0.0,
	1.0,
	1.0, // 17
	0.5,
	0.5,
	0.5,
	0.0,
	1.0,
	1.0, // 18
	0.5,
	-0.5,
	0.5,
	0.0,
	1.0,
	1.0, // 19

	// Left face
	-0.5,
	-0.5,
	-0.5,
	1.0,
	0.0,
	1.0, // 20
	-0.5,
	0.5,
	-0.5,
	1.0,
	0.0,
	1.0, // 21
	-0.5,
	0.5,
	0.5,
	1.0,
	0.0,
	1.0, // 22
	-0.5,
	-0.5,
	0.5,
	1.0,
	0.0,
	1.0, // 23
}
indices: [36]u16 = {
	0,
	1,
	2,
	0,
	2,
	3, // Front
	4,
	5,
	6,
	4,
	6,
	7, // Back
	8,
	9,
	10,
	8,
	10,
	11, // Top
	12,
	13,
	14,
	12,
	14,
	15, // Bottom
	16,
	17,
	18,
	16,
	18,
	19, // Right
	20,
	21,
	22,
	20,
	22,
	23, // Left
}

CONTEXT_ID :: "canvas"

@(export)
init :: proc() {
	_ = gl.CreateCurrentContextById(CONTEXT_ID, {})
	_ = gl.SetCurrentContextById(CONTEXT_ID)

	vertex_shader := gl.CreateShader(gl.VERTEX_SHADER)
	gl.ShaderSource(vertex_shader, {vertex_source})
	gl.CompileShader(vertex_shader)

	fragment_shader := gl.CreateShader(gl.FRAGMENT_SHADER)
	gl.ShaderSource(fragment_shader, {fragment_source})
	gl.CompileShader(fragment_shader)

	shader_program = gl.CreateProgram()
	gl.AttachShader(shader_program, vertex_shader)
	gl.AttachShader(shader_program, fragment_shader)
	gl.LinkProgram(shader_program)
	gl.UseProgram(shader_program)

	vertex_buffer = gl.CreateBuffer()
	gl.BindBuffer(gl.ARRAY_BUFFER, vertex_buffer)
	gl.BufferData(gl.ARRAY_BUFFER, len(vertices) * size_of(f32), &vertices, gl.STATIC_DRAW)

	position_attrib := gl.GetAttribLocation(shader_program, "position")
	gl.EnableVertexAttribArray(position_attrib)
	gl.VertexAttribPointer(position_attrib, 3, gl.FLOAT, false, 6 * size_of(f32), 0)

	gl.Enable(gl.DEPTH_TEST)
	gl.ClearColor(0.0, 0.0, 1.0, 1.0)

	fmt.println("ODIN: Init called!")
}

@(export)
step :: proc(delta_time: f64) -> bool {
	gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)
	gl.DrawElements(gl.TRIANGLES, 36, gl.UNSIGNED_SHORT, nil)
	return true
}
main :: proc() {
	init()
}
