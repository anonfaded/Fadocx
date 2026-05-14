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

  // Slide enter animations
  late final AnimationController _enterController;
  late final Animation<double> _iconScale;
  late final Animation<double> _textFade;
  late final Animation<Offset> _textSlide;

  // Exit animation
  bool _exiting = false;
  late final AnimationController _exitController;
  late final Animation<double> _exitScale;
  late final Animation<double> _exitFade;

  static const _totalPages = 3;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    _enterController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..forward();

    _iconScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _enterController,
        curve: const Interval(0.0, 0.5, curve: Curves.elasticOut),
      ),
    );
    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _enterController,
        curve: const Interval(0.3, 0.7, curve: Curves.easeOut),
      ),
    );
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _enterController,
        curve: const Interval(0.3, 0.7, curve: Curves.easeOutCubic),
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
    _enterController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() => _currentPage = page);
    _enterController.reset();
    _enterController.forward();
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

  void _finish() {
    if (_exiting) return;
    setState(() => _exiting = true);

    final mutator = ref.read(settingsMutatorProvider);
    mutator.updateHasDismissedWelcome(true);
    mutator.updateShowOnboardingNextLaunch(false);

    _exitController.forward().then((_) {
      if (mounted) context.go(RouteNames.home);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isLastPage = _currentPage == _totalPages - 1;

    final slides = [
      _SlideData(
        icon: Icons.security_rounded,
        title: l10n.onboardingSlide1Title,
        description: l10n.onboardingSlide1Desc,
      ),
      _SlideData(
        icon: Icons.folder_special_rounded,
        title: l10n.onboardingSlide2Title,
        description: l10n.onboardingSlide2Desc,
      ),
      _SlideData(
        icon: Icons.phone_android_rounded,
        title: l10n.onboardingSlide3Title,
        description: l10n.onboardingSlide3Desc,
      ),
    ];

    return AnimatedBuilder(
      animation: Listenable.merge([_exitScale, _exitFade]),
      builder: (context, child) {
        return Opacity(
          opacity: _exitFade.value,
          child: Transform.scale(
            scale: _exitScale.value,
            child: child,
          ),
        );
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              // Slides
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  itemCount: _totalPages,
                  itemBuilder: (context, index) {
                    final slide = slides[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Animated icon
                          AnimatedBuilder(
                            animation: _iconScale,
                            builder: (context, _) {
                              return Transform.scale(
                                scale: _iconScale.value,
                                child: Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    slide.icon,
                                    size: 44,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 40),
                          // Animated title + description
                          AnimatedBuilder(
                            animation: Listenable.merge(
                                [_textFade, _textSlide]),
                            builder: (context, _) {
                              return Opacity(
                                opacity: _textFade.value,
                                child: SlideTransition(
                                  position: _textSlide,
                                  child: Column(
                                    children: [
                                      Text(
                                        slide.title,
                                        textAlign: TextAlign.center,
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        slide.description,
                                        textAlign: TextAlign.center,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyLarge
                                            ?.copyWith(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                              height: 1.5,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
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
                    // Dots
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

                    // Next / Get Started button
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
}

class _SlideData {
  final IconData icon;
  final String title;
  final String description;

  const _SlideData({
    required this.icon,
    required this.title,
    required this.description,
  });
}
