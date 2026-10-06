package com.midiofa.curvas.app

import android.os.Bundle
import androidx.core.view.WindowCompat
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Apply after Flutter configures its window, including on Android < 15.
        // Flutter's SafeArea/MediaQuery handle insets; do not consume them here.
        WindowCompat.enableEdgeToEdge(window)
    }
}
