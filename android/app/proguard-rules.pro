# Flutter-specific ProGuard rules for SpendWise
# Keep Flutter engine and plugin classes
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.plugin.common.** { *; }
-dontwarn io.flutter.**

# Keep Firebase classes
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# Keep app's own package (SMS receiver + MainActivity must not be renamed)
-keep class com.family.spendwise.** { *; }

# Preserve annotations used at runtime
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable

# Keep Parcelable implementations
-keepclassmembers class * implements android.os.Parcelable {
    static ** CREATOR;
}
