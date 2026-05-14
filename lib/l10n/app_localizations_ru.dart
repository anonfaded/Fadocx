// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appName => 'Fadocx';

  @override
  String get appDescription => 'Document Viewer';

  @override
  String get homeTitle => 'Fadocx';

  @override
  String get recentFiles => 'Недавние файлы';

  @override
  String get noRecentFiles => 'Нет недавних файлов. Откройте документ, чтобы начать.';

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
  String get ok => 'ОК';

  @override
  String get cancel => 'Отмена';

  @override
  String get delete => 'Удалить';

  @override
  String get clear => 'Очистить';

  @override
  String get close => 'Закрыть';

  @override
  String get copy => 'Копировать';

  @override
  String get retry => 'Повторить';

  @override
  String get rename => 'Переименовать';

  @override
  String get restore => 'Восстановить';

  @override
  String get export => 'Экспорт';

  @override
  String get duplicate => 'Дублировать';

  @override
  String get imports => 'Импорт';

  @override
  String get next => 'Далее';

  @override
  String get previous => 'Назад';

  @override
  String get back => 'Назад';

  @override
  String get settings => 'Настройки';

  @override
  String get about => 'О приложении';

  @override
  String get error => 'Ошибка';

  @override
  String get warning => 'Предупреждение';

  @override
  String get success => 'Успешно';

  @override
  String get unsupportedFileType => 'Формат файла не поддерживается';

  @override
  String get fileNotFound => 'Файл не найден';

  @override
  String get permissionDenied => 'Доступ запрещён';

  @override
  String get corruptedFile => 'File appears to be corrupted';

  @override
  String get loadingDocument => 'Загрузка документа...';

  @override
  String get settingsTitle => 'Настройки';

  @override
  String get theme => 'Тема';

  @override
  String get themeDark => 'Тёмная';

  @override
  String get themeLight => 'Светлая';

  @override
  String get themeSystem => 'Системная';

  @override
  String get language => 'Язык';

  @override
  String get languageEnglish => 'Английский';

  @override
  String get languageUrdu => 'اردو';

  @override
  String get languageRussian => 'Русский';

  @override
  String get languageChinese => 'Китайский';

  @override
  String get languageJapanese => 'Японский';

  @override
  String get languageFrench => 'Французский';

  @override
  String get languageArabic => 'Арабский';

  @override
  String get languageSpanish => 'Испанский';

  @override
  String get languageGerman => 'Немецкий';

  @override
  String get languagePortuguese => 'Португальский';

  @override
  String get languageHindi => 'Хинди';

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
  String get copiedToClipboard => 'Copied to clipboard';

  @override
  String get navHome => 'Главная';

  @override
  String get navLibrary => 'Библиотека';

  @override
  String get navSettings => 'Настройки';

  @override
  String get navRecents => 'Недавние';

  @override
  String get categoryAll => 'Все';

  @override
  String get categoryPdfs => 'PDF';

  @override
  String get categoryDocs => 'Документы';

  @override
  String get categorySheets => 'Таблицы';

  @override
  String get categorySlides => 'Слайды';

  @override
  String get categoryCode => 'Код';

  @override
  String get categoryScans => 'Сканы';

  @override
  String get categoryOther => 'Прочее';

  @override
  String get categoryPresentations => 'Презентации';

  @override
  String get supportDevelopment => 'Support Development';

  @override
  String get visitPatreon => 'Visit Patreon';

  @override
  String get copyLink => 'Copy Link';

  @override
  String get becomeAPatron => 'Become a Patron';

  @override
  String get patreonDescription => 'Your support keeps Fadocx and FadCam growing. Patreon subscribers unlock exclusive benefits including premium features and early access across all FadSec Lab apps.\n\nFor more info, visit Patreon from the link below and check the available tiers with their benefits.';

  @override
  String get discordTitle => 'Join our Discord';

  @override
  String get openInBrowser => 'Открыть в браузере';

  @override
  String get comingSoon => 'Скоро';

  @override
  String get newBadge => 'NEW';

  @override
  String get timeAgoJustNow => 'Just now';

  @override
  String timeAgoMinute(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutes ago',
      one: '1 minute ago',
    );
    return '$_temp0';
  }

  @override
  String timeAgoHour(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hours ago',
      one: '1 hour ago',
    );
    return '$_temp0';
  }

  @override
  String timeAgoDay(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days ago',
      one: '1 day ago',
    );
    return '$_temp0';
  }

  @override
  String timeAgoWeek(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count weeks ago',
      one: '1 week ago',
    );
    return '$_temp0';
  }

  @override
  String timeAgoMonth(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count months ago',
      one: '1 month ago',
    );
    return '$_temp0';
  }

  @override
  String timeAgoYear(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count years ago',
      one: '1 year ago',
    );
    return '$_temp0';
  }

  @override
  String get monthJan => 'Jan';

  @override
  String get monthFeb => 'Feb';

  @override
  String get monthMar => 'Mar';

  @override
  String get monthApr => 'Apr';

  @override
  String get monthMay => 'May';

  @override
  String get monthJun => 'Jun';

  @override
  String get monthJul => 'Jul';

  @override
  String get monthAug => 'Aug';

  @override
  String get monthSep => 'Sep';

  @override
  String get monthOct => 'Oct';

  @override
  String get monthNov => 'Nov';

  @override
  String get monthDec => 'Dec';

  @override
  String get homeWelcomeTitle => 'Добро пожаловать в Fadocx';

  @override
  String get homeWelcomeSubtitle => 'Изучите примеры файлов или импортируйте свои документы';

  @override
  String get homeExploreSamples => 'Просмотреть примеры файлов';

  @override
  String get homeDocumentManagement => 'Document Management';

  @override
  String get homeSeeAll => 'Смотреть все';

  @override
  String get homeNoRecentFiles => 'Нет недавних файлов';

  @override
  String get homeScanDocument => 'Сканировать документ';

  @override
  String get homeScanDocumentDesc => 'Извлечь текст из документов с помощью OCR';

  @override
  String get homeImportDocument => 'Импортировать документ';

  @override
  String get homeImportDocumentDesc => 'Просмотреть и импортировать файлы с устройства';

  @override
  String get onboardingSkip => 'Пропустить';

  @override
  String get onboardingNext => 'Далее';

  @override
  String get onboardingGetStarted => 'Начать';

  @override
  String get onboardingSlide1Title => 'Добро пожаловать в Fadocx';

  @override
  String get onboardingSlide1Tagline => 'Ваш универсальный приватный помощник для документов';

  @override
  String get onboardingSlide1Bullet1 => 'Открывайте любые форматы — PDF, Office, изображения и не только';

  @override
  String get onboardingSlide1Bullet2 => 'Приватное хранилище, скрытое от галереи и файлового менеджера';

  @override
  String get onboardingSlide1Bullet3 => 'Бесплатно, открытый код — без регистрации и аккаунта';

  @override
  String get onboardingSlide2Title => 'Встроенные инструменты';

  @override
  String get onboardingSlide2Bullet1 => 'Сканируйте документы камерой — текст извлекается мгновенно';

  @override
  String get onboardingSlide2Bullet2 => 'Воспроизводите аудио и видео прямо в приложении, без лишних программ';

  @override
  String get onboardingSlide2Bullet3 => 'Всё автоматически сортируется по категориям при импорте';

  @override
  String get onboardingSlide2Bullet4 => 'Безопасное удаление — восстановите всё из корзины в любой момент';

  @override
  String get onboardingSlide3Title => 'Приватность по замыслу';

  @override
  String get onboardingSlide3Bullet1 => 'Ничто никогда не покидает ваше устройство — без облака и серверов';

  @override
  String get onboardingSlide3Bullet2 => 'Без слежки, без рекламы, без аналитики. Никогда.';

  @override
  String get onboardingSlide3Bullet3 => 'Открытый код — каждая строка кода публична';

  @override
  String get homeStatDocuments => 'Documents';

  @override
  String get homeStatStorage => 'Storage';

  @override
  String get homeStatTimeRead => 'Time Read';

  @override
  String get homeStatLastOpened => 'Last Opened: ';

  @override
  String get homePressBackExit => 'Нажмите ещё раз для выхода';

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
  String get homeFileInfo => 'File info';

  @override
  String get homeFileName => 'Name';

  @override
  String get homeFileType => 'Type';

  @override
  String get homeFileSize => 'Size';

  @override
  String get homeFileLocation => 'Location';

  @override
  String get homeFileDateOpened => 'Date opened';

  @override
  String get homeFileLastModified => 'Last modified';

  @override
  String get homeFileInTrash => 'In trash';

  @override
  String get homeFileInfoCopied => 'File info copied';

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
  String get libraryTitle => 'Библиотека';

  @override
  String get librarySearchHint => 'Поиск в библиотеке...';

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
  String get libraryNoDocuments => 'Нет документов';

  @override
  String get libraryAdjustSearch => 'Попробуйте изменить поиск или фильтры';

  @override
  String get libraryDocumentsAppearHere => 'Ваши документы появятся здесь';

  @override
  String get browseTitle => 'Import Documents';

  @override
  String get browseBack => 'Back';

  @override
  String get browseSearchHint => 'Search documents...';

  @override
  String get browseCancel => 'Cancel';

  @override
  String get browseBrowseFiles => 'Browse';

  @override
  String get browseBrowseFilesDesc => 'Import additional files manually';

  @override
  String get browseScanFailed => 'Scan failed';

  @override
  String get browseUnknownError => 'Unknown error occurred';

  @override
  String get browseRetryScan => 'Retry Scan';

  @override
  String get browseImportManually => 'Import Files Manually';

  @override
  String get browseNoDocumentsFound => 'No documents found';

  @override
  String get browseNoDocumentsMatch => 'No documents match your search';

  @override
  String get browseAdjustSearch => 'Try adjusting your search or filters';

  @override
  String get browseClearSelection => 'Clear';

  @override
  String get browseImport => 'Import';

  @override
  String get browseAllFilesAccessRequired => 'All files access permission is required to browse documents on your device';

  @override
  String get browsePermissionRequired => 'Permission Required';

  @override
  String get browseAllFilesAccessDenied => 'All files access permission is required to browse and read documents on your device. Please grant this permission to continue.';

  @override
  String get browseOpenSettings => 'Open Settings';

  @override
  String get browseAccessStillDisabled => 'All files access is still disabled. Please enable it in Settings to continue.';

  @override
  String get browseNoDirectories => 'No document directories found on device';

  @override
  String browseErrorPrefix(String error) {
    return 'Error: $error';
  }

  @override
  String get browseSortBy => 'Sort by';

  @override
  String browseImportedFiles(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Imported $count files',
      one: 'Imported 1 file',
    );
    return '$_temp0';
  }

  @override
  String get trashTitle => 'Корзина';

  @override
  String get trashEmpty => 'Корзина пуста';

  @override
  String get trashEmptySubtitle => 'Удалённые файлы появятся здесь';

  @override
  String get trashErrorLoading => 'Error loading trash';

  @override
  String trashFilesSelected(num count) {
    return '$count selected';
  }

  @override
  String get trashFilesLabel => 'files';

  @override
  String get trashFileRestored => 'File restored successfully';

  @override
  String get trashDeletePermanently => 'Удалить навсегда';

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
  String get whatsNewTitle => 'Что нового';

  @override
  String get whatsNewWhatsIncluded => 'What\'s Included';

  @override
  String get whatsNewPlanned => 'Planned';

  @override
  String get whatsNewReleasedToday => 'Released today';

  @override
  String get whatsNewReleasedYesterday => 'Released yesterday';

  @override
  String whatsNewReleasedDate(String date) {
    return 'Released $date';
  }

  @override
  String get whatsNewDocAndSheets => 'Documents & Spreadsheets';

  @override
  String get whatsNewDocAndSheetsDesc => 'View PDFs, Word documents, Excel spreadsheets, and more — all locally on your device.';

  @override
  String get whatsNewOcrAi => 'Intelligent OCR & On-Device AI';

  @override
  String get whatsNewOcrAiDesc => 'Extract text from images using advanced on-device OCR. Multiple languages supported.';

  @override
  String get whatsNewSyntaxHighlighting => 'Syntax Highlighting';

  @override
  String get whatsNewSyntaxHighlightingDesc => 'Beautiful code highlighting for 50+ programming languages.';

  @override
  String get whatsNewReadingStats => 'Reading Stats Dashboard';

  @override
  String get whatsNewReadingStatsDesc => 'Track your reading progress with detailed statistics and time tracking.';

  @override
  String get whatsNewLibraryCategories => 'Library with Category Folders';

  @override
  String get whatsNewLibraryCategoriesDesc => 'Organize your documents by type with smart automatic categorization.';

  @override
  String get whatsNewFileManagement => 'File Management';

  @override
  String get whatsNewFileManagementDesc => 'Rename, duplicate, export, and delete your documents with ease.';

  @override
  String get whatsNewThemes => 'Light & Dark Themes';

  @override
  String get whatsNewThemesDesc => 'Choose the look that suits you — dark mode for night, light mode for day.';

  @override
  String get whatsNewFadDrive => 'FadDrive';

  @override
  String get whatsNewFadDriveDesc => 'Cloud sync for your documents — access them anywhere, anytime.';

  @override
  String get whatsNewEditing => 'Document Editing';

  @override
  String get whatsNewEditingDesc => 'Make quick edits to your documents right within Fadocx.';

  @override
  String get whatsNewBookmarks => 'Bookmarks & Annotations';

  @override
  String get whatsNewBookmarksDesc => 'Mark important pages and add annotations for later reference.';

  @override
  String get whatsNewConversion => 'Document Conversion';

  @override
  String get whatsNewConversionDesc => 'Convert between formats like PDF, DOCX, and more.';

  @override
  String get whatsNewAmoled => 'AMOLED Black Theme';

  @override
  String get whatsNewAmoledDesc => 'Pure black theme for AMOLED displays — save battery on dark mode.';

  @override
  String get whatsNewMoreOcr => 'More OCR Languages';

  @override
  String get whatsNewMoreOcrDesc => 'Support for additional OCR languages and improved recognition accuracy.';

  @override
  String get whatsNewOfflineFirst => 'An offline-first document viewer built for privacy. No accounts, no tracking, no internet required.';

  @override
  String get whatsNewThankYou => 'Thank You for Using Fadocx';

  @override
  String get whatsNewThankYouDesc => 'If you find value in Fadocx, consider supporting its development. Your contribution helps us keep building privacy-first tools.';

  @override
  String get drawerWhatNew => 'What\'s New';

  @override
  String get drawerRecentFiles => 'Recent Files';

  @override
  String get drawerVisible => 'Visible';

  @override
  String get drawerHidden => 'Hidden';

  @override
  String get drawerUnlockBenefits => 'Unlock exclusive benefits';

  @override
  String get fileActionRename => 'Rename';

  @override
  String get fileActionRenameDesc => 'Change file name';

  @override
  String get fileActionDuplicate => 'Duplicate';

  @override
  String get fileActionDuplicateDesc => 'Create a copy';

  @override
  String get fileActionExport => 'Export / Save As';

  @override
  String get fileActionExportDesc => 'Save a copy to Downloads';

  @override
  String get fileActionCopyText => 'Copy Text';

  @override
  String get fileActionCopyTextDesc => 'Copy extracted text to clipboard';

  @override
  String get fileActionConvert => 'Convert';

  @override
  String get fileActionConvertDesc => 'Convert to another format';

  @override
  String get fileActionUpload => 'Upload to FadDrive';

  @override
  String get fileActionUploadDesc => 'Sync to cloud storage';

  @override
  String get fileActionFileInfo => 'File info';

  @override
  String get fileActionSubtitle => 'File actions and management';

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
  String get settingsAppearance => 'Внешний вид';

  @override
  String get settingsStorage => 'Хранилище';

  @override
  String get settingsDocumentsSize => 'Documents Size';

  @override
  String get settingsCalculating => 'Calculating...';

  @override
  String get settingsCustomStorage => 'Custom Storage';

  @override
  String get settingsUnknown => 'Unknown';

  @override
  String get settingsStorageDetails => 'Storage';

  @override
  String get settingsStoragePdfs => 'PDFs';

  @override
  String get settingsStorageDocs => 'Docs';

  @override
  String get settingsStorageSheets => 'Sheets';

  @override
  String get settingsStoragePresentations => 'Presentations';

  @override
  String get settingsStorageCode => 'Code';

  @override
  String get settingsStorageScans => 'Scans';

  @override
  String get settingsStorageImages => 'Images';

  @override
  String get settingsStorageOther => 'Other';

  @override
  String get settingsStorageInfo => 'Documents are stored in a private folder on your device and cannot be accessed by other apps';

  @override
  String get settingsStoragePrivateFolderInfo => 'Documents are stored in a private folder, hidden from other apps and file managers. Only Fadocx can access them.';

  @override
  String get settingsStorageDeleteInfo => 'Delete documents from Danger Zone in Settings';

  @override
  String get settingsStorageEmpty => 'No documents';

  @override
  String get settingsStorageFailedLoad => 'Failed to load storage data';

  @override
  String get settingsUpdates => 'Обновления';

  @override
  String get settingsAutoUpdateCheck => 'Автопроверка обновлений';

  @override
  String get settingsReplayOnboarding => 'Повторить знакомство';

  @override
  String get settingsReplayOnboardingDesc => 'Показывать вводные слайды при следующем запуске';

  @override
  String get settingsEnabled => 'Включено';

  @override
  String get settingsDisabled => 'Выключено';

  @override
  String get settingsAppLock => 'App Lock';

  @override
  String get settingsAbout => 'О приложении';

  @override
  String get settingsVersion => 'Версия';

  @override
  String get settingsSourceCode => 'Исходный код';

  @override
  String get settingsContact => 'Связаться';

  @override
  String get settingsJoinCommunity => 'Join Community';

  @override
  String get settingsPrivacyPolicy => 'Политика конфиденциальности';

  @override
  String get settingsMoreFromFadsec => 'More from FadSec Lab';

  @override
  String get settingsFadocxDesc => 'Your private document viewer';

  @override
  String get settingsDangerZone => 'Зона опасности';

  @override
  String get settingsTrash => 'Корзина';

  @override
  String get settingsTrashDesc => 'Просмотр удалённых файлов';

  @override
  String get settingsResetSettings => 'Сбросить настройки';

  @override
  String get settingsResetSettingsDesc => 'Восстановить все настройки по умолчанию';

  @override
  String get settingsResetDone => 'Настройки сброшены';

  @override
  String get settingsRetry => 'Retry';

  @override
  String get settingsChooseTheme => 'Выберите тему';

  @override
  String get settingsSelectLanguage => 'Выберите язык';

  @override
  String get settingsCheckForUpdates => 'Проверить обновления';

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
  String get settingsCopiedInfo => 'Copied to clipboard';

  @override
  String get settingsCopyInfo => 'Copy Info';

  @override
  String get settingsShareApp => 'Share with Friends';

  @override
  String get settingsShareVia => 'Share via...';

  @override
  String get settingsShareWhatsApp => 'WhatsApp';

  @override
  String get settingsWhatsAppNotInstalled => 'WhatsApp is not installed on this device';

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
  String get settingsSecurity => 'Security';

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
  String get confirm => 'Подтвердить';

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
  String get settingsFadcamDesc => 'Privacy-focused Android multimedia suite: background video recording, dashcam, screen recorder, live streaming & remote control — ad-free & open-source.';

  @override
  String get settingsQuranCliDesc => 'Your Terminal Companion for the Holy Quran: Read, Listen & Generate Subtitles for Video Editing!';

  @override
  String get settingsFadcryptDesc => 'Advanced and elegant cross-platform app locker — files, folders, and applications all protected with military-grade AES-256-GCM encryption. Open-source, completely free, no telemetry!';

  @override
  String get settingsFadcatDesc => 'Lightweight, feature-rich, cross-platform Android logcat replacement — no Android Studio bloat. Bundles ADB for supported architectures, runs in GUI, CLI, or MCP server mode.';

  @override
  String get settingsMacosComingSoon => 'macOS coming soon';

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
  String get scannerTitle => 'Сканер документов';

  @override
  String get scannerCapture => 'Снять';

  @override
  String get scannerProcessing => 'Обработка';

  @override
  String get scannerResults => 'Результаты';

  @override
  String get scannerInitializingCamera => 'Initializing Camera...';

  @override
  String get scannerDocumentDetected => 'Document detected — hold steady';

  @override
  String get scannerKeepDocumentFlat => 'Keep document upright & flat for best results';

  @override
  String get scannerUpload => 'Upload';

  @override
  String scannerFailedOpenImage(String error) {
    return 'Failed to open image: $error';
  }

  @override
  String get scannerFlash => 'Flash';

  @override
  String scannerFailedTorch(String error) {
    return 'Failed to toggle torch: $error';
  }

  @override
  String get scannerStartingCamera => 'Starting Camera...';

  @override
  String get scannerCameraUnavailable => 'Camera Unavailable';

  @override
  String get scannerCameraUnavailableDesc => 'Unable to initialize camera';

  @override
  String get scannerAnalysisComplete => 'Analysis Complete';

  @override
  String get scannerAnalyzing => 'Analyzing Document...';

  @override
  String get scannerEnhancing => 'Enhancing image quality...';

  @override
  String get scannerExtractingText => 'Extracting text data...';

  @override
  String get scannerNoScansYet => 'No Scans Yet';

  @override
  String get scannerNoScansDesc => 'Capture a document to see extracted text here';

  @override
  String get scannerExtractedText => 'Extracted Text';

  @override
  String get scannerNoTextExtracted => '(No text extracted)';

  @override
  String get scannerDetectedLines => 'Detected Lines';

  @override
  String get scannerTextCopied => 'Text copied to clipboard';

  @override
  String get scannerCopyAll => 'Копировать всё';

  @override
  String get scannerNewScan => 'Новый скан';

  @override
  String get linkTileCopy => 'Копировать';

  @override
  String get linkTileCopiedToClipboard => 'Copied to clipboard';

  @override
  String get linkTileSendEmail => 'Отправить письмо';

  @override
  String get linkTileOpenInBrowser => 'Открыть в браузере';

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
    return 'In trash: yes (deleted at: $date)';
  }

  @override
  String get homeUnknown => 'unknown';

  @override
  String routeNotFound(String path) {
    return 'Маршрут не найден: $path';
  }

  @override
  String get routeGoHome => 'На главную';

  @override
  String get routeInvalidDocumentPath => 'Неверный путь к документу';

  @override
  String get pdfCopyTextTitle => 'Копировать текст PDF';

  @override
  String get pdfExtractingText => 'Извлечение текста...';

  @override
  String pdfExtractingTextProgress(num current, num total) {
    return 'Извлечение текста... ($current/$total страниц)';
  }

  @override
  String get pdfErrorExtractingText => 'Ошибка при извлечении текста';

  @override
  String pdfWordCount(num count) {
    return 'Количество слов: $count';
  }

  @override
  String get pdfNoTextFound => 'Текст в PDF не найден';

  @override
  String get pdfFullTextCopied => 'Полный текст PDF скопирован в буфер обмена';

  @override
  String get pdfPasswordRequired => 'Требуется пароль PDF';

  @override
  String get pdfPasswordDesc => 'Этот PDF защищён паролем. Введите пароль для разблокировки.';

  @override
  String get pdfPasswordLabel => 'Пароль';

  @override
  String get pdfUnlock => 'Разблокировать';

  @override
  String get pdfSearchHint => 'Поиск в PDF...';

  @override
  String get pdfTextCannotBeExtracted => 'Текст не может быть извлечён с этой страницы';

  @override
  String get pdfLoadingPageTexts => 'Загрузка текстов страниц...';

  @override
  String pdfPageCopied(num page) {
    return 'Текст страницы $page скопирован в буфер обмена';
  }

  @override
  String get viewerTooltipSidebar => 'Боковая панель';

  @override
  String get viewerTooltipFirst => 'Первая';

  @override
  String get viewerTooltipLast => 'Последняя';

  @override
  String get viewerTooltipCopyPageText => 'Копировать текст страницы';

  @override
  String get textDocSearchHint => 'Поиск текста...';

  @override
  String get textDocSearchPrevResult => 'Предыдущий результат';

  @override
  String get textDocSearchNextResult => 'Следующий результат';

  @override
  String get imageFailedToLoad => 'Не удалось загрузить изображение';

  @override
  String get mediaLoading => 'Загрузка медиа...';

  @override
  String get mediaFailedToPlay => 'Не удалось воспроизвести медиа';

  @override
  String get mediaPlay => 'Воспроизвести';

  @override
  String get audioPlaybackNote => 'Для воспроизведения аудио требуется дополнительная библиотека.';

  @override
  String sheetNoData(String sheetName) {
    return 'Нет данных в $sheetName';
  }

  @override
  String documentNoSheets(String format) {
    return 'В $format не найдено листов';
  }

  @override
  String get viewerPlaybackSpeed => 'Скорость воспроизведения';

  @override
  String urlCopiedToClipboard(String url) {
    return 'URL скопирован в буфер обмена: $url';
  }

  @override
  String get lokitPreparingDoc => 'Подготовка вашего документа...';

  @override
  String get lokitWarmingUp => 'Запуск движка Fadocx...';

  @override
  String get lokitAlmostThere => 'Почти готово';

  @override
  String get lokitJustAMoment => 'Подождите секунду';

  @override
  String get lokitFailedToRender => 'Не удалось отобразить документ';
}
