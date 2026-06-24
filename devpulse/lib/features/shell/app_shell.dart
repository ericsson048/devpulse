import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/services/api_service.dart';

/// InheritedWidget providing user dashboard data to all child screens.
class UserDataScope extends InheritedWidget {
  const UserDataScope({
    super.key,
    required this.data,
    required super.child,
  });

  final Map<String, dynamic> data;

  static Map<String, dynamic>? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<UserDataScope>()?.data;
  }

  @override
  bool updateShouldNotify(UserDataScope old) => old.data != data;
}

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.child});
  final Widget child;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await ApiService.getHomeDashboard();
      if (mounted) setState(() => _userData = data);
    } catch (_) {}
  }

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

  int _currentIndex(String loc) {
    if (loc.contains('profile') || loc.contains('settings')) { return 4; }
    if (loc.contains('editor')) { return 3; }
    if (loc.contains('module') || loc.contains('lesson') || loc.contains('quiz')) { return 2; }
    if (loc.contains('library')) { return 1; }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final loc = GoRouterState.of(context).uri.toString();
    final idx = _currentIndex(loc);
    final user = _userData;

    return UserDataScope(
      data: _userData ?? {},
      child: Scaffold(
        body: widget.child,
        bottomNavigationBar: _BottomNav(
          tabs: _tabs,
          currentIndex: idx,
          userData: user,
        ),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({
    required this.tabs,
    required this.currentIndex,
    this.userData,
  });
  final List<_TabItem> tabs;
  final int currentIndex;
  final Map<String, dynamic>? userData;

  @override
  Widget build(BuildContext context) {
    final streak = userData?['streak'] as int? ?? 0;
    final xp = userData?['xp'] as int? ?? 0;
    final xpNext = userData?['xp_next_level'] as int? ?? 1000;
    final xpRatio = xpNext > 0 ? (xp / xpNext).clamp(0.0, 1.0) : 0.0;

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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _XpMiniBar(ratio: xpRatio, streak: streak),
            SizedBox(
              height: 64,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(tabs.length, (i) {
                  if (i == 4) {
                    return _NavItem(
                      tab: tabs[i],
                      active: i == currentIndex,
                      index: i,
                      userData: userData,
                      onTap: () => context.go(tabs[i].path),
                    );
                  }
                  return _NavItem(
                    tab: tabs[i],
                    active: i == currentIndex,
                    index: i,
                    onTap: () => context.go(tabs[i].path),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .slideY(begin: 1, end: 0, duration: 500.ms, curve: Curves.easeOutCubic)
        .fadeIn(duration: 400.ms);
  }
}

class _XpMiniBar extends StatelessWidget {
  const _XpMiniBar({required this.ratio, required this.streak});
  final double ratio;
  final int streak;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(1),
              child: Stack(
                children: [
                  Container(
                    height: 2,
                    color: AppColors.outlineVariant.withValues(alpha: 0.2),
                  ),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: ratio),
                    duration: 1000.ms,
                    curve: Curves.easeOutCubic,
                    builder: (_, v, __) => Container(
                      height: 2,
                      width: MediaQuery.of(context).size.width * v,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary.withValues(alpha: 0.6),
                            AppColors.primary,
                            AppColors.neonBlue,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (streak > 0)
            Padding(
              padding: const EdgeInsets.only(left: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.local_fire_department_rounded,
                      size: 12, color: AppColors.neonGold),
                  const SizedBox(width: 2),
                  Text('$streak',
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: AppColors.neonGold,
                        letterSpacing: -0.3,
                      )),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  const _NavItem({
    required this.tab,
    required this.active,
    required this.index,
    this.userData,
    required this.onTap,
  });
  final _TabItem tab;
  final bool active;
  final int index;
  final Map<String, dynamic>? userData;
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
    final isProfile = widget.index == 4;
    final level = widget.userData?['level'] as int?;

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
          padding: EdgeInsets.only(
            left: 14,
            right: 14,
            top: isProfile && level != null ? 4 : 8,
            bottom: isProfile && level != null ? 4 : 8,
          ),
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
              const SizedBox(height: 2),
              if (isProfile && level != null)
                _LevelPill(level: level, active: widget.active)
              else
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

class _LevelPill extends StatelessWidget {
  const _LevelPill({required this.level, required this.active});
  final int level;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: active
            ? AppColors.primary.withValues(alpha: 0.15)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        border: active
            ? Border.all(color: AppColors.primary.withValues(alpha: 0.3))
            : null,
      ),
      child: Text(
        'Lv $level',
        style: TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.w700,
          color: active ? AppColors.primary : AppColors.onSurfaceVariant,
          letterSpacing: 0.3,
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
