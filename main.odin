package main

import "core:fmt"
import "core:time"

import glm "core:math/linalg/glsl"
import gl "vendor:wasm/WebGL"


vertex_source := `
  attribute vec3 position;
  uniform mat4 model_matrix;

  void main() {
    gl_Position = model_matrix * vec4(position, 1.0);
  }
`


fragment_source := `
void main() {
  gl_FragColor = vec4(0, 1, 0, 1.0); // Green for front faces
}
`


shader_program: gl.Program
vertex_buffer: gl.Buffer

vertices: [36]glm.vec3 = generate_cube(0.5)
generate_cube :: proc(scale: f32) -> [36]glm.vec3 {
	half_scale := scale / 2.0
	return [36]glm.vec3 {
		// Front face
		glm.vec3{-half_scale, -half_scale, half_scale},
		glm.vec3{half_scale, -half_scale, half_scale},
		glm.vec3{half_scale, half_scale, half_scale},
		glm.vec3{half_scale, half_scale, half_scale},
		glm.vec3{-half_scale, half_scale, half_scale},
		glm.vec3{-half_scale, -half_scale, half_scale},

		// Back face
		glm.vec3{-half_scale, -half_scale, -half_scale},
		glm.vec3{half_scale, -half_scale, -half_scale},
		glm.vec3{half_scale, half_scale, -half_scale},
		glm.vec3{half_scale, half_scale, -half_scale},
		glm.vec3{-half_scale, half_scale, -half_scale},
		glm.vec3{-half_scale, -half_scale, -half_scale},

		// Top face
		glm.vec3{-half_scale, half_scale, -half_scale},
		glm.vec3{half_scale, half_scale, -half_scale},
		glm.vec3{half_scale, half_scale, half_scale},
		glm.vec3{half_scale, half_scale, half_scale},
		glm.vec3{-half_scale, half_scale, half_scale},
		glm.vec3{-half_scale, half_scale, -half_scale},

		// Bottom face
		glm.vec3{-half_scale, -half_scale, -half_scale},
		glm.vec3{half_scale, -half_scale, -half_scale},
		glm.vec3{half_scale, -half_scale, half_scale},
		glm.vec3{half_scale, -half_scale, half_scale},
		glm.vec3{-half_scale, -half_scale, half_scale},
		glm.vec3{-half_scale, -half_scale, -half_scale},

		// Right face
		glm.vec3{half_scale, -half_scale, -half_scale},
		glm.vec3{half_scale, half_scale, -half_scale},
		glm.vec3{half_scale, half_scale, half_scale},
		glm.vec3{half_scale, half_scale, half_scale},
		glm.vec3{half_scale, -half_scale, half_scale},
		glm.vec3{half_scale, -half_scale, -half_scale},

		// Left face
		glm.vec3{-half_scale, -half_scale, -half_scale},
		glm.vec3{-half_scale, half_scale, -half_scale},
		glm.vec3{-half_scale, half_scale, half_scale},
		glm.vec3{-half_scale, half_scale, half_scale},
		glm.vec3{-half_scale, -half_scale, half_scale},
		glm.vec3{-half_scale, -half_scale, -half_scale},
	}
}

Input :: struct {
	key_states:  [256]bool,
	mouse_pos:   glm.vec2,
	mouse_state: [3]bool,
}

input: Input

@(export)
on_mouse_move :: proc(x: f64, y: f64) {
	input.mouse_pos = glm.vec2{f32(x), f32(y)}
}

@(export)
on_mouse_down :: proc(button: i32) {
	input.mouse_state[button] = true
}

@(export)
on_mouse_up :: proc(button: i32) {
	input.mouse_state[button] = false
}

@(export)
on_key_down :: proc(key: i32) {
	input.key_states[key] = true
}

@(export)
on_key_up :: proc(key: i32) {
	input.key_states[key] = false
}

model_matrix: glm.mat4

CONTEXT_ID :: "canvas"
@(export)
init :: proc() {

	// attach our gl context to the html surface.
	_ = gl.CreateCurrentContextById(CONTEXT_ID, {})
	_ = gl.SetCurrentContextById(CONTEXT_ID)

	// set the background clear color.
	gl.ClearColor(0.0, 0.0, 0.0, 1.0)

	// compile shaders
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

	// setup our vertex array & buffer.
	vao := gl.CreateVertexArray()
	gl.BindVertexArray(vao)

	vertex_buffer = gl.CreateBuffer()
	gl.BindBuffer(gl.ARRAY_BUFFER, vertex_buffer)
	gl.BufferData(gl.ARRAY_BUFFER, size_of(vertices), &vertices, gl.STATIC_DRAW)

	gl.EnableVertexAttribArray(0)
	gl.VertexAttribPointer(0, 3, gl.FLOAT, false, size_of(glm.vec3), 0)

	// A debug print.
	fmt.println("ODIN: Init called!")

	model_matrix = glm.identity(glm.mat4)
}

@(export)
step :: proc(delta_time: f64) -> bool {

	gl.UniformMatrix4fv(gl.GetUniformLocation(shader_program, "model_matrix"), model_matrix)

	if input.mouse_state[0] {
		@(static) last_pos: glm.vec2
		rotation_speed: f32 = 0.01
		delta_pos := input.mouse_pos - last_pos
		model_matrix =
			glm.mat4Rotate(glm.vec3{1, 0, 0}, delta_pos.y * rotation_speed) *
			glm.mat4Rotate(glm.vec3{0, 1, 0}, delta_pos.x * rotation_speed) *
			model_matrix
		last_pos = input.mouse_pos
	}
	// clear the screen and draw the cube.
	gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)
	gl.DrawArrays(gl.TRIANGLES, 0, 36)
	return true
}

main :: proc() {
	init()
}
