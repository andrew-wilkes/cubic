shader_type spatial;

uniform vec3 color: source_color;
uniform vec3 grey_color: source_color;
uniform bool grey = false;

void fragment() {
	if (grey) {
		ALBEDO = grey_color;
	} else {
		ALBEDO = color;
	}
}
