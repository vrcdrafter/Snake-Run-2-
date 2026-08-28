shader_type spatial;

uniform float bulge_pos = 0.5;   // 0.0 (Tail) to 1.0 (Head)
uniform float bulge_size = 0.1;
uniform float bulge_amount = 0.5;
uniform float struggle_offset;
/*
0 = Use UV.x for snake length
1 = Use UV.y for snake length
*/
uniform int uv_mode = 0;

void vertex()
{
    float t;

    // Use unchangeable UV coordinates to determine position along the body
    if (uv_mode == 0) {
        t = UV.x;
    } else {
        t = UV.y;
    }

float d = abs(t - bulge_pos);

float falloff =
    1.0 - smoothstep(0.0, bulge_size, d);

float body_limit =
    1.0 - smoothstep(0.85, 1.0, t);

falloff *= body_limit;

VERTEX.z += struggle_offset * falloff * 0.5;

VERTEX += NORMAL * falloff * bulge_amount * 0.1;
}
