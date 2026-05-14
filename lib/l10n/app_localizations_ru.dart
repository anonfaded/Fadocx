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
  String get copiedToClipboard => 'Скопировано в буфер обмена';

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
  String get supportDevelopment => 'Поддержать разработку';

  @override
  String get visitPatreon => 'Открыть Patreon';

  @override
  String get copyLink => 'Копировать ссылку';

  @override
  String get becomeAPatron => 'Become a Patron';

  @override
  String get patreonDescription => 'Ваша поддержка помогает Fadocx и FadCam развиваться. Подписчики Patreon получают эксклюзивные преимущества, включая премиальные функции и ранний доступ во всех приложениях FadSec Lab.\n\nЧтобы узнать больше, откройте Patreon по ссылке ниже и посмотрите доступные уровни с их преимуществами.';

  @override
  String get discordTitle => 'Присоединяйтесь к нашему Discord';

  @override
  String get openInBrowser => 'Открыть в браузере';

  @override
  String get comingSoon => 'Скоро';

  @override
  String get newBadge => 'NEW';

  @override
  String get timeAgoJustNow => 'Только что';

  @override
  String timeAgoMinute(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count минут назад',
      one: '1 минуту назад',
    );
    return '$_temp0';
  }

  @override
  String timeAgoHour(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count часов назад',
      one: '1 час назад',
    );
    return '$_temp0';
  }

  @override
  String timeAgoDay(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count дней назад',
      one: '1 день назад',
    );
    return '$_temp0';
  }

  @override
  String timeAgoWeek(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count недель назад',
      one: '1 неделю назад',
    );
    return '$_temp0';
  }

  @override
  String timeAgoMonth(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count месяцев назад',
      one: '1 месяц назад',
    );
    return '$_temp0';
  }

  @override
  String timeAgoYear(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count лет назад',
      one: '1 год назад',
    );
    return '$_temp0';
  }

  @override
  String get monthJan => 'янв';

  @override
  String get monthFeb => 'фев';

  @override
  String get monthMar => 'мар';

  @override
  String get monthApr => 'апр';

  @override
  String get monthMay => 'май';

  @override
  String get monthJun => 'июн';

  @override
  String get monthJul => 'июл';

  @override
  String get monthAug => 'авг';

  @override
  String get monthSep => 'сен';

  @override
  String get monthOct => 'окт';

  @override
  String get monthNov => 'ноя';

  @override
  String get monthDec => 'дек';

  @override
  String get homeWelcomeTitle => 'Добро пожаловать в Fadocx';

  @override
  String get homeWelcomeSubtitle => 'Изучите примеры файлов или импортируйте свои документы';

  @override
  String get homeExploreSamples => 'Просмотреть примеры файлов';

  @override
  String get homeDocumentManagement => 'Управление документами';

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
  String get homeStatDocuments => 'Документы';

  @override
  String get homeStatStorage => 'Хранилище';

  @override
  String get homeStatTimeRead => 'Время чтения';

  @override
  String get homeStatLastOpened => 'Открыто в последний раз: ';

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
  String get homeFileInfo => 'Информация о файле';

  @override
  String get homeFileName => 'Имя';

  @override
  String get homeFileType => 'Тип';

  @override
  String get homeFileSize => 'Размер';

  @override
  String get homeFileLocation => 'Расположение';

  @override
  String get homeFileDateOpened => 'Дата открытия';

  @override
  String get homeFileLastModified => 'Последнее изменение';

  @override
  String get homeFileInTrash => 'В корзине';

  @override
  String get homeFileInfoCopied => 'Информация о файле скопирована';

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
  String get browseTitle => 'Импорт документов';

  @override
  String get browseBack => 'Назад';

  @override
  String get browseSearchHint => 'Поиск документов...';

  @override
  String get browseCancel => 'Отмена';

  @override
  String get browseBrowseFiles => 'Обзор';

  @override
  String get browseBrowseFilesDesc => 'Импортировать дополнительные файлы вручную';

  @override
  String get browseScanFailed => 'Сканирование не удалось';

  @override
  String get browseUnknownError => 'Произошла неизвестная ошибка';

  @override
  String get browseRetryScan => 'Повторить сканирование';

  @override
  String get browseImportManually => 'Импортировать файлы вручную';

  @override
  String get browseNoDocumentsFound => 'Документы не найдены';

  @override
  String get browseNoDocumentsMatch => 'Нет документов, соответствующих вашему запросу';

  @override
  String get browseAdjustSearch => 'Попробуйте изменить поиск или фильтры';

  @override
  String get browseClearSelection => 'Очистить';

  @override
  String get browseImport => 'Импорт';

  @override
  String get browseAllFilesAccessRequired => 'Для просмотра документов на устройстве требуется разрешение на доступ ко всем файлам';

  @override
  String get browsePermissionRequired => 'Требуется разрешение';

  @override
  String get browseAllFilesAccessDenied => 'Для просмотра и чтения документов на устройстве требуется разрешение на доступ ко всем файлам. Пожалуйста, предоставьте его, чтобы продолжить.';

  @override
  String get browseOpenSettings => 'Открыть настройки';

  @override
  String get browseAccessStillDisabled => 'Доступ ко всем файлам всё ещё отключён. Включите его в настройках, чтобы продолжить.';

  @override
  String get browseNoDirectories => 'На устройстве не найдены каталоги с документами';

  @override
  String browseErrorPrefix(String error) {
    return 'Ошибка: $error';
  }

  @override
  String get browseSortBy => 'Сортировать по';

  @override
  String browseImportedFiles(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Импортировано $count файлов',
      one: 'Импортирован 1 файл',
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
  String get trashSelect => 'Выбрать';

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
  String get whatsNewWhatsIncluded => 'Что входит';

  @override
  String get whatsNewPlanned => 'Запланировано';

  @override
  String get whatsNewReleasedToday => 'Выпущено сегодня';

  @override
  String get whatsNewReleasedYesterday => 'Выпущено вчера';

  @override
  String whatsNewReleasedDate(String date) {
    return 'Выпущено $date';
  }

  @override
  String get whatsNewDocAndSheets => 'Документы и таблицы';

  @override
  String get whatsNewDocAndSheetsDesc => 'Просматривайте PDF, документы Word, таблицы Excel и многое другое — всё локально на вашем устройстве.';

  @override
  String get whatsNewOcrAi => 'Интеллектуальный OCR и ИИ на устройстве';

  @override
  String get whatsNewOcrAiDesc => 'Извлекайте текст из изображений с помощью продвинутого OCR на устройстве. Поддерживается несколько языков.';

  @override
  String get whatsNewSyntaxHighlighting => 'Подсветка синтаксиса';

  @override
  String get whatsNewSyntaxHighlightingDesc => 'Красивая подсветка кода для более чем 50 языков программирования.';

  @override
  String get whatsNewReadingStats => 'Панель статистики чтения';

  @override
  String get whatsNewReadingStatsDesc => 'Отслеживайте прогресс чтения с помощью подробной статистики и учёта времени.';

  @override
  String get whatsNewLibraryCategories => 'Библиотека с папками по категориям';

  @override
  String get whatsNewLibraryCategoriesDesc => 'Организуйте документы по типам с помощью умной автоматической категоризации.';

  @override
  String get whatsNewFileManagement => 'Управление файлами';

  @override
  String get whatsNewFileManagementDesc => 'Переименовывайте, дублируйте, экспортируйте и удаляйте документы с лёгкостью.';

  @override
  String get whatsNewThemes => 'Светлая и тёмная темы';

  @override
  String get whatsNewThemesDesc => 'Выберите подходящий вид — тёмный режим ночью, светлый днём.';

  @override
  String get whatsNewFadDrive => 'FadDrive';

  @override
  String get whatsNewFadDriveDesc => 'Облачная синхронизация для ваших документов — доступ откуда угодно и когда угодно.';

  @override
  String get whatsNewEditing => 'Редактирование документов';

  @override
  String get whatsNewEditingDesc => 'Быстро вносите изменения в документы прямо в Fadocx.';

  @override
  String get whatsNewBookmarks => 'Закладки и аннотации';

  @override
  String get whatsNewBookmarksDesc => 'Отмечайте важные страницы и добавляйте заметки для будущих ссылок.';

  @override
  String get whatsNewConversion => 'Конвертация документов';

  @override
  String get whatsNewConversionDesc => 'Преобразование между форматами, такими как PDF, DOCX и другими.';

  @override
  String get whatsNewAmoled => 'Чёрная AMOLED-тема';

  @override
  String get whatsNewAmoledDesc => 'Чисто чёрная тема для AMOLED-экранов — экономит батарею в тёмном режиме.';

  @override
  String get whatsNewMoreOcr => 'Больше языков OCR';

  @override
  String get whatsNewMoreOcrDesc => 'Поддержка дополнительных языков OCR и улучшенная точность распознавания.';

  @override
  String get whatsNewOfflineFirst => 'Просмотрщик документов с приоритетом офлайн и акцентом на приватность. Без аккаунтов, без отслеживания, без обязательного интернета.';

  @override
  String get whatsNewThankYou => 'Спасибо за использование Fadocx';

  @override
  String get whatsNewThankYouDesc => 'Если Fadocx приносит вам пользу, рассмотрите возможность поддержать его развитие. Ваш вклад помогает нам и дальше создавать инструменты с приоритетом приватности.';

  @override
  String get drawerWhatNew => 'Что нового';

  @override
  String get drawerRecentFiles => 'Недавние файлы';

  @override
  String get drawerVisible => 'Видимо';

  @override
  String get drawerHidden => 'Скрыто';

  @override
  String get drawerUnlockBenefits => 'Откройте эксклюзивные преимущества';

  @override
  String get fileActionRename => 'Переименовать';

  @override
  String get fileActionRenameDesc => 'Изменить имя файла';

  @override
  String get fileActionDuplicate => 'Дублировать';

  @override
  String get fileActionDuplicateDesc => 'Создать копию';

  @override
  String get fileActionExport => 'Экспорт / Сохранить как';

  @override
  String get fileActionExportDesc => 'Сохранить копию в Загрузки';

  @override
  String get fileActionCopyText => 'Копировать текст';

  @override
  String get fileActionCopyTextDesc => 'Копировать извлечённый текст в буфер обмена';

  @override
  String get fileActionConvert => 'Преобразовать';

  @override
  String get fileActionConvertDesc => 'Преобразовать в другой формат';

  @override
  String get fileActionUpload => 'Загрузить в FadDrive';

  @override
  String get fileActionUploadDesc => 'Синхронизировать с облачным хранилищем';

  @override
  String get fileActionFileInfo => 'Информация о файле';

  @override
  String get fileActionSubtitle => 'Действия и управление файлом';

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
  String get settingsDocumentsSize => 'Размер документов';

  @override
  String get settingsCalculating => 'Вычисление...';

  @override
  String get settingsCustomStorage => 'Пользовательское хранилище';

  @override
  String get settingsUnknown => 'Unknown';

  @override
  String get settingsStorageDetails => 'Хранилище';

  @override
  String get settingsStoragePdfs => 'PDF';

  @override
  String get settingsStorageDocs => 'Документы';

  @override
  String get settingsStorageSheets => 'Таблицы';

  @override
  String get settingsStoragePresentations => 'Презентации';

  @override
  String get settingsStorageCode => 'Код';

  @override
  String get settingsStorageScans => 'Сканы';

  @override
  String get settingsStorageImages => 'Изображения';

  @override
  String get settingsStorageOther => 'Прочее';

  @override
  String get settingsStorageInfo => 'Документы хранятся в приватной папке на вашем устройстве и недоступны другим приложениям';

  @override
  String get settingsStoragePrivateFolderInfo => 'Документы хранятся в приватной папке, скрытой от других приложений и файловых менеджеров. Доступ к ним есть только у Fadocx.';

  @override
  String get settingsStorageDeleteInfo => 'Удаляйте документы из опасной зоны в настройках';

  @override
  String get settingsStorageEmpty => 'Нет документов';

  @override
  String get settingsStorageFailedLoad => 'Не удалось загрузить данные хранилища';

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
  String get settingsAppLock => 'Блокировка приложения';

  @override
  String get settingsAbout => 'О приложении';

  @override
  String get settingsVersion => 'Версия';

  @override
  String get settingsSourceCode => 'Исходный код';

  @override
  String get settingsContact => 'Связаться';

  @override
  String get settingsJoinCommunity => 'Присоединиться к сообществу';

  @override
  String get settingsPrivacyPolicy => 'Политика конфиденциальности';

  @override
  String get settingsMoreFromFadsec => 'Больше от FadSec Lab';

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
  String get settingsCopiedInfo => 'Скопировано в буфер обмена';

  @override
  String get settingsCopyInfo => 'Копировать информацию';

  @override
  String settingsVersionClipboardInfo(String appName, String version, String buildNumber, String packageName) {
    return '$appName v$version (Build $buildNumber)\nПакет: $packageName';
  }

  @override
  String get settingsShareApp => 'Поделиться с друзьями';

  @override
  String get settingsShareMessage => 'Попробуйте Fadocx!\n\nУниверсальный просмотрщик документов: PDF, Office, таблицы, презентации, файлы кода и OCR-извлечение текста — полностью офлайн, без отслеживания, с открытым исходным кодом.\n\nhttps://github.com/anonfaded/Fadocx';

  @override
  String get settingsShareVia => 'Поделиться через...';

  @override
  String get settingsShareWhatsApp => 'WhatsApp';

  @override
  String get settingsWhatsAppNotInstalled => 'WhatsApp не установлен на этом устройстве';

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
  String get settingsSecurity => 'Безопасность';

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
  String get settingsFadcamDesc => 'Мультимедийный набор для Android с упором на приватность: фоновая видеозапись, видеорегистратор, запись экрана, прямые трансляции и удалённое управление — без рекламы и с открытым исходным кодом.';

  @override
  String get settingsQuranCliDesc => 'Ваш терминальный помощник для Священного Корана: читайте, слушайте и создавайте субтитры для видеомонтажа!';

  @override
  String get settingsFadcryptDesc => 'Продвинутый и элегантный кроссплатформенный блокировщик приложений — файлы, папки и приложения защищены шифрованием AES-256-GCM военного уровня. Открытый исходный код, полностью бесплатно, без телеметрии!';

  @override
  String get settingsFadcatDesc => 'Лёгкая, функциональная, кроссплатформенная замена Android logcat — без тяжести Android Studio. Включает ADB для поддерживаемых архитектур и работает в режимах GUI, CLI или MCP-сервера.';

  @override
  String get settingsMacosComingSoon => 'macOS скоро появится';

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
  String get scannerInitializingCamera => 'Инициализация камеры...';

  @override
  String get scannerDocumentDetected => 'Документ обнаружен — держите неподвижно';

  @override
  String get scannerKeepDocumentFlat => 'Держите документ ровно и плоско для лучшего результата';

  @override
  String get scannerUpload => 'Загрузить';

  @override
  String scannerFailedOpenImage(String error) {
    return 'Не удалось открыть изображение: $error';
  }

  @override
  String get scannerFlash => 'Вспышка';

  @override
  String scannerFailedTorch(String error) {
    return 'Не удалось переключить фонарик: $error';
  }

  @override
  String get scannerStartingCamera => 'Запуск камеры...';

  @override
  String get scannerCameraUnavailable => 'Камера недоступна';

  @override
  String get scannerCameraUnavailableDesc => 'Не удалось инициализировать камеру';

  @override
  String get scannerAnalysisComplete => 'Анализ завершён';

  @override
  String get scannerAnalyzing => 'Анализ документа...';

  @override
  String get scannerEnhancing => 'Улучшение качества изображения...';

  @override
  String get scannerExtractingText => 'Извлечение текстовых данных...';

  @override
  String get scannerNoScansYet => 'Сканов пока нет';

  @override
  String get scannerNoScansDesc => 'Снимите документ, чтобы увидеть извлечённый текст здесь';

  @override
  String get scannerExtractedText => 'Извлечённый текст';

  @override
  String get scannerNoTextExtracted => '(Текст не извлечён)';

  @override
  String get scannerDetectedLines => 'Обнаруженные строки';

  @override
  String get scannerTextCopied => 'Текст скопирован в буфер обмена';

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
    return 'В корзине: да (удалено: $date)';
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
