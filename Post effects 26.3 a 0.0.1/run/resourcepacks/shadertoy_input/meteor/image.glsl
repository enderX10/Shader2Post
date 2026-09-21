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
