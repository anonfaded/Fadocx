// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appName => 'Fadocx';

  @override
  String get appDescription => 'Document Viewer';

  @override
  String get homeTitle => 'Fadocx';

  @override
  String get recentFiles => 'Zuletzt geöffnet';

  @override
  String get noRecentFiles => 'Keine zuletzt geöffneten Dateien. Öffnen Sie ein Dokument.';

  @override
  String get openFile => 'Open File';

  @override
  String get openFileTooltip => 'Browse and open a document';

  @override
  String get pdfFile => 'PDF File';

  @override
  String get docxFile => 'Word Document';

  @override
  String get xlsxFile => 'Excel Spreadsheet';

  @override
  String get csvFile => 'CSV File';

  @override
  String get unknownFile => 'Unknown File';

  @override
  String get page => 'Page';

  @override
  String get pageOf => 'of';

  @override
  String get jumpToPage => 'Jump to page';

  @override
  String get sheet => 'Sheet';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get delete => 'Löschen';

  @override
  String get clear => 'Leeren';

  @override
  String get close => 'Schließen';

  @override
  String get copy => 'Kopieren';

  @override
  String get retry => 'Erneut versuchen';

  @override
  String get rename => 'Umbenennen';

  @override
  String get restore => 'Wiederherstellen';

  @override
  String get export => 'Exportieren';

  @override
  String get duplicate => 'Duplizieren';

  @override
  String get imports => 'Importieren';

  @override
  String get next => 'Weiter';

  @override
  String get previous => 'Zurück';

  @override
  String get back => 'Zurück';

  @override
  String get settings => 'Einstellungen';

  @override
  String get about => 'Über die App';

  @override
  String get error => 'Fehler';

  @override
  String get warning => 'Warnung';

  @override
  String get success => 'Erfolg';

  @override
  String get unsupportedFileType => 'Dateiformat nicht unterstützt';

  @override
  String get fileNotFound => 'Datei nicht gefunden';

  @override
  String get permissionDenied => 'Zugriff verweigert';

  @override
  String get corruptedFile => 'File appears to be corrupted';

  @override
  String get loadingDocument => 'Dokument wird geladen...';

  @override
  String get settingsTitle => 'Einstellungen';

  @override
  String get theme => 'Thema';

  @override
  String get themeDark => 'Dunkel';

  @override
  String get themeLight => 'Hell';

  @override
  String get themeSystem => 'System';

  @override
  String get language => 'Sprache';

  @override
  String get languageEnglish => 'Englisch';

  @override
  String get languageUrdu => 'اردو';

  @override
  String get languageRussian => 'Russisch';

  @override
  String get languageChinese => 'Chinesisch';

  @override
  String get languageJapanese => 'Japanisch';

  @override
  String get languageFrench => 'Französisch';

  @override
  String get languageArabic => 'Arabisch';

  @override
  String get languageSpanish => 'Spanisch';

  @override
  String get languageGerman => 'Deutsch';

  @override
  String get languagePortuguese => 'Portugiesisch';

  @override
  String get languageHindi => 'Hindi';

  @override
  String get appVersion => 'App Version';

  @override
  String get clearRecentFiles => 'Clear recent files';

  @override
  String get backButton => 'Back';

  @override
  String get emptyTitle => 'No Documents';

  @override
  String get emptyMessage => 'Start by opening a document from your device';

  @override
  String get startBrowsing => 'Start Browsing';

  @override
  String get languageChanged => 'Language changed to English';

  @override
  String get privacyDescription => 'Fadocx is a document viewer. Your files are stored locally on your device and are never transmitted to any server.';

  @override
  String get aboutDescription => 'Fadocx v1.0.0 - Your private document viewer. Built to respect your privacy.';

  @override
  String get tableRows => 'rows';

  @override
  String get tableEmpty => 'No data to display';

  @override
  String get tableNoContent => 'Sheet is empty';

  @override
  String get sheetEmpty => 'Sheet is empty';

  @override
  String get noTableData => 'No table data';

  @override
  String get noSpreadsheetData => 'No spreadsheet data';

  @override
  String get rowsSymbol => 'rows';

  @override
  String get colsSymbol => 'cols';

  @override
  String get noSlidesFound => 'No slides found';

  @override
  String get slidesCount => 'slides';

  @override
  String get pptUnsupported => 'PPT file parsed but contains no slides';

  @override
  String get odpUnsupported => 'ODP file parsed but contains no slides or unreadable content';

  @override
  String get noTextContent => 'No text content found';

  @override
  String get couldNotParse => 'Could not parse file';

  @override
  String get file => 'File';

  @override
  String get slides => 'Slide';

  @override
  String get previewNotSupported => 'Preview not yet supported';

  @override
  String get openWithSystemApp => 'Open with System App';

  @override
  String get systemAppNotImplemented => 'System app opening not yet implemented';

  @override
  String get type => 'Type';

  @override
  String get fileNotFoundMessage => 'File not found';

  @override
  String get fileTooLarge => 'File size exceeds maximum limit (100MB)';

  @override
  String get errorLoadingFile => 'Error loading file';

  @override
  String get docxPreviewNotSupported => 'DOCX preview not yet fully supported';

  @override
  String get docParseError => 'Could not parse DOC file. Try converting to DOCX.';

  @override
  String get xlsxParseError => 'Could not parse XLSX file';

  @override
  String get xlsParseError => 'Could not parse XLS file. Try converting to XLSX.';

  @override
  String get csvParseError => 'Could not parse CSV file';

  @override
  String get odtParseError => 'Could not parse ODT file';

  @override
  String get odsParseError => 'Could not parse ODS file';

  @override
  String get odpParseError => 'Could not parse ODP file';

  @override
  String get pptParseError => 'Could not parse PPT file';

  @override
  String get rtfParseError => 'Could not parse RTF file';

  @override
  String get txtFileEmpty => 'File is empty';

  @override
  String get unsupportedFormat => 'File format is not supported yet';

  @override
  String get txtLoaded => 'TXT';

  @override
  String get charactersLoaded => 'characters';

  @override
  String get copiedToClipboard => 'In Zwischenablage kopiert';

  @override
  String get navHome => 'Startseite';

  @override
  String get navLibrary => 'Bibliothek';

  @override
  String get navSettings => 'Einstellungen';

  @override
  String get navRecents => 'Zuletzt';

  @override
  String get categoryAll => 'Alle';

  @override
  String get categoryPdfs => 'PDFs';

  @override
  String get categoryDocs => 'Dokumente';

  @override
  String get categorySheets => 'Tabellen';

  @override
  String get categorySlides => 'Präsentationen';

  @override
  String get categoryCode => 'Code';

  @override
  String get categoryScans => 'Scans';

  @override
  String get categoryOther => 'Sonstiges';

  @override
  String get categoryPresentations => 'Präsentationen';

  @override
  String get supportDevelopment => 'Entwicklung unterstützen';

  @override
  String get visitPatreon => 'Patreon besuchen';

  @override
  String get copyLink => 'Link kopieren';

  @override
  String get becomeAPatron => 'Become a Patron';

  @override
  String get patreonDescription => 'Deine Unterstützung hilft Fadocx und FadCam zu wachsen. Patreon-Abonnenten erhalten exklusive Vorteile, darunter Premium-Funktionen und frühen Zugriff auf alle FadSec Lab Apps.\n\nFür mehr Infos besuche Patreon über den Link unten und prüfe die verfügbaren Stufen samt Vorteilen.';

  @override
  String get discordTitle => 'Tritt unserem Discord bei';

  @override
  String get openInBrowser => 'Im Browser öffnen';

  @override
  String get comingSoon => 'Demnächst';

  @override
  String get newBadge => 'NEW';

  @override
  String get timeAgoJustNow => 'Gerade eben';

  @override
  String timeAgoMinute(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'vor $count Minuten',
      one: 'vor 1 Minute',
    );
    return '$_temp0';
  }

  @override
  String timeAgoHour(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'vor $count Stunden',
      one: 'vor 1 Stunde',
    );
    return '$_temp0';
  }

  @override
  String timeAgoDay(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'vor $count Tagen',
      one: 'vor 1 Tag',
    );
    return '$_temp0';
  }

  @override
  String timeAgoWeek(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'vor $count Wochen',
      one: 'vor 1 Woche',
    );
    return '$_temp0';
  }

  @override
  String timeAgoMonth(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'vor $count Monaten',
      one: 'vor 1 Monat',
    );
    return '$_temp0';
  }

  @override
  String timeAgoYear(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'vor $count Jahren',
      one: 'vor 1 Jahr',
    );
    return '$_temp0';
  }

  @override
  String get monthJan => 'Jan';

  @override
  String get monthFeb => 'Feb';

  @override
  String get monthMar => 'Mär';

  @override
  String get monthApr => 'Apr';

  @override
  String get monthMay => 'Mai';

  @override
  String get monthJun => 'Jun';

  @override
  String get monthJul => 'Jul';

  @override
  String get monthAug => 'Aug';

  @override
  String get monthSep => 'Sep';

  @override
  String get monthOct => 'Okt';

  @override
  String get monthNov => 'Nov';

  @override
  String get monthDec => 'Dez';

  @override
  String get homeWelcomeTitle => 'Willkommen bei Fadocx';

  @override
  String get homeWelcomeSubtitle => 'Erkunden Sie Beispieldateien oder importieren Sie Ihre eigenen Dokumente';

  @override
  String get homeExploreSamples => 'Beispieldateien erkunden';

  @override
  String get homeDocumentManagement => 'Dokumentenverwaltung';

  @override
  String get homeSeeAll => 'Alle anzeigen';

  @override
  String get homeNoRecentFiles => 'Keine zuletzt geöffneten Dateien';

  @override
  String get homeScanDocument => 'Dokument scannen';

  @override
  String get homeScanDocumentDesc => 'Text aus Dokumenten per OCR extrahieren';

  @override
  String get homeImportDocument => 'Dokument importieren';

  @override
  String get homeImportDocumentDesc => 'Dateien vom Gerät durchsuchen und importieren';

  @override
  String get onboardingSkip => 'Überspringen';

  @override
  String get onboardingNext => 'Weiter';

  @override
  String get onboardingGetStarted => 'Los geht\'s';

  @override
  String get onboardingSlide1Title => 'Willkommen bei Fadocx';

  @override
  String get onboardingSlide1Tagline => 'Ihr privater Alles-in-einem-Dokumentenbegleiter';

  @override
  String get onboardingSlide1Bullet1 => 'Öffnen Sie jedes Format — PDFs, Office-Dateien, Bilder und mehr';

  @override
  String get onboardingSlide1Bullet2 => 'Privater Speicher, versteckt vor Ihrer Galerie und dem Dateimanager';

  @override
  String get onboardingSlide1Bullet3 => 'Kostenlos, Open Source — kein Konto oder Registrierung nötig';

  @override
  String get onboardingSlide2Title => 'Eingebaute Werkzeuge';

  @override
  String get onboardingSlide2Bullet1 => 'Dokumente mit der Kamera scannen — Text wird sofort extrahiert';

  @override
  String get onboardingSlide2Bullet2 => 'Audio und Video direkt in der App abspielen, ohne Extras';

  @override
  String get onboardingSlide2Bullet3 => 'Alles wird beim Import automatisch in Kategorien sortiert';

  @override
  String get onboardingSlide2Bullet4 => 'Sicheres Löschen — jederzeit aus dem Papierkorb wiederherstellen';

  @override
  String get onboardingSlide3Title => 'Datenschutz by Design';

  @override
  String get onboardingSlide3Bullet1 => 'Nichts verlässt jemals Ihr Gerät — keine Cloud, keine Server';

  @override
  String get onboardingSlide3Bullet2 => 'Kein Tracking, keine Werbung, keine Analyse. Niemals.';

  @override
  String get onboardingSlide3Bullet3 => 'Open Source — jede Codezeile ist öffentlich';

  @override
  String get homeStatDocuments => 'Dokumente';

  @override
  String get homeStatStorage => 'Speicher';

  @override
  String get homeStatTimeRead => 'Lesezeit';

  @override
  String get homeStatLastOpened => 'Zuletzt geöffnet: ';

  @override
  String get homePressBackExit => 'Nochmals drücken zum Beenden';

  @override
  String get homeImportingSamples => 'Importing sample files...';

  @override
  String homeSamplesImported(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sample files imported successfully!',
      one: '1 sample file imported successfully!',
    );
    return '$_temp0';
  }

  @override
  String get homeViewFiles => 'View Files';

  @override
  String homeFailedImportSamples(String error) {
    return 'Failed to import sample files: $error';
  }

  @override
  String homeFileMovedToTrash(String name) {
    return '$name moved to trash';
  }

  @override
  String get homeFileInfo => 'Dateiinfos';

  @override
  String get homeFileName => 'Name';

  @override
  String get homeFileType => 'Typ';

  @override
  String get homeFileSize => 'Größe';

  @override
  String get homeFileLocation => 'Speicherort';

  @override
  String get homeFileDateOpened => 'Geöffnet am';

  @override
  String get homeFileLastModified => 'Zuletzt geändert';

  @override
  String get homeFileInTrash => 'Im Papierkorb';

  @override
  String get homeFileInfoCopied => 'Dateiinfos kopiert';

  @override
  String get homeCopySuffix => ' (copy)';

  @override
  String homeCopySuffixCounter(num counter) {
    return ' (copy $counter)';
  }

  @override
  String homeDuplicatedAs(String name) {
    return 'Duplicated as $name';
  }

  @override
  String homeFailedDuplicate(String error) {
    return 'Failed to duplicate file: $error';
  }

  @override
  String get homeRenameFile => 'Rename file';

  @override
  String get homeFileNameLabel => 'File name';

  @override
  String get homeFileAlreadyExists => 'A file with this name already exists';

  @override
  String homeRenamedTo(String name) {
    return 'Renamed to $name';
  }

  @override
  String get homeFailedRename => 'Failed to rename file';

  @override
  String get homeExport => 'Export';

  @override
  String get homeSaveToDownloads => 'Save to Downloads';

  @override
  String homeSaveToDownloadsPath(String name) {
    return 'Download/Fadocx/$name';
  }

  @override
  String get homeChooseLocation => 'Choose location';

  @override
  String get homeChooseLocationDesc => 'Pick a custom save directory';

  @override
  String homeSavedToDownloads(String name) {
    return 'Saved to Download/Fadocx/$name';
  }

  @override
  String homeSavedTo(String path) {
    return 'Saved to $path';
  }

  @override
  String get homeFailedExport => 'Failed to export file';

  @override
  String get homeChooseSaveLocation => 'Choose save location';

  @override
  String get homeConvertComingSoon => 'Convert feature coming soon!';

  @override
  String get homeFadDriveComingSoon => 'FadDrive coming soon!';

  @override
  String get homePresentationsTooltip => 'Coming Soon';

  @override
  String homeErrorPrefix(String error) {
    return 'Error: $error';
  }

  @override
  String get libraryTitle => 'Bibliothek';

  @override
  String get librarySearchHint => 'Bibliothek durchsuchen...';

  @override
  String librarySelected(num count) {
    return '$count selected';
  }

  @override
  String get libraryDeleteSelected => 'Delete selected?';

  @override
  String libraryDeleteConfirm(num count) {
    return 'Move $count files to trash? You can restore them later.';
  }

  @override
  String libraryItemsMovedToTrash(num count) {
    return '$count items moved to trash';
  }

  @override
  String libraryErrorLoading(String error) {
    return 'Error loading library: $error';
  }

  @override
  String libraryItemCount(num count) {
    return '$count items';
  }

  @override
  String get libraryDeselectAll => 'Deselect all';

  @override
  String get librarySelectAll => 'Select all';

  @override
  String libraryNoCategoryFound(String category) {
    return 'No $category found';
  }

  @override
  String get libraryNoDocuments => 'Keine Dokumente';

  @override
  String get libraryAdjustSearch => 'Passen Sie Ihre Suche oder Filter an';

  @override
  String get libraryDocumentsAppearHere => 'Ihre Dokumente erscheinen hier';

  @override
  String get browseTitle => 'Dokumente importieren';

  @override
  String get browseBack => 'Zurück';

  @override
  String get browseSearchHint => 'Dokumente durchsuchen...';

  @override
  String get browseCancel => 'Abbrechen';

  @override
  String get browseBrowseFiles => 'Durchsuchen';

  @override
  String get browseBrowseFilesDesc => 'Weitere Dateien manuell importieren';

  @override
  String get browseScanFailed => 'Scan fehlgeschlagen';

  @override
  String get browseUnknownError => 'Unbekannter Fehler aufgetreten';

  @override
  String get browseRetryScan => 'Scan erneut versuchen';

  @override
  String get browseImportManually => 'Dateien manuell importieren';

  @override
  String get browseNoDocumentsFound => 'Keine Dokumente gefunden';

  @override
  String get browseNoDocumentsMatch => 'Keine Dokumente passen zu deiner Suche';

  @override
  String get browseAdjustSearch => 'Passe Suche oder Filter an';

  @override
  String get browseClearSelection => 'Löschen';

  @override
  String get browseImport => 'Importieren';

  @override
  String get browseAllFilesAccessRequired => 'Für das Durchsuchen von Dokumenten auf deinem Gerät ist Zugriff auf alle Dateien erforderlich';

  @override
  String get browsePermissionRequired => 'Berechtigung erforderlich';

  @override
  String get browseAllFilesAccessDenied => 'Für das Durchsuchen und Lesen von Dokumenten auf deinem Gerät ist Zugriff auf alle Dateien erforderlich. Bitte erteile diese Berechtigung, um fortzufahren.';

  @override
  String get browseOpenSettings => 'Einstellungen öffnen';

  @override
  String get browseAccessStillDisabled => 'Der Zugriff auf alle Dateien ist weiterhin deaktiviert. Bitte aktiviere ihn in den Einstellungen, um fortzufahren.';

  @override
  String get browseNoDirectories => 'Keine Dokumentordner auf dem Gerät gefunden';

  @override
  String browseErrorPrefix(String error) {
    return 'Fehler: $error';
  }

  @override
  String get browseSortBy => 'Sortieren nach';

  @override
  String browseImportedFiles(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Dateien importiert',
      one: '1 Datei importiert',
    );
    return '$_temp0';
  }

  @override
  String get trashTitle => 'Papierkorb';

  @override
  String get trashEmpty => 'Papierkorb ist leer';

  @override
  String get trashEmptySubtitle => 'Gelöschte Dateien werden hier angezeigt';

  @override
  String get trashErrorLoading => 'Error loading trash';

  @override
  String trashFilesSelected(num count) {
    return '$count selected';
  }

  @override
  String get trashFilesLabel => 'files';

  @override
  String get trashSelect => 'Auswählen';

  @override
  String get trashFileRestored => 'File restored successfully';

  @override
  String get trashDeletePermanently => 'Dauerhaft löschen';

  @override
  String get trashDeletePermanentlyConfirm => 'Delete Permanently?';

  @override
  String trashDeletePermanentlyMessage(num count) {
    return 'You are about to permanently delete $count file(s). This action cannot be undone.';
  }

  @override
  String get trashDeleteTypeConfirm => 'Type DELETE in capital letters to confirm:';

  @override
  String get trashDeleteHint => 'DELETE';

  @override
  String trashFilesPermanentlyDeleted(num count) {
    return '$count file(s) permanently deleted';
  }

  @override
  String get whatsNewTitle => 'Neuigkeiten';

  @override
  String get whatsNewWhatsIncluded => 'Enthalten';

  @override
  String get whatsNewPlanned => 'Geplant';

  @override
  String get whatsNewReleasedToday => 'Heute veröffentlicht';

  @override
  String get whatsNewReleasedYesterday => 'Gestern veröffentlicht';

  @override
  String whatsNewReleasedDate(String date) {
    return 'Veröffentlicht $date';
  }

  @override
  String get whatsNewDocAndSheets => 'Dokumente & Tabellen';

  @override
  String get whatsNewDocAndSheetsDesc => 'Zeige PDFs, Word-Dokumente, Excel-Tabellen und mehr an – alles lokal auf deinem Gerät.';

  @override
  String get whatsNewOcrAi => 'Intelligentes OCR & KI auf dem Gerät';

  @override
  String get whatsNewOcrAiDesc => 'Extrahiere Text aus Bildern mit fortschrittlichem OCR auf dem Gerät. Mehrere Sprachen werden unterstützt.';

  @override
  String get whatsNewSyntaxHighlighting => 'Syntaxhervorhebung';

  @override
  String get whatsNewSyntaxHighlightingDesc => 'Schöne Codehervorhebung für über 50 Programmiersprachen.';

  @override
  String get whatsNewReadingStats => 'Lesestatistik-Dashboard';

  @override
  String get whatsNewReadingStatsDesc => 'Verfolge deinen Lesefortschritt mit detaillierten Statistiken und Zeitmessung.';

  @override
  String get whatsNewLibraryCategories => 'Bibliothek mit Kategorieordnern';

  @override
  String get whatsNewLibraryCategoriesDesc => 'Organisiere deine Dokumente nach Typ mit intelligenter automatischer Kategorisierung.';

  @override
  String get whatsNewFileManagement => 'Dateiverwaltung';

  @override
  String get whatsNewFileManagementDesc => 'Benenne deine Dokumente um, dupliziere, exportiere und lösche sie ganz einfach.';

  @override
  String get whatsNewThemes => 'Helle & dunkle Designs';

  @override
  String get whatsNewThemesDesc => 'Wähle den Look, der zu dir passt – Dunkelmodus für die Nacht, Hellmodus für den Tag.';

  @override
  String get whatsNewFadDrive => 'FadDrive';

  @override
  String get whatsNewFadDriveDesc => 'Cloud-Synchronisierung für deine Dokumente – greife überall und jederzeit darauf zu.';

  @override
  String get whatsNewEditing => 'Dokumentbearbeitung';

  @override
  String get whatsNewEditingDesc => 'Nimm schnelle Änderungen direkt in Fadocx an deinen Dokumenten vor.';

  @override
  String get whatsNewBookmarks => 'Lesezeichen & Anmerkungen';

  @override
  String get whatsNewBookmarksDesc => 'Markiere wichtige Seiten und füge Anmerkungen für später hinzu.';

  @override
  String get whatsNewConversion => 'Dokumentkonvertierung';

  @override
  String get whatsNewConversionDesc => 'Konvertiere zwischen Formaten wie PDF, DOCX und mehr.';

  @override
  String get whatsNewAmoled => 'AMOLED-Schwarz-Design';

  @override
  String get whatsNewAmoledDesc => 'Rein schwarzes Design für AMOLED-Displays – spart Akku im Dunkelmodus.';

  @override
  String get whatsNewMoreOcr => 'Mehr OCR-Sprachen';

  @override
  String get whatsNewMoreOcrDesc => 'Unterstützung für zusätzliche OCR-Sprachen und verbesserte Erkennungsgenauigkeit.';

  @override
  String get whatsNewOfflineFirst => 'Ein Offline-First-Dokumentbetrachter für Privatsphäre. Keine Konten, kein Tracking, kein Internet erforderlich.';

  @override
  String get whatsNewThankYou => 'Danke, dass du Fadocx nutzt';

  @override
  String get whatsNewThankYouDesc => 'Wenn du Fadocx nützlich findest, unterstütze seine Entwicklung. Dein Beitrag hilft uns, weiterhin datenschutzfreundliche Werkzeuge zu bauen.';

  @override
  String get drawerWhatNew => 'Neuigkeiten';

  @override
  String get drawerRecentFiles => 'Zuletzt verwendete Dateien';

  @override
  String get drawerVisible => 'Sichtbar';

  @override
  String get drawerHidden => 'Ausgeblendet';

  @override
  String get drawerUnlockBenefits => 'Exklusive Vorteile freischalten';

  @override
  String get fileActionRename => 'Umbenennen';

  @override
  String get fileActionRenameDesc => 'Dateinamen ändern';

  @override
  String get fileActionDuplicate => 'Duplizieren';

  @override
  String get fileActionDuplicateDesc => 'Kopie erstellen';

  @override
  String get fileActionExport => 'Exportieren / Speichern unter';

  @override
  String get fileActionExportDesc => 'Kopie in Downloads speichern';

  @override
  String get fileActionCopyText => 'Text kopieren';

  @override
  String get fileActionCopyTextDesc => 'Extrahierten Text in Zwischenablage kopieren';

  @override
  String get fileActionConvert => 'Konvertieren';

  @override
  String get fileActionConvertDesc => 'In anderes Format konvertieren';

  @override
  String get fileActionUpload => 'Zu FadDrive hochladen';

  @override
  String get fileActionUploadDesc => 'Mit Cloud-Speicher synchronisieren';

  @override
  String get fileActionFileInfo => 'Dateiinfo';

  @override
  String get fileActionSubtitle => 'Dateiaktionen und Verwaltung';

  @override
  String get updateAvailableTitle => 'Update Available';

  @override
  String get updateAvailableSubtitle => 'A new version is ready to download';

  @override
  String get updateStableRelease => 'Stable Release';

  @override
  String get updateStableDesc => 'Recommended for most users';

  @override
  String get updateBetaRelease => 'Beta Release';

  @override
  String get updateBetaDesc => 'Latest features — may be unstable';

  @override
  String get updateMaybeLater => 'Maybe Later';

  @override
  String get updateCurrent => 'Current';

  @override
  String get updateNew => 'New';

  @override
  String get updateVisitGithub => 'Visit GitHub';

  @override
  String get updateBetaInfo => 'The Fadocx beta is a standalone app that can be installed alongside the stable version. It will not interfere with your stable app or its data.\n\nInstall the beta to test new features before they reach the stable release.';

  @override
  String get updateBannerStable => 'Stable Update';

  @override
  String get updateBannerBeta => 'Beta Update';

  @override
  String get settingsAppearance => 'Darstellung';

  @override
  String get settingsStorage => 'Speicher';

  @override
  String get settingsDocumentsSize => 'Dokumentgröße';

  @override
  String get settingsCalculating => 'Wird berechnet...';

  @override
  String get settingsCustomStorage => 'Benutzerdefinierter Speicher';

  @override
  String get settingsUnknown => 'Unknown';

  @override
  String get settingsStorageDetails => 'Speicher';

  @override
  String get settingsStoragePdfs => 'PDFs';

  @override
  String get settingsStorageDocs => 'Dokumente';

  @override
  String get settingsStorageSheets => 'Tabellen';

  @override
  String get settingsStoragePresentations => 'Präsentationen';

  @override
  String get settingsStorageCode => 'Code';

  @override
  String get settingsStorageScans => 'Scans';

  @override
  String get settingsStorageImages => 'Bilder';

  @override
  String get settingsStorageOther => 'Sonstiges';

  @override
  String get settingsStorageInfo => 'Dokumente werden in einem privaten Ordner auf deinem Gerät gespeichert und können nicht von anderen Apps aufgerufen werden';

  @override
  String get settingsStoragePrivateFolderInfo => 'Dokumente werden in einem privaten Ordner gespeichert, der vor anderen Apps und Dateimanagern verborgen ist. Nur Fadocx kann darauf zugreifen.';

  @override
  String get settingsStorageDeleteInfo => 'Lösche Dokumente in der Gefahrenzone der Einstellungen';

  @override
  String get settingsStorageEmpty => 'Keine Dokumente';

  @override
  String get settingsStorageFailedLoad => 'Speicherdaten konnten nicht geladen werden';

  @override
  String get settingsUpdates => 'Updates';

  @override
  String get settingsAutoUpdateCheck => 'Automatische Update-Prüfung';

  @override
  String get settingsReplayOnboarding => 'Einführung wiederholen';

  @override
  String get settingsReplayOnboardingDesc => 'Einführungsfolien beim nächsten Start anzeigen';

  @override
  String get settingsEnabled => 'Aktiviert';

  @override
  String get settingsDisabled => 'Deaktiviert';

  @override
  String get settingsAppLock => 'App-Sperre';

  @override
  String get settingsAbout => 'Über die App';

  @override
  String get settingsVersion => 'Version';

  @override
  String get settingsSourceCode => 'Quellcode';

  @override
  String get settingsContact => 'Kontakt';

  @override
  String get settingsJoinCommunity => 'Community beitreten';

  @override
  String get settingsPrivacyPolicy => 'Datenschutzrichtlinie';

  @override
  String get settingsMoreFromFadsec => 'Mehr von FadSec Lab';

  @override
  String get settingsFadocxDesc => 'Your private document viewer';

  @override
  String get settingsDangerZone => 'Gefahrenzone';

  @override
  String get settingsTrash => 'Papierkorb';

  @override
  String get settingsTrashDesc => 'Gelöschte Dateien anzeigen';

  @override
  String get settingsResetSettings => 'Einstellungen zurücksetzen';

  @override
  String get settingsResetSettingsDesc => 'Alle Einstellungen auf Standard zurücksetzen';

  @override
  String get settingsResetDone => 'Einstellungen zurückgesetzt';

  @override
  String get settingsRetry => 'Retry';

  @override
  String get settingsChooseTheme => 'Thema auswählen';

  @override
  String get settingsSelectLanguage => 'Sprache auswählen';

  @override
  String get settingsCheckForUpdates => 'Nach Updates suchen';

  @override
  String get settingsCheckingUpdates => 'Checking for updates…';

  @override
  String get settingsNoInternet => 'No internet connection. Check your network and try again.';

  @override
  String get settingsUpToDate => 'You\'re up to date';

  @override
  String settingsUpToDateDesc(String version) {
    return 'v$version is the latest version.';
  }

  @override
  String settingsBetaAvailable(String version) {
    return 'Beta v$version available';
  }

  @override
  String settingsVersionWithBuild(String version, String buildNumber) {
    return 'Version $version (Build $buildNumber)';
  }

  @override
  String get settingsCopiedInfo => 'In Zwischenablage kopiert';

  @override
  String get settingsCopyInfo => 'Infos kopieren';

  @override
  String settingsVersionClipboardInfo(String appName, String version, String buildNumber, String packageName) {
    return '$appName v$version (Build $buildNumber)\nPaket: $packageName';
  }

  @override
  String get settingsShareApp => 'Mit Freunden teilen';

  @override
  String get settingsShareMessage => 'Schau dir Fadocx an!\n\nAll-in-One-Dokumentbetrachter: PDF, Office, Tabellen, Präsentationen, Codedateien und OCR-Texterkennung — komplett offline, ohne Tracking, Open Source.\n\nhttps://github.com/anonfaded/Fadocx';

  @override
  String get settingsShareVia => 'Teilen über...';

  @override
  String get settingsShareWhatsApp => 'WhatsApp';

  @override
  String get settingsWhatsAppNotInstalled => 'WhatsApp ist auf diesem Gerät nicht installiert';

  @override
  String get settingsPrivacyOffline => '100% Offline';

  @override
  String get settingsPrivacyLocalStorage => 'Local Storage Only';

  @override
  String get settingsPrivacyOnDevice => 'On-Device AI';

  @override
  String get settingsPrivacyOpenSource => 'Open Source';

  @override
  String get settingsPrivacyNoAds => 'No Ads';

  @override
  String get settingsPrivacyByDesign => 'We believe in privacy by design.';

  @override
  String get settingsPrivacyTransparency => 'Fadocx is built with transparency. Your documents are your business - not ours.';

  @override
  String get settingsViewSourceCode => 'View Source Code';

  @override
  String get settingsSecurity => 'Sicherheit';

  @override
  String settingsStorageFilesSummary(String size, num count) {
    return '$size • $count files';
  }

  @override
  String settingsErrorPrefix(String error) {
    return 'Error: $error';
  }

  @override
  String settingsCopiedText(String text) {
    return 'Copied: $text';
  }

  @override
  String get settingsVisitGithub => 'Visit GitHub';

  @override
  String get settingsMadeWith => 'Made with';

  @override
  String get settingsAt => 'at';

  @override
  String get settingsIn => 'in';

  @override
  String get settingsCopyright => '© 2024 – 2026 FadSec Lab · GPLv3 · fadseclab.com';

  @override
  String settingsTypeToConfirm(String text) {
    return 'Type \"$text\" to confirm:';
  }

  @override
  String get confirm => 'Bestätigen';

  @override
  String get settingsPrivacyOfflineDesc => 'All processing happens on your device. No internet required.';

  @override
  String get settingsPrivacyLocalStorageDesc => 'Your documents stay on your device. Nothing is uploaded.';

  @override
  String get settingsPrivacyOnDeviceDesc => 'Uses OpenCV + Tesseract for OCR. AI runs locally.';

  @override
  String get settingsPrivacyOpenSourceDesc => 'Code is public. Audit it yourself on GitHub.';

  @override
  String get settingsPrivacyNoAdsDesc => 'No advertisements. No tracking. No analytics. No crash logs. Zero telemetry.';

  @override
  String get settingsFadcamDesc => 'Datenschutzorientierte Android-Multimedia-Suite: Hintergrundvideoaufnahme, Dashcam, Bildschirmrekorder, Live-Streaming und Fernsteuerung — werbefrei und Open Source.';

  @override
  String get settingsQuranCliDesc => 'Dein Terminal-Begleiter für den Heiligen Quran: Lesen, Hören und Untertitel für die Videobearbeitung erzeugen!';

  @override
  String get settingsFadcryptDesc => 'Fortschrittliche und elegante plattformübergreifende App-Sperre – Dateien, Ordner und Anwendungen mit militärischer AES-256-GCM-Verschlüsselung geschützt. Open Source, komplett kostenlos, keine Telemetrie!';

  @override
  String get settingsFadcatDesc => 'Leichter, funktionsreicher, plattformübergreifender Android-logcat-Ersatz – ohne Android-Studio-Ballast. Enthält ADB für unterstützte Architekturen und läuft als GUI, CLI oder MCP-Server.';

  @override
  String get settingsMacosComingSoon => 'macOS kommt bald';

  @override
  String get settingsOpenInBrowser => 'Open in Browser';

  @override
  String get viewerFindHint => 'Find...';

  @override
  String get viewerTypeToFind => 'Type to find';

  @override
  String get viewerSidebarPages => 'Pages';

  @override
  String get viewerSidebarSearch => 'Search';

  @override
  String get viewerSidebarTOC => 'TOC';

  @override
  String get viewerSidebarNotes => 'Notes';

  @override
  String get viewerSidebarBookmarks => 'Bookmarks';

  @override
  String get viewerSidebarNotesDesc => 'Add notes and annotations to PDF pages';

  @override
  String get viewerSidebarBookmarksDesc => 'Save and organize your favorite pages';

  @override
  String viewerCellCopied(String value) {
    return 'Cell $value copied';
  }

  @override
  String get viewerGoToPage => 'Go to Page';

  @override
  String viewerGoToPageHint(num totalPages) {
    return 'Enter page number (1-$totalPages)';
  }

  @override
  String get viewerGo => 'Go';

  @override
  String viewerInvalidPage(num totalPages) {
    return 'Please enter a number between 1 and $totalPages';
  }

  @override
  String get viewerNoContent => 'No content';

  @override
  String get viewerResetZoom => 'Reset zoom';

  @override
  String get viewerCopyTextTitle => 'Copy Text';

  @override
  String get viewerCopyTextChoose => 'Choose what to copy:';

  @override
  String viewerCopyPageOnly(num page) {
    return 'Page $page only';
  }

  @override
  String viewerCopyAllPages(num totalPages) {
    return 'All $totalPages pages';
  }

  @override
  String viewerExtractingText(String label) {
    return 'Extracting text from $label...';
  }

  @override
  String get viewerNoTextFound => 'No text content found';

  @override
  String viewerPageLabel(num currentPage) {
    return 'Page $currentPage';
  }

  @override
  String viewerAllPagesLabel(num totalPages) {
    return '$totalPages pages';
  }

  @override
  String viewerTextExtracted(String pageLabel) {
    return 'Text extracted from $pageLabel.';
  }

  @override
  String viewerWordsFound(num count) {
    return '$count words found';
  }

  @override
  String viewerCopiedWords(num count, String pageLabel) {
    return 'Copied $count words from $pageLabel';
  }

  @override
  String get viewerCopyAllTextTitle => 'Copy All Text';

  @override
  String viewerCopyAllTextConfirm(num pageCount) {
    return 'This will extract text from all $pageCount pages and copy to clipboard.';
  }

  @override
  String viewerCopiedAllPages(num count, num pageCount) {
    return 'Copied $count words from $pageCount pages';
  }

  @override
  String get viewerCopyDocumentText => 'This will copy the entire document content to clipboard.';

  @override
  String viewerWordsLines(num words, num lines) {
    return '$words words, $lines lines';
  }

  @override
  String viewerWordsOnly(num count) {
    return '$count words';
  }

  @override
  String viewerLinesOnly(num lines) {
    return '$lines lines';
  }

  @override
  String viewerCopiedFromLines(num words, num lines) {
    return 'Copied $words words from $lines lines';
  }

  @override
  String viewerCharactersCount(num count) {
    return '$count characters';
  }

  @override
  String get viewerCopyExtractedTitle => 'Copy Extracted Text';

  @override
  String get viewerCopyExtractedDesc => 'Copy text extracted from this image via OCR.';

  @override
  String viewerCopiedWordsChars(num words, num chars) {
    return 'Copied $words words ($chars characters)';
  }

  @override
  String get viewerErrorAccessText => 'Error accessing extracted text';

  @override
  String get viewerNoTextForImage => 'No extracted text available for this image';

  @override
  String get viewerExtractingAllPages => 'Extracting text from all pages...';

  @override
  String get viewerTextExtractionUnavailable => 'Text extraction not available';

  @override
  String get viewerNoPdfText => 'No text found in this PDF';

  @override
  String get viewerNoTextAvailable => 'No text content available';

  @override
  String viewerReadingTime(num minutes) {
    return '$minutes min read';
  }

  @override
  String get viewerReadingTimeSingle => '1 min read';

  @override
  String get viewerCopy => 'Copy';

  @override
  String viewerErrorPrefix(String error) {
    return 'Error: $error';
  }

  @override
  String viewerCellValue(String cell) {
    return 'Cell $cell';
  }

  @override
  String viewerLowerPageLabel(num page) {
    return 'page $page';
  }

  @override
  String get viewerAllPagesLower => 'all pages';

  @override
  String get viewerCopied => 'Copied';

  @override
  String get viewerCopyValue => 'Copy value';

  @override
  String get viewerToggleFullscreen => 'Toggle fullscreen';

  @override
  String get viewerInvert => 'Invert';

  @override
  String get viewerText => 'Text';

  @override
  String get viewerSyntax => 'Syntax';

  @override
  String get viewerFont => 'Font';

  @override
  String get viewerFontStyle => 'Font Style';

  @override
  String get viewerMonospaceCourier => 'Monospace (Courier)';

  @override
  String get viewerSystemUbuntu => 'System (Ubuntu)';

  @override
  String get viewerEdit => 'Edit';

  @override
  String get viewerEditWithEngine => 'Edit with Fadocx Engine';

  @override
  String get viewerEditWithEngineDesc => 'Open this spreadsheet in the Fadocx rendering engine for a faithful visual preview with full formatting, charts, and layout fidelity.';

  @override
  String get viewerEditWithEngineNote => 'Note: Interactive editing is coming in a future update.';

  @override
  String get viewerNotNow => 'Not Now';

  @override
  String get viewerGotIt => 'Got It';

  @override
  String get viewerErrorLoadingDocument => 'Error loading document';

  @override
  String get viewerGoBack => 'Go Back';

  @override
  String viewerReadingTimeMinutes(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutes read',
      one: '1 minute read',
    );
    return '$_temp0';
  }

  @override
  String viewerReadingTimeHoursMinutes(num hours, num minutes) {
    return '${hours}h ${minutes}m read';
  }

  @override
  String get scannerTitle => 'Dokumentscanner';

  @override
  String get scannerCapture => 'Aufnehmen';

  @override
  String get scannerProcessing => 'Verarbeitung';

  @override
  String get scannerResults => 'Ergebnisse';

  @override
  String get scannerInitializingCamera => 'Kamera wird initialisiert...';

  @override
  String get scannerDocumentDetected => 'Dokument erkannt – bitte ruhig halten';

  @override
  String get scannerKeepDocumentFlat => 'Halte das Dokument gerade und flach für beste Ergebnisse';

  @override
  String get scannerUpload => 'Hochladen';

  @override
  String scannerFailedOpenImage(String error) {
    return 'Bild konnte nicht geöffnet werden: $error';
  }

  @override
  String get scannerFlash => 'Blitz';

  @override
  String scannerFailedTorch(String error) {
    return 'Blitz konnte nicht umgeschaltet werden: $error';
  }

  @override
  String get scannerStartingCamera => 'Kamera wird gestartet...';

  @override
  String get scannerCameraUnavailable => 'Kamera nicht verfügbar';

  @override
  String get scannerCameraUnavailableDesc => 'Kamera konnte nicht initialisiert werden';

  @override
  String get scannerAnalysisComplete => 'Analyse abgeschlossen';

  @override
  String get scannerAnalyzing => 'Dokument wird analysiert...';

  @override
  String get scannerEnhancing => 'Bildqualität wird verbessert...';

  @override
  String get scannerExtractingText => 'Textdaten werden extrahiert...';

  @override
  String get scannerNoScansYet => 'Noch keine Scans';

  @override
  String get scannerNoScansDesc => 'Erfasse ein Dokument, um hier extrahierten Text zu sehen';

  @override
  String get scannerExtractedText => 'Extrahierter Text';

  @override
  String get scannerNoTextExtracted => '(Kein Text extrahiert)';

  @override
  String get scannerDetectedLines => 'Erkannte Zeilen';

  @override
  String get scannerTextCopied => 'Text in Zwischenablage kopiert';

  @override
  String get scannerCopyAll => 'Alles kopieren';

  @override
  String get scannerNewScan => 'Neuer Scan';

  @override
  String get linkTileCopy => 'Kopieren';

  @override
  String get linkTileCopiedToClipboard => 'Copied to clipboard';

  @override
  String get linkTileSendEmail => 'E-Mail senden';

  @override
  String get linkTileOpenInBrowser => 'Im Browser öffnen';

  @override
  String linkTileCouldNotOpen(String value) {
    return 'Could not open $value';
  }

  @override
  String get librarySortBy => 'Sort by';

  @override
  String get librarySortLatest => 'Latest';

  @override
  String get librarySortOldest => 'Oldest';

  @override
  String get librarySortLargest => 'Largest';

  @override
  String get librarySortSmallest => 'Smallest';

  @override
  String get homeDeleteFile => 'Delete file?';

  @override
  String homeDeleteFileConfirm(String name) {
    return 'Move \"$name\" to trash? You can restore it later.';
  }

  @override
  String homeCopiedCharactersToClipboard(num count) {
    return 'Copied $count characters to clipboard';
  }

  @override
  String homeFileInTrashDetail(String date) {
    return 'Im Papierkorb: ja (gelöscht am: $date)';
  }

  @override
  String get homeUnknown => 'unknown';

  @override
  String routeNotFound(String path) {
    return 'Route nicht gefunden: $path';
  }

  @override
  String get routeGoHome => 'Zur Startseite';

  @override
  String get routeInvalidDocumentPath => 'Ungültiger Dokumentpfad';

  @override
  String get pdfCopyTextTitle => 'PDF-Text kopieren';

  @override
  String get pdfExtractingText => 'Text wird extrahiert...';

  @override
  String pdfExtractingTextProgress(num current, num total) {
    return 'Text wird extrahiert... ($current/$total Seiten)';
  }

  @override
  String get pdfErrorExtractingText => 'Fehler beim Extrahieren des Textes';

  @override
  String pdfWordCount(num count) {
    return 'Wortanzahl: $count';
  }

  @override
  String get pdfNoTextFound => 'Kein Text im PDF gefunden';

  @override
  String get pdfFullTextCopied => 'Vollständiger PDF-Text in die Zwischenablage kopiert';

  @override
  String get pdfPasswordRequired => 'PDF-Passwort erforderlich';

  @override
  String get pdfPasswordDesc => 'Dieses PDF ist passwortgeschützt. Geben Sie das Passwort ein, um es zu entsperren.';

  @override
  String get pdfPasswordLabel => 'Passwort';

  @override
  String get pdfUnlock => 'Entsperren';

  @override
  String get pdfSearchHint => 'PDF durchsuchen...';

  @override
  String get pdfTextCannotBeExtracted => 'Text kann von dieser Seite nicht extrahiert werden';

  @override
  String get pdfLoadingPageTexts => 'Seitentexte werden geladen...';

  @override
  String pdfPageCopied(num page) {
    return 'Text von Seite $page in die Zwischenablage kopiert';
  }

  @override
  String get viewerTooltipSidebar => 'Seitenleiste';

  @override
  String get viewerTooltipFirst => 'Erste';

  @override
  String get viewerTooltipLast => 'Letzte';

  @override
  String get viewerTooltipCopyPageText => 'Seitentext kopieren';

  @override
  String get textDocSearchHint => 'Text suchen...';

  @override
  String get textDocSearchPrevResult => 'Vorheriges Ergebnis';

  @override
  String get textDocSearchNextResult => 'Nächstes Ergebnis';

  @override
  String get imageFailedToLoad => 'Bild konnte nicht geladen werden';

  @override
  String get mediaLoading => 'Medien werden geladen...';

  @override
  String get mediaFailedToPlay => 'Medien konnten nicht abgespielt werden';

  @override
  String get mediaPlay => 'Abspielen';

  @override
  String get audioPlaybackNote => 'Für die Audiowiedergabe ist eine zusätzliche Bibliothek erforderlich.';

  @override
  String sheetNoData(String sheetName) {
    return 'Keine Daten in $sheetName';
  }

  @override
  String documentNoSheets(String format) {
    return 'Keine Tabellen in $format gefunden';
  }

  @override
  String get viewerPlaybackSpeed => 'Wiedergabegeschwindigkeit';

  @override
  String urlCopiedToClipboard(String url) {
    return 'URL in die Zwischenablage kopiert: $url';
  }

  @override
  String get lokitPreparingDoc => 'Ihr Dokument wird vorbereitet...';

  @override
  String get lokitWarmingUp => 'Fadocx-Engine wird gestartet...';

  @override
  String get lokitAlmostThere => 'Fast fertig';

  @override
  String get lokitJustAMoment => 'Einen Moment';

  @override
  String get lokitFailedToRender => 'Dokument konnte nicht gerendert werden';
}
