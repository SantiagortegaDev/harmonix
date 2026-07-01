# ProGuard / R8 rules para Harmonix

# Flutter
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
-dontwarn io.flutter.embedding.**

# just_audio + audio_service
-keep class com.ryanheise.audioservice.** { *; }
-keep class com.ryanheise.just_audio.** { *; }

# Hive (reflexión)
-keep class * extends com.google.protobuf.GeneratedMessageLite { *; }
-keepattributes Signature
-keepattributes *Annotation*
-keep class com.github.omarmiatello.kotlinplayground.** { *; }

# Retrofit / OkHttp
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn retrofit2.**
-keepattributes RuntimeVisibleAnnotations,RuntimeInvisibleAnnotations
-keepclassmembers,allowshrinking,allowobfuscation interface * {
    @retrofit2.http.* <methods>;
}

# Modelos serializados con Hive (mantener campos)
-keep class com.harmonix.app.** { *; }
-keep class com.harmonix.** { *; }

# FlutterDownloader
-keep class vn.hunghd.flutterdownloader.** { *; }
