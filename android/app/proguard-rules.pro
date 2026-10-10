-dontoptimize

# Google ML Kit ProGuard Rules
-keep class com.google.mlkit.** { *; }
-dontwarn com.google.mlkit.**
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# Camera and SQLite rules
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.plugins.**
