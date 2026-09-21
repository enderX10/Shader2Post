#version 330

#include <minecraft:globals.glsl>

uniform sampler2D InSampler; // obraz gry (iChannel0)

layout(std140) uniform SamplerInfo {
    vec2 OutSize;
    vec2 InSize;
};

layout(std140) uniform ShadertoyConfig {
    float TimeScale;
};

layout(location = 0) out vec4 _fragOut;

#define iTime (GameTime * 1200.0 * TimeScale)
#define iTimeDelta 0.016
#define iFrameRate 60.0
#define iFrame int(iTime * 60.0)
#define iResolution vec3(OutSize, 1.0)
#define iMouse vec4(0.0)
#define iChannel0 InSampler

// ================= ORYGINALNY KOD SHADERTOY (bez zmian) =================
#line 1