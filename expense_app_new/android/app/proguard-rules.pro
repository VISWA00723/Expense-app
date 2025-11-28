# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# ML Kit Text Recognition - Suppress warnings for missing optional language models
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**

# Firebase Analytics
-keep class com.google.firebase.analytics.** { *; }
-dontwarn com.google.firebase.analytics.**

# Speech to Text
-dontwarn com.csdcorp.speech_to_text.**

# Play Core - Suppress warnings for missing deferred component classes
-dontwarn com.google.android.play.core.splitcompat.**
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**

# Biometrics (local_auth)
-keep class io.flutter.plugins.localauth.** { *; }
-keep class androidx.biometric.** { *; }
-dontwarn androidx.biometric.**

# Speech to Text
-keep class com.csdcorp.speech_to_text.** { *; }
-dontwarn com.google.android.speech.IWSpeechService

# Drift (Database)
# Keep generated database classes and tables
-keep class * extends androidx.room.RoomDatabase
-keep class * extends androidx.room.Entity
-keep class * extends androidx.room.Dao
-dontwarn androidx.room.paging.**

# Flutter Local Notifications
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-dontwarn com.dexterous.flutterlocalnotifications.**

# General Safety for Data Models (Reflection/Serialization)
-keepnames class com.example.expense_app_new.database.** { *; }
-keepclassmembers class com.example.expense_app_new.database.** {
    <fields>;
}
