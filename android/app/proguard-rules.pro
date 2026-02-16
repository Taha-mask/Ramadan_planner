# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Timezone
-keep class org.threeten.bp.** { *; }
-keep class org.threeten.bp.zone.** { *; }
-keep class com.jakewharton.threetenabp.** { *; }
-keep class java.time.** { *; }
-keep class java.util.TimeZone { *; }

# Flutter Local Notifications
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keepclassmembers class com.dexterous.flutterlocalnotifications.** { *; }

# Intl
-keep class com.google.i18n.phonenumbers.** { *; }
