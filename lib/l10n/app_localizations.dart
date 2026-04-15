import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ur.dart';

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
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ur')
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Fadocx'**
  String get appName;

  /// No description provided for @appDescription.
  ///
  /// In en, this message translates to:
  /// **'Document Viewer'**
  String get appDescription;

  /// No description provided for @homeTitle.
  ///
  /// In en, this message translates to:
  /// **'Fadocx'**
  String get homeTitle;

  /// No description provided for @recentFiles.
  ///
  /// In en, this message translates to:
  /// **'Recent Files'**
  String get recentFiles;

  /// No description provided for @noRecentFiles.
  ///
  /// In en, this message translates to:
  /// **'No recent files. Open a document to get started.'**
  String get noRecentFiles;

  /// No description provided for @openFile.
  ///
  /// In en, this message translates to:
  /// **'Open File'**
  String get openFile;

  /// No description provided for @openFileTooltip.
  ///
  /// In en, this message translates to:
  /// **'Browse and open a document'**
  String get openFileTooltip;

  /// No description provided for @pdfFile.
  ///
  /// In en, this message translates to:
  /// **'PDF File'**
  String get pdfFile;

  /// No description provided for @docxFile.
  ///
  /// In en, this message translates to:
  /// **'Word Document'**
  String get docxFile;

  /// No description provided for @xlsxFile.
  ///
  /// In en, this message translates to:
  /// **'Excel Spreadsheet'**
  String get xlsxFile;

  /// No description provided for @csvFile.
  ///
  /// In en, this message translates to:
  /// **'CSV File'**
  String get csvFile;

  /// No description provided for @unknownFile.
  ///
  /// In en, this message translates to:
  /// **'Unknown File'**
  String get unknownFile;

  /// No description provided for @page.
  ///
  /// In en, this message translates to:
  /// **'Page'**
  String get page;

  /// No description provided for @pageOf.
  ///
  /// In en, this message translates to:
  /// **'of'**
  String get pageOf;

  /// No description provided for @jumpToPage.
  ///
  /// In en, this message translates to:
  /// **'Jump to page'**
  String get jumpToPage;

  /// No description provided for @sheet.
  ///
  /// In en, this message translates to:
  /// **'Sheet'**
  String get sheet;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @warning.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get warning;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @unsupportedFileType.
  ///
  /// In en, this message translates to:
  /// **'File type not supported'**
  String get unsupportedFileType;

  /// No description provided for @fileNotFound.
  ///
  /// In en, this message translates to:
  /// **'File not found'**
  String get fileNotFound;

  /// No description provided for @permissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Permission denied'**
  String get permissionDenied;

  /// No description provided for @corruptedFile.
  ///
  /// In en, this message translates to:
  /// **'File appears to be corrupted'**
  String get corruptedFile;

  /// No description provided for @loadingDocument.
  ///
  /// In en, this message translates to:
  /// **'Loading document...'**
  String get loadingDocument;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System Default'**
  String get themeSystem;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageUrdu.
  ///
  /// In en, this message translates to:
  /// **'اردو'**
  String get languageUrdu;

  /// No description provided for @appVersion.
  ///
  /// In en, this message translates to:
  /// **'App Version'**
  String get appVersion;

  /// No description provided for @clearRecentFiles.
  ///
  /// In en, this message translates to:
  /// **'Clear recent files'**
  String get clearRecentFiles;

  /// No description provided for @backButton.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get backButton;

  /// No description provided for @emptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No Documents'**
  String get emptyTitle;

  /// No description provided for @emptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Start by opening a document from your device'**
  String get emptyMessage;

  /// No description provided for @startBrowsing.
  ///
  /// In en, this message translates to:
  /// **'Start Browsing'**
  String get startBrowsing;

  /// No description provided for @languageChanged.
  ///
  /// In en, this message translates to:
  /// **'Language changed to English'**
  String get languageChanged;

  /// No description provided for @privacyDescription.
  ///
  /// In en, this message translates to:
  /// **'Fadocx is a document viewer. Your files are stored locally on your device and are never transmitted to any server.'**
  String get privacyDescription;

  /// No description provided for @aboutDescription.
  ///
  /// In en, this message translates to:
  /// **'Fadocx v1.0.0 - Your private document viewer. Built to respect your privacy.'**
  String get aboutDescription;

  /// No description provided for @tableRows.
  ///
  /// In en, this message translates to:
  /// **'rows'**
  String get tableRows;

  /// No description provided for @tableEmpty.
  ///
  /// In en, this message translates to:
  /// **'No data to display'**
  String get tableEmpty;

  /// No description provided for @tableNoContent.
  ///
  /// In en, this message translates to:
  /// **'Sheet is empty'**
  String get tableNoContent;

  /// No description provided for @sheetEmpty.
  ///
  /// In en, this message translates to:
  /// **'Sheet is empty'**
  String get sheetEmpty;

  /// No description provided for @noTableData.
  ///
  /// In en, this message translates to:
  /// **'No table data'**
  String get noTableData;

  /// No description provided for @noSpreadsheetData.
  ///
  /// In en, this message translates to:
  /// **'No spreadsheet data'**
  String get noSpreadsheetData;

  /// No description provided for @rowsSymbol.
  ///
  /// In en, this message translates to:
  /// **'rows'**
  String get rowsSymbol;

  /// No description provided for @colsSymbol.
  ///
  /// In en, this message translates to:
  /// **'cols'**
  String get colsSymbol;

  /// No description provided for @noSlidesFound.
  ///
  /// In en, this message translates to:
  /// **'No slides found'**
  String get noSlidesFound;

  /// No description provided for @slidesCount.
  ///
  /// In en, this message translates to:
  /// **'slides'**
  String get slidesCount;

  /// No description provided for @pptUnsupported.
  ///
  /// In en, this message translates to:
  /// **'PPT file parsed but contains no slides'**
  String get pptUnsupported;

  /// No description provided for @odpUnsupported.
  ///
  /// In en, this message translates to:
  /// **'ODP file parsed but contains no slides or unreadable content'**
  String get odpUnsupported;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @previous.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previous;

  /// No description provided for @noTextContent.
  ///
  /// In en, this message translates to:
  /// **'No text content found'**
  String get noTextContent;

  /// No description provided for @couldNotParse.
  ///
  /// In en, this message translates to:
  /// **'Could not parse file'**
  String get couldNotParse;

  /// No description provided for @file.
  ///
  /// In en, this message translates to:
  /// **'File'**
  String get file;

  /// No description provided for @slides.
  ///
  /// In en, this message translates to:
  /// **'Slide'**
  String get slides;

  /// No description provided for @previewNotSupported.
  ///
  /// In en, this message translates to:
  /// **'Preview not yet supported'**
  String get previewNotSupported;

  /// No description provided for @openWithSystemApp.
  ///
  /// In en, this message translates to:
  /// **'Open with System App'**
  String get openWithSystemApp;

  /// No description provided for @systemAppNotImplemented.
  ///
  /// In en, this message translates to:
  /// **'System app opening not yet implemented'**
  String get systemAppNotImplemented;

  /// No description provided for @type.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get type;

  /// No description provided for @fileNotFoundMessage.
  ///
  /// In en, this message translates to:
  /// **'File not found'**
  String get fileNotFoundMessage;

  /// No description provided for @fileTooLarge.
  ///
  /// In en, this message translates to:
  /// **'File size exceeds maximum limit (100MB)'**
  String get fileTooLarge;

  /// No description provided for @errorLoadingFile.
  ///
  /// In en, this message translates to:
  /// **'Error loading file'**
  String get errorLoadingFile;

  /// No description provided for @docxPreviewNotSupported.
  ///
  /// In en, this message translates to:
  /// **'DOCX preview not yet fully supported'**
  String get docxPreviewNotSupported;

  /// No description provided for @docParseError.
  ///
  /// In en, this message translates to:
  /// **'Could not parse DOC file. Try converting to DOCX.'**
  String get docParseError;

  /// No description provided for @xlsxParseError.
  ///
  /// In en, this message translates to:
  /// **'Could not parse XLSX file'**
  String get xlsxParseError;

  /// No description provided for @xlsParseError.
  ///
  /// In en, this message translates to:
  /// **'Could not parse XLS file. Try converting to XLSX.'**
  String get xlsParseError;

  /// No description provided for @csvParseError.
  ///
  /// In en, this message translates to:
  /// **'Could not parse CSV file'**
  String get csvParseError;

  /// No description provided for @odtParseError.
  ///
  /// In en, this message translates to:
  /// **'Could not parse ODT file'**
  String get odtParseError;

  /// No description provided for @odsParseError.
  ///
  /// In en, this message translates to:
  /// **'Could not parse ODS file'**
  String get odsParseError;

  /// No description provided for @odpParseError.
  ///
  /// In en, this message translates to:
  /// **'Could not parse ODP file'**
  String get odpParseError;

  /// No description provided for @pptParseError.
  ///
  /// In en, this message translates to:
  /// **'Could not parse PPT file'**
  String get pptParseError;

  /// No description provided for @rtfParseError.
  ///
  /// In en, this message translates to:
  /// **'Could not parse RTF file'**
  String get rtfParseError;

  /// No description provided for @txtFileEmpty.
  ///
  /// In en, this message translates to:
  /// **'File is empty'**
  String get txtFileEmpty;

  /// No description provided for @unsupportedFormat.
  ///
  /// In en, this message translates to:
  /// **'File format is not supported yet'**
  String get unsupportedFormat;

  /// No description provided for @txtLoaded.
  ///
  /// In en, this message translates to:
  /// **'TXT'**
  String get txtLoaded;

  /// No description provided for @charactersLoaded.
  ///
  /// In en, this message translates to:
  /// **'characters'**
  String get charactersLoaded;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'ur'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'ur': return AppLocalizationsUr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
