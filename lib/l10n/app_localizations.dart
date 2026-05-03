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

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @rename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get rename;

  /// No description provided for @restore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restore;

  /// No description provided for @export.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get export;

  /// No description provided for @duplicate.
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get duplicate;

  /// No description provided for @imports.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get imports;

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

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

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

  /// No description provided for @copiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get copiedToClipboard;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navLibrary.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get navLibrary;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @navRecents.
  ///
  /// In en, this message translates to:
  /// **'Recents'**
  String get navRecents;

  /// No description provided for @categoryAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get categoryAll;

  /// No description provided for @categoryPdfs.
  ///
  /// In en, this message translates to:
  /// **'PDFs'**
  String get categoryPdfs;

  /// No description provided for @categoryDocs.
  ///
  /// In en, this message translates to:
  /// **'Docs'**
  String get categoryDocs;

  /// No description provided for @categorySheets.
  ///
  /// In en, this message translates to:
  /// **'Sheets'**
  String get categorySheets;

  /// No description provided for @categorySlides.
  ///
  /// In en, this message translates to:
  /// **'Slides'**
  String get categorySlides;

  /// No description provided for @categoryCode.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get categoryCode;

  /// No description provided for @categoryScans.
  ///
  /// In en, this message translates to:
  /// **'Scans'**
  String get categoryScans;

  /// No description provided for @categoryOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get categoryOther;

  /// No description provided for @categoryPresentations.
  ///
  /// In en, this message translates to:
  /// **'Presentations'**
  String get categoryPresentations;

  /// No description provided for @supportDevelopment.
  ///
  /// In en, this message translates to:
  /// **'Support Development'**
  String get supportDevelopment;

  /// No description provided for @visitPatreon.
  ///
  /// In en, this message translates to:
  /// **'Visit Patreon'**
  String get visitPatreon;

  /// No description provided for @copyLink.
  ///
  /// In en, this message translates to:
  /// **'Copy Link'**
  String get copyLink;

  /// No description provided for @becomeAPatron.
  ///
  /// In en, this message translates to:
  /// **'Become a Patron'**
  String get becomeAPatron;

  /// No description provided for @patreonDescription.
  ///
  /// In en, this message translates to:
  /// **'Your support keeps Fadocx and FadCam growing. Patreon subscribers unlock exclusive benefits including premium features and early access across all FadSec Lab apps.\n\nFor more info, visit Patreon from the link below and check the available tiers with their benefits.'**
  String get patreonDescription;

  /// No description provided for @discordTitle.
  ///
  /// In en, this message translates to:
  /// **'Join our Discord'**
  String get discordTitle;

  /// No description provided for @openInBrowser.
  ///
  /// In en, this message translates to:
  /// **'Open in Browser'**
  String get openInBrowser;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming Soon'**
  String get comingSoon;

  /// No description provided for @newBadge.
  ///
  /// In en, this message translates to:
  /// **'NEW'**
  String get newBadge;

  /// No description provided for @timeAgoJustNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get timeAgoJustNow;

  /// No description provided for @timeAgoMinute.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 minute ago} other{{count} minutes ago}}'**
  String timeAgoMinute(num count);

  /// No description provided for @timeAgoHour.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 hour ago} other{{count} hours ago}}'**
  String timeAgoHour(num count);

  /// No description provided for @timeAgoDay.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day ago} other{{count} days ago}}'**
  String timeAgoDay(num count);

  /// No description provided for @timeAgoWeek.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 week ago} other{{count} weeks ago}}'**
  String timeAgoWeek(num count);

  /// No description provided for @timeAgoMonth.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 month ago} other{{count} months ago}}'**
  String timeAgoMonth(num count);

  /// No description provided for @timeAgoYear.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 year ago} other{{count} years ago}}'**
  String timeAgoYear(num count);

  /// No description provided for @monthJan.
  ///
  /// In en, this message translates to:
  /// **'Jan'**
  String get monthJan;

  /// No description provided for @monthFeb.
  ///
  /// In en, this message translates to:
  /// **'Feb'**
  String get monthFeb;

  /// No description provided for @monthMar.
  ///
  /// In en, this message translates to:
  /// **'Mar'**
  String get monthMar;

  /// No description provided for @monthApr.
  ///
  /// In en, this message translates to:
  /// **'Apr'**
  String get monthApr;

  /// No description provided for @monthMay.
  ///
  /// In en, this message translates to:
  /// **'May'**
  String get monthMay;

  /// No description provided for @monthJun.
  ///
  /// In en, this message translates to:
  /// **'Jun'**
  String get monthJun;

  /// No description provided for @monthJul.
  ///
  /// In en, this message translates to:
  /// **'Jul'**
  String get monthJul;

  /// No description provided for @monthAug.
  ///
  /// In en, this message translates to:
  /// **'Aug'**
  String get monthAug;

  /// No description provided for @monthSep.
  ///
  /// In en, this message translates to:
  /// **'Sep'**
  String get monthSep;

  /// No description provided for @monthOct.
  ///
  /// In en, this message translates to:
  /// **'Oct'**
  String get monthOct;

  /// No description provided for @monthNov.
  ///
  /// In en, this message translates to:
  /// **'Nov'**
  String get monthNov;

  /// No description provided for @monthDec.
  ///
  /// In en, this message translates to:
  /// **'Dec'**
  String get monthDec;

  /// No description provided for @homeWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Fadocx'**
  String get homeWelcomeTitle;

  /// No description provided for @homeWelcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Explore sample files or import your own documents to get started'**
  String get homeWelcomeSubtitle;

  /// No description provided for @homeExploreSamples.
  ///
  /// In en, this message translates to:
  /// **'Explore Sample Files'**
  String get homeExploreSamples;

  /// No description provided for @homeDocumentManagement.
  ///
  /// In en, this message translates to:
  /// **'Document Management'**
  String get homeDocumentManagement;

  /// No description provided for @homeSeeAll.
  ///
  /// In en, this message translates to:
  /// **'See All'**
  String get homeSeeAll;

  /// No description provided for @homeNoRecentFiles.
  ///
  /// In en, this message translates to:
  /// **'No recent files'**
  String get homeNoRecentFiles;

  /// No description provided for @homeScanDocument.
  ///
  /// In en, this message translates to:
  /// **'Scan a Document'**
  String get homeScanDocument;

  /// No description provided for @homeScanDocumentDesc.
  ///
  /// In en, this message translates to:
  /// **'Extract text from documents using OCR'**
  String get homeScanDocumentDesc;

  /// No description provided for @homeImportDocument.
  ///
  /// In en, this message translates to:
  /// **'Import a Document'**
  String get homeImportDocument;

  /// No description provided for @homeImportDocumentDesc.
  ///
  /// In en, this message translates to:
  /// **'Browse and import files from your device'**
  String get homeImportDocumentDesc;

  /// No description provided for @homeStatDocuments.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get homeStatDocuments;

  /// No description provided for @homeStatStorage.
  ///
  /// In en, this message translates to:
  /// **'Storage'**
  String get homeStatStorage;

  /// No description provided for @homeStatTimeRead.
  ///
  /// In en, this message translates to:
  /// **'Time Read'**
  String get homeStatTimeRead;

  /// No description provided for @homeStatLastOpened.
  ///
  /// In en, this message translates to:
  /// **'Last Opened: '**
  String get homeStatLastOpened;

  /// No description provided for @homePressBackExit.
  ///
  /// In en, this message translates to:
  /// **'Press back again to exit'**
  String get homePressBackExit;

  /// No description provided for @homeImportingSamples.
  ///
  /// In en, this message translates to:
  /// **'Importing sample files...'**
  String get homeImportingSamples;

  /// No description provided for @homeSamplesImported.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 sample file imported successfully!} other{{count} sample files imported successfully!}}'**
  String homeSamplesImported(num count);

  /// No description provided for @homeViewFiles.
  ///
  /// In en, this message translates to:
  /// **'View Files'**
  String get homeViewFiles;

  /// No description provided for @homeFailedImportSamples.
  ///
  /// In en, this message translates to:
  /// **'Failed to import sample files: {error}'**
  String homeFailedImportSamples(String error);

  /// No description provided for @homeFileMovedToTrash.
  ///
  /// In en, this message translates to:
  /// **'{name} moved to trash'**
  String homeFileMovedToTrash(String name);

  /// No description provided for @homeFileInfo.
  ///
  /// In en, this message translates to:
  /// **'File info'**
  String get homeFileInfo;

  /// No description provided for @homeFileName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get homeFileName;

  /// No description provided for @homeFileType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get homeFileType;

  /// No description provided for @homeFileSize.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get homeFileSize;

  /// No description provided for @homeFileLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get homeFileLocation;

  /// No description provided for @homeFileDateOpened.
  ///
  /// In en, this message translates to:
  /// **'Date opened'**
  String get homeFileDateOpened;

  /// No description provided for @homeFileLastModified.
  ///
  /// In en, this message translates to:
  /// **'Last modified'**
  String get homeFileLastModified;

  /// No description provided for @homeFileInTrash.
  ///
  /// In en, this message translates to:
  /// **'In trash'**
  String get homeFileInTrash;

  /// No description provided for @homeFileInfoCopied.
  ///
  /// In en, this message translates to:
  /// **'File info copied'**
  String get homeFileInfoCopied;

  /// No description provided for @homeCopySuffix.
  ///
  /// In en, this message translates to:
  /// **' (copy)'**
  String get homeCopySuffix;

  /// No description provided for @homeCopySuffixCounter.
  ///
  /// In en, this message translates to:
  /// **' (copy {counter})'**
  String homeCopySuffixCounter(num counter);

  /// No description provided for @homeDuplicatedAs.
  ///
  /// In en, this message translates to:
  /// **'Duplicated as {name}'**
  String homeDuplicatedAs(String name);

  /// No description provided for @homeFailedDuplicate.
  ///
  /// In en, this message translates to:
  /// **'Failed to duplicate file: {error}'**
  String homeFailedDuplicate(String error);

  /// No description provided for @homeRenameFile.
  ///
  /// In en, this message translates to:
  /// **'Rename file'**
  String get homeRenameFile;

  /// No description provided for @homeFileNameLabel.
  ///
  /// In en, this message translates to:
  /// **'File name'**
  String get homeFileNameLabel;

  /// No description provided for @homeFileAlreadyExists.
  ///
  /// In en, this message translates to:
  /// **'A file with this name already exists'**
  String get homeFileAlreadyExists;

  /// No description provided for @homeRenamedTo.
  ///
  /// In en, this message translates to:
  /// **'Renamed to {name}'**
  String homeRenamedTo(String name);

  /// No description provided for @homeFailedRename.
  ///
  /// In en, this message translates to:
  /// **'Failed to rename file'**
  String get homeFailedRename;

  /// No description provided for @homeExport.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get homeExport;

  /// No description provided for @homeSaveToDownloads.
  ///
  /// In en, this message translates to:
  /// **'Save to Downloads'**
  String get homeSaveToDownloads;

  /// No description provided for @homeSaveToDownloadsPath.
  ///
  /// In en, this message translates to:
  /// **'Download/Fadocx/{name}'**
  String homeSaveToDownloadsPath(String name);

  /// No description provided for @homeChooseLocation.
  ///
  /// In en, this message translates to:
  /// **'Choose location'**
  String get homeChooseLocation;

  /// No description provided for @homeChooseLocationDesc.
  ///
  /// In en, this message translates to:
  /// **'Pick a custom save directory'**
  String get homeChooseLocationDesc;

  /// No description provided for @homeSavedToDownloads.
  ///
  /// In en, this message translates to:
  /// **'Saved to Download/Fadocx/{name}'**
  String homeSavedToDownloads(String name);

  /// No description provided for @homeSavedTo.
  ///
  /// In en, this message translates to:
  /// **'Saved to {path}'**
  String homeSavedTo(String path);

  /// No description provided for @homeFailedExport.
  ///
  /// In en, this message translates to:
  /// **'Failed to export file'**
  String get homeFailedExport;

  /// No description provided for @homeChooseSaveLocation.
  ///
  /// In en, this message translates to:
  /// **'Choose save location'**
  String get homeChooseSaveLocation;

  /// No description provided for @homeConvertComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Convert feature coming soon!'**
  String get homeConvertComingSoon;

  /// No description provided for @homeFadDriveComingSoon.
  ///
  /// In en, this message translates to:
  /// **'FadDrive coming soon!'**
  String get homeFadDriveComingSoon;

  /// No description provided for @homePresentationsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Coming Soon'**
  String get homePresentationsTooltip;

  /// No description provided for @homeErrorPrefix.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String homeErrorPrefix(String error);

  /// No description provided for @libraryTitle.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get libraryTitle;

  /// No description provided for @librarySearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search library...'**
  String get librarySearchHint;

  /// No description provided for @librarySelected.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String librarySelected(num count);

  /// No description provided for @libraryDeleteSelected.
  ///
  /// In en, this message translates to:
  /// **'Delete selected?'**
  String get libraryDeleteSelected;

  /// No description provided for @libraryDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Move {count} files to trash? You can restore them later.'**
  String libraryDeleteConfirm(num count);

  /// No description provided for @libraryItemsMovedToTrash.
  ///
  /// In en, this message translates to:
  /// **'{count} items moved to trash'**
  String libraryItemsMovedToTrash(num count);

  /// No description provided for @libraryErrorLoading.
  ///
  /// In en, this message translates to:
  /// **'Error loading library: {error}'**
  String libraryErrorLoading(String error);

  /// No description provided for @libraryItemCount.
  ///
  /// In en, this message translates to:
  /// **'{count} items'**
  String libraryItemCount(num count);

  /// No description provided for @libraryDeselectAll.
  ///
  /// In en, this message translates to:
  /// **'Deselect all'**
  String get libraryDeselectAll;

  /// No description provided for @librarySelectAll.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get librarySelectAll;

  /// No description provided for @libraryNoCategoryFound.
  ///
  /// In en, this message translates to:
  /// **'No {category} found'**
  String libraryNoCategoryFound(String category);

  /// No description provided for @libraryNoDocuments.
  ///
  /// In en, this message translates to:
  /// **'No documents yet'**
  String get libraryNoDocuments;

  /// No description provided for @libraryAdjustSearch.
  ///
  /// In en, this message translates to:
  /// **'Try adjusting your search or filters'**
  String get libraryAdjustSearch;

  /// No description provided for @libraryDocumentsAppearHere.
  ///
  /// In en, this message translates to:
  /// **'Your documents will appear here'**
  String get libraryDocumentsAppearHere;

  /// No description provided for @browseTitle.
  ///
  /// In en, this message translates to:
  /// **'Import Documents'**
  String get browseTitle;

  /// No description provided for @browseBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get browseBack;

  /// No description provided for @browseSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search documents...'**
  String get browseSearchHint;

  /// No description provided for @browseCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get browseCancel;

  /// No description provided for @browseBrowseFiles.
  ///
  /// In en, this message translates to:
  /// **'Browse'**
  String get browseBrowseFiles;

  /// No description provided for @browseBrowseFilesDesc.
  ///
  /// In en, this message translates to:
  /// **'Import additional files manually'**
  String get browseBrowseFilesDesc;

  /// No description provided for @browseScanFailed.
  ///
  /// In en, this message translates to:
  /// **'Scan failed'**
  String get browseScanFailed;

  /// No description provided for @browseUnknownError.
  ///
  /// In en, this message translates to:
  /// **'Unknown error occurred'**
  String get browseUnknownError;

  /// No description provided for @browseRetryScan.
  ///
  /// In en, this message translates to:
  /// **'Retry Scan'**
  String get browseRetryScan;

  /// No description provided for @browseImportManually.
  ///
  /// In en, this message translates to:
  /// **'Import Files Manually'**
  String get browseImportManually;

  /// No description provided for @browseNoDocumentsFound.
  ///
  /// In en, this message translates to:
  /// **'No documents found'**
  String get browseNoDocumentsFound;

  /// No description provided for @browseNoDocumentsMatch.
  ///
  /// In en, this message translates to:
  /// **'No documents match your search'**
  String get browseNoDocumentsMatch;

  /// No description provided for @browseAdjustSearch.
  ///
  /// In en, this message translates to:
  /// **'Try adjusting your search or filters'**
  String get browseAdjustSearch;

  /// No description provided for @browseClearSelection.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get browseClearSelection;

  /// No description provided for @browseImport.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get browseImport;

  /// No description provided for @browseAllFilesAccessRequired.
  ///
  /// In en, this message translates to:
  /// **'All files access permission is required to browse documents on your device'**
  String get browseAllFilesAccessRequired;

  /// No description provided for @browsePermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Permission Required'**
  String get browsePermissionRequired;

  /// No description provided for @browseAllFilesAccessDenied.
  ///
  /// In en, this message translates to:
  /// **'All files access permission is required to browse and read documents on your device. Please grant this permission to continue.'**
  String get browseAllFilesAccessDenied;

  /// No description provided for @browseOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get browseOpenSettings;

  /// No description provided for @browseAccessStillDisabled.
  ///
  /// In en, this message translates to:
  /// **'All files access is still disabled. Please enable it in Settings to continue.'**
  String get browseAccessStillDisabled;

  /// No description provided for @browseNoDirectories.
  ///
  /// In en, this message translates to:
  /// **'No document directories found on device'**
  String get browseNoDirectories;

  /// No description provided for @browseErrorPrefix.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String browseErrorPrefix(String error);

  /// No description provided for @browseSortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get browseSortBy;

  /// No description provided for @browseImportedFiles.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Imported 1 file} other{Imported {count} files}}'**
  String browseImportedFiles(num count);

  /// No description provided for @trashTitle.
  ///
  /// In en, this message translates to:
  /// **'Trash'**
  String get trashTitle;

  /// No description provided for @trashEmpty.
  ///
  /// In en, this message translates to:
  /// **'Trash is empty'**
  String get trashEmpty;

  /// No description provided for @trashEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Deleted files will appear here'**
  String get trashEmptySubtitle;

  /// No description provided for @trashErrorLoading.
  ///
  /// In en, this message translates to:
  /// **'Error loading trash'**
  String get trashErrorLoading;

  /// No description provided for @trashFilesSelected.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String trashFilesSelected(num count);

  /// No description provided for @trashFilesLabel.
  ///
  /// In en, this message translates to:
  /// **'files'**
  String get trashFilesLabel;

  /// No description provided for @trashFileRestored.
  ///
  /// In en, this message translates to:
  /// **'File restored successfully'**
  String get trashFileRestored;

  /// No description provided for @trashDeletePermanently.
  ///
  /// In en, this message translates to:
  /// **'Delete Permanently'**
  String get trashDeletePermanently;

  /// No description provided for @trashDeletePermanentlyConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete Permanently?'**
  String get trashDeletePermanentlyConfirm;

  /// No description provided for @trashDeletePermanentlyMessage.
  ///
  /// In en, this message translates to:
  /// **'You are about to permanently delete {count} file(s). This action cannot be undone.'**
  String trashDeletePermanentlyMessage(num count);

  /// No description provided for @trashDeleteTypeConfirm.
  ///
  /// In en, this message translates to:
  /// **'Type DELETE in capital letters to confirm:'**
  String get trashDeleteTypeConfirm;

  /// No description provided for @trashDeleteHint.
  ///
  /// In en, this message translates to:
  /// **'DELETE'**
  String get trashDeleteHint;

  /// No description provided for @trashFilesPermanentlyDeleted.
  ///
  /// In en, this message translates to:
  /// **'{count} file(s) permanently deleted'**
  String trashFilesPermanentlyDeleted(num count);

  /// No description provided for @whatsNewTitle.
  ///
  /// In en, this message translates to:
  /// **'What\'s New'**
  String get whatsNewTitle;

  /// No description provided for @whatsNewWhatsIncluded.
  ///
  /// In en, this message translates to:
  /// **'What\'s Included'**
  String get whatsNewWhatsIncluded;

  /// No description provided for @whatsNewPlanned.
  ///
  /// In en, this message translates to:
  /// **'Planned'**
  String get whatsNewPlanned;

  /// No description provided for @whatsNewReleasedToday.
  ///
  /// In en, this message translates to:
  /// **'Released today'**
  String get whatsNewReleasedToday;

  /// No description provided for @whatsNewReleasedYesterday.
  ///
  /// In en, this message translates to:
  /// **'Released yesterday'**
  String get whatsNewReleasedYesterday;

  /// No description provided for @whatsNewReleasedDate.
  ///
  /// In en, this message translates to:
  /// **'Released {date}'**
  String whatsNewReleasedDate(String date);

  /// No description provided for @whatsNewDocAndSheets.
  ///
  /// In en, this message translates to:
  /// **'Documents & Spreadsheets'**
  String get whatsNewDocAndSheets;

  /// No description provided for @whatsNewDocAndSheetsDesc.
  ///
  /// In en, this message translates to:
  /// **'View PDFs, Word documents, Excel spreadsheets, and more — all locally on your device.'**
  String get whatsNewDocAndSheetsDesc;

  /// No description provided for @whatsNewOcrAi.
  ///
  /// In en, this message translates to:
  /// **'Intelligent OCR & On-Device AI'**
  String get whatsNewOcrAi;

  /// No description provided for @whatsNewOcrAiDesc.
  ///
  /// In en, this message translates to:
  /// **'Extract text from images using advanced on-device OCR. Multiple languages supported.'**
  String get whatsNewOcrAiDesc;

  /// No description provided for @whatsNewSyntaxHighlighting.
  ///
  /// In en, this message translates to:
  /// **'Syntax Highlighting'**
  String get whatsNewSyntaxHighlighting;

  /// No description provided for @whatsNewSyntaxHighlightingDesc.
  ///
  /// In en, this message translates to:
  /// **'Beautiful code highlighting for 50+ programming languages.'**
  String get whatsNewSyntaxHighlightingDesc;

  /// No description provided for @whatsNewReadingStats.
  ///
  /// In en, this message translates to:
  /// **'Reading Stats Dashboard'**
  String get whatsNewReadingStats;

  /// No description provided for @whatsNewReadingStatsDesc.
  ///
  /// In en, this message translates to:
  /// **'Track your reading progress with detailed statistics and time tracking.'**
  String get whatsNewReadingStatsDesc;

  /// No description provided for @whatsNewLibraryCategories.
  ///
  /// In en, this message translates to:
  /// **'Library with Category Folders'**
  String get whatsNewLibraryCategories;

  /// No description provided for @whatsNewLibraryCategoriesDesc.
  ///
  /// In en, this message translates to:
  /// **'Organize your documents by type with smart automatic categorization.'**
  String get whatsNewLibraryCategoriesDesc;

  /// No description provided for @whatsNewFileManagement.
  ///
  /// In en, this message translates to:
  /// **'File Management'**
  String get whatsNewFileManagement;

  /// No description provided for @whatsNewFileManagementDesc.
  ///
  /// In en, this message translates to:
  /// **'Rename, duplicate, export, and delete your documents with ease.'**
  String get whatsNewFileManagementDesc;

  /// No description provided for @whatsNewThemes.
  ///
  /// In en, this message translates to:
  /// **'Light & Dark Themes'**
  String get whatsNewThemes;

  /// No description provided for @whatsNewThemesDesc.
  ///
  /// In en, this message translates to:
  /// **'Choose the look that suits you — dark mode for night, light mode for day.'**
  String get whatsNewThemesDesc;

  /// No description provided for @whatsNewFadDrive.
  ///
  /// In en, this message translates to:
  /// **'FadDrive'**
  String get whatsNewFadDrive;

  /// No description provided for @whatsNewFadDriveDesc.
  ///
  /// In en, this message translates to:
  /// **'Cloud sync for your documents — access them anywhere, anytime.'**
  String get whatsNewFadDriveDesc;

  /// No description provided for @whatsNewEditing.
  ///
  /// In en, this message translates to:
  /// **'Document Editing'**
  String get whatsNewEditing;

  /// No description provided for @whatsNewEditingDesc.
  ///
  /// In en, this message translates to:
  /// **'Make quick edits to your documents right within Fadocx.'**
  String get whatsNewEditingDesc;

  /// No description provided for @whatsNewBookmarks.
  ///
  /// In en, this message translates to:
  /// **'Bookmarks & Annotations'**
  String get whatsNewBookmarks;

  /// No description provided for @whatsNewBookmarksDesc.
  ///
  /// In en, this message translates to:
  /// **'Mark important pages and add annotations for later reference.'**
  String get whatsNewBookmarksDesc;

  /// No description provided for @whatsNewConversion.
  ///
  /// In en, this message translates to:
  /// **'Document Conversion'**
  String get whatsNewConversion;

  /// No description provided for @whatsNewConversionDesc.
  ///
  /// In en, this message translates to:
  /// **'Convert between formats like PDF, DOCX, and more.'**
  String get whatsNewConversionDesc;

  /// No description provided for @whatsNewAmoled.
  ///
  /// In en, this message translates to:
  /// **'AMOLED Black Theme'**
  String get whatsNewAmoled;

  /// No description provided for @whatsNewAmoledDesc.
  ///
  /// In en, this message translates to:
  /// **'Pure black theme for AMOLED displays — save battery on dark mode.'**
  String get whatsNewAmoledDesc;

  /// No description provided for @whatsNewMoreOcr.
  ///
  /// In en, this message translates to:
  /// **'More OCR Languages'**
  String get whatsNewMoreOcr;

  /// No description provided for @whatsNewMoreOcrDesc.
  ///
  /// In en, this message translates to:
  /// **'Support for additional OCR languages and improved recognition accuracy.'**
  String get whatsNewMoreOcrDesc;

  /// No description provided for @whatsNewOfflineFirst.
  ///
  /// In en, this message translates to:
  /// **'An offline-first document viewer built for privacy. No accounts, no tracking, no internet required.'**
  String get whatsNewOfflineFirst;

  /// No description provided for @whatsNewThankYou.
  ///
  /// In en, this message translates to:
  /// **'Thank You for Using Fadocx'**
  String get whatsNewThankYou;

  /// No description provided for @whatsNewThankYouDesc.
  ///
  /// In en, this message translates to:
  /// **'If you find value in Fadocx, consider supporting its development. Your contribution helps us keep building privacy-first tools.'**
  String get whatsNewThankYouDesc;

  /// No description provided for @drawerWhatNew.
  ///
  /// In en, this message translates to:
  /// **'What\'s New'**
  String get drawerWhatNew;

  /// No description provided for @drawerRecentFiles.
  ///
  /// In en, this message translates to:
  /// **'Recent Files'**
  String get drawerRecentFiles;

  /// No description provided for @drawerVisible.
  ///
  /// In en, this message translates to:
  /// **'Visible'**
  String get drawerVisible;

  /// No description provided for @drawerHidden.
  ///
  /// In en, this message translates to:
  /// **'Hidden'**
  String get drawerHidden;

  /// No description provided for @drawerUnlockBenefits.
  ///
  /// In en, this message translates to:
  /// **'Unlock exclusive benefits'**
  String get drawerUnlockBenefits;

  /// No description provided for @fileActionRename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get fileActionRename;

  /// No description provided for @fileActionRenameDesc.
  ///
  /// In en, this message translates to:
  /// **'Change file name'**
  String get fileActionRenameDesc;

  /// No description provided for @fileActionDuplicate.
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get fileActionDuplicate;

  /// No description provided for @fileActionDuplicateDesc.
  ///
  /// In en, this message translates to:
  /// **'Create a copy'**
  String get fileActionDuplicateDesc;

  /// No description provided for @fileActionExport.
  ///
  /// In en, this message translates to:
  /// **'Export / Save As'**
  String get fileActionExport;

  /// No description provided for @fileActionExportDesc.
  ///
  /// In en, this message translates to:
  /// **'Save a copy to Downloads'**
  String get fileActionExportDesc;

  /// No description provided for @fileActionCopyText.
  ///
  /// In en, this message translates to:
  /// **'Copy Text'**
  String get fileActionCopyText;

  /// No description provided for @fileActionCopyTextDesc.
  ///
  /// In en, this message translates to:
  /// **'Copy extracted text to clipboard'**
  String get fileActionCopyTextDesc;

  /// No description provided for @fileActionConvert.
  ///
  /// In en, this message translates to:
  /// **'Convert'**
  String get fileActionConvert;

  /// No description provided for @fileActionConvertDesc.
  ///
  /// In en, this message translates to:
  /// **'Convert to another format'**
  String get fileActionConvertDesc;

  /// No description provided for @fileActionUpload.
  ///
  /// In en, this message translates to:
  /// **'Upload to FadDrive'**
  String get fileActionUpload;

  /// No description provided for @fileActionUploadDesc.
  ///
  /// In en, this message translates to:
  /// **'Sync to cloud storage'**
  String get fileActionUploadDesc;

  /// No description provided for @fileActionFileInfo.
  ///
  /// In en, this message translates to:
  /// **'File info'**
  String get fileActionFileInfo;

  /// No description provided for @fileActionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'File actions and management'**
  String get fileActionSubtitle;

  /// No description provided for @updateAvailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Update Available'**
  String get updateAvailableTitle;

  /// No description provided for @updateAvailableSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A new version is ready to download'**
  String get updateAvailableSubtitle;

  /// No description provided for @updateStableRelease.
  ///
  /// In en, this message translates to:
  /// **'Stable Release'**
  String get updateStableRelease;

  /// No description provided for @updateStableDesc.
  ///
  /// In en, this message translates to:
  /// **'Recommended for most users'**
  String get updateStableDesc;

  /// No description provided for @updateBetaRelease.
  ///
  /// In en, this message translates to:
  /// **'Beta Release'**
  String get updateBetaRelease;

  /// No description provided for @updateBetaDesc.
  ///
  /// In en, this message translates to:
  /// **'Latest features — may be unstable'**
  String get updateBetaDesc;

  /// No description provided for @updateMaybeLater.
  ///
  /// In en, this message translates to:
  /// **'Maybe Later'**
  String get updateMaybeLater;

  /// No description provided for @updateCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get updateCurrent;

  /// No description provided for @updateNew.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get updateNew;

  /// No description provided for @updateVisitGithub.
  ///
  /// In en, this message translates to:
  /// **'Visit GitHub'**
  String get updateVisitGithub;

  /// No description provided for @updateBetaInfo.
  ///
  /// In en, this message translates to:
  /// **'This is a standalone APK...'**
  String get updateBetaInfo;

  /// No description provided for @updateBannerStable.
  ///
  /// In en, this message translates to:
  /// **'Stable Update'**
  String get updateBannerStable;

  /// No description provided for @updateBannerBeta.
  ///
  /// In en, this message translates to:
  /// **'Beta Update'**
  String get updateBannerBeta;

  /// No description provided for @settingsAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// No description provided for @settingsStorage.
  ///
  /// In en, this message translates to:
  /// **'Storage'**
  String get settingsStorage;

  /// No description provided for @settingsDocumentsSize.
  ///
  /// In en, this message translates to:
  /// **'Documents Size'**
  String get settingsDocumentsSize;

  /// No description provided for @settingsCalculating.
  ///
  /// In en, this message translates to:
  /// **'Calculating...'**
  String get settingsCalculating;

  /// No description provided for @settingsCustomStorage.
  ///
  /// In en, this message translates to:
  /// **'Custom Storage'**
  String get settingsCustomStorage;

  /// No description provided for @settingsUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get settingsUnknown;

  /// No description provided for @settingsStorageDetails.
  ///
  /// In en, this message translates to:
  /// **'Storage'**
  String get settingsStorageDetails;

  /// No description provided for @settingsStoragePdfs.
  ///
  /// In en, this message translates to:
  /// **'PDFs'**
  String get settingsStoragePdfs;

  /// No description provided for @settingsStorageDocs.
  ///
  /// In en, this message translates to:
  /// **'Docs'**
  String get settingsStorageDocs;

  /// No description provided for @settingsStorageSheets.
  ///
  /// In en, this message translates to:
  /// **'Sheets'**
  String get settingsStorageSheets;

  /// No description provided for @settingsStoragePresentations.
  ///
  /// In en, this message translates to:
  /// **'Presentations'**
  String get settingsStoragePresentations;

  /// No description provided for @settingsStorageCode.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get settingsStorageCode;

  /// No description provided for @settingsStorageScans.
  ///
  /// In en, this message translates to:
  /// **'Scans'**
  String get settingsStorageScans;

  /// No description provided for @settingsStorageImages.
  ///
  /// In en, this message translates to:
  /// **'Images'**
  String get settingsStorageImages;

  /// No description provided for @settingsStorageOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get settingsStorageOther;

  /// No description provided for @settingsStorageInfo.
  ///
  /// In en, this message translates to:
  /// **'Documents are stored in a private folder on your device and cannot be accessed by other apps'**
  String get settingsStorageInfo;

  /// No description provided for @settingsStoragePrivateFolderInfo.
  ///
  /// In en, this message translates to:
  /// **'Documents are stored in a private folder, hidden from other apps and file managers. Only Fadocx can access them.'**
  String get settingsStoragePrivateFolderInfo;

  /// No description provided for @settingsStorageDeleteInfo.
  ///
  /// In en, this message translates to:
  /// **'Delete documents from Danger Zone in Settings'**
  String get settingsStorageDeleteInfo;

  /// No description provided for @settingsStorageEmpty.
  ///
  /// In en, this message translates to:
  /// **'No documents'**
  String get settingsStorageEmpty;

  /// No description provided for @settingsStorageFailedLoad.
  ///
  /// In en, this message translates to:
  /// **'Failed to load storage data'**
  String get settingsStorageFailedLoad;

  /// No description provided for @settingsUpdates.
  ///
  /// In en, this message translates to:
  /// **'Updates'**
  String get settingsUpdates;

  /// No description provided for @settingsAutoUpdateCheck.
  ///
  /// In en, this message translates to:
  /// **'Auto Update Check'**
  String get settingsAutoUpdateCheck;

  /// No description provided for @settingsEnabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get settingsEnabled;

  /// No description provided for @settingsDisabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get settingsDisabled;

  /// No description provided for @settingsAppLock.
  ///
  /// In en, this message translates to:
  /// **'App Lock'**
  String get settingsAppLock;

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// No description provided for @settingsVersion.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get settingsVersion;

  /// No description provided for @settingsSourceCode.
  ///
  /// In en, this message translates to:
  /// **'Source Code'**
  String get settingsSourceCode;

  /// No description provided for @settingsContact.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get settingsContact;

  /// No description provided for @settingsJoinCommunity.
  ///
  /// In en, this message translates to:
  /// **'Join Community'**
  String get settingsJoinCommunity;

  /// No description provided for @settingsPrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get settingsPrivacyPolicy;

  /// No description provided for @settingsMoreFromFadsec.
  ///
  /// In en, this message translates to:
  /// **'More from FadSec Lab'**
  String get settingsMoreFromFadsec;

  /// No description provided for @settingsFadocxDesc.
  ///
  /// In en, this message translates to:
  /// **'Your private document viewer'**
  String get settingsFadocxDesc;

  /// No description provided for @settingsDangerZone.
  ///
  /// In en, this message translates to:
  /// **'Danger Zone'**
  String get settingsDangerZone;

  /// No description provided for @settingsTrash.
  ///
  /// In en, this message translates to:
  /// **'Trash'**
  String get settingsTrash;

  /// No description provided for @settingsTrashDesc.
  ///
  /// In en, this message translates to:
  /// **'View deleted files'**
  String get settingsTrashDesc;

  /// No description provided for @settingsResetSettings.
  ///
  /// In en, this message translates to:
  /// **'Reset Settings'**
  String get settingsResetSettings;

  /// No description provided for @settingsResetSettingsDesc.
  ///
  /// In en, this message translates to:
  /// **'Restore all settings to defaults'**
  String get settingsResetSettingsDesc;

  /// No description provided for @settingsResetDone.
  ///
  /// In en, this message translates to:
  /// **'Settings reset to defaults'**
  String get settingsResetDone;

  /// No description provided for @settingsRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get settingsRetry;

  /// No description provided for @settingsChooseTheme.
  ///
  /// In en, this message translates to:
  /// **'Choose Theme'**
  String get settingsChooseTheme;

  /// No description provided for @settingsSelectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get settingsSelectLanguage;

  /// No description provided for @settingsCheckForUpdates.
  ///
  /// In en, this message translates to:
  /// **'Check for Updates'**
  String get settingsCheckForUpdates;

  /// No description provided for @settingsCheckingUpdates.
  ///
  /// In en, this message translates to:
  /// **'Checking for updates…'**
  String get settingsCheckingUpdates;

  /// No description provided for @settingsNoInternet.
  ///
  /// In en, this message translates to:
  /// **'No internet connection. Check your network and try again.'**
  String get settingsNoInternet;

  /// No description provided for @settingsUpToDate.
  ///
  /// In en, this message translates to:
  /// **'You\'re up to date'**
  String get settingsUpToDate;

  /// No description provided for @settingsUpToDateDesc.
  ///
  /// In en, this message translates to:
  /// **'v{version} is the latest version.'**
  String settingsUpToDateDesc(String version);

  /// No description provided for @settingsBetaAvailable.
  ///
  /// In en, this message translates to:
  /// **'Beta v{version} available'**
  String settingsBetaAvailable(String version);

  /// No description provided for @settingsVersionWithBuild.
  ///
  /// In en, this message translates to:
  /// **'Version {version} (Build {buildNumber})'**
  String settingsVersionWithBuild(String version, String buildNumber);

  /// No description provided for @settingsCopiedInfo.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get settingsCopiedInfo;

  /// No description provided for @settingsCopyInfo.
  ///
  /// In en, this message translates to:
  /// **'Copy Info'**
  String get settingsCopyInfo;

  /// No description provided for @settingsShareApp.
  ///
  /// In en, this message translates to:
  /// **'Share with Friends'**
  String get settingsShareApp;

  /// No description provided for @settingsShareVia.
  ///
  /// In en, this message translates to:
  /// **'Share via...'**
  String get settingsShareVia;

  /// No description provided for @settingsShareWhatsApp.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp'**
  String get settingsShareWhatsApp;

  /// No description provided for @settingsWhatsAppNotInstalled.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp is not installed on this device'**
  String get settingsWhatsAppNotInstalled;

  /// No description provided for @settingsPrivacyOffline.
  ///
  /// In en, this message translates to:
  /// **'100% Offline'**
  String get settingsPrivacyOffline;

  /// No description provided for @settingsPrivacyLocalStorage.
  ///
  /// In en, this message translates to:
  /// **'Local Storage Only'**
  String get settingsPrivacyLocalStorage;

  /// No description provided for @settingsPrivacyOnDevice.
  ///
  /// In en, this message translates to:
  /// **'On-Device AI'**
  String get settingsPrivacyOnDevice;

  /// No description provided for @settingsPrivacyOpenSource.
  ///
  /// In en, this message translates to:
  /// **'Open Source'**
  String get settingsPrivacyOpenSource;

  /// No description provided for @settingsPrivacyNoAds.
  ///
  /// In en, this message translates to:
  /// **'No Ads'**
  String get settingsPrivacyNoAds;

  /// No description provided for @settingsPrivacyByDesign.
  ///
  /// In en, this message translates to:
  /// **'We believe in privacy by design.'**
  String get settingsPrivacyByDesign;

  /// No description provided for @settingsPrivacyTransparency.
  ///
  /// In en, this message translates to:
  /// **'Fadocx is built with transparency. Your documents are your business - not ours.'**
  String get settingsPrivacyTransparency;

  /// No description provided for @settingsViewSourceCode.
  ///
  /// In en, this message translates to:
  /// **'View Source Code'**
  String get settingsViewSourceCode;

  /// No description provided for @settingsSecurity.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get settingsSecurity;

  /// No description provided for @settingsStorageFilesSummary.
  ///
  /// In en, this message translates to:
  /// **'{size} • {count} files'**
  String settingsStorageFilesSummary(String size, num count);

  /// No description provided for @settingsErrorPrefix.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String settingsErrorPrefix(String error);

  /// No description provided for @settingsCopiedText.
  ///
  /// In en, this message translates to:
  /// **'Copied: {text}'**
  String settingsCopiedText(String text);

  /// No description provided for @settingsVisitGithub.
  ///
  /// In en, this message translates to:
  /// **'Visit GitHub'**
  String get settingsVisitGithub;

  /// No description provided for @settingsMadeWith.
  ///
  /// In en, this message translates to:
  /// **'Made with'**
  String get settingsMadeWith;

  /// No description provided for @settingsAt.
  ///
  /// In en, this message translates to:
  /// **'at'**
  String get settingsAt;

  /// No description provided for @settingsIn.
  ///
  /// In en, this message translates to:
  /// **'in'**
  String get settingsIn;

  /// No description provided for @settingsCopyright.
  ///
  /// In en, this message translates to:
  /// **'© 2024 – 2026 FadSec Lab · GPLv3 · fadseclab.com'**
  String get settingsCopyright;

  /// No description provided for @settingsTypeToConfirm.
  ///
  /// In en, this message translates to:
  /// **'Type \"{text}\" to confirm:'**
  String settingsTypeToConfirm(String text);

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @settingsPrivacyOfflineDesc.
  ///
  /// In en, this message translates to:
  /// **'All processing happens on your device. No internet required.'**
  String get settingsPrivacyOfflineDesc;

  /// No description provided for @settingsPrivacyLocalStorageDesc.
  ///
  /// In en, this message translates to:
  /// **'Your documents stay on your device. Nothing is uploaded.'**
  String get settingsPrivacyLocalStorageDesc;

  /// No description provided for @settingsPrivacyOnDeviceDesc.
  ///
  /// In en, this message translates to:
  /// **'Uses OpenCV + Tesseract for OCR. AI runs locally.'**
  String get settingsPrivacyOnDeviceDesc;

  /// No description provided for @settingsPrivacyOpenSourceDesc.
  ///
  /// In en, this message translates to:
  /// **'Code is public. Audit it yourself on GitHub.'**
  String get settingsPrivacyOpenSourceDesc;

  /// No description provided for @settingsPrivacyNoAdsDesc.
  ///
  /// In en, this message translates to:
  /// **'No advertisements. No tracking. No analytics. No crash logs. Zero telemetry.'**
  String get settingsPrivacyNoAdsDesc;

  /// No description provided for @settingsFadcamDesc.
  ///
  /// In en, this message translates to:
  /// **'Privacy-focused Android multimedia suite: background video recording, dashcam, screen recorder, live streaming & remote control — ad-free & open-source.'**
  String get settingsFadcamDesc;

  /// No description provided for @settingsQuranCliDesc.
  ///
  /// In en, this message translates to:
  /// **'Your Terminal Companion for the Holy Quran: Read, Listen & Generate Subtitles for Video Editing!'**
  String get settingsQuranCliDesc;

  /// No description provided for @settingsFadcryptDesc.
  ///
  /// In en, this message translates to:
  /// **'Advanced and elegant cross-platform app locker — files, folders, and applications all protected with military-grade AES-256-GCM encryption. Open-source, completely free, no telemetry!'**
  String get settingsFadcryptDesc;

  /// No description provided for @settingsFadcatDesc.
  ///
  /// In en, this message translates to:
  /// **'Lightweight, feature-rich, cross-platform Android logcat replacement — no Android Studio bloat. Bundles ADB for supported architectures, runs in GUI, CLI, or MCP server mode.'**
  String get settingsFadcatDesc;

  /// No description provided for @settingsMacosComingSoon.
  ///
  /// In en, this message translates to:
  /// **'macOS coming soon'**
  String get settingsMacosComingSoon;

  /// No description provided for @settingsOpenInBrowser.
  ///
  /// In en, this message translates to:
  /// **'Open in Browser'**
  String get settingsOpenInBrowser;

  /// No description provided for @viewerFindHint.
  ///
  /// In en, this message translates to:
  /// **'Find...'**
  String get viewerFindHint;

  /// No description provided for @viewerTypeToFind.
  ///
  /// In en, this message translates to:
  /// **'Type to find'**
  String get viewerTypeToFind;

  /// No description provided for @viewerSidebarPages.
  ///
  /// In en, this message translates to:
  /// **'Pages'**
  String get viewerSidebarPages;

  /// No description provided for @viewerSidebarSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get viewerSidebarSearch;

  /// No description provided for @viewerSidebarTOC.
  ///
  /// In en, this message translates to:
  /// **'TOC'**
  String get viewerSidebarTOC;

  /// No description provided for @viewerSidebarNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get viewerSidebarNotes;

  /// No description provided for @viewerSidebarBookmarks.
  ///
  /// In en, this message translates to:
  /// **'Bookmarks'**
  String get viewerSidebarBookmarks;

  /// No description provided for @viewerSidebarNotesDesc.
  ///
  /// In en, this message translates to:
  /// **'Add notes and annotations to PDF pages'**
  String get viewerSidebarNotesDesc;

  /// No description provided for @viewerSidebarBookmarksDesc.
  ///
  /// In en, this message translates to:
  /// **'Save and organize your favorite pages'**
  String get viewerSidebarBookmarksDesc;

  /// No description provided for @viewerCellCopied.
  ///
  /// In en, this message translates to:
  /// **'Cell {value} copied'**
  String viewerCellCopied(String value);

  /// No description provided for @viewerGoToPage.
  ///
  /// In en, this message translates to:
  /// **'Go to Page'**
  String get viewerGoToPage;

  /// No description provided for @viewerGoToPageHint.
  ///
  /// In en, this message translates to:
  /// **'Enter page number (1-{totalPages})'**
  String viewerGoToPageHint(num totalPages);

  /// No description provided for @viewerGo.
  ///
  /// In en, this message translates to:
  /// **'Go'**
  String get viewerGo;

  /// No description provided for @viewerInvalidPage.
  ///
  /// In en, this message translates to:
  /// **'Please enter a number between 1 and {totalPages}'**
  String viewerInvalidPage(num totalPages);

  /// No description provided for @viewerNoContent.
  ///
  /// In en, this message translates to:
  /// **'No content'**
  String get viewerNoContent;

  /// No description provided for @viewerResetZoom.
  ///
  /// In en, this message translates to:
  /// **'Reset zoom'**
  String get viewerResetZoom;

  /// No description provided for @viewerCopyTextTitle.
  ///
  /// In en, this message translates to:
  /// **'Copy Text'**
  String get viewerCopyTextTitle;

  /// No description provided for @viewerCopyTextChoose.
  ///
  /// In en, this message translates to:
  /// **'Choose what to copy:'**
  String get viewerCopyTextChoose;

  /// No description provided for @viewerCopyPageOnly.
  ///
  /// In en, this message translates to:
  /// **'Page {page} only'**
  String viewerCopyPageOnly(num page);

  /// No description provided for @viewerCopyAllPages.
  ///
  /// In en, this message translates to:
  /// **'All {totalPages} pages'**
  String viewerCopyAllPages(num totalPages);

  /// No description provided for @viewerExtractingText.
  ///
  /// In en, this message translates to:
  /// **'Extracting text from {label}...'**
  String viewerExtractingText(String label);

  /// No description provided for @viewerNoTextFound.
  ///
  /// In en, this message translates to:
  /// **'No text content found'**
  String get viewerNoTextFound;

  /// No description provided for @viewerPageLabel.
  ///
  /// In en, this message translates to:
  /// **'Page {currentPage}'**
  String viewerPageLabel(num currentPage);

  /// No description provided for @viewerAllPagesLabel.
  ///
  /// In en, this message translates to:
  /// **'{totalPages} pages'**
  String viewerAllPagesLabel(num totalPages);

  /// No description provided for @viewerTextExtracted.
  ///
  /// In en, this message translates to:
  /// **'Text extracted from {pageLabel}.'**
  String viewerTextExtracted(String pageLabel);

  /// No description provided for @viewerWordsFound.
  ///
  /// In en, this message translates to:
  /// **'{count} words found'**
  String viewerWordsFound(num count);

  /// No description provided for @viewerCopiedWords.
  ///
  /// In en, this message translates to:
  /// **'Copied {count} words from {pageLabel}'**
  String viewerCopiedWords(num count, String pageLabel);

  /// No description provided for @viewerCopyAllTextTitle.
  ///
  /// In en, this message translates to:
  /// **'Copy All Text'**
  String get viewerCopyAllTextTitle;

  /// No description provided for @viewerCopyAllTextConfirm.
  ///
  /// In en, this message translates to:
  /// **'This will extract text from all {pageCount} pages and copy to clipboard.'**
  String viewerCopyAllTextConfirm(num pageCount);

  /// No description provided for @viewerCopiedAllPages.
  ///
  /// In en, this message translates to:
  /// **'Copied {count} words from {pageCount} pages'**
  String viewerCopiedAllPages(num count, num pageCount);

  /// No description provided for @viewerCopyDocumentText.
  ///
  /// In en, this message translates to:
  /// **'This will copy the entire document content to clipboard.'**
  String get viewerCopyDocumentText;

  /// No description provided for @viewerWordsLines.
  ///
  /// In en, this message translates to:
  /// **'{words} words, {lines} lines'**
  String viewerWordsLines(num words, num lines);

  /// No description provided for @viewerWordsOnly.
  ///
  /// In en, this message translates to:
  /// **'{count} words'**
  String viewerWordsOnly(num count);

  /// No description provided for @viewerLinesOnly.
  ///
  /// In en, this message translates to:
  /// **'{lines} lines'**
  String viewerLinesOnly(num lines);

  /// No description provided for @viewerCopiedFromLines.
  ///
  /// In en, this message translates to:
  /// **'Copied {words} words from {lines} lines'**
  String viewerCopiedFromLines(num words, num lines);

  /// No description provided for @viewerCharactersCount.
  ///
  /// In en, this message translates to:
  /// **'{count} characters'**
  String viewerCharactersCount(num count);

  /// No description provided for @viewerCopyExtractedTitle.
  ///
  /// In en, this message translates to:
  /// **'Copy Extracted Text'**
  String get viewerCopyExtractedTitle;

  /// No description provided for @viewerCopyExtractedDesc.
  ///
  /// In en, this message translates to:
  /// **'Copy text extracted from this image via OCR.'**
  String get viewerCopyExtractedDesc;

  /// No description provided for @viewerCopiedWordsChars.
  ///
  /// In en, this message translates to:
  /// **'Copied {words} words ({chars} characters)'**
  String viewerCopiedWordsChars(num words, num chars);

  /// No description provided for @viewerErrorAccessText.
  ///
  /// In en, this message translates to:
  /// **'Error accessing extracted text'**
  String get viewerErrorAccessText;

  /// No description provided for @viewerNoTextForImage.
  ///
  /// In en, this message translates to:
  /// **'No extracted text available for this image'**
  String get viewerNoTextForImage;

  /// No description provided for @viewerExtractingAllPages.
  ///
  /// In en, this message translates to:
  /// **'Extracting text from all pages...'**
  String get viewerExtractingAllPages;

  /// No description provided for @viewerTextExtractionUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Text extraction not available'**
  String get viewerTextExtractionUnavailable;

  /// No description provided for @viewerNoPdfText.
  ///
  /// In en, this message translates to:
  /// **'No text found in this PDF'**
  String get viewerNoPdfText;

  /// No description provided for @viewerNoTextAvailable.
  ///
  /// In en, this message translates to:
  /// **'No text content available'**
  String get viewerNoTextAvailable;

  /// No description provided for @viewerReadingTime.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min read'**
  String viewerReadingTime(num minutes);

  /// No description provided for @viewerReadingTimeSingle.
  ///
  /// In en, this message translates to:
  /// **'1 min read'**
  String get viewerReadingTimeSingle;

  /// No description provided for @viewerCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get viewerCopy;

  /// No description provided for @viewerErrorPrefix.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String viewerErrorPrefix(String error);

  /// No description provided for @viewerCellValue.
  ///
  /// In en, this message translates to:
  /// **'Cell {cell}'**
  String viewerCellValue(String cell);

  /// No description provided for @viewerLowerPageLabel.
  ///
  /// In en, this message translates to:
  /// **'page {page}'**
  String viewerLowerPageLabel(num page);

  /// No description provided for @viewerAllPagesLower.
  ///
  /// In en, this message translates to:
  /// **'all pages'**
  String get viewerAllPagesLower;

  /// No description provided for @viewerCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get viewerCopied;

  /// No description provided for @viewerCopyValue.
  ///
  /// In en, this message translates to:
  /// **'Copy value'**
  String get viewerCopyValue;

  /// No description provided for @viewerToggleFullscreen.
  ///
  /// In en, this message translates to:
  /// **'Toggle fullscreen'**
  String get viewerToggleFullscreen;

  /// No description provided for @viewerInvert.
  ///
  /// In en, this message translates to:
  /// **'Invert'**
  String get viewerInvert;

  /// No description provided for @viewerText.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get viewerText;

  /// No description provided for @viewerSyntax.
  ///
  /// In en, this message translates to:
  /// **'Syntax'**
  String get viewerSyntax;

  /// No description provided for @viewerFont.
  ///
  /// In en, this message translates to:
  /// **'Font'**
  String get viewerFont;

  /// No description provided for @viewerFontStyle.
  ///
  /// In en, this message translates to:
  /// **'Font Style'**
  String get viewerFontStyle;

  /// No description provided for @viewerMonospaceCourier.
  ///
  /// In en, this message translates to:
  /// **'Monospace (Courier)'**
  String get viewerMonospaceCourier;

  /// No description provided for @viewerSystemUbuntu.
  ///
  /// In en, this message translates to:
  /// **'System (Ubuntu)'**
  String get viewerSystemUbuntu;

  /// No description provided for @viewerEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get viewerEdit;

  /// No description provided for @viewerEditWithEngine.
  ///
  /// In en, this message translates to:
  /// **'Edit with Fadocx Engine'**
  String get viewerEditWithEngine;

  /// No description provided for @viewerEditWithEngineDesc.
  ///
  /// In en, this message translates to:
  /// **'Open this spreadsheet in the Fadocx rendering engine for a faithful visual preview with full formatting, charts, and layout fidelity.'**
  String get viewerEditWithEngineDesc;

  /// No description provided for @viewerEditWithEngineNote.
  ///
  /// In en, this message translates to:
  /// **'Note: Interactive editing is coming in a future update.'**
  String get viewerEditWithEngineNote;

  /// No description provided for @viewerNotNow.
  ///
  /// In en, this message translates to:
  /// **'Not Now'**
  String get viewerNotNow;

  /// No description provided for @viewerGotIt.
  ///
  /// In en, this message translates to:
  /// **'Got It'**
  String get viewerGotIt;

  /// No description provided for @viewerErrorLoadingDocument.
  ///
  /// In en, this message translates to:
  /// **'Error loading document'**
  String get viewerErrorLoadingDocument;

  /// No description provided for @viewerGoBack.
  ///
  /// In en, this message translates to:
  /// **'Go Back'**
  String get viewerGoBack;

  /// No description provided for @viewerReadingTimeMinutes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 minute read} other{{count} minutes read}}'**
  String viewerReadingTimeMinutes(num count);

  /// No description provided for @viewerReadingTimeHoursMinutes.
  ///
  /// In en, this message translates to:
  /// **'{hours}h {minutes}m read'**
  String viewerReadingTimeHoursMinutes(num hours, num minutes);

  /// No description provided for @scannerTitle.
  ///
  /// In en, this message translates to:
  /// **'Document Scanner'**
  String get scannerTitle;

  /// No description provided for @scannerCapture.
  ///
  /// In en, this message translates to:
  /// **'Capture'**
  String get scannerCapture;

  /// No description provided for @scannerProcessing.
  ///
  /// In en, this message translates to:
  /// **'Processing'**
  String get scannerProcessing;

  /// No description provided for @scannerResults.
  ///
  /// In en, this message translates to:
  /// **'Results'**
  String get scannerResults;

  /// No description provided for @scannerInitializingCamera.
  ///
  /// In en, this message translates to:
  /// **'Initializing Camera...'**
  String get scannerInitializingCamera;

  /// No description provided for @scannerDocumentDetected.
  ///
  /// In en, this message translates to:
  /// **'Document detected — hold steady'**
  String get scannerDocumentDetected;

  /// No description provided for @scannerKeepDocumentFlat.
  ///
  /// In en, this message translates to:
  /// **'Keep document upright & flat for best results'**
  String get scannerKeepDocumentFlat;

  /// No description provided for @scannerUpload.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get scannerUpload;

  /// No description provided for @scannerFailedOpenImage.
  ///
  /// In en, this message translates to:
  /// **'Failed to open image: {error}'**
  String scannerFailedOpenImage(String error);

  /// No description provided for @scannerFlash.
  ///
  /// In en, this message translates to:
  /// **'Flash'**
  String get scannerFlash;

  /// No description provided for @scannerFailedTorch.
  ///
  /// In en, this message translates to:
  /// **'Failed to toggle torch: {error}'**
  String scannerFailedTorch(String error);

  /// No description provided for @scannerStartingCamera.
  ///
  /// In en, this message translates to:
  /// **'Starting Camera...'**
  String get scannerStartingCamera;

  /// No description provided for @scannerCameraUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Camera Unavailable'**
  String get scannerCameraUnavailable;

  /// No description provided for @scannerCameraUnavailableDesc.
  ///
  /// In en, this message translates to:
  /// **'Unable to initialize camera'**
  String get scannerCameraUnavailableDesc;

  /// No description provided for @scannerAnalysisComplete.
  ///
  /// In en, this message translates to:
  /// **'Analysis Complete'**
  String get scannerAnalysisComplete;

  /// No description provided for @scannerAnalyzing.
  ///
  /// In en, this message translates to:
  /// **'Analyzing Document...'**
  String get scannerAnalyzing;

  /// No description provided for @scannerEnhancing.
  ///
  /// In en, this message translates to:
  /// **'Enhancing image quality...'**
  String get scannerEnhancing;

  /// No description provided for @scannerExtractingText.
  ///
  /// In en, this message translates to:
  /// **'Extracting text data...'**
  String get scannerExtractingText;

  /// No description provided for @scannerNoScansYet.
  ///
  /// In en, this message translates to:
  /// **'No Scans Yet'**
  String get scannerNoScansYet;

  /// No description provided for @scannerNoScansDesc.
  ///
  /// In en, this message translates to:
  /// **'Capture a document to see extracted text here'**
  String get scannerNoScansDesc;

  /// No description provided for @scannerExtractedText.
  ///
  /// In en, this message translates to:
  /// **'Extracted Text'**
  String get scannerExtractedText;

  /// No description provided for @scannerNoTextExtracted.
  ///
  /// In en, this message translates to:
  /// **'(No text extracted)'**
  String get scannerNoTextExtracted;

  /// No description provided for @scannerDetectedLines.
  ///
  /// In en, this message translates to:
  /// **'Detected Lines'**
  String get scannerDetectedLines;

  /// No description provided for @scannerTextCopied.
  ///
  /// In en, this message translates to:
  /// **'Text copied to clipboard'**
  String get scannerTextCopied;

  /// No description provided for @scannerCopyAll.
  ///
  /// In en, this message translates to:
  /// **'Copy All'**
  String get scannerCopyAll;

  /// No description provided for @scannerNewScan.
  ///
  /// In en, this message translates to:
  /// **'New Scan'**
  String get scannerNewScan;

  /// No description provided for @linkTileCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get linkTileCopy;

  /// No description provided for @linkTileCopiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get linkTileCopiedToClipboard;

  /// No description provided for @linkTileSendEmail.
  ///
  /// In en, this message translates to:
  /// **'Send Email'**
  String get linkTileSendEmail;

  /// No description provided for @linkTileOpenInBrowser.
  ///
  /// In en, this message translates to:
  /// **'Open in Browser'**
  String get linkTileOpenInBrowser;

  /// No description provided for @linkTileCouldNotOpen.
  ///
  /// In en, this message translates to:
  /// **'Could not open {value}'**
  String linkTileCouldNotOpen(String value);

  /// No description provided for @librarySortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get librarySortBy;

  /// No description provided for @librarySortLatest.
  ///
  /// In en, this message translates to:
  /// **'Latest'**
  String get librarySortLatest;

  /// No description provided for @librarySortOldest.
  ///
  /// In en, this message translates to:
  /// **'Oldest'**
  String get librarySortOldest;

  /// No description provided for @librarySortLargest.
  ///
  /// In en, this message translates to:
  /// **'Largest'**
  String get librarySortLargest;

  /// No description provided for @librarySortSmallest.
  ///
  /// In en, this message translates to:
  /// **'Smallest'**
  String get librarySortSmallest;

  /// No description provided for @homeDeleteFile.
  ///
  /// In en, this message translates to:
  /// **'Delete file?'**
  String get homeDeleteFile;

  /// No description provided for @homeDeleteFileConfirm.
  ///
  /// In en, this message translates to:
  /// **'Move \"{name}\" to trash? You can restore it later.'**
  String homeDeleteFileConfirm(String name);

  /// No description provided for @homeCopiedCharactersToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Copied {count} characters to clipboard'**
  String homeCopiedCharactersToClipboard(num count);

  /// No description provided for @homeFileInTrashDetail.
  ///
  /// In en, this message translates to:
  /// **'In trash: yes (deleted at: {date})'**
  String homeFileInTrashDetail(String date);

  /// No description provided for @homeUnknown.
  ///
  /// In en, this message translates to:
  /// **'unknown'**
  String get homeUnknown;
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
