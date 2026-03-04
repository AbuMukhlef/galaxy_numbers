import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en')
  ];

  /// App title
  ///
  /// In ar, this message translates to:
  /// **'مجرة الأرقام'**
  String get appTitle;

  /// No description provided for @startJourney.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ رحلتك'**
  String get startJourney;

  /// No description provided for @yourHeroName.
  ///
  /// In ar, this message translates to:
  /// **'ما اسمك البطولي؟'**
  String get yourHeroName;

  /// No description provided for @nameHint.
  ///
  /// In ar, this message translates to:
  /// **'اكتبي اسمك هنا...'**
  String get nameHint;

  /// No description provided for @choosePath.
  ///
  /// In ar, this message translates to:
  /// **'اختاري مسارك'**
  String get choosePath;

  /// No description provided for @readyToLaunch.
  ///
  /// In ar, this message translates to:
  /// **'جاهزة للانطلاق!'**
  String get readyToLaunch;

  /// No description provided for @enterGalaxy.
  ///
  /// In ar, this message translates to:
  /// **'ادخلي المجرة'**
  String get enterGalaxy;

  /// No description provided for @multiplicationPath.
  ///
  /// In ar, this message translates to:
  /// **'مسار الضرب'**
  String get multiplicationPath;

  /// No description provided for @fourOpsPath.
  ///
  /// In ar, this message translates to:
  /// **'مسار العمليات الأربع'**
  String get fourOpsPath;

  /// No description provided for @recommended.
  ///
  /// In ar, this message translates to:
  /// **'مُوصى به'**
  String get recommended;

  /// No description provided for @layer1.
  ///
  /// In ar, this message translates to:
  /// **'الطبقة 1 — فهم بصري'**
  String get layer1;

  /// No description provided for @layer2.
  ///
  /// In ar, this message translates to:
  /// **'الطبقة 2 — تثبيت'**
  String get layer2;

  /// No description provided for @layer3.
  ///
  /// In ar, this message translates to:
  /// **'الطبقة 3 — السرعة'**
  String get layer3;

  /// No description provided for @moonEnergy.
  ///
  /// In ar, this message translates to:
  /// **'طاقة القمر'**
  String get moonEnergy;

  /// No description provided for @needEnergy.
  ///
  /// In ar, this message translates to:
  /// **'تحتاجين 100% لفتح القمر التالي'**
  String get needEnergy;

  /// No description provided for @challengeMode.
  ///
  /// In ar, this message translates to:
  /// **'وضع التحدي'**
  String get challengeMode;

  /// No description provided for @questionPrompt.
  ///
  /// In ar, this message translates to:
  /// **'كم ناتج؟'**
  String get questionPrompt;

  /// No description provided for @tryAgain.
  ///
  /// In ar, this message translates to:
  /// **'جربي مرة ثانية 👀'**
  String get tryAgain;

  /// No description provided for @streak.
  ///
  /// In ar, this message translates to:
  /// **'سلسلة'**
  String get streak;

  /// No description provided for @confirm.
  ///
  /// In ar, this message translates to:
  /// **'✓ تأكيد'**
  String get confirm;

  /// No description provided for @certTitle.
  ///
  /// In ar, this message translates to:
  /// **'شهادة الإنجاز'**
  String get certTitle;

  /// No description provided for @certIntro.
  ///
  /// In ar, this message translates to:
  /// **'تشهد مجرة الأرقام بأن'**
  String get certIntro;

  /// No description provided for @certAction.
  ///
  /// In ar, this message translates to:
  /// **'أتقنت بكفاءة كاملة'**
  String get certAction;

  /// No description provided for @saveImage.
  ///
  /// In ar, this message translates to:
  /// **'حفظ كصورة'**
  String get saveImage;

  /// No description provided for @nextMoon.
  ///
  /// In ar, this message translates to:
  /// **'القمر التالي'**
  String get nextMoon;

  /// No description provided for @correct.
  ///
  /// In ar, this message translates to:
  /// **'صحيح'**
  String get correct;

  /// No description provided for @energyGained.
  ///
  /// In ar, this message translates to:
  /// **'طاقة مكتسبة'**
  String get energyGained;

  /// No description provided for @bestStreak.
  ///
  /// In ar, this message translates to:
  /// **'أفضل سلسلة'**
  String get bestStreak;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
