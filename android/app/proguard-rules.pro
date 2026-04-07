# ProGuard rules for LinkVault

# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.embedding.** { *; }

# Hive
-keep class * extends com.google.flatbuffers.Table
-keep class com.google.flatbuffers.** { *; }
-keep @interface io.hive.** { *; }
-keep class * extends hive.** { *; }

# Supabase / Postgrest
-keep class io.github.jan.supabase.** { *; }
-keep class io.ktor.** { *; }
-dontwarn io.ktor.**

# OkHttp
-dontwarn okhttp3.**
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }

# Encrypt / PointyCastle
-keep class org.bouncycastle.** { *; }
-dontwarn org.bouncycastle.**

# Local Auth
-keep class androidx.biometric.** { *; }

# Kotlin coroutines
-keepclassmembernames class kotlinx.** { volatile <fields>; }

# Keep enums
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Prevent stripping line number info (useful for crash reports)
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile
