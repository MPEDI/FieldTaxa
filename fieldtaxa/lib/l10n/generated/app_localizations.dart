import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_it.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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
    Locale('de'),
    Locale('en'),
    Locale('fr'),
    Locale('it'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'FieldTaxa'**
  String get appTitle;

  /// No description provided for @gallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get gallery;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @capture.
  ///
  /// In en, this message translates to:
  /// **'Capture'**
  String get capture;

  /// No description provided for @taxonomy.
  ///
  /// In en, this message translates to:
  /// **'Taxonomy'**
  String get taxonomy;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @classify.
  ///
  /// In en, this message translates to:
  /// **'Classify'**
  String get classify;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @addTag.
  ///
  /// In en, this message translates to:
  /// **'Add tag'**
  String get addTag;

  /// No description provided for @importRoll.
  ///
  /// In en, this message translates to:
  /// **'Import from camera roll'**
  String get importRoll;

  /// No description provided for @photo.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get photo;

  /// No description provided for @video.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get video;

  /// No description provided for @shutter.
  ///
  /// In en, this message translates to:
  /// **'Shutter'**
  String get shutter;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @storage.
  ///
  /// In en, this message translates to:
  /// **'Storage Library'**
  String get storage;

  /// No description provided for @light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// No description provided for @dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// No description provided for @auto.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get auto;

  /// No description provided for @appOnly.
  ///
  /// In en, this message translates to:
  /// **'In-app only'**
  String get appOnly;

  /// No description provided for @rollOnly.
  ///
  /// In en, this message translates to:
  /// **'Camera roll'**
  String get rollOnly;

  /// No description provided for @both.
  ///
  /// In en, this message translates to:
  /// **'Both'**
  String get both;

  /// No description provided for @platform.
  ///
  /// In en, this message translates to:
  /// **'Maps'**
  String get platform;

  /// No description provided for @results.
  ///
  /// In en, this message translates to:
  /// **'results'**
  String get results;

  /// No description provided for @recent.
  ///
  /// In en, this message translates to:
  /// **'Recent searches'**
  String get recent;

  /// No description provided for @selectCats.
  ///
  /// In en, this message translates to:
  /// **'Filter by category'**
  String get selectCats;

  /// No description provided for @runSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get runSearch;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @addCategory.
  ///
  /// In en, this message translates to:
  /// **'Add category'**
  String get addCategory;

  /// No description provided for @drillMode.
  ///
  /// In en, this message translates to:
  /// **'Browse tree'**
  String get drillMode;

  /// No description provided for @searchMode.
  ///
  /// In en, this message translates to:
  /// **'Find'**
  String get searchMode;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @tagsOn.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get tagsOn;

  /// No description provided for @noTags.
  ///
  /// In en, this message translates to:
  /// **'No tags'**
  String get noTags;

  /// No description provided for @linked.
  ///
  /// In en, this message translates to:
  /// **'Linked'**
  String get linked;

  /// No description provided for @linkedNote.
  ///
  /// In en, this message translates to:
  /// **'Linked to camera roll'**
  String get linkedNote;

  /// No description provided for @items.
  ///
  /// In en, this message translates to:
  /// **'items'**
  String get items;

  /// No description provided for @newCat.
  ///
  /// In en, this message translates to:
  /// **'New category'**
  String get newCat;

  /// No description provided for @editTree.
  ///
  /// In en, this message translates to:
  /// **'Edit tree'**
  String get editTree;

  /// No description provided for @unclassified.
  ///
  /// In en, this message translates to:
  /// **'Unclassified'**
  String get unclassified;

  /// No description provided for @chooseFromRoll.
  ///
  /// In en, this message translates to:
  /// **'Choose from roll'**
  String get chooseFromRoll;

  /// No description provided for @platformNote.
  ///
  /// In en, this message translates to:
  /// **'Swisstopo is only available in Switzerland'**
  String get platformNote;

  /// No description provided for @dateRange.
  ///
  /// In en, this message translates to:
  /// **'Date range'**
  String get dateRange;

  /// No description provided for @from.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get from;

  /// No description provided for @to.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get to;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @developer.
  ///
  /// In en, this message translates to:
  /// **'Developer'**
  String get developer;

  /// No description provided for @website.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get website;

  /// No description provided for @releaseDate.
  ///
  /// In en, this message translates to:
  /// **'Release date'**
  String get releaseDate;

  /// No description provided for @appDesc.
  ///
  /// In en, this message translates to:
  /// **'FieldTaxa lets you capture, classify, and track field observations of fauna, flora, and other taxa.'**
  String get appDesc;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get seeAll;

  /// No description provided for @gpsLocation.
  ///
  /// In en, this message translates to:
  /// **'GPS location'**
  String get gpsLocation;

  /// No description provided for @obs.
  ///
  /// In en, this message translates to:
  /// **'observation'**
  String get obs;

  /// No description provided for @observations.
  ///
  /// In en, this message translates to:
  /// **'observations'**
  String get observations;

  /// No description provided for @firstObs.
  ///
  /// In en, this message translates to:
  /// **'First obs.'**
  String get firstObs;

  /// No description provided for @lastObs.
  ///
  /// In en, this message translates to:
  /// **'Last obs.'**
  String get lastObs;

  /// No description provided for @locations.
  ///
  /// In en, this message translates to:
  /// **'Locations'**
  String get locations;

  /// No description provided for @logSighting.
  ///
  /// In en, this message translates to:
  /// **'Log sighting'**
  String get logSighting;

  /// No description provided for @obsDateTime.
  ///
  /// In en, this message translates to:
  /// **'Date & time'**
  String get obsDateTime;

  /// No description provided for @addObs.
  ///
  /// In en, this message translates to:
  /// **'Add observation (no photo)'**
  String get addObs;

  /// No description provided for @coordLabel.
  ///
  /// In en, this message translates to:
  /// **'Coordinates'**
  String get coordLabel;

  /// No description provided for @mapLabel.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get mapLabel;

  /// No description provided for @defaultMaps.
  ///
  /// In en, this message translates to:
  /// **'System maps'**
  String get defaultMaps;

  /// No description provided for @openIn.
  ///
  /// In en, this message translates to:
  /// **'Open in …'**
  String get openIn;

  /// No description provided for @openMapsNote.
  ///
  /// In en, this message translates to:
  /// **'System maps will open the external maps app'**
  String get openMapsNote;

  /// No description provided for @lv95Note.
  ///
  /// In en, this message translates to:
  /// **'Swiss territory only — LV95 outside Switzerland may be inaccurate'**
  String get lv95Note;

  /// No description provided for @coordinates.
  ///
  /// In en, this message translates to:
  /// **'Coordinates'**
  String get coordinates;

  /// No description provided for @tapToCapture.
  ///
  /// In en, this message translates to:
  /// **'Tap to capture'**
  String get tapToCapture;

  /// No description provided for @closeCamera.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get closeCamera;

  /// No description provided for @noObservations.
  ///
  /// In en, this message translates to:
  /// **'No observations yet'**
  String get noObservations;

  /// No description provided for @sightings.
  ///
  /// In en, this message translates to:
  /// **'sightings'**
  String get sightings;

  /// No description provided for @addChildCategory.
  ///
  /// In en, this message translates to:
  /// **'Add child category'**
  String get addChildCategory;

  /// No description provided for @deleteCategory.
  ///
  /// In en, this message translates to:
  /// **'Delete category'**
  String get deleteCategory;

  /// No description provided for @confirmDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete this category and all its children?'**
  String get confirmDelete;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @categoryName.
  ///
  /// In en, this message translates to:
  /// **'Category name'**
  String get categoryName;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @deutsch.
  ///
  /// In en, this message translates to:
  /// **'Deutsch'**
  String get deutsch;

  /// No description provided for @italiano.
  ///
  /// In en, this message translates to:
  /// **'Italiano'**
  String get italiano;

  /// No description provided for @francais.
  ///
  /// In en, this message translates to:
  /// **'Français'**
  String get francais;

  /// No description provided for @systemMaps.
  ///
  /// In en, this message translates to:
  /// **'System Maps'**
  String get systemMaps;

  /// No description provided for @swisstopo.
  ///
  /// In en, this message translates to:
  /// **'Swisstopo'**
  String get swisstopo;

  /// No description provided for @gps.
  ///
  /// In en, this message translates to:
  /// **'GPS'**
  String get gps;

  /// No description provided for @lv95.
  ///
  /// In en, this message translates to:
  /// **'Swiss LV95'**
  String get lv95;

  /// No description provided for @aboutFieldTaxa.
  ///
  /// In en, this message translates to:
  /// **'About FieldTaxa'**
  String get aboutFieldTaxa;

  /// No description provided for @build.
  ///
  /// In en, this message translates to:
  /// **'Build'**
  String get build;

  /// No description provided for @noDate.
  ///
  /// In en, this message translates to:
  /// **'No date'**
  String get noDate;

  /// No description provided for @allItems.
  ///
  /// In en, this message translates to:
  /// **'All items'**
  String get allItems;

  /// No description provided for @storageLibrary.
  ///
  /// In en, this message translates to:
  /// **'Storage Library'**
  String get storageLibrary;

  /// No description provided for @coordSystem.
  ///
  /// In en, this message translates to:
  /// **'Coordinates'**
  String get coordSystem;

  /// No description provided for @mapProvider.
  ///
  /// In en, this message translates to:
  /// **'Maps'**
  String get mapProvider;

  /// No description provided for @previewNote.
  ///
  /// In en, this message translates to:
  /// **'LV95 coordinates are only accurate within Swiss territory.'**
  String get previewNote;
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
      <String>['de', 'en', 'fr', 'it'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
    case 'it':
      return AppLocalizationsIt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
