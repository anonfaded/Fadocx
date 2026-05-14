import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fadocx/config/routing/app_router.dart';
import 'package:fadocx/l10n/app_localizations.dart';
import 'package:fadocx/features/settings/presentation/providers/settings_providers.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with TickerProviderStateMixin {
  late final PageController _pageController;
  int _currentPage = 0;

  // Staggered reveal animation
  int _revealedCount = 0;
  Timer? _revealTimer;

  // Icon + title animations
  late final AnimationController _iconController;
  late final Animation<double> _iconScale;
  late final Animation<double> _titleFade;
  late final Animation<Offset> _titleSlide;

  // Exit
  bool _exiting = false;
  late final AnimationController _exitController;
  late final Animation<double> _exitScale;
  late final Animation<double> _exitFade;

  static const _totalPages = 3;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    _iconController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );
    _iconScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _iconController, curve: Curves.easeOutBack),
    );
    _titleFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _iconController,
        curve: const Interval(0.3, 0.85, curve: Curves.easeOut),
      ),
    );
    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _iconController,
        curve: const Interval(0.3, 0.85, curve: Curves.easeOutCubic),
      ),
    );

    _exitController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _exitScale = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(
        parent: _exitController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );
    _exitFade = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _exitController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeIn),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _iconController.dispose();
    _exitController.dispose();
    _revealTimer?.cancel();
    super.dispose();
  }

  void _startRevealing(int bulletCount) {
    _revealTimer?.cancel();
    if (!mounted) return;
    setState(() => _revealedCount = 0);
    _revealTimer = Timer.periodic(const Duration(milliseconds: 300), (timer) {
      if (!mounted || _exiting) {
        timer.cancel();
        return;
      }
      if (_revealedCount >= bulletCount) {
        timer.cancel();
        return;
      }
      setState(() => _revealedCount++);
    });
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
      _revealedCount = 0;
    });
    _iconController.reset();
    _iconController.forward();
    final slides = _buildSlides();
    if (page < slides.length) {
      _startRevealing(slides[page].bullets.length);
    }
  }

  void _startFirstSlide(int bulletCount) {
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted && !_exiting) {
        _iconController.forward();
        _startRevealing(bulletCount);
      }
    });
  }

  void _goToNext() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    if (_exiting) return;
    setState(() => _exiting = true);
    _revealTimer?.cancel();

    final mutator = ref.read(settingsMutatorProvider);
    await mutator.completeOnboarding();

    _exitController.forward().then((_) {
      if (mounted) context.go(RouteNames.home);
    });
  }

  List<_SlideData> _buildSlides() {
    final l = AppLocalizations.of(context)!;
    return [
      _SlideData(
        icon: Icons.auto_awesome_rounded,
        title: l.onboardingSlide1Title,
        tagline: l.onboardingSlide1Tagline,
        bullets: [
          l.onboardingSlide1Bullet1,
          l.onboardingSlide1Bullet2,
          l.onboardingSlide1Bullet3,
        ],
      ),
      _SlideData(
        icon: Icons.widgets_rounded,
        title: l.onboardingSlide2Title,
        bulletIcons: const [
          Icons.document_scanner_rounded,
          Icons.play_circle_outline_rounded,
          Icons.folder_special_rounded,
          Icons.restore_from_trash_rounded,
        ],
        bullets: [
          l.onboardingSlide2Bullet1,
          l.onboardingSlide2Bullet2,
          l.onboardingSlide2Bullet3,
          l.onboardingSlide2Bullet4,
        ],
      ),
      _SlideData(
        icon: Icons.verified_user_rounded,
        title: l.onboardingSlide3Title,
        bulletIcons: const [
          Icons.cloud_off_rounded,
          Icons.visibility_off_rounded,
          Icons.code_rounded,
        ],
        bullets: [
          l.onboardingSlide3Bullet1,
          l.onboardingSlide3Bullet2,
          l.onboardingSlide3Bullet3,
        ],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isLastPage = _currentPage == _totalPages - 1;
    final slides = _buildSlides();
    final currentSlide =
        slides[_currentPage < slides.length ? _currentPage : 0];

    return AnimatedBuilder(
      animation: Listenable.merge([_exitScale, _exitFade]),
      builder: (context, child) => Opacity(
        opacity: _exitFade.value,
        child: Transform.scale(scale: _exitScale.value, child: child),
      ),
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  itemCount: _totalPages,
                  itemBuilder: (context, index) {
                    if (index == 0 &&
                        !_iconController.isAnimating &&
                        _revealedCount == 0) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          _startFirstSlide(currentSlide.bullets.length);
                        }
                      });
                    }
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Icon — bounce in with ring
                          AnimatedBuilder(
                            animation: _iconScale,
                            builder: (context, _) => Transform.scale(
                              scale: _iconScale.value,
                              child: Container(
                                width: 96,
                                height: 96,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withValues(alpha: 0.12),
                                  border: Border.all(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withValues(alpha: 0.22),
                                    width: 1.5,
                                  ),
                                ),
                                child: Icon(
                                  currentSlide.icon,
                                  size: 42,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 28),

                          // Title + tagline — fade + slide up
                          AnimatedBuilder(
                            animation:
                                Listenable.merge([_titleFade, _titleSlide]),
                            builder: (context, _) => Opacity(
                              opacity: _titleFade.value,
                              child: SlideTransition(
                                position: _titleSlide,
                                child: Column(
                                  children: [
                                    Text(
                                      currentSlide.title,
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineSmall
                                          ?.copyWith(
                                              fontWeight: FontWeight.bold),
                                    ),
                                    if (currentSlide.tagline != null) ...[
                                      const SizedBox(height: 6),
                                      Text(
                                        currentSlide.tagline!,
                                        textAlign: TextAlign.center,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Bullets
                          _buildBullets(
                              context, currentSlide.bullets, _currentPage,
                              bulletIcons: currentSlide.bulletIcons),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Dots + Button
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: List.generate(_totalPages, (i) {
                        final isActive = i == _currentPage;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(right: 8),
                          width: isActive ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isActive
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant
                                    .withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }),
                    ),
                    FilledButton(
                      onPressed: _goToNext,
                      child: Text(
                        isLastPage
                            ? l10n.onboardingGetStarted
                            : l10n.onboardingNext,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBullets(
    BuildContext context,
    List<String> allBullets,
    int slideIndex, {
    List<IconData>? bulletIcons,
  }) {
    return Column(
      key: ValueKey(slideIndex),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(allBullets.length, (i) {
        final isRevealed = i < _revealedCount;
        return AnimatedSlide(
          duration: const Duration(milliseconds: 380),
          curve: Curves.easeOutCubic,
          offset: isRevealed ? Offset.zero : const Offset(0, 0.3),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: isRevealed ? 1.0 : 0.0,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBulletLeading(
                      context, slideIndex, i, isRevealed, bulletIcons),
                  Expanded(
                    child: Text(
                      allBullets[i],
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                            height: 1.45,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildBulletLeading(
    BuildContext context,
    int slideIndex,
    int bulletIndex,
    bool isRevealed,
    List<IconData>? bulletIcons,
  ) {
    final primary = Theme.of(context).colorScheme.primary;

    switch (slideIndex) {
      // Slide 1 — welcome: simple filled dot
      case 0:
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: 8,
          height: 8,
          margin: const EdgeInsets.only(right: 14, top: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: isRevealed ? primary : Colors.transparent,
          ),
        );

      // Slide 2 — power tools: squircle icon tile
      case 1:
        final icon = bulletIcons != null && bulletIndex < bulletIcons.length
            ? bulletIcons[bulletIndex]
            : Icons.star_outline_rounded;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: 36,
          height: 36,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: isRevealed
                ? primary.withValues(alpha: 0.12)
                : Colors.transparent,
          ),
          child: isRevealed ? Icon(icon, size: 18, color: primary) : null,
        );

      // Slide 3 — privacy: circle icon
      default:
        final icon = bulletIcons != null && bulletIndex < bulletIcons.length
            ? bulletIcons[bulletIndex]
            : Icons.shield_outlined;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: 34,
          height: 34,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(100),
            color: isRevealed
                ? primary.withValues(alpha: 0.12)
                : Colors.transparent,
          ),
          child: isRevealed ? Icon(icon, size: 17, color: primary) : null,
        );
    }
  }
}

class _SlideData {
  final IconData icon;
  final String title;
  final String? tagline;
  final List<String> bullets;
  final List<IconData>? bulletIcons;

  const _SlideData({
    required this.icon,
    required this.title,
    this.tagline,
    required this.bullets,
    this.bulletIcons,
  });
}
