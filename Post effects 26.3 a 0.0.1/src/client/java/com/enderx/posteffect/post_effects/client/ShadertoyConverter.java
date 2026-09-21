package com.enderx.posteffect.post_effects.client;

import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.nio.file.DirectoryStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.List;
import java.util.Properties;

/**
 * Czysta Java (bez klas Minecrafta). Czyta lokalne pliki Shadertoy i generuje resource pack.
 *
 * Wejscie:  resourcepacks/shadertoy_input/<nazwa>/buffer_a.glsl   (wymagany)
 *                                                /image.glsl      (opcjonalny)
 *                                                /settings.properties (opcjonalny: time_scale=10.0)
 *           resourcepacks/shadertoy_input/pack.mcmeta               (opcjonalny - nadpisuje domyslny)
 * Wyjscie:  resourcepacks/shadertoy_generated/...
 *
 * Kod uzytkownika NIE jest przepisywany - dostaje tylko naglowek i stopke.
 */
public final class ShadertoyConverter {

    public static final String NAMESPACE = "shader";;
    public static final String INPUT_DIR = "shadertoy_input";
    public static final String OUTPUT_DIR = "shadertoy_generated";
    public static final float DEFAULT_TIME_SCALE = 1.0f;

    private static final String DEFAULT_PACK_MCMETA = """
            {
              "pack": {
                "description": "Shadertoy converted (local, do not distribute)",
                "min_format": 65,
                "max_format": 999
              }
            }
            """;

    private ShadertoyConverter() {}

    private static String res(String name) throws IOException {
        try (InputStream in = ShadertoyConverter.class.getResourceAsStream("/shadertoyconv/" + name)) {
            if (in == null) throw new IOException("No resources provided: " + name);
            return new String(in.readAllBytes(), StandardCharsets.UTF_8);
        }
    }

    /** Usuwa #version z kodu uzytkownika (naglowek ma wlasny) i normalizuje konce linii. */
    /** Usuwa #version, normalizuje konce linii i naprawia "#define NAZWA.28" (glslang wymaga spacji). */
    static String clean(String src) {
        String s = src.replace("\r\n", "\n").replace('\r', '\n').replace("\uFEFF", "");
        s = s.replaceAll("(?m)^[ \\t]*#version.*$", "");
        s = s.replaceAll("(?m)^([ \\t]*#[ \\t]*define[ \\t]+[A-Za-z_][A-Za-z0-9_]*)(?=\\.[0-9])", "$1 ");
        return s;
    }

    private static String join(String header, String src, String footer) {
        // stripTrailing + "\n": kod uzytkownika zawsze zaczyna sie w nowej linii,
        // a jego pierwsza linia ma numer 1 (dzieki "#line 1" na koncu naglowka)
        return header.stripTrailing() + "\n" + clean(src) + footer;
    }

    public static String convertBuffer(String src) throws IOException {
        return join(res("buffer_header.glsl"), src, res("buffer_footer.glsl"));
    }

    public static String convertImage(String src) throws IOException {
        return join(res("image_header.glsl"), src, res("image_footer.glsl"));
    }

    public static String convertSingle(String src) throws IOException {
        return join(res("single_header.glsl"), src, res("single_footer.glsl"));
    }

    public static String postEffectJson(String ns, String name, float timeScale) {
        return """
                {
                  "targets": {
                    "swap": {},
                    "previous": { "persistent": true }
                  },
                  "passes": [
                    {
                      "vertex_shader": "minecraft:core/screenquad",
                      "fragment_shader": "%1$s:post/%2$s",
                      "inputs": [
                        { "sampler_name": "In", "target": "minecraft:main" },
                        { "sampler_name": "Prev", "target": "previous", "bilinear": true }
                      ],
                      "output": "swap",
                      "uniforms": {
                        "ShadertoyConfig": [
                          { "name": "TimeScale", "type": "float", "value": %3$s }
                        ]
                      }
                    },
                    {
                      "vertex_shader": "minecraft:core/screenquad",
                      "fragment_shader": "minecraft:post/blit",
                      "inputs": [
                        { "sampler_name": "In", "target": "swap" }
                      ],
                      "output": "previous",
                      "uniforms": {
                        "BlitConfig": [
                          { "name": "ColorModulate", "type": "vec4", "value": [1.0, 1.0, 1.0, 1.0] }
                        ]
                      }
                    },
                    {
                      "vertex_shader": "minecraft:core/screenquad",
                      "fragment_shader": "%1$s:post/%2$s_image",
                      "inputs": [
                        { "sampler_name": "In", "target": "swap" }
                      ],
                      "output": "minecraft:main"
                    }
                  ]
                }
                """.formatted(ns, name, Float.toString(timeScale));
    }

    public static String postEffectJsonSingle(String ns, String name, float timeScale) {
        return """
            {
              "targets": { "swap": {} },
              "passes": [
                {
                  "vertex_shader": "minecraft:core/screenquad",
                  "fragment_shader": "%1$s:post/%2$s",
                  "inputs": [ { "sampler_name": "In", "target": "minecraft:main" } ],
                  "output": "swap",
                  "uniforms": {
                    "ShadertoyConfig": [ { "name": "TimeScale", "type": "float", "value": %3$s } ]
                  }
                },
                {
                  "vertex_shader": "minecraft:core/screenquad",
                  "fragment_shader": "minecraft:post/blit",
                  "inputs": [ { "sampler_name": "In", "target": "swap" } ],
                  "output": "minecraft:main",
                  "uniforms": {
                    "BlitConfig": [ { "name": "ColorModulate", "type": "vec4", "value": [1.0, 1.0, 1.0, 1.0] } ]
                  }
                }
              ]
            }
            """.formatted(ns, name, Float.toString(timeScale));
    }

    public static String sanitize(String folderName) {
        return folderName.toLowerCase().replaceAll("[^a-z0-9_]", "_");
    }

    /** @return lista nazw wygenerowanych efektow; komunikaty w {@code log}. */
    public static List<String> run(Path resourcePacksDir, List<String> log) throws IOException {
        List<String> generated = new ArrayList<>();
        Path in = resourcePacksDir.resolve(INPUT_DIR);
        Path out = resourcePacksDir.resolve(OUTPUT_DIR);

        if (!Files.isDirectory(in)) {
            Files.createDirectories(in);
            log.add("Created entry folder: " + in + " (add <name>/buffer_a.glsl)");
            return generated;
        }

        Path shaders = out.resolve("assets/" + NAMESPACE + "/shaders/post");
        Path effects = out.resolve("assets/" + NAMESPACE + "/post_effect");
        Files.createDirectories(shaders);
        Files.createDirectories(effects);

        try (DirectoryStream<Path> dirs = Files.newDirectoryStream(in, Files::isDirectory)) {
            for (Path d : dirs) {
                Path buf = d.resolve("buffer_a.glsl");
                Path img = d.resolve("image.glsl");
                boolean hasBuf = Files.isRegularFile(buf);
                boolean hasImg = Files.isRegularFile(img);
                if (!hasBuf && !hasImg) {
                    log.add("Skiping " + d.getFileName() + " (no buffer_a.glsl and image.glsl)");
                    continue;
                }
                String name = sanitize(d.getFileName().toString());
                float timeScale = readTimeScale(d.resolve("settings.properties"), log);

                if (hasBuf) {
                    String imageSrc = hasImg ? Files.readString(img) : res("default_image.glsl");
                    Files.writeString(shaders.resolve(name + ".fsh"), convertBuffer(Files.readString(buf)));
                    Files.writeString(shaders.resolve(name + "_image.fsh"), convertImage(imageSrc));
                    Files.writeString(effects.resolve(name + ".json"), postEffectJson(NAMESPACE, name, timeScale));
                } else {
                    Files.writeString(shaders.resolve(name + ".fsh"), convertSingle(Files.readString(img)));
                    Files.writeString(effects.resolve(name + ".json"), postEffectJsonSingle(NAMESPACE, name, timeScale));
                }
                generated.add(name);
                log.add("Generated effect: " + NAMESPACE + ":" + name + (hasBuf ? " (Buffer A + Image)" : " (only Image)")
                        + ", time_scale=" + timeScale);
            }
        }

        Path customMeta = in.resolve("pack.mcmeta");
        Files.writeString(out.resolve("pack.mcmeta"),
                Files.isRegularFile(customMeta) ? Files.readString(customMeta) : DEFAULT_PACK_MCMETA);
        return generated;
    }

    private static float readTimeScale(Path file, List<String> log) {
        if (!Files.isRegularFile(file)) return DEFAULT_TIME_SCALE;
        try (InputStream is = Files.newInputStream(file)) {
            Properties p = new Properties();
            p.load(is);
            return Float.parseFloat(p.getProperty("time_scale", Float.toString(DEFAULT_TIME_SCALE)).trim());
        } catch (IOException | NumberFormatException e) {
            log.add("Zly settings.properties w " + file.getParent().getFileName() + ": " + e.getMessage());
            return DEFAULT_TIME_SCALE;
        }
    }
}
