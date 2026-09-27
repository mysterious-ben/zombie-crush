// A shader is a tiny program the graphics card runs for every pixel it draws.
// "canvas_item" means it is for 2D nodes (sprites, labels, ...), not 3D
shader_type canvas_item;

// A uniform is an input set from outside: in the Inspector, or from GDScript with
// material.set_shader_parameter("white_replacement", color).
// "source_color" makes the Inspector show a color picker; vec4(1.0) is white (r, g, b, a all 1)
// Pure white pixels in the texture are drawn with this color instead
uniform vec4 white_replacement : source_color = vec4(1.0);

// fragment() runs once for every pixel of the sprite, all in parallel.
// When it starts, COLOR already holds that pixel's color from the texture
// (times the node's modulate); whatever COLOR holds at the end is what gets drawn
void fragment() {
	// Colors go from 0.0 to 1.0 per channel, so white is r = g = b = 1.0.
	// We check "> 0.99" instead of "== 1.0" because decimal numbers are rarely exactly equal
	if (COLOR.r > 0.99 && COLOR.g > 0.99 && COLOR.b > 0.99) {
		// Replace only red, green and blue; keep the pixel's transparency (COLOR.a)
		COLOR.rgb = white_replacement.rgb;
	}
}
