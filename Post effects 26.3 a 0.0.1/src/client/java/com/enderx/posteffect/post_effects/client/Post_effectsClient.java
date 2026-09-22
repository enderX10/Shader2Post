package com.enderx.posteffect.post_effects.client;

import com.mojang.brigadier.arguments.StringArgumentType;
import net.fabricmc.api.ClientModInitializer;
import net.fabricmc.fabric.api.client.command.v2.ClientCommandRegistrationCallback;
import net.fabricmc.fabric.api.client.command.v2.FabricClientCommandSource;
import net.fabricmc.loader.api.FabricLoader;
import net.minecraft.client.Minecraft;
import net.minecraft.network.chat.Component;
import net.fabricmc.fabric.api.client.command.v2.ClientCommands;
import java.io.IOException;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.List;


public class Post_effectsClient implements ClientModInitializer {

    private static volatile String activeEffect = null;

    private static Path packsDir() {
        return FabricLoader.getInstance().getGameDir().resolve("resourcepacks");
    }

    @Override
    public void onInitializeClient() {
        // conversion on game startup (the pack must exist before you enable it in the resource packs menu)
        List<String> log = new ArrayList<>();
        try {
            ShadertoyConverter.run(packsDir(), log);
        } catch (IOException e) {
            log.add("Error in conevrting: " + e);
        }
        log.forEach(l -> System.out.println("[shadertoyconv] " + l));

        ClientCommandRegistrationCallback.EVENT.register((dispatcher, registryAccess) ->
                dispatcher.register(ClientCommands.literal("shadertoy")
                        .then(ClientCommands.literal("convert").executes(ctx -> {
                            List<String> l = new ArrayList<>();
                            try {
                                List<String> names = ShadertoyConverter.run(packsDir(), l);
                                l.forEach(s -> ctx.getSource().sendFeedback(Component.literal(s)));
                                if (names.isEmpty()) return 0;
                            } catch (IOException e) {
                                ctx.getSource().sendError(Component.literal("Error in converting: " + e));
                                return 0;
                            }
                            ctx.getSource().sendFeedback(Component.literal(
                                    "Realoding resources... (pack 'shadertoy_generated' needs to be turned on in resourcepacks)"));
                            Minecraft mc = Minecraft.getInstance();
                            mc.reloadResourcePacks().thenRun(() -> mc.execute(() -> {
                                String a = activeEffect;
                                if (a != null) apply(ctx.getSource(), a);
                            }));
                            return 1;
                        }))
                        .then(ClientCommands.literal("on")
                                .then(ClientCommands.argument("name", StringArgumentType.word()).executes(ctx -> {
                                    String name = StringArgumentType.getString(ctx, "name");
                                    return apply(ctx.getSource(), name) ? 1 : 0;
                                })))
                        .then(ClientCommands.literal("off").executes(ctx -> {
                            try {
                                PostEffectController.disable();
                                activeEffect = null;
                                ctx.getSource().sendFeedback(Component.literal("Effect turned off."));
                                return 1;
                            } catch (Exception e) {
                                ctx.getSource().sendError(Component.literal("Failed to turn off: " + e));
                                return 0;
                            }
                        }))
                ));
    }

    private static boolean apply(FabricClientCommandSource src, String name) {
        try {
            PostEffectController.enable(ShadertoyConverter.NAMESPACE, name);
            activeEffect = name;
            src.sendFeedback(Component.literal("Effect turned on " + ShadertoyConverter.NAMESPACE + ":" + name));
            return true;
        } catch (Exception e) {
            src.sendError(Component.literal("Failed to turn on: " + e));
            e.printStackTrace();
            return false;
        }
    }
}