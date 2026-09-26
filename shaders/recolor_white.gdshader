shader_type canvas_item;

// Pure white pixels in the texture are drawn with this color instead
uniform vec4 white_replacement : source_color = vec4(1.0);

void fragment() {
	if (COLOR.r > 0.99 && COLOR.g > 0.99 && COLOR.b > 0.99) {
		COLOR.rgb = white_replacement.rgb;
	}
}
