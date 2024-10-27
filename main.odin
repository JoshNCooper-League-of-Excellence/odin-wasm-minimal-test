package main

import "core:fmt"
import "core:time"

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
  gl_FragColor = vec4(0, 1, 0, 1.0);
}
`


shader_program: gl.Program
vertex_buffer: gl.Buffer
vertices: [36]glm.vec3 = {
	// Front face
	glm.vec3{-0.5, -0.5, 0.5},
	glm.vec3{0.5, -0.5, 0.5},
	glm.vec3{0.5, 0.5, 0.5},
	glm.vec3{0.5, 0.5, 0.5},
	glm.vec3{-0.5, 0.5, 0.5},
	glm.vec3{-0.5, -0.5, 0.5},

	// Back face
	glm.vec3{-0.5, -0.5, -0.5},
	glm.vec3{0.5, -0.5, -0.5},
	glm.vec3{0.5, 0.5, -0.5},
	glm.vec3{0.5, 0.5, -0.5},
	glm.vec3{-0.5, 0.5, -0.5},
	glm.vec3{-0.5, -0.5, -0.5},

	// Top face
	glm.vec3{-0.5, 0.5, -0.5},
	glm.vec3{0.5, 0.5, -0.5},
	glm.vec3{0.5, 0.5, 0.5},
	glm.vec3{0.5, 0.5, 0.5},
	glm.vec3{-0.5, 0.5, 0.5},
	glm.vec3{-0.5, 0.5, -0.5},

	// Bottom face
	glm.vec3{-0.5, -0.5, -0.5},
	glm.vec3{0.5, -0.5, -0.5},
	glm.vec3{0.5, -0.5, 0.5},
	glm.vec3{0.5, -0.5, 0.5},
	glm.vec3{-0.5, -0.5, 0.5},
	glm.vec3{-0.5, -0.5, -0.5},

	// Right face
	glm.vec3{0.5, -0.5, -0.5},
	glm.vec3{0.5, 0.5, -0.5},
	glm.vec3{0.5, 0.5, 0.5},
	glm.vec3{0.5, 0.5, 0.5},
	glm.vec3{0.5, -0.5, 0.5},
	glm.vec3{0.5, -0.5, -0.5},

	// Left face
	glm.vec3{-0.5, -0.5, -0.5},
	glm.vec3{-0.5, 0.5, -0.5},
	glm.vec3{-0.5, 0.5, 0.5},
	glm.vec3{-0.5, 0.5, 0.5},
	glm.vec3{-0.5, -0.5, 0.5},
	glm.vec3{-0.5, -0.5, -0.5},
}


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

	gl.Enable(gl.DEPTH_TEST)

	// A debug print.
	fmt.println("ODIN: Init called!")
}

@(export)
step :: proc(delta_time: f64) -> bool {
	// clear the screen and draw the cube.
	gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)
	gl.DrawArrays(gl.TRIANGLES, 0, 36)
	return true
}

main :: proc() {
	init()
}
