import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});
  final Widget child;

  static const _tabs = [
    _TabItem(icon: Icons.home_outlined,         activeIcon: Icons.home_rounded,
        label: 'Home',    path: '/app/home'),
    _TabItem(icon: Icons.menu_book_outlined,    activeIcon: Icons.menu_book,
        label: 'Library', path: '/app/library'),
    _TabItem(icon: Icons.timeline_outlined,     activeIcon: Icons.timeline,
        label: 'Paths',   path: '/app/module'),
    _TabItem(icon: Icons.code_outlined,         activeIcon: Icons.code,
        label: 'Editor',  path: '/app/editor'),
    _TabItem(icon: Icons.person_outline_rounded,activeIcon: Icons.person_rounded,
        label: 'Profile', path: '/app/profile'),
  ];

  int _currentIndex(BuildContext context) {
    final loc = GoRouterState.of(context).uri.toString();
    if (loc.contains('profile') || loc.contains('settings')) return 4;
    if (loc.contains('editor'))  return 3;
    if (loc.contains('module') || loc.contains('lesson') ||
        loc.contains('quiz'))    return 2;
    if (loc.contains('library')) return 1;
    return 0; // home
  }

  @override
  Widget build(BuildContext context) {
    final idx = _currentIndex(context);
    return Scaffold(
      body: child,
      bottomNavigationBar: _BottomNav(tabs: _tabs, currentIndex: idx),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.tabs, required this.currentIndex});
  final List<_TabItem> tabs;
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer.withValues(alpha: 0.97),
        border: Border(
          top: BorderSide(
              color: AppColors.outlineVariant.withValues(alpha: 0.25)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(tabs.length, (i) {
              return _NavItem(
                tab: tabs[i],
                active: i == currentIndex,
                index: i,
                onTap: () => context.go(tabs[i].path),
              );
            }),
          ),
        ),
      ),
    )
        .animate()
        .slideY(begin: 1, end: 0, duration: 500.ms, curve: Curves.easeOutCubic)
        .fadeIn(duration: 400.ms);
  }
}

class _NavItem extends StatefulWidget {
  const _NavItem({
    required this.tab,
    required this.active,
    required this.index,
    required this.onTap,
  });
  final _TabItem tab;
  final bool active;
  final int index;
  final VoidCallback onTap;

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: 200.ms);
  late final Animation<double> _scale =
      Tween<double>(begin: 1.0, end: 0.88).animate(
    CurvedAnimation(parent: _c, curve: Curves.easeInOut),
  );

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _c.forward(),
      onTapUp: (_) {
        _c.reverse();
        widget.onTap();
      },
      onTapCancel: () => _c.reverse(),
      behavior: HitTestBehavior.opaque,
      child: ScaleTransition(
        scale: _scale,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: widget.active
              ? BoxDecoration(
                  color: AppColors.primaryContainer.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      blurRadius: 12,
                    ),
                  ],
                )
              : null,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, anim) => ScaleTransition(
                  scale: anim,
                  child: child,
                ),
                child: Icon(
                  widget.active ? widget.tab.activeIcon : widget.tab.icon,
                  key: ValueKey(widget.active),
                  color: widget.active
                      ? AppColors.primary
                      : AppColors.onSurfaceVariant,
                  size: 22,
                ),
              ),
              const SizedBox(height: 3),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: AppTextStyles.labelSm(
                  color: widget.active
                      ? AppColors.primary
                      : AppColors.onSurfaceVariant,
                ).copyWith(fontSize: 10),
                child: Text(widget.tab.label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabItem {
  const _TabItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.path,
  });
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String path;
}
