#version 330
#include <minecraft:globals.glsl>

uniform sampler2D InSampler; // score pass Buffer A (iChannel0 = Buffer A)

layout(std140) uniform SamplerInfo {
    vec2 OutSize;
    vec2 InSize;
};

layout(location = 0) out vec4 _fragOut;

#define iTime (GameTime * 1200.0)
#define iTimeDelta 0.016
#define iFrameRate 60.0
#define iFrame 0
#define iResolution vec3(OutSize, 1.0)
#define iMouse vec4(0.0)
#define iChannel0 InSampler


#line 1
