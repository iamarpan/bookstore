# Add project specific ProGuard rules here.
# You can control the set of applied configuration files using the
# proguardFiles setting in build.gradle.kts.
#
# For more details, see
#   http://developer.android.com/guide/developing/tools/proguard.html

# If your project uses WebView with JS, uncomment the following
# and specify the fully qualified class name to the JavaScript interface
# class:
#-keepclassmembers class fqcn.of.javascript.interface.for.webview {
#   public *;
#}

# Uncomment this to preserve the line number information for
# debugging stack traces.
-keepattributes SourceFile,LineNumberTable

# If you keep the line number information, uncomment this to
# hide the original source file name.
#-renamesourcefileattribute SourceFile

# --- Retrofit & Gson ---
-keepattributes Signature
-keepclassmembers,allowshrinking,allowobfuscation interface * {
    @retrofit2.http.* <methods>;
}
-keep class com.bookstore.bookapp.data.remote.api.** { *; }
-keep class com.bookstore.bookapp.domain.model.** { *; }

# --- Room ---
-keep class * extends androidx.room.RoomDatabase
-keep @androidx.room.Entity class *
-keep class com.bookstore.bookapp.data.local.entity.** { *; }

# --- Coroutines ---
-keepnames class kotlinx.coroutines.internal.MainDispatcherFactory {}
-keepnames class kotlinx.coroutines.CoroutineExceptionHandler {}
-keepclassmembernames class kotlinx.** {
    volatile <fields>;
}

# --- Hilt ---
-keep,allowobfuscation,allowshrinking class dagger.**
-keep,allowobfuscation,allowshrinking class * extends dagger.internal.codegen.ComponentProcessor
-keepclassmembers class * {
    @javax.inject.Inject *;
}

# --- Google ML Kit ---
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.vision.** { *; }
