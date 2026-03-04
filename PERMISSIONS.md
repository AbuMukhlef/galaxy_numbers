# صلاحيات مجرة الأرقام — image_gallery_saver_plus

## 🤖 Android

### android/app/src/main/AndroidManifest.xml
أضف قبل وسم <application>:

```xml
<!-- حفظ الشهادة في الاستوديو — Android 12 وما دون -->
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"
    android:maxSdkVersion="32" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"
    android:maxSdkVersion="32" />

<!-- Android 13+ -->
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />

<!-- اهتزاز HapticFeedback -->
<uses-permission android:name="android.permission.VIBRATE" />
```

### android/app/build.gradle
```gradle
defaultConfig {
    minSdkVersion 21
    targetSdkVersion 34
}
```

---

## 🍎 iOS

### ios/Runner/Info.plist
أضف داخل <dict>:

```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>نحتاج الوصول لمعرض صورك لحفظ شهادة الإنجاز</string>

<key>NSPhotoLibraryAddUsageDescription</key>
<string>نحتاج إضافة شهادة الإنجاز إلى معرض صورك</string>
```

---

## ملخص

| الصلاحية | السبب | المنصة |
|---|---|---|
| WRITE_EXTERNAL_STORAGE | حفظ الشهادة | Android ≤ 12 |
| READ_EXTERNAL_STORAGE | قراءة المعرض | Android ≤ 12 |
| READ_MEDIA_IMAGES | الوصول للصور | Android 13+ |
| VIBRATE | HapticFeedback | Android |
| NSPhotoLibraryAddUsageDescription | حفظ في الاستوديو | iOS |

> image_gallery_saver_plus يطلب الإذن تلقائياً — لا تحتاج كود إضافي.
