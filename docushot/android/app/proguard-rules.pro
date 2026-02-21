# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Google Play Billing (in_app_purchase)
-keep class com.android.vending.billing.** { *; }

# Google ML Kit (all modules)
-keep class com.google.mlkit.** { *; }
-dontwarn com.google.mlkit.**

# ML Kit Text Recognition script-specific modules
-keep class com.google.mlkit.vision.text.** { *; }
-dontwarn com.google.mlkit.vision.text.**

# Google Play Core (deferred components)
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**
