

// ================= KONIEC ORYGINALNEGO KODU =================
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
