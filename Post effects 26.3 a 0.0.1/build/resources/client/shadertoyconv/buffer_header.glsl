#version 330
#include <minecraft:globals.glsl>

uniform sampler2D InSampler;   // render gry - nieuzywany
uniform sampler2D PrevSampler; // poprzednia klatka tego samego shadera (iChannel0 = Buffer A)

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

// ---- Stan (macierz kamery, licznik klatek) w celu RGBA8 ----
// Target post effect jest 8-bitowy, wiec kazdy float zapisujemy jako 4 bajty (jeden piksel).
// Logiczny piksel k (0..3) zajmuje fizyczne piksele 4k..4k+3 w wierszu y=0.
// Licznik klatek jest w fizycznym pikselu x=16.
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

// Odczyt logicznych pikseli stanu; reszta idzie do prawdziwego texelFetch.
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

// ================= ORYGINALNY KOD SHADERTOY (bez zmian) =================
#line 1
