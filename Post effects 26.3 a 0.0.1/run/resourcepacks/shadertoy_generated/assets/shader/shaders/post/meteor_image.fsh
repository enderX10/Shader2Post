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
// see Buffer A for the image code - this is
// just gaussian filter

void mainImage(out vec4 O, vec2 u) {
    vec2 R = iResolution.xy,
        uv = u/R;

    O *= 0.;

    float[] gk1s = float[](
        0.003765, 0.015019, 0.023792, 0.015019, 0.003765,
        0.015019, 0.059912, 0.094907, 0.059912, 0.015019,
        0.023792, 0.094907, 0.150342, 0.094907, 0.023792,
        0.015019, 0.059912, 0.094907, 0.059912, 0.015019,
        0.003765, 0.015019, 0.023792, 0.015019, 0.003765
    );

    //golfed by fabriceneyret2
    for (int k; k < 25; k++)
        O += gk1s[k] * texture(iChannel0, uv + ( vec2(k%5,k/5) - 2. ) / R );

    O =   .2*O + 40.*fwidth(O*R.x/4000.);
}


// ================= END OF ORIGINAL CODE =================
void main() {
    vec2 fc = gl_FragCoord.xy;
    // ukryj wiersz z zapakowanym stanem (16 + 1 pikseli w lewym dolnym rogu)
    if (fc.y < 1.0 && fc.x < 17.0) fc.y += 1.0;
    vec4 c = vec4(0.0);
    mainImage(c, fc);
    _fragOut = vec4(c.rgb, 1.0);
}
