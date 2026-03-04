# 🌌 مجرة الأرقام — Galaxy Numbers

لعبة تعليمية فضائية لتعلم الرياضيات | Flutter + Cubit + Hive + Supabase

---

## 📁 هيكل المشروع الكامل

```
galaxy_numbers/
├── lib/
│   ├── main.dart                        ← نقطة البداية
│   ├── l10n/
│   │   ├── app_ar.arb                   ← النصوص العربية
│   │   └── app_en.arb                   ← النصوص الإنجليزية
│   ├── core/
│   │   ├── app_router.dart              ← التوجيه بناءً على Auth
│   │   ├── app_providers.dart           ← MultiBlocProvider
│   │   └── app_theme.dart               ← الثيم الداكن
│   ├── services/
│   │   ├── hive_service.dart            ← التخزين المحلي
│   │   └── audio_service.dart           ← الأصوات (يعمل بـ haptic الآن)
│   ├── models/                          ← UserModel, MoonProgress, ...
│   ├── cubits/                          ← Auth, Galaxy, Moon, Challenge, ...
│   └── screens/
│       ├── onboarding/                  ← 4 صفحات الترحيب
│       ├── galaxy/                      ← خريطة المجرة
│       ├── moon/                        ← الطبقات الثلاث
│       ├── challenge/                   ← محرك الأسئلة
│       └── certificate/                 ← شهادة الإنجاز
├── assets/
│   └── sounds/
│       └── README.txt                   ← تعليمات إضافة ملفات الصوت
├── fonts/                               ← ضع هنا خط Cairo
├── pubspec.yaml
├── l10n.yaml                            ← إعداد الترجمة
└── supabase_schema.sql                  ← شغّله في SQL Editor
```

---

## 🚀 خطوات التشغيل

### الخطوة 1 — إنشاء مشروع Flutter
```bash
# في مجلد فارغ جديد:
flutter create galaxy_numbers
cd galaxy_numbers

# احذف lib/ الافتراضي وانسخ lib/ من هذا المشروع
```

### الخطوة 2 — تثبيت الـ packages
```bash
flutter pub get
```

### الخطوة 3 — توليد Hive adapters
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### الخطوة 4 — إعداد Supabase
1. أنشئ مشروعاً على [supabase.com](https://supabase.com)
2. من القائمة الجانبية: **SQL Editor**
3. انسخ `supabase_schema.sql` كله → الصق → اضغط **RUN**
4. من **Settings → API** انسخ:
   - `Project URL`
   - `anon public key`
5. ضعهما في `lib/main.dart`

### الخطوة 5 — تشغيل التطبيق
```bash
flutter run
```

> التطبيق يعمل **بدون Supabase** — كل البيانات تُحفظ محلياً بـ Hive.

---

## 🌍 دعم اللغتين

| الملف | المحتوى |
|---|---|
| `lib/l10n/app_ar.arb` | كل النصوص بالعربية |
| `lib/l10n/app_en.arb` | كل النصوص بالإنجليزية |
| `l10n.yaml` | إعداد نظام الترجمة |

لتغيير اللغة في `main.dart`:
```dart
locale: const Locale('en'),  // إنجليزي
locale: const Locale('ar'),  // عربي (الافتراضي)
```

---

## 🔊 الأصوات

الأصوات تعمل حالياً بـ **HapticFeedback** (اهتزاز). لإضافة أصوات حقيقية:
1. راجع `assets/sounds/README.txt`
2. ضع الملفات `.mp3` في `assets/sounds/`
3. أضف `audioplayers: ^6.0.0` في `pubspec.yaml`
4. فعّل الكود المعلّق في `lib/services/audio_service.dart`

---

## 📱 Android و iOS

مجلدا `android/` و `ios/` يُولَّدان تلقائياً عند تشغيل:
```bash
flutter create galaxy_numbers
```
Flutter يدعم Android و iOS و Web بنفس الكود.

---

## ⚡ نظام الطاقة

| الحدث | الطاقة |
|---|---|
| إجابة صحيحة | +2% |
| سلسلة 5 متتالية | +5% |
| سرعة < 3 ثوانٍ | +3% |
| خطأ | لا تنقص |

---

## 🧠 المحرك التكيفي

- `weaknessScore = wrong ÷ attempts`
- إذا > 0.35 → تدخل قائمة الضعف
- توليد الأسئلة: **70% عادي + 30% ضعف**
- تكرار متباعد: بعد 3 مسائل، ثم 10، ثم اليوم التالي

---

## 📦 جميع المكتبات

| المكتبة | الاستخدام |
|---|---|
| `flutter_bloc` | إدارة الحالة بـ Cubit |
| `equatable` | مقارنة الـ states |
| `hive_flutter` | تخزين محلي سريع |
| `supabase_flutter` | مزامنة سحابية |
| `flutter_localizations` | دعم العربية والإنجليزية |
| `image_gallery_saver` | حفظ الشهادة صورة |
| `connectivity_plus` | كشف الاتصال بالإنترنت |
| `uuid` | معرّفات فريدة للمستخدمين |
