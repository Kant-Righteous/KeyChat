package io.github.kantrighteous.keychat

import android.content.Context
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun provideFlutterEngine(context: Context): FlutterEngine =
        (application as KeyChatApplication).flutterEngine

    override fun shouldDestroyEngineWithHost(): Boolean = false
}
