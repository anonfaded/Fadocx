// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appName => 'Fadocx';

  @override
  String get appDescription => 'Document Viewer';

  @override
  String get homeTitle => 'Fadocx';

  @override
  String get recentFiles => '最近のファイル';

  @override
  String get noRecentFiles => '最近のファイルはありません。ドキュメントを開いてください。';

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
  String get cancel => 'キャンセル';

  @override
  String get delete => '削除';

  @override
  String get clear => 'クリア';

  @override
  String get close => '閉じる';

  @override
  String get copy => 'コピー';

  @override
  String get retry => '再試行';

  @override
  String get rename => '名前変更';

  @override
  String get restore => '復元';

  @override
  String get export => 'エクスポート';

  @override
  String get duplicate => '複製';

  @override
  String get imports => 'インポート';

  @override
  String get next => '次へ';

  @override
  String get previous => '前へ';

  @override
  String get back => '戻る';

  @override
  String get settings => '設定';

  @override
  String get about => 'アプリについて';

  @override
  String get error => 'エラー';

  @override
  String get warning => '警告';

  @override
  String get success => '成功';

  @override
  String get unsupportedFileType => 'このファイル形式はサポートされていません';

  @override
  String get fileNotFound => 'ファイルが見つかりません';

  @override
  String get permissionDenied => '権限が拒否されました';

  @override
  String get corruptedFile => 'File appears to be corrupted';

  @override
  String get loadingDocument => 'ドキュメントを読み込み中...';

  @override
  String get settingsTitle => '設定';

  @override
  String get theme => 'テーマ';

  @override
  String get themeDark => 'ダーク';

  @override
  String get themeLight => 'ライト';

  @override
  String get themeSystem => 'システム';

  @override
  String get language => '言語';

  @override
  String get languageEnglish => '英語';

  @override
  String get languageUrdu => 'ウルドゥー語';

  @override
  String get languageRussian => 'ロシア語';

  @override
  String get languageChinese => '中国語';

  @override
  String get languageJapanese => '日本語';

  @override
  String get languageFrench => 'フランス語';

  @override
  String get languageArabic => 'アラビア語';

  @override
  String get languageSpanish => 'スペイン語';

  @override
  String get languageGerman => 'ドイツ語';

  @override
  String get languagePortuguese => 'ポルトガル語';

  @override
  String get languageHindi => 'ヒンディー語';

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
  String get copiedToClipboard => 'クリップボードにコピーしました';

  @override
  String get navHome => 'ホーム';

  @override
  String get navLibrary => 'ライブラリ';

  @override
  String get navSettings => '設定';

  @override
  String get navRecents => '最近';

  @override
  String get categoryAll => 'すべて';

  @override
  String get categoryPdfs => 'PDF';

  @override
  String get categoryDocs => '文書';

  @override
  String get categorySheets => 'スプレッドシート';

  @override
  String get categorySlides => 'スライド';

  @override
  String get categoryCode => 'コード';

  @override
  String get categoryScans => 'スキャン';

  @override
  String get categoryOther => 'その他';

  @override
  String get categoryPresentations => 'プレゼンテーション';

  @override
  String get supportDevelopment => '開発を支援';

  @override
  String get visitPatreon => 'Patreon を開く';

  @override
  String get copyLink => 'リンクをコピー';

  @override
  String get becomeAPatron => 'Become a Patron';

  @override
  String get patreonDescription => 'あなたの支援は Fadocx と FadCam の成長を支えます。Patreon の支援者は、プレミアム機能や FadSec Lab のすべてのアプリでの先行アクセスなど、限定特典を利用できます。\n\n詳しくは下のリンクから Patreon を開き、利用可能なプランと特典を確認してください。';

  @override
  String get discordTitle => 'Discord に参加';

  @override
  String get openInBrowser => 'ブラウザで開く';

  @override
  String get comingSoon => '近日公開';

  @override
  String get newBadge => 'NEW';

  @override
  String get timeAgoJustNow => 'たった今';

  @override
  String timeAgoMinute(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count分前',
      one: '1分前',
    );
    return '$_temp0';
  }

  @override
  String timeAgoHour(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count時間前',
      one: '1時間前',
    );
    return '$_temp0';
  }

  @override
  String timeAgoDay(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count日前',
      one: '1日前',
    );
    return '$_temp0';
  }

  @override
  String timeAgoWeek(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count週間前',
      one: '1週間前',
    );
    return '$_temp0';
  }

  @override
  String timeAgoMonth(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countか月前',
      one: '1か月前',
    );
    return '$_temp0';
  }

  @override
  String timeAgoYear(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count年前',
      one: '1年前',
    );
    return '$_temp0';
  }

  @override
  String get monthJan => '1月';

  @override
  String get monthFeb => '2月';

  @override
  String get monthMar => '3月';

  @override
  String get monthApr => '4月';

  @override
  String get monthMay => '5月';

  @override
  String get monthJun => '6月';

  @override
  String get monthJul => '7月';

  @override
  String get monthAug => '8月';

  @override
  String get monthSep => '9月';

  @override
  String get monthOct => '10月';

  @override
  String get monthNov => '11月';

  @override
  String get monthDec => '12月';

  @override
  String get homeWelcomeTitle => 'Fadocxへようこそ';

  @override
  String get homeWelcomeSubtitle => 'サンプルファイルを探索するか、自分のドキュメントをインポートしてください';

  @override
  String get homeExploreSamples => 'サンプルファイルを見る';

  @override
  String get homeDocumentManagement => 'ドキュメント管理';

  @override
  String get homeSeeAll => 'すべて見る';

  @override
  String get homeNoRecentFiles => '最近のファイルはありません';

  @override
  String get homeScanDocument => '文書をスキャン';

  @override
  String get homeScanDocumentDesc => 'OCRを使用して文書からテキストを抽出';

  @override
  String get homeImportDocument => '文書をインポート';

  @override
  String get homeImportDocumentDesc => 'デバイスからファイルを参照してインポート';

  @override
  String get onboardingSkip => 'スキップ';

  @override
  String get onboardingNext => '次へ';

  @override
  String get onboardingGetStarted => '始める';

  @override
  String get onboardingSlide1Title => 'Fadocxへようこそ';

  @override
  String get onboardingSlide1Tagline => 'オールインワンのプライベート文書管理';

  @override
  String get onboardingSlide1Bullet1 => 'あらゆる形式を開く — PDF、Officeファイル、画像など';

  @override
  String get onboardingSlide1Bullet2 => 'ギャラリーやファイルマネージャーに非表示のプライベートストレージ';

  @override
  String get onboardingSlide1Bullet3 => '無料・オープンソース — アカウント不要';

  @override
  String get onboardingSlide2Title => '内蔵パワーツール';

  @override
  String get onboardingSlide2Bullet1 => 'カメラで書類をスキャン — テキストを即座に抽出';

  @override
  String get onboardingSlide2Bullet2 => 'アプリ内で音声・動画を再生、追加インストール不要';

  @override
  String get onboardingSlide2Bullet3 => 'インポート時に自動でカテゴリに分類';

  @override
  String get onboardingSlide2Bullet4 => '安全な削除 — いつでもゴミ箱から復元可能';

  @override
  String get onboardingSlide3Title => 'プライバシー優先設計';

  @override
  String get onboardingSlide3Bullet1 => 'データはデバイスから出ない — クラウドもサーバーも不要';

  @override
  String get onboardingSlide3Bullet2 => '追跡なし、広告なし、分析なし。永遠に。';

  @override
  String get onboardingSlide3Bullet3 => 'オープンソース — すべてのコードが公開されています';

  @override
  String get homeStatDocuments => 'ドキュメント';

  @override
  String get homeStatStorage => 'ストレージ';

  @override
  String get homeStatTimeRead => '読書時間';

  @override
  String get homeStatLastOpened => '最終オープン: ';

  @override
  String get homePressBackExit => 'もう一度押すと終了します';

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
  String get homeFileInfo => 'ファイル情報';

  @override
  String get homeFileName => '名前';

  @override
  String get homeFileType => '種類';

  @override
  String get homeFileSize => 'サイズ';

  @override
  String get homeFileLocation => '場所';

  @override
  String get homeFileDateOpened => '開いた日';

  @override
  String get homeFileLastModified => '最終更新';

  @override
  String get homeFileInTrash => 'ゴミ箱内';

  @override
  String get homeFileInfoCopied => 'ファイル情報をコピーしました';

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
  String get libraryTitle => 'ライブラリ';

  @override
  String get librarySearchHint => 'ライブラリを検索...';

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
  String get libraryNoDocuments => 'ドキュメントがありません';

  @override
  String get libraryAdjustSearch => '検索条件やフィルターを変更してみてください';

  @override
  String get libraryDocumentsAppearHere => 'ドキュメントがここに表示されます';

  @override
  String get browseTitle => 'ドキュメントをインポート';

  @override
  String get browseBack => '戻る';

  @override
  String get browseSearchHint => 'ドキュメントを検索...';

  @override
  String get browseCancel => 'キャンセル';

  @override
  String get browseBrowseFiles => '参照';

  @override
  String get browseBrowseFilesDesc => '追加ファイルを手動でインポート';

  @override
  String get browseScanFailed => 'スキャンに失敗しました';

  @override
  String get browseUnknownError => '不明なエラーが発生しました';

  @override
  String get browseRetryScan => '再スキャン';

  @override
  String get browseImportManually => 'ファイルを手動でインポート';

  @override
  String get browseNoDocumentsFound => 'ドキュメントが見つかりません';

  @override
  String get browseNoDocumentsMatch => '検索に一致するドキュメントがありません';

  @override
  String get browseAdjustSearch => '検索またはフィルターを調整してください';

  @override
  String get browseClearSelection => 'クリア';

  @override
  String get browseImport => 'インポート';

  @override
  String get browseAllFilesAccessRequired => '端末上のドキュメントを参照するには、すべてのファイルへのアクセス権が必要です';

  @override
  String get browsePermissionRequired => '権限が必要です';

  @override
  String get browseAllFilesAccessDenied => '端末上のドキュメントを参照・読み取るには、すべてのファイルへのアクセス権が必要です。続行するには権限を許可してください。';

  @override
  String get browseOpenSettings => '設定を開く';

  @override
  String get browseAccessStillDisabled => 'すべてのファイルへのアクセスはまだ無効です。続行するには設定で有効にしてください。';

  @override
  String get browseNoDirectories => '端末上にドキュメントディレクトリが見つかりません';

  @override
  String browseErrorPrefix(String error) {
    return 'エラー: $error';
  }

  @override
  String get browseSortBy => '並び替え';

  @override
  String browseImportedFiles(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count件のファイルをインポートしました',
      one: '1件のファイルをインポートしました',
    );
    return '$_temp0';
  }

  @override
  String get trashTitle => 'ゴミ箱';

  @override
  String get trashEmpty => 'ゴミ箱は空です';

  @override
  String get trashEmptySubtitle => '削除されたファイルはここに表示されます';

  @override
  String get trashErrorLoading => 'Error loading trash';

  @override
  String trashFilesSelected(num count) {
    return '$count selected';
  }

  @override
  String get trashFilesLabel => 'files';

  @override
  String get trashSelect => '選択';

  @override
  String get trashFileRestored => 'File restored successfully';

  @override
  String get trashDeletePermanently => '完全に削除';

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
  String get whatsNewTitle => '新機能';

  @override
  String get whatsNewWhatsIncluded => '含まれる内容';

  @override
  String get whatsNewPlanned => '予定中';

  @override
  String get whatsNewReleasedToday => '本日公開';

  @override
  String get whatsNewReleasedYesterday => '昨日公開';

  @override
  String whatsNewReleasedDate(String date) {
    return '$date に公開';
  }

  @override
  String get whatsNewDocAndSheets => 'ドキュメントと表計算';

  @override
  String get whatsNewDocAndSheetsDesc => 'PDF、Word 文書、Excel シートなどを、すべて端末上でローカル表示できます。';

  @override
  String get whatsNewOcrAi => '高性能 OCR とオンデバイス AI';

  @override
  String get whatsNewOcrAiDesc => '高度なオンデバイス OCR で画像からテキストを抽出。複数言語に対応しています。';

  @override
  String get whatsNewSyntaxHighlighting => 'シンタックスハイライト';

  @override
  String get whatsNewSyntaxHighlightingDesc => '50 以上のプログラミング言語に対応した美しいコードハイライト。';

  @override
  String get whatsNewReadingStats => '読書統計ダッシュボード';

  @override
  String get whatsNewReadingStatsDesc => '詳細な統計と時間追跡で読書の進捗を確認できます。';

  @override
  String get whatsNewLibraryCategories => 'カテゴリ別フォルダーのライブラリ';

  @override
  String get whatsNewLibraryCategoriesDesc => '賢い自動分類でドキュメントを種類ごとに整理できます。';

  @override
  String get whatsNewFileManagement => 'ファイル管理';

  @override
  String get whatsNewFileManagementDesc => '名前変更、複製、エクスポート、削除を簡単に行えます。';

  @override
  String get whatsNewThemes => 'ライトテーマとダークテーマ';

  @override
  String get whatsNewThemesDesc => '昼はライト、夜はダークなど、好みに合う見た目を選べます。';

  @override
  String get whatsNewFadDrive => 'FadDrive';

  @override
  String get whatsNewFadDriveDesc => 'ドキュメントのクラウド同期。いつでもどこでもアクセスできます。';

  @override
  String get whatsNewEditing => 'ドキュメント編集';

  @override
  String get whatsNewEditingDesc => 'Fadocx 内でドキュメントをすばやく編集できます。';

  @override
  String get whatsNewBookmarks => 'ブックマークと注釈';

  @override
  String get whatsNewBookmarksDesc => '重要なページに印を付け、あとで見返すための注釈を追加できます。';

  @override
  String get whatsNewConversion => 'ドキュメント変換';

  @override
  String get whatsNewConversionDesc => 'PDF、DOCX などの形式間で変換できます。';

  @override
  String get whatsNewAmoled => 'AMOLED ブラックテーマ';

  @override
  String get whatsNewAmoledDesc => 'AMOLED ディスプレイ向けの純黒テーマ。ダークモードでバッテリーを節約します。';

  @override
  String get whatsNewMoreOcr => 'OCR 言語の追加';

  @override
  String get whatsNewMoreOcrDesc => 'OCR 言語の追加対応と認識精度の向上。';

  @override
  String get whatsNewOfflineFirst => 'プライバシー重視のオフラインファースト文書ビューア。アカウント不要、トラッキングなし、インターネット不要。';

  @override
  String get whatsNewThankYou => 'Fadocx をご利用いただきありがとうございます';

  @override
  String get whatsNewThankYouDesc => 'Fadocx に価値を感じたら、開発支援をご検討ください。あなたの貢献が、プライバシー第一のツール開発を支えます。';

  @override
  String get drawerWhatNew => '新機能';

  @override
  String get drawerRecentFiles => '最近のファイル';

  @override
  String get drawerVisible => '表示中';

  @override
  String get drawerHidden => '非表示';

  @override
  String get drawerUnlockBenefits => '限定特典を解除';

  @override
  String get fileActionRename => '名前を変更';

  @override
  String get fileActionRenameDesc => 'ファイル名を変更';

  @override
  String get fileActionDuplicate => '複製';

  @override
  String get fileActionDuplicateDesc => 'コピーを作成';

  @override
  String get fileActionExport => 'エクスポート / 名前を付けて保存';

  @override
  String get fileActionExportDesc => 'ダウンロードにコピーを保存';

  @override
  String get fileActionCopyText => 'テキストをコピー';

  @override
  String get fileActionCopyTextDesc => '抽出したテキストをクリップボードにコピー';

  @override
  String get fileActionConvert => '変換';

  @override
  String get fileActionConvertDesc => '別の形式に変換';

  @override
  String get fileActionUpload => 'FadDrive にアップロード';

  @override
  String get fileActionUploadDesc => 'クラウドストレージに同期';

  @override
  String get fileActionFileInfo => 'ファイル情報';

  @override
  String get fileActionSubtitle => 'ファイル操作と管理';

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
  String get settingsAppearance => '外観';

  @override
  String get settingsStorage => 'ストレージ';

  @override
  String get settingsDocumentsSize => 'ドキュメントサイズ';

  @override
  String get settingsCalculating => '計算中...';

  @override
  String get settingsCustomStorage => 'カスタムストレージ';

  @override
  String get settingsUnknown => 'Unknown';

  @override
  String get settingsStorageDetails => 'ストレージ';

  @override
  String get settingsStoragePdfs => 'PDF';

  @override
  String get settingsStorageDocs => 'ドキュメント';

  @override
  String get settingsStorageSheets => 'シート';

  @override
  String get settingsStoragePresentations => 'プレゼンテーション';

  @override
  String get settingsStorageCode => 'コード';

  @override
  String get settingsStorageScans => 'スキャン';

  @override
  String get settingsStorageImages => '画像';

  @override
  String get settingsStorageOther => 'その他';

  @override
  String get settingsStorageInfo => 'ドキュメントは端末内のプライベートフォルダーに保存され、他のアプリからはアクセスできません';

  @override
  String get settingsStoragePrivateFolderInfo => 'ドキュメントは他のアプリやファイルマネージャーから見えないプライベートフォルダーに保存されています。アクセスできるのは Fadocx のみです。';

  @override
  String get settingsStorageDeleteInfo => '設定の危険ゾーンからドキュメントを削除してください';

  @override
  String get settingsStorageEmpty => 'ドキュメントはありません';

  @override
  String get settingsStorageFailedLoad => 'ストレージデータの読み込みに失敗しました';

  @override
  String get settingsUpdates => 'アップデート';

  @override
  String get settingsAutoUpdateCheck => '自動アップデート確認';

  @override
  String get settingsReplayOnboarding => 'チュートリアルを再生';

  @override
  String get settingsReplayOnboardingDesc => '次回起動時に紹介スライドを表示';

  @override
  String get settingsEnabled => '有効';

  @override
  String get settingsDisabled => '無効';

  @override
  String get settingsAppLock => 'アプリロック';

  @override
  String get settingsAbout => 'アプリについて';

  @override
  String get settingsVersion => 'バージョン';

  @override
  String get settingsSourceCode => 'ソースコード';

  @override
  String get settingsContact => 'お問い合わせ';

  @override
  String get settingsJoinCommunity => 'コミュニティに参加';

  @override
  String get settingsPrivacyPolicy => 'プライバシーポリシー';

  @override
  String get settingsMoreFromFadsec => 'FadSec Lab のその他の製品';

  @override
  String get settingsFadocxDesc => 'Your private document viewer';

  @override
  String get settingsDangerZone => '危険ゾーン';

  @override
  String get settingsTrash => 'ゴミ箱';

  @override
  String get settingsTrashDesc => '削除されたファイルを表示';

  @override
  String get settingsResetSettings => '設定をリセット';

  @override
  String get settingsResetSettingsDesc => 'すべての設定をデフォルトに戻す';

  @override
  String get settingsResetDone => '設定をリセットしました';

  @override
  String get settingsRetry => 'Retry';

  @override
  String get settingsChooseTheme => 'テーマを選択';

  @override
  String get settingsSelectLanguage => '言語を選択';

  @override
  String get settingsCheckForUpdates => 'アップデートを確認';

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
  String get settingsCopiedInfo => 'クリップボードにコピーしました';

  @override
  String get settingsCopyInfo => '情報をコピー';

  @override
  String settingsVersionClipboardInfo(String appName, String version, String buildNumber, String packageName) {
    return '$appName v$version (Build $buildNumber)\nパッケージ: $packageName';
  }

  @override
  String get settingsShareApp => '友だちと共有';

  @override
  String get settingsShareMessage => 'Fadocx をチェック！\n\nPDF、Office、スプレッドシート、プレゼンテーション、コードファイル、OCR テキスト抽出に対応したオールインワンドキュメントビューア。完全オフライン、トラッキングなし、オープンソース。\n\nhttps://github.com/anonfaded/Fadocx';

  @override
  String get settingsShareVia => '共有方法...';

  @override
  String get settingsShareWhatsApp => 'WhatsApp';

  @override
  String get settingsWhatsAppNotInstalled => 'この端末に WhatsApp はインストールされていません';

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
  String get settingsSecurity => 'セキュリティ';

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
  String get confirm => '確認';

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
  String get settingsFadcamDesc => 'プライバシー重視の Android マルチメディアスイート。バックグラウンド動画録画、ドライブレコーダー、画面録画、ライブ配信、リモート操作に対応。広告なし、オープンソース。';

  @override
  String get settingsQuranCliDesc => '聖クルアーンのためのターミナルコンパニオン。読んで、聞いて、動画編集用の字幕を生成できます。';

  @override
  String get settingsFadcryptDesc => '高度で洗練されたクロスプラットフォームのアプリロッカー。ファイル、フォルダー、アプリを AES-256-GCM の軍用レベル暗号化で保護。オープンソース、完全無料、テレメトリなし。';

  @override
  String get settingsFadcatDesc => '軽量で高機能なクロスプラットフォーム Android logcat 代替ツール。Android Studio の重さなし。対応アーキテクチャ向け ADB 同梱、GUI・CLI・MCP サーバーモードで動作。';

  @override
  String get settingsMacosComingSoon => 'macOS は近日対応予定';

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
  String get scannerTitle => '文書スキャナー';

  @override
  String get scannerCapture => '撮影';

  @override
  String get scannerProcessing => '処理中';

  @override
  String get scannerResults => '結果';

  @override
  String get scannerInitializingCamera => 'カメラを初期化中...';

  @override
  String get scannerDocumentDetected => '文書を検出しました。動かさないでください';

  @override
  String get scannerKeepDocumentFlat => '最良の結果のため、文書をまっすぐ平らに保ってください';

  @override
  String get scannerUpload => 'アップロード';

  @override
  String scannerFailedOpenImage(String error) {
    return '画像を開けませんでした: $error';
  }

  @override
  String get scannerFlash => 'フラッシュ';

  @override
  String scannerFailedTorch(String error) {
    return 'ライトの切り替えに失敗しました: $error';
  }

  @override
  String get scannerStartingCamera => 'カメラを起動中...';

  @override
  String get scannerCameraUnavailable => 'カメラを利用できません';

  @override
  String get scannerCameraUnavailableDesc => 'カメラを初期化できませんでした';

  @override
  String get scannerAnalysisComplete => '解析完了';

  @override
  String get scannerAnalyzing => '文書を解析中...';

  @override
  String get scannerEnhancing => '画像品質を改善中...';

  @override
  String get scannerExtractingText => 'テキストデータを抽出中...';

  @override
  String get scannerNoScansYet => 'まだスキャンがありません';

  @override
  String get scannerNoScansDesc => '文書を撮影すると、抽出されたテキストがここに表示されます';

  @override
  String get scannerExtractedText => '抽出されたテキスト';

  @override
  String get scannerNoTextExtracted => '(テキストは抽出されませんでした)';

  @override
  String get scannerDetectedLines => '検出された行';

  @override
  String get scannerTextCopied => 'テキストをクリップボードにコピーしました';

  @override
  String get scannerCopyAll => 'すべてコピー';

  @override
  String get scannerNewScan => '新しいスキャン';

  @override
  String get linkTileCopy => 'コピー';

  @override
  String get linkTileCopiedToClipboard => 'Copied to clipboard';

  @override
  String get linkTileSendEmail => 'メールを送信';

  @override
  String get linkTileOpenInBrowser => 'ブラウザで開く';

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
    return 'ゴミ箱内: はい (削除日: $date)';
  }

  @override
  String get homeUnknown => 'unknown';

  @override
  String routeNotFound(String path) {
    return 'ルートが見つかりません: $path';
  }

  @override
  String get routeGoHome => 'ホームへ戻る';

  @override
  String get routeInvalidDocumentPath => '無効なドキュメントパス';

  @override
  String get pdfCopyTextTitle => 'PDFテキストをコピー';

  @override
  String get pdfExtractingText => 'テキストを抽出中...';

  @override
  String pdfExtractingTextProgress(num current, num total) {
    return 'テキストを抽出中（$current/$total ページ）...';
  }

  @override
  String get pdfErrorExtractingText => 'テキスト抽出エラー';

  @override
  String pdfWordCount(num count) {
    return '単語数: $count';
  }

  @override
  String get pdfNoTextFound => 'PDFにテキストが見つかりませんでした';

  @override
  String get pdfFullTextCopied => 'PDFの全テキストをクリップボードにコピーしました';

  @override
  String get pdfPasswordRequired => 'PDFパスワードが必要です';

  @override
  String get pdfPasswordDesc => 'このPDFはパスワードで保護されています。パスワードを入力していただけますか？';

  @override
  String get pdfPasswordLabel => 'パスワード';

  @override
  String get pdfUnlock => 'ロック記解除';

  @override
  String get pdfSearchHint => 'PDFを検索...';

  @override
  String get pdfTextCannotBeExtracted => 'このページからテキストを抽出できません';

  @override
  String get pdfLoadingPageTexts => 'ページのテキストを読み込み中...';

  @override
  String pdfPageCopied(num page) {
    return '$pageページのテキストをクリップボードにコピーしました';
  }

  @override
  String get viewerTooltipSidebar => 'サイドバー';

  @override
  String get viewerTooltipFirst => '最初';

  @override
  String get viewerTooltipLast => '最後';

  @override
  String get viewerTooltipCopyPageText => 'ページのテキストをコピー';

  @override
  String get textDocSearchHint => 'テキストを検索...';

  @override
  String get textDocSearchPrevResult => '前の結果';

  @override
  String get textDocSearchNextResult => '次の結果';

  @override
  String get imageFailedToLoad => '画像の読み込みに失敗しました';

  @override
  String get mediaLoading => 'メディアを読み込み中...';

  @override
  String get mediaFailedToPlay => 'メディアを再生できませんでした';

  @override
  String get mediaPlay => '再生';

  @override
  String get audioPlaybackNote => '音声の再生には追加のライブラリが必要です。';

  @override
  String sheetNoData(String sheetName) {
    return '$sheetName にデータがありません';
  }

  @override
  String documentNoSheets(String format) {
    return '$format にシートが見つかりません';
  }

  @override
  String get viewerPlaybackSpeed => '再生速度';

  @override
  String urlCopiedToClipboard(String url) {
    return 'URLをクリップボードにコピーしました: $url';
  }

  @override
  String get lokitPreparingDoc => 'ドキュメントを準備中...';

  @override
  String get lokitWarmingUp => 'Fadocx エンジンを起動中...';

  @override
  String get lokitAlmostThere => 'もう少し';

  @override
  String get lokitJustAMoment => '少々お待ちください';

  @override
  String get lokitFailedToRender => 'ドキュメントの表示に失敗しました';
}
