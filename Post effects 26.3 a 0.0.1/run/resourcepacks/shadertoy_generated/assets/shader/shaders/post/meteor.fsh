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
#define rot(x) mat2(cos(x+vec4(0,11,33,0)))

//formula for creating colors;
#define H(h)  (  cos(  h*2. +  vec3(1,2,3)   )*.5 + .3 )

//formula for mapping scale factor
#define M(c)  log(1.+c)

#define R iResolution



void mainImage( out vec4 O, vec2 U) {

    O = vec4(0);

    vec3 c=vec3(0);
    vec4 rd = normalize( vec4(U-.5*R.xy, R.y, .3*R.y))*50.;

    float sc,dotp,totdist=0., tt=iTime/3., t=0.;

    rd.yz  *= rot(.5);
    rd.xz  *= rot( iTime/7. );

    for (float i=0.; i<80.; i++) {

        vec4 p = vec4( rd*totdist);

        float shell = length(p) - 1.;

        //p.xz += iTime/3.;
        p.x += 2.;

        p.y += iTime;

        float dd = 3.5;
        p.xyz = mod(p.xyz-dd,2.*dd)-dd;


        sc = 1.;

        vec4 w = p;

        for (float j=0.; j<5.; j++) {

            p = abs(p)*.95 - .25;

            p.xw *= rot(.4);

            dotp = clamp(1./dot(p,p),.1,6.);
            sc *= dotp;

            p = p * dotp - .5;


        }

        float dist = max( -shell, (length(p.yzw)-.1*length(p.xyz) ) /  sc  ) ;
        float stepsize = dist/30. ;
        totdist += stepsize;

        if (dist < 1e-9) break;

        if (i > 14.)
        c +=
             .04 * H(M(sc))   *  exp(-totdist*20.);
    }

    c = 1. - exp(-c*c);
    O = ( vec4(c,0) ) + .95*texture(iChannel0, U/R.xy);

}

// ================= END OF ORIGINAL CODE =================
#undef texelFetch

void main() {
    ivec2 ip = ivec2(gl_FragCoord.xy);

    _iFrame = int(_unpack(texelFetch(PrevSampler, ivec2(_COUNTER_X, 0), 0)) + 0.5);

    // wiersz stanu: liczymy logiczny piksel (0.5 + k, 0.5) i pakujemy jedna skladowa
    if (ip.y == 0 && ip.x < 4 * _STATE_LOGICAL) {
        int k = ip.x / 4;
        int c = ip.x - 4 * k;
        vec4 v = vec4(0.0);
        mainImage(v, vec2(float(k) + 0.5, 0.5));
        _fragOut = _pack(v[c]);
        return;
    }
    if (ip.y == 0 && ip.x == _COUNTER_X) {
        _fragOut = _pack(float(_iFrame + 1));
        return;
    }

    vec4 c = vec4(0.0);
    mainImage(c, gl_FragCoord.xy);
    _fragOut = c;
}
