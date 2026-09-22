#version 330
#include <minecraft:globals.glsl>

uniform sampler2D InSampler;   // game render - unused
uniform sampler2D PrevSampler; // previous frame of the same shader (iChannel0 = Buffer A)

layout(std140) uniform SamplerInfo {
    vec2 OutSize;
    vec2 InSize;
};

layout(std140) uniform ShadertoyConfig {
    float TimeScale;
};

layout(location = 0) out vec4 _fragOut;

// ---- Shadertoy -> Minecraft ----
int _iFrame = 0;
#define iFrame _iFrame
#define iTime (GameTime * 1200.0 * TimeScale)
#define iTimeDelta 0.016
#define iFrameRate 60.0
#define iResolution vec3(OutSize, 1.0)
#define iMouse vec4(0.0)
#define iDate vec4(2026.0, 0.0, 1.0, 0.0)
#define iChannel0 PrevSampler

// ---- State (camera matrix, frame counter) in RGBA8 target ----
// The post effect target is 8-bit, so we store each float as 4 bytes (one pixel).
// Logical pixel k (0..3) occupies physical pixels 4k..4k+3 in row y=0.
// The frame counter is at physical pixel x=16.
const int _STATE_LOGICAL = 4;
const int _COUNTER_X = 16;

vec4 _pack(float f) {
    uint u = floatBitsToUint(f);
    return vec4(float(u & 255u), float((u >> 8) & 255u),
                float((u >> 16) & 255u), float(u >> 24)) / 255.0;
}

float _unpack(vec4 c) {
    uvec4 b = uvec4(c * 255.0 + 0.5);
    return uintBitsToFloat(b.x | (b.y << 8) | (b.z << 16) | (b.w << 24));
}

// Reading logical state pixels; the rest goes to actual texelFetch.
vec4 _stateFetch(sampler2D s, ivec2 p, int lod) {
    if (p.y == 0 && p.x >= 0 && p.x < _STATE_LOGICAL) {
        return vec4(_unpack(texelFetch(s, ivec2(4 * p.x + 0, 0), lod)),
                    _unpack(texelFetch(s, ivec2(4 * p.x + 1, 0), lod)),
                    _unpack(texelFetch(s, ivec2(4 * p.x + 2, 0), lod)),
                    _unpack(texelFetch(s, ivec2(4 * p.x + 3, 0), lod)));
    }
    return texelFetch(s, p, lod);
}
#define texelFetch _stateFetch


#line 1