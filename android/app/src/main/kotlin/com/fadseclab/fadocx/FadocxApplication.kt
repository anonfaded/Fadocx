package com.fadseclab.fadocx

import android.app.Application
import android.util.Log
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.dart.DartExecutor

class FadocxApplication : Application() {
    lateinit var flutterEngine: FlutterEngine

    override fun onCreate() {
        super.onCreate()

        // 1. Pre-warm Flutter Engine
        flutterEngine = FlutterEngine(this)
        flutterEngine.dartExecutor.executeDartEntrypoint(
            DartExecutor.DartEntrypoint.createDefault()
        )
        FlutterEngineCache.getInstance().put("fadocx_engine", flutterEngine)

        // 2. Offload heavy library initialization to background thread
        Thread {
            try {
                val loaderClass = Class.forName("com.tom_roush.pdfbox.android.PDFBoxResourceLoader")
                loaderClass.getDeclaredMethod("init", android.content.Context::class.java)
                    .invoke(null, this)
                Log.i("Fadocx.App", "Native PDFBox initialized in background")
            } catch (e: Exception) {
                Log.e("Fadocx.App", "Native init error", e)
            }
        }.start()
    }
}
