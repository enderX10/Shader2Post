

// ================= KONIEC ORYGINALNEGO KODU =================
void main() {
    vec2 fc = gl_FragCoord.xy;
    // ukryj wiersz z zapakowanym stanem (16 + 1 pikseli w lewym dolnym rogu)
    if (fc.y < 1.0 && fc.x < 17.0) fc.y += 1.0;
    vec4 c = vec4(0.0);
    mainImage(c, fc);
    _fragOut = vec4(c.rgb, 1.0);
}
