package io.github.kantrighteous.keychat

import android.app.Application
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel

class KeyChatApplication : Application() {
    lateinit var flutterEngine: FlutterEngine
        private set

    override fun onCreate() {
        super.onCreate()

        flutterEngine = FlutterEngine(this)
        configureBackgroundGenerationChannel(flutterEngine)
        flutterEngine.dartExecutor.executeDartEntrypoint(
            DartExecutor.DartEntrypoint.createDefault(),
        )
        FlutterEngineCache.getInstance().put(FLUTTER_ENGINE_ID, flutterEngine)
    }

    private fun configureBackgroundGenerationChannel(engine: FlutterEngine) {
        MethodChannel(engine.dartExecutor.binaryMessenger, BACKGROUND_GENERATION_CHANNEL)
            .setMethodCallHandler { call, result ->
                try {
                    when (call.method) {
                        "start" -> {
                            BackgroundGenerationService.start(this)
                            result.success(null)
                        }

                        "stop" -> {
                            BackgroundGenerationService.stop(this)
                            result.success(null)
                        }

                        else -> result.notImplemented()
                    }
                } catch (_: RuntimeException) {
                    result.error(
                        "background_generation_unavailable",
                        "Background generation is unavailable",
                        null,
                    )
                }
            }
    }

    companion object {
        const val FLUTTER_ENGINE_ID = "keychat_engine"
        private const val BACKGROUND_GENERATION_CHANNEL =
            "io.github.kantrighteous.keychat/background_generation"
    }
}
