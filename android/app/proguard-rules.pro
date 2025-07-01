# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep RenderScript classes
-keep class android.renderscript.** { *; }

# Keep Bluetooth related classes
-keep class com.google.android.gms.** { *; }
-keep class com.google.android.gms.common.** { *; }
-keep class com.google.android.gms.common.api.** { *; }

# Keep SQLite related classes
-keep class org.sqlite.** { *; }
-keep class org.sqlite.database.** { *; }

# Keep file picker related classes
-keep class com.mr.flutter.plugin.filepicker.** { *; }

# Keep mobile scanner related classes
-keep class dev.steenbakker.mobile_scanner.** { *; }

# Keep share plus related classes
-keep class dev.fluttercommunity.plus.share.** { *; }

# Keep PDF related classes
-keep class com.itextpdf.** { *; }

# Keep Excel related classes
-keep class org.apache.poi.** { *; }

# Keep permission handler related classes
-keep class com.baseflow.permissionhandler.** { *; }

# Keep flutter blue plus related classes
-keep class com.polidea.flutter_blue_plus.** { *; }

# Keep path provider related classes
-keep class io.flutter.plugins.pathprovider.** { *; }

# Keep package info plus related classes
-keep class dev.fluttercommunity.plus.packageinfo.** { *; }

# Keep sqflite related classes
-keep class com.tekartik.sqflite.** { *; }

# Keep intl related classes
-keep class com.google.common.** { *; }

# Keep all native methods
-keepclassmembers class * {
    native <methods>;
}

# Keep all classes in your app's package
-keep class com.karaninfosys.gatepass.** { *; }

# Keep Bluetooth
-keep class com.polidea.rxandroidble2.** { *; }

# Keep QR code
-keep class com.google.zxing.** { *; }

# Keep image picker
-keep class com.github.dhaval2404.imagepicker.** { *; }

# Keep your application class
-keep class com.karaninfosys.gatepass.** { *; }

# Keep Parcelable classes
-keep class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}

# Keep Serializable classes
-keepnames class * implements java.io.Serializable
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    !static !transient <fields>;
    !private <fields>;
    !private <methods>;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# Keep R classes
-keepclassmembers class **.R$* {
    public static <fields>;
}

# Keep Excel library
-keep class org.apache.poi.** { *; }
-keep class org.apache.commons.** { *; }

# Keep Bluetooth related classes
-keep class com.polidea.rxandroidble2.** { *; }
-keep class io.reactivex.** { *; }

# Keep file picker
-keep class com.mr.flutter.plugin.filepicker.** { *; }

# Keep path provider
-keep class io.flutter.plugins.pathprovider.** { *; }

# Keep permission handler
-keep class com.baseflow.permissionhandler.** { *; }

# Keep QR code scanner
-keep class com.journeyapps.barcodescanner.** { *; }

# Keep printing
-keep class net.sf.andpdf.** { *; }
-keep class com.itextpdf.** { *; }

# Keep shared preferences
-keep class androidx.preference.** { *; }

# Keep multidex
-keep class androidx.multidex.** { *; }

# Keep Kotlin
-keep class kotlin.** { *; }
-keep class kotlin.Metadata { *; }
-dontwarn kotlin.**
-keepclassmembers class **$WhenMappings {
    <fields>;
}
-keepclassmembers class kotlin.Metadata {
    public <methods>;
}

# Keep Play Core and Flutter deferred components
-keep class com.google.android.play.** { *; }
-keep class com.google.android.play.core.** { *; }
-keep class io.flutter.embedding.engine.deferredcomponents.** { *; }
-keep class io.flutter.embedding.android.FlutterPlayStoreSplitApplication { *; }

# Workarounds for common R8/ProGuard annotation issues
-dontwarn proguard.annotation.Keep
-dontwarn proguard.annotation.KeepClassMembers

# Add any additional keep rules as needed for your plugins 