

// ================= KONIEC ORYGINALNEGO KODU =================
void main() {
    vec4 c = vec4(0.0);
    mainImage(c, gl_FragCoord.xy);
    _fragOut = vec4(c.rgb, 1.0);
}