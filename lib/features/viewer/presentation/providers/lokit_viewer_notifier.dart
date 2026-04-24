import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import '../../data/services/lokit_service.dart';

class LOKitViewerState {
  final bool isInitialized;
  final bool isLoading;
  final bool isRendering;
  final String? error;
  final String? fileName;
  final int currentPart;
  final int totalParts;
  final int documentWidth;
  final int documentHeight;
  final int documentType;
  final String typeName;
  final Uint8List? currentPageImage;
  final int renderedPart;
  final double renderedZoom;

  const LOKitViewerState({
    this.isInitialized = false,
    this.isLoading = false,
    this.isRendering = false,
    this.error,
    this.fileName,
    this.currentPart = 0,
    this.totalParts = 0,
    this.documentWidth = 0,
    this.documentHeight = 0,
    this.documentType = -1,
    this.typeName = '',
    this.currentPageImage,
    this.renderedPart = -1,
    this.renderedZoom = 0,
  });

  LOKitViewerState copyWith({
    bool? isInitialized,
    bool? isLoading,
    bool? isRendering,
    String? error,
    String? fileName,
    int? currentPart,
    int? totalParts,
    int? documentWidth,
    int? documentHeight,
    int? documentType,
    String? typeName,
    Uint8List? currentPageImage,
    int? renderedPart,
    double? renderedZoom,
    bool clearError = false,
    bool clearImage = false,
  }) {
    return LOKitViewerState(
      isInitialized: isInitialized ?? this.isInitialized,
      isLoading: isLoading ?? this.isLoading,
      isRendering: isRendering ?? this.isRendering,
      error: clearError ? null : (error ?? this.error),
      fileName: fileName ?? this.fileName,
      currentPart: currentPart ?? this.currentPart,
      totalParts: totalParts ?? this.totalParts,
      documentWidth: documentWidth ?? this.documentWidth,
      documentHeight: documentHeight ?? this.documentHeight,
      documentType: documentType ?? this.documentType,
      typeName: typeName ?? this.typeName,
      currentPageImage: clearImage ? null : (currentPageImage ?? this.currentPageImage),
      renderedPart: renderedPart ?? this.renderedPart,
      renderedZoom: renderedZoom ?? this.renderedZoom,
    );
  }
}

class LOKitViewerNotifier extends Notifier<LOKitViewerState> {
  static final _log = Logger(printer: PrettyPrinter(methodCount: 0));
  static bool _globalInitialized = false;

  @override
  LOKitViewerState build() {
    ref.onDispose(() {
      _closeDocument();
    });
    return const LOKitViewerState();
  }

  Future<bool> initialize() async {
    if (_globalInitialized) {
      state = state.copyWith(isInitialized: true);
      return true;
    }
    try {
      final ok = await LOKitService.init();
      if (ok) {
        _globalInitialized = true;
        state = state.copyWith(isInitialized: true);
      }
      return ok;
    } catch (e) {
      _log.e('LOKit init failed', error: e);
      state = state.copyWith(error: 'Failed to initialize: $e');
      return false;
    }
  }

  Future<bool> loadDocument(String filePath, {String? name}) async {
    state = state.copyWith(isLoading: true, clearError: true, fileName: name);
    try {
      if (!_globalInitialized) {
        final ok = await initialize();
        if (!ok) {
          state = state.copyWith(isLoading: false, error: 'Initialization failed');
          return false;
        }
      }
      final info = await LOKitService.loadDocument(filePath);
      if (info == null) {
        state = state.copyWith(isLoading: false, error: 'Failed to load document');
        return false;
      }
      final parts = (info['parts'] as int?) ?? 1;
      final width = (info['width'] as int?) ?? 0;
      final height = (info['height'] as int?) ?? 0;
      final type = (info['type'] as int?) ?? 0;
      final tName = (info['typeName'] as String?) ?? LOKitService.getDocTypeName(type);
      state = state.copyWith(
        isLoading: false,
        totalParts: parts,
        documentWidth: width,
        documentHeight: height,
        documentType: type,
        typeName: tName,
        currentPart: 0,
      );
      return true;
    } catch (e) {
      _log.e('Load document failed', error: e);
      state = state.copyWith(isLoading: false, error: 'Failed to load: $e');
      return false;
    }
  }

  Future<void> renderCurrentPage({int maxWidth = 1080, int maxHeight = 1920}) async {
    if (state.isRendering) return;
    final part = state.currentPart;
    state = state.copyWith(isRendering: true);
    try {
      final pngBytes = await LOKitService.renderPageHighQuality(
        part: part,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        scale: 2.0,
      );
      if (pngBytes != null) {
        state = state.copyWith(
          isRendering: false,
          currentPageImage: pngBytes,
          renderedPart: part,
        );
      } else {
        state = state.copyWith(isRendering: false, error: 'Rendering returned null');
      }
    } catch (e) {
      _log.e('Render failed', error: e);
      state = state.copyWith(isRendering: false, error: 'Render failed: $e');
    }
  }

  Future<void> goToPart(int index) async {
    if (index < 0 || index >= state.totalParts || index == state.currentPart) return;
    state = state.copyWith(currentPart: index, clearImage: true);
    await renderCurrentPage();
  }

  Future<void> nextPage() async {
    if (state.currentPart < state.totalParts - 1) {
      await goToPart(state.currentPart + 1);
    }
  }

  Future<void> prevPage() async {
    if (state.currentPart > 0) {
      await goToPart(state.currentPart - 1);
    }
  }

  void _closeDocument() {
    if (_globalInitialized) {
      LOKitService.closeDocument();
    }
  }

  static void destroyGlobal() {
    if (_globalInitialized) {
      LOKitService.destroy();
      _globalInitialized = false;
    }
  }
}

final lokitViewerProvider = NotifierProvider.autoDispose<LOKitViewerNotifier, LOKitViewerState>(
  LOKitViewerNotifier.new,
);
