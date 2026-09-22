package com.enderx.posteffect.post_effects.client;

import net.minecraft.client.Minecraft;

import java.lang.reflect.Method;
import java.lang.reflect.Modifier;

/**
 * Enables/disables post-effects via GameRenderer.
 * Uses reflection because signatures (Identifier vs ResourceLocation, method names) changed between versions;
 * in 26.x the code is unobfuscated, so names are stable. If the name changes, you will get a clear error in the log.
 */
public final class PostEffectController {

    private PostEffectController() {}

    public static void enable(String namespace, String path) throws Exception {
        Object renderer = Minecraft.getInstance().gameRenderer;
        Method setter = null;
        for (Method m : renderer.getClass().getMethods()) {
            if (m.getName().equals("setPostEffect") && m.getParameterCount() == 1) { setter = m; break; }
        }
        if (setter == null) throw new NoSuchMethodException("GameRenderer#setPostEffect(...) not found - match the name to 26.3");
        setter.invoke(renderer, makeId(setter.getParameterTypes()[0], namespace, path));
    }

    public static void disable() throws Exception {
        Object renderer = Minecraft.getInstance().gameRenderer;
        for (Method m : renderer.getClass().getMethods()) {
            if (m.getName().equals("clearPostEffect") && m.getParameterCount() == 0) { m.invoke(renderer); return; }
        }
        throw new NoSuchMethodException("GameRenderer#clearPostEffect() not found - match the name to 26.3");
    }

    private static Object makeId(Class<?> idClass, String ns, String path) throws Exception {
        for (Method m : idClass.getMethods()) {
            if (!Modifier.isStatic(m.getModifiers()) || m.getReturnType() != idClass) continue;
            Class<?>[] p = m.getParameterTypes();
            if (m.getName().equals("fromNamespaceAndPath") && p.length == 2 && p[0] == String.class && p[1] == String.class)
                return m.invoke(null, ns, path);
        }
        for (Method m : idClass.getMethods()) {
            if (!Modifier.isStatic(m.getModifiers()) || m.getReturnType() != idClass) continue;
            Class<?>[] p = m.getParameterTypes();
            if (m.getName().equals("parse") && p.length == 1 && p[0] == String.class)
                return m.invoke(null, ns + ":" + path);
        }
        throw new NoSuchMethodException("Build failed " + idClass.getName() + " from text");
    }
}