import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/lokit_viewer_notifier.dart';

class LOKitDocumentViewer extends ConsumerStatefulWidget {
  final String filePath;
  final String? fileName;
  final VoidCallback? onTap;
  final VoidCallback? onSearchHighlight;
  final Function(int currentPage, int totalPages)? onPageChanged;
  final Function(double zoom)? onZoomChanged;

  const LOKitDocumentViewer({
    super.key,
    required this.filePath,
    this.fileName,
    this.onTap,
    this.onSearchHighlight,
    this.onPageChanged,
    this.onZoomChanged,
  });

  @override
  ConsumerState<LOKitDocumentViewer> createState() => LOKitDocumentViewerState();
}

class LOKitDocumentViewerState extends ConsumerState<LOKitDocumentViewer>
    with TickerProviderStateMixin {
  final _repaintKey = GlobalKey();
  TransformationController? _transformController;
  bool _sidebarOpen = false;
  int _drawerVersion = 0;
  Offset? _tapStartPosition;
  DateTime? _tapStartTime;
  double _currentZoom = 1.0;
  double get currentZoom => _currentZoom;
  StreamSubscription? _pageChangeSub;
  int _lastReportedPage = -1;

  bool get showSidebar => _sidebarOpen;

  void toggleSidebar() {
    setState(() => _sidebarOpen = !_sidebarOpen);
  }

  void goToPage(int page) {
    final notifier = ref.read(lokitViewerProvider.notifier);
    notifier.goToPart(page - 1);
  }

  void goToFirstPage() => goToPage(1);
  void goToLastPage() => goToPage(ref.read(lokitViewerProvider).totalParts);
  void goToPreviousPage() => ref.read(lokitViewerProvider.notifier).prevPage();
  void goToNextPage() => ref.read(lokitViewerProvider.notifier).nextPage();

  Widget? buildDrawerContent(BuildContext context) {
    final lokitState = ref.read(lokitViewerProvider);
    final theme = Theme.of(context);
    final pages = lokitState.totalParts;
    if (pages <= 1) return null;

    return ValueListenableBuilder<int>(
      valueListenable: ValueNotifier(_drawerVersion),
      builder: (context, _, __) {
        final currentPage = ref.read(lokitViewerProvider).currentPart + 1;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Pages',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                itemCount: pages,
                itemBuilder: (context, index) {
                  final pageNum = index + 1;
                  final isActive = pageNum == currentPage;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Material(
                      color: isActive
                          ? theme.colorScheme.primary.withValues(alpha: 0.15)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          goToPage(pageNum);
                          setState(() {
                            _sidebarOpen = false;
                            _drawerVersion++;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          child: Row(
                            children: [
                              Icon(
                                _pageIcon(lokitState.documentType),
                                size: 18,
                                color: isActive
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Page $pageNum',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: isActive
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.onSurface,
                                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                                  ),
                                ),
                              ),
                              if (isActive)
                                Icon(Icons.check_circle,
                                    size: 16, color: theme.colorScheme.primary),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  IconData _pageIcon(int docType) {
    switch (docType) {
      case 1:
        return Icons.grid_on;
      case 2:
        return Icons.slideshow;
      case 3:
        return Icons.draw;
      default:
        return Icons.description;
    }
  }

  @override
  void initState() {
    super.initState();
    _transformController = TransformationController();
    _transformController!.addListener(_onZoomChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadDocument());
  }

  void _onZoomChanged() {
    final scale = _transformController!.value.getMaxScaleOnAxis();
    if ((scale - _currentZoom).abs() > 0.01) {
      _currentZoom = scale;
      widget.onZoomChanged?.call(scale);
    }
  }

  Future<void> _loadDocument() async {
    final notifier = ref.read(lokitViewerProvider.notifier);
    final ok = await notifier.loadDocument(widget.filePath, name: widget.fileName);
    if (!ok || !mounted) return;
    _reportPageChange(1, ref.read(lokitViewerProvider).totalParts);
    await notifier.renderCurrentPage();
  }

  void _reportPageChange(int current, int total) {
    if (current != _lastReportedPage && widget.onPageChanged != null) {
      _lastReportedPage = current;
      widget.onPageChanged!(current, total);
    }
  }

  @override
  void dispose() {
    _transformController?.removeListener(_onZoomChanged);
    _transformController?.dispose();
    _pageChangeSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lokitState = ref.watch(lokitViewerProvider);
    final screenSize = MediaQuery.sizeOf(context);

    ref.listen<LOKitViewerState>(lokitViewerProvider, (prev, next) {
      if (prev?.currentPart != next.currentPart) {
        _reportPageChange(next.currentPart + 1, next.totalParts);
        _resetZoom();
        setState(() => _drawerVersion++);
      }
    });

    if (lokitState.error != null && !lokitState.isLoading && lokitState.currentPageImage == null) {
      return _buildError(lokitState.error!);
    }

    if (lokitState.isLoading) {
      return _buildLoading();
    }

    if (lokitState.currentPageImage == null && !lokitState.isRendering) {
      return _buildLoading();
    }

    return Listener(
      onPointerDown: (e) {
        _tapStartPosition = e.position;
        _tapStartTime = DateTime.now();
      },
      onPointerUp: (e) {
        if (_tapStartPosition != null && _tapStartTime != null) {
          final distance = (e.position - _tapStartPosition!).distance;
          final duration = DateTime.now().difference(_tapStartTime!);
          if (duration.inMilliseconds < 200 && distance < 10) {
            widget.onTap?.call();
          }
        }
        _tapStartPosition = null;
        _tapStartTime = null;
      },
      child: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: RepaintBoundary(
          key: _repaintKey,
          child: InteractiveViewer(
            
            transformationController: _transformController,
            minScale: 0.5,
            maxScale: 4.0,
            boundaryMargin: const EdgeInsets.all(double.infinity),
            child: Center(
              child: _buildPageImage(lokitState, screenSize),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPageImage(LOKitViewerState state, Size screenSize) {
    if (state.currentPageImage == null) {
      return const SizedBox.shrink();
    }
    return FutureBuilder<ui.Image>(
      future: _decodeImage(state.currentPageImage!),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }
        final img = snapshot.data!;
        final imgW = img.width.toDouble();
        final imgH = img.height.toDouble();
        final displayW = screenSize.width;
        final displayH = screenSize.height;
        final scale = min(displayW / imgW, displayH / imgH);
        final fitW = imgW * scale;
        final fitH = imgH * scale;

        return SizedBox(
          width: fitW,
          height: fitH,
          child: CustomPaint(
            painter: _ImagePainter(img),
          ),
        );
      },
    );
  }

  Future<ui.Image> _decodeImage(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  Widget _buildLoading() {
    final theme = Theme.of(context);
    final lokitState = ref.watch(lokitViewerProvider);
    final isInit = lokitState.isInitialized;
    final label = isInit ? 'Preparing your document...' : 'Warming up the Fadocx engine...';
    final sublabel = isInit ? 'Almost there' : 'Just a moment';
    return Container(
      color: theme.scaffoldBackgroundColor,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              sublabel,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(String error) {
    final theme = Theme.of(context);
    return Container(
      color: theme.scaffoldBackgroundColor,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
              const SizedBox(height: 16),
              Text(
                'Failed to render document',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                error,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.tonal(
                onPressed: _loadDocument,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _resetZoom() {
    if (_transformController != null) {
      _transformController!.value = Matrix4.identity();
      setState(() => _currentZoom = 1.0);
    }
  }

  void resetZoom() => _resetZoom();
}

class _ImagePainter extends CustomPainter {
  final ui.Image image;
  _ImagePainter(this.image);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..filterQuality = FilterQuality.high;
    final src = Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());
    canvas.drawImageRect(image, src, Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant _ImagePainter old) => old.image != image;
}
