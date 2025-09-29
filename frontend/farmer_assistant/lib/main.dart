import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cached_network_image/cached_network_image.dart';
// Removed carousel_slider due to name clash with Flutter 3.22+ material Carousel.
// Using PageController-based carousel implementation instead.
import 'package:confetti/confetti.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'services/state_service.dart';
import 'app_theme.dart';
import 'screens/profile_screen.dart';
import 'screens/policy_screen.dart' as policy;
import 'screens/disease_detection_screen.dart';
import 'widgets/calendar_dropdown.dart';
import 'widgets/loading_screen.dart';
import 'models/api_models.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('hi'), Locale('ta'), Locale('te'), Locale('ml')],
      fallbackLocale: const Locale('en'),
      path: 'assets/translations',
      child: const FarmerAssistantApp(),
    ),
  );
}

class FarmerAssistantApp extends StatelessWidget {
  const FarmerAssistantApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => StateService()..bootstrap(),
      child: Consumer<StateService>(
        builder: (context, stateService, child) {
          return MaterialApp(
            title: 'Pravah',
            theme: AppTheme.light(),
            debugShowCheckedModeBanner: false,
            home: AnimatedSwitcher(
              duration: const Duration(milliseconds: 800),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.0, 0.1),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    )),
                    child: child,
                  ),
                );
              },
              child: stateService.isAppLoading
                  ? const LoadingScreen(key: ValueKey('loading'))
                  : stateService.isAuthenticated
                      ? AppShell(key: const ValueKey('app'))
                      : const LoginScreen(key: ValueKey('login')),
            ),
            locale: context.locale,
            supportedLocales: context.supportedLocales,
            localizationsDelegates: context.localizationDelegates,
          );
        },
      ),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with TickerProviderStateMixin {
  int _index = 0;
  late final AnimationController _fabPulseController;
  late final Animation<double> _fabPulseAnimation;
  OverlayEntry? _greetingEntry;
  final LayerLink _calendarLink = LayerLink();
  final LayerLink _notifLink = LayerLink();
  OverlayEntry? _calendarOverlay;
  OverlayEntry? _notifOverlay;
  bool _isOnGamification = false;
  bool _isChatbotActive = false;
  late final AnimationController _fabTransformController;
  late final Animation<double> _fabScaleAnimation;
  late final Animation<Offset> _fabPositionAnimation;

  @override
  void initState() {
    super.initState();
    _fabPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
      lowerBound: 0.0,
      upperBound: 1.0,
    )..repeat(reverse: true);
    _fabPulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fabPulseController, curve: Curves.easeInOut),
    );

    _fabTransformController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fabScaleAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _fabTransformController, curve: Curves.easeInOut),
    );
    _fabPositionAnimation = Tween<Offset>(
      begin: const Offset(0, 0),
      end: const Offset(0, 0),
    ).animate(
      CurvedAnimation(parent: _fabTransformController, curve: Curves.easeInOut),
    );

    // Show greeting bubble after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showGreetingBubble();
    });
  }

  @override
  void dispose() {
    _fabPulseController.dispose();
    _fabTransformController.dispose();
    _removeGreetingBubble();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<StateService>(
      builder: (context, stateService, child) {
        final screens = [
          HomeScreen(),
          const policy.PolicyScreen(),
          UpdatesScreen(),
          DiseaseDetectionScreen(),
        ];

    return Scaffold(
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(72),
            child: _TopBar(
              userProfile: stateService.userProfile,
              onProfileTap: () => _showProfile(context, stateService),
              calendarTargetLink: _calendarLink,
              notifTargetLink: _notifLink,
              onCalendarTap: () => _toggleCalendarDropdown(stateService),
              onPointsTap: () {
                setState(() => _isOnGamification = true);
                Navigator.of(context)
                    .push(MaterialPageRoute(builder: (_) => const GamificationScreen()))
                    .then((_) => setState(() => _isOnGamification = false));
              },
              onNotificationsTap: _toggleNotificationsDropdown,
              isCalendarOpen: _calendarOverlay != null,
              isNotificationsOpen: _notifOverlay != null,
              isOnGamification: _isOnGamification,
            ),
          ),
          body: SafeArea(child: screens[_index]),
          floatingActionButtonLocation: const _CenterBorderFabLocation(),
          floatingActionButton: AnimatedBuilder(
            animation: _fabTransformController,
            builder: (context, child) {
              if (_isChatbotActive) {
                // FAB is shrinking/hidden when chatbot is active
                return Transform.scale(
                  scale: _fabScaleAnimation.value,
                  child: Opacity(
                    opacity: 1.0 - _fabScaleAnimation.value,
                    child: _GradientFab(onPressed: () {}),
                  ),
                );
              } else {
                // Normal FAB with pulse animation
                final pulseScale = 0.96 + (_fabPulseAnimation.value * 0.08);
                return Transform.scale(
                  scale: pulseScale,
                  child: _GradientFab(onPressed: () => _showChatbot(context)),
                );
              }
            },
          ),
          bottomNavigationBar: BottomAppBar(
            shape: const CircularNotchedRectangle(),
            child: Container(
              height: 64,
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: AppColors.neutralGray, width: 1),
                ),
              ),
              child: Row(
                mainAxisAlignment: _isChatbotActive 
                    ? MainAxisAlignment.spaceEvenly 
                    : MainAxisAlignment.spaceAround,
                children: [
                  _BottomNavItem(
                    icon: Icons.route,
                    active: _index == 0,
                    activeColor: AppColors.green,
                    inactiveColor: AppColors.brownDark,
                    tooltip: 'Home',
                    onPressed: () => setState(() => _index = 0),
                  ),
                  _BottomNavItem(
                    icon: Icons.policy,
                    active: _index == 1,
                    activeColor: AppColors.green,
                    inactiveColor: AppColors.mustardDark,
                    tooltip: 'Policy',
                    onPressed: () => setState(() => _index = 1),
                  ),
                  if (!_isChatbotActive) const SizedBox(width: 48),
                  _BottomNavItem(
                    icon: Icons.trending_up,
                    active: _index == 2,
                    activeColor: AppColors.green,
                    inactiveColor: AppColors.brown,
                    tooltip: 'Market Updates',
                    onPressed: () => setState(() => _index = 2),
                  ),
                  _BottomNavItem(
                    icon: Icons.bug_report,
                    active: _index == 3,
                    activeColor: AppColors.green,
                    inactiveColor: AppColors.mustard,
                    tooltip: 'Disease',
                    onPressed: () => setState(() => _index = 3),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }


  void _showProfile(BuildContext context, StateService stateService) {
    final user = stateService.userProfile;
    final farm = stateService.farmProfile;
    if (user != null && farm != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProfileScreen(userProfile: user, farmProfile: farm),
        ),
      );
      return;
    }
    // Mock profile fallback
    final mockUser = UserProfile(
      userId: 'mock_user',
      name: 'Farmer Dev',
      phone: '+91 90000 00000',
      language: 'en',
      farmProfileId: 'mock_farm',
      aadhaarHash: 'XXXX-XXXX-XXXX',
      uniqueFarmId: 'FARM-123456',
      uniqueFarmerId: 'FRMR-654321',
    );
    final mockFarm = FarmProfile(
      farmId: 'mock_farm',
      userId: 'mock_user',
      state: 'Kerala',
      district: 'Ernakulam',
      lat: 9.9816,
      lng: 76.2999,
      soilType: 'Loamy',
      area: 2.5,
      waterLevel: 'Medium',
      primaryCrop: 'Rice',
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileScreen(userProfile: mockUser, farmProfile: mockFarm),
      ),
    );
  }

  void _toggleCalendarDropdown(StateService stateService) {
    if (_calendarOverlay != null) {
      _calendarOverlay!.remove();
      _calendarOverlay = null;
      return;
    }
    final overlay = Overlay.of(context);
    if (overlay == null) return;
    _calendarOverlay = OverlayEntry(
      builder: (_) => Positioned.fill(
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => _toggleCalendarDropdown(stateService),
          child: Stack(children: [
            CompositedTransformFollower(
              link: _calendarLink,
              offset: const Offset(-120, 60),
              child: Material(
                color: Colors.transparent,
                child: CalendarDropdown(
                  tasks: stateService.tasks,
                  onDateSelected: (_) {},
                  onTaskComplete: (taskId) => stateService.markTaskComplete(taskId),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
    overlay.insert(_calendarOverlay!);
  }

  void _toggleNotificationsDropdown() {
    if (_notifOverlay != null) {
      _notifOverlay!.remove();
      _notifOverlay = null;
      return;
    }
    final overlay = Overlay.of(context);
    if (overlay == null) return;
    _notifOverlay = OverlayEntry(
      builder: (_) => Positioned.fill(
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: _toggleNotificationsDropdown,
          child: Stack(children: [
            CompositedTransformFollower(
              link: _notifLink,
              offset: const Offset(-240, 60),
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 320,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _NotifSection(title: 'notifications.policy'.tr()),
                      const SizedBox(height: 8),
                      _NotifSection(title: 'notifications.weather'.tr()),
                      const SizedBox(height: 8),
                      _NotifSection(title: 'notifications.disaster'.tr()),
                    ],
                  ),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
    overlay.insert(_notifOverlay!);
  }

  void _showChatbot(BuildContext context) {
    setState(() {
      _isChatbotActive = true;
    });

    // 1) Show overlay immediately with slide-up
    _showChatbotOverlay(context, voiceDelayMs: 1500);

    // 2) After 500ms, shrink FAB
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _fabTransformController.forward();
      }
    });
  }

  void _showChatbotOverlay(BuildContext context, {int voiceDelayMs = 200}) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 0,
        left: 0,
        right: 0,
        bottom: 80, // Leave space for bottom navigation bar
        child: ChatbotOverlay(
          voiceDelayMs: voiceDelayMs,
          onClose: () {
            overlayEntry.remove();
            if (mounted) {
              _fabTransformController.reverse().then((_) {
                if (mounted) {
                  setState(() {
                    _isChatbotActive = false;
                  });
                }
              });
            }
          },
        ),
      ),
    );

    overlay.insert(overlayEntry);
  }

  void _showGreetingBubble() {
    // Show for ~2 seconds only once
    _removeGreetingBubble();
    final overlay = Overlay.of(context);
    if (overlay == null) return;

    final renderBox = context.findRenderObject() as RenderBox?;
    final size = renderBox?.size ?? MediaQuery.of(context).size;

    _greetingEntry = OverlayEntry(
      builder: (context) {
        return Positioned(
          bottom: 64 + 72 + 12, // above bottom bar and FAB
          left: size.width * 0.5 - 120,
          child: _GreetingBubble(),
        );
      },
    );
    overlay.insert(_greetingEntry!);
    Future.delayed(const Duration(seconds: 2), _removeGreetingBubble);
  }

  void _removeGreetingBubble() {
    _greetingEntry?.remove();
    _greetingEntry = null;
  }

}

class _CenterBorderFabLocation extends FloatingActionButtonLocation {
  const _CenterBorderFabLocation();

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    final fabSize = scaffoldGeometry.floatingActionButtonSize;
    final contentWidth = scaffoldGeometry.scaffoldSize.width;
    final fabX = (contentWidth - fabSize.width) / 2;
    // Approximate BottomAppBar height (matches our SizedBox/Container height)
    const bottomBarHeight = 64.0;
    final scaffoldHeight = scaffoldGeometry.scaffoldSize.height;
    // Place FAB so its center lies on the top border of BottomAppBar
    final fabY = scaffoldHeight - bottomBarHeight - (fabSize.height / 2);
    return Offset(fabX, fabY);
  }
}

class _GreetingBubble extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        builder: (context, value, child) {
          return Transform.scale(
            scale: 0.96 + 0.04 * value,
            child: Opacity(opacity: value, child: child),
          );
        },
        child: Container(
          width: 240,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.smart_toy, color: Color(0xFF12D8A5)),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Hi! I can help with tasks, policies and crop issues.',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GradientFab extends StatelessWidget {
  final VoidCallback onPressed;
  const _GradientFab({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      height: 72,
      child: RawMaterialButton(
        onPressed: onPressed,
        shape: const CircleBorder(),
        elevation: 6,
        fillColor: Colors.transparent,
        child: Ink(
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [AppColors.green, AppColors.mustard],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const Center(
            child: Icon(Icons.smart_toy, color: Colors.white, size: 28),
          ),
        ),
      ),
    );
  }
}

class _NotifSection extends StatelessWidget {
  final String title;
  const _NotifSection({required this.title});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.circle, size: 8, color: Colors.green),
          title: Text('notif.sample'.tr()),
        ),
      ],
    );
  }
}

class GamificationScreen extends StatefulWidget {
  const GamificationScreen({super.key});

  @override
  State<GamificationScreen> createState() => _GamificationScreenState();
}

class _GamificationScreenState extends State<GamificationScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch leaderboard on open
    Future.microtask(() {
      final state = context.read<StateService>();
      state.fetchLeaderboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<StateService>(
      builder: (context, state, _) {
        final entries = state.leaderboard;
        final top10 = entries.take(10).toList();
        final meId = state.userProfile?.userId ?? '';
        final myEntry = entries.firstWhere(
          (e) => e.userId == meId,
          orElse: () => entries.isNotEmpty
              ? entries.last
              : LeaderboardEntry(
                  userId: meId, 
                  name: state.userProfile?.name ?? 'You', 
                  points: state.totalPoints, 
                  rank: 0,
                  level: 'Beginner',
                  badge: 'Rising',
                  village: state.farmProfile?.district ?? 'Unknown',
                  state: state.farmProfile?.state ?? 'Unknown',
                  tasksCompleted: state.tasks.where((t) => t.status == 'done').length,
                  streak: state.weeklyStreak,
                ),
        );

        return Scaffold(
          appBar: AppBar(title: Text('leaderboard.title'.tr())),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'leaderboard.top_10'.tr(),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: top10.isEmpty
                      ? Center(child: Text('leaderboard.empty'.tr()))
                      : ListView.separated(
                          itemCount: top10.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final item = top10[index];
                            return _LeaderboardTile(entry: item, highlight: true);
                          },
                        ),
                ),
                const SizedBox(height: 8),
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  'leaderboard.your_position'.tr(),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                _LeaderboardTile(entry: myEntry, highlight: true, emphasizeSelf: true),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LeaderboardTile extends StatelessWidget {
  final LeaderboardEntry entry;
  final bool highlight;
  final bool emphasizeSelf;
  const _LeaderboardTile({required this.entry, this.highlight = false, this.emphasizeSelf = false});

  @override
  Widget build(BuildContext context) {
    final rank = entry.rank;
    final isTop3 = rank == 1 || rank == 2 || rank == 3;
    final bgColor = isTop3
        ? (rank == 1
            ? const Color(0xFFFFF8E1) // gold tint
            : rank == 2
                ? const Color(0xFFE3F2FD) // silver/blue tint
                : const Color(0xFFFFF3E0)) // bronze/orange tint
        : (highlight ? Colors.green.withOpacity(0.06) : Colors.white);
    final borderColor = isTop3 ? Colors.amber : (highlight ? Colors.green.withOpacity(0.2) : Colors.grey.withOpacity(0.2));

    return Container
    (
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          _RankMedal(rank: rank),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: isTop3 || emphasizeSelf ? FontWeight.w700 : FontWeight.w600,
                          color: emphasizeSelf ? Colors.green.shade800 : Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${entry.points} ${'leaderboard.points'.tr()}',
                  style: TextStyle(
                    fontSize: 12,
                    color: emphasizeSelf ? Colors.green.shade700 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isTop3 ? Colors.amber.withOpacity(0.15) : Colors.black.withOpacity(0.06),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isTop3 ? Colors.amber : Colors.black12),
            ),
            child: Text(
              '#${entry.rank}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isTop3 ? Colors.amber.shade800 : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RankMedal extends StatelessWidget {
  final int rank;
  const _RankMedal({required this.rank});

  @override
  Widget build(BuildContext context) {
    IconData icon = Icons.emoji_events;
    Color color;
    switch (rank) {
      case 1:
        color = const Color(0xFFFFD700); // gold
        break;
      case 2:
        color = const Color(0xFFC0C0C0); // silver
        break;
      case 3:
        color = const Color(0xFFCD7F32); // bronze
        break;
      default:
        color = Colors.green;
    }

    return CircleAvatar(
      radius: 20,
      backgroundColor: color.withOpacity(0.15),
      child: Icon(icon, color: color, size: 20),
    );
  }
}

class _TopBar extends StatelessWidget {
  final UserProfile? userProfile;
  final VoidCallback onProfileTap;
  final VoidCallback onCalendarTap;
  final VoidCallback onPointsTap;
  final VoidCallback onNotificationsTap;
  final LayerLink calendarTargetLink;
  final LayerLink notifTargetLink;
  final bool isCalendarOpen;
  final bool isNotificationsOpen;
  final bool isOnGamification;

  const _TopBar({
    super.key,
    this.userProfile,
    required this.onProfileTap,
    required this.onCalendarTap,
    required this.onPointsTap,
    required this.onNotificationsTap,
    required this.calendarTargetLink,
    required this.notifTargetLink,
    required this.isCalendarOpen,
    required this.isNotificationsOpen,
    required this.isOnGamification,
  });

  @override
  Widget build(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(72),
      child: AppBar(
        elevation: 2,
        backgroundColor: Colors.white,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.neutralDark.withOpacity(0.12)),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _TopIcon(
              icon: Icons.person,
              color: AppColors.green,
              active: false,
              onPressed: onProfileTap,
              tooltip: 'Profile',
            ),
            CompositedTransformTarget(
              link: calendarTargetLink,
              child: _TopIcon(
                icon: Icons.calendar_month,
                color: AppColors.mustardDark,
                active: isCalendarOpen,
                onPressed: onCalendarTap,
                tooltip: 'Calendar',
              ),
            ),
            _TopIcon(
              icon: Icons.emoji_events,
              color: AppColors.green,
              active: isOnGamification,
              onPressed: onPointsTap,
              tooltip: 'Points',
            ),
            CompositedTransformTarget(
              link: notifTargetLink,
              child: Stack(
                children: [
                  _TopIcon(
                    icon: Icons.notifications,
                    color: AppColors.brown,
                    active: isNotificationsOpen,
                    onPressed: onNotificationsTap,
                    tooltip: 'Notifications',
                  ),
                  Positioned(
                    right: 10,
                    top: 10,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(color: AppColors.mustard, shape: BoxShape.circle),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  final IconData icon;
  final bool active;
  final Color activeColor;
  final Color inactiveColor;
  final VoidCallback onPressed;
  final String tooltip;

  const _BottomNavItem({
    required this.icon,
    required this.active,
    required this.activeColor,
    required this.inactiveColor,
    required this.onPressed,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(icon, color: active ? activeColor : inactiveColor),
          onPressed: onPressed,
          tooltip: tooltip,
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          height: 3,
          width: active ? 16 : 0,
          decoration: BoxDecoration(
            color: activeColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }
}

class _TopIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final bool active;
  final VoidCallback onPressed;
  final String tooltip;

  const _TopIcon({
    required this.icon,
    required this.color,
    required this.active,
    required this.onPressed,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: onPressed,
          tooltip: tooltip,
          icon: Icon(icon, color: active ? AppColors.green : color),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          height: 3,
          width: active ? 16 : 0,
          decoration: BoxDecoration(
            color: AppColors.green,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }
}

class _ConcavePainter extends CustomPainter {
  final Color barColor;
  final Color shadowColor;
  final double notchCenterX;
  final double notchRadius;

  _ConcavePainter({
    required this.barColor,
    required this.shadowColor,
    required this.notchCenterX,
    required this.notchRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rectPath = Path();
    rectPath.addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    // Concave notch along bottom edge
    final notchPath = Path();
    final center = Offset(notchCenterX, size.height);
    notchPath.addOval(Rect.fromCircle(center: center, radius: notchRadius));

    final paint = Paint()..color = barColor;

    // Draw shadow for notch
    final shadowPaint = Paint()
      ..color = shadowColor
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    final shadowPath = Path.combine(PathOperation.intersect, rectPath, notchPath);
    canvas.save();
    canvas.translate(0, 2); // subtle drop
    canvas.drawPath(shadowPath, shadowPaint);
    canvas.restore();

    // Cut the notch out of bar
    final barWithNotch = Path.combine(PathOperation.difference, rectPath, notchPath);
    canvas.drawPath(barWithNotch, paint);
  }

  @override
  bool shouldRepaint(covariant _ConcavePainter oldDelegate) {
    return oldDelegate.barColor != barColor ||
        oldDelegate.shadowColor != shadowColor ||
        oldDelegate.notchCenterX != notchCenterX ||
        oldDelegate.notchRadius != notchRadius;
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<StateService>(
      builder: (context, stateService, child) {
        final hasRoadmap = stateService.hasRoadmap;
        return Container(
          color: Colors.grey[100],
          child: ListView(
            padding: const EdgeInsets.only(bottom: 80, top: 12),
            children: [
              if (!hasRoadmap)
                _GenerateRoadmapCard(onGenerate: stateService.generateRoadmap)
              else ...[
                _TodaysTaskCardV2(tasks: stateService.tasks),
                _QuickCheckCardV2(),
                _ProgressCardV2(
                  yearlyPercent: 62,
                  checkpoints: const ['roadmap.sowing', 'roadmap.growth', 'roadmap.fertilizing', 'roadmap.harvesting'],
                  current: stateService.roadmapPhase.isEmpty ? 'roadmap.sowing'.tr() : stateService.roadmapPhase,
                ),
                _VisualInsightsCardV2(waterUsage: 0.72, cropHealth: const [0.8, 0.65, 0.9, 0.7]),
                const SizedBox(height: 16),
              ],
            ],
          ),
        );
      },
    );
  }
}

class UpdatesScreen extends StatelessWidget {
  const UpdatesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<StateService>(
      builder: (context, stateService, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text('updates.title'.tr()),
            backgroundColor: Colors.white,
            elevation: 2,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 80),
            child: Column(
              children: [
                const SizedBox(height: 12),
                _WeatherTipCard(
                  weatherData: stateService.weatherData,
                  roadmapPhase: stateService.roadmapPhase,
                ),
                _MarketTrendsCard(),
                _OrganicFertilizersCard(),
                _SustainabilityTipCard(
                  currentTask: stateService.tasks.isNotEmpty ? stateService.tasks.first : null,
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }
}

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(child: Text('progress.roadmap'.tr()));
  }
}

// Weather Tip Card
class _WeatherTipCard extends StatelessWidget {
  final WeatherData? weatherData;
  final String roadmapPhase;
  
  const _WeatherTipCard({
    required this.weatherData,
    required this.roadmapPhase,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Background image
          Container(
            height: 200,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: NetworkImage('https://images.unsplash.com/photo-1504608524841-42fe6f032b4b?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Gradient overlay
          Container(
            height: 200,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.3),
                  Colors.black.withOpacity(0.7),
                ],
              ),
            ),
          ),
          // Content
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.wb_sunny, color: Colors.white, size: 24),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _getWeatherCondition(weatherData?.current.condition ?? 'Sunny'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${weatherData?.current.tempC?.round() ?? 28}°C',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getWeatherTip(roadmapPhase, weatherData?.current.condition),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getWeatherTip(String phase, String? condition) {
    if (condition?.toLowerCase().contains('rain') == true) {
      return 'weather.tips.rain'.tr(namedArgs: {'phase': phase});
    } else if (condition?.toLowerCase().contains('sun') == true) {
      return 'weather.tips.sun'.tr(namedArgs: {'phase': phase});
    } else {
      return 'weather.tips.default'.tr(namedArgs: {'phase': phase});
    }
  }

  String _getWeatherCondition(String condition) {
    final lowerCondition = condition.toLowerCase();
    if (lowerCondition.contains('sun') || lowerCondition.contains('clear')) {
      return 'weather.conditions.sunny'.tr();
    } else if (lowerCondition.contains('rain') || lowerCondition.contains('shower')) {
      return 'weather.conditions.rainy'.tr();
    } else if (lowerCondition.contains('cloud')) {
      return 'weather.conditions.cloudy'.tr();
    } else {
      return 'weather.conditions.unknown'.tr();
    }
  }
}

// Market Trends Card
class _MarketTrendsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.trending_up, color: Colors.green, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'market.price_trends'.tr(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'market.region'.tr(),
                      style: const TextStyle(
                        color: Colors.green,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildPriceItem('market.crops.rice_basmati'.tr(), '₹2,850', '+5.2%', Colors.green),
            _buildPriceItem('market.crops.coconut'.tr(), '₹8,500', '+2.1%', Colors.green),
            _buildPriceItem('market.crops.spices_cardamom'.tr(), '₹1,200', '-1.8%', Colors.red),
            _buildPriceItem('market.crops.rubber'.tr(), '₹180', '+3.5%', Colors.green),
            _buildPriceItem('market.crops.tea'.tr(), '₹220', '+0.8%', Colors.green),
            const SizedBox(height: 12),
            Text(
              'market.tip'.tr(),
              style: TextStyle(
                color: Colors.green.shade700,
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceItem(String crop, String price, String change, Color changeColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              crop,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Text(
            price,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: changeColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              change,
              style: TextStyle(
                color: changeColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Organic Fertilizers Card
class _OrganicFertilizersCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Background image
          Container(
            height: 180,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: NetworkImage('https://images.unsplash.com/photo-1574943320219-553eb213f72d?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Gradient overlay
          Container(
            height: 180,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.2),
                  Colors.black.withOpacity(0.6),
                ],
              ),
            ),
          ),
          // Content
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.eco, color: Colors.white, size: 24),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'organic.title'.tr(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'organic.neem_pesticides'.tr(),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'organic.compost_tea'.tr(),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Sustainability Tip Card
class _SustainabilityTipCard extends StatelessWidget {
  final Task? currentTask;
  
  const _SustainabilityTipCard({required this.currentTask});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.eco, color: Colors.green, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'sustainability.title'.tr(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'sustainability.today_task'.tr(),
                      style: const TextStyle(
                        color: Colors.green,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (currentTask != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'sustainability.current_task'.tr(namedArgs: {'task': currentTask!.title}),
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.green,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getSustainabilityTip(currentTask!.title),
                      style: const TextStyle(fontSize: 14),
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'sustainability.setup_message'.tr(),
                  style: const TextStyle(fontSize: 14),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getSustainabilityTip(String taskTitle) {
    if (taskTitle.toLowerCase().contains('irrigation')) {
      return 'sustainability.tips.irrigation'.tr();
    } else if (taskTitle.toLowerCase().contains('pest')) {
      return 'sustainability.tips.pest'.tr();
    } else if (taskTitle.toLowerCase().contains('fertiliz')) {
      return 'sustainability.tips.fertilizer'.tr();
    } else {
      return 'sustainability.tips.default'.tr();
    }
  }
}

class DiseaseScreen extends StatelessWidget {
  const DiseaseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(child: Text('disease.title'.tr()));
  }
}

class WeatherCard extends StatelessWidget {
  final WeatherData? weatherData;
  final bool loading;
  final VoidCallback onRefresh;

  const WeatherCard({
    super.key,
    this.weatherData,
    required this.loading,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, (1 - value) * 12),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(
            colors: [AppColors.green, AppColors.mustard],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        margin: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: loading
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : Row(
                  children: [
                    SvgPicture.asset(
                      'assets/svg/ic_weather_sun.svg',
                      width: 48,
                      height: 48,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${weatherData?.current.tempC.toStringAsFixed(0) ?? '--'}°C • ${_getWeatherCondition(weatherData?.current.condition ?? 'Unknown')}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            weatherData?.current.advice ?? 'weather.no_advice'.tr(),
                            style: const TextStyle(fontSize: 14, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: onRefresh,
                      icon: const Icon(Icons.refresh, color: Colors.white),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  String _getWeatherCondition(String condition) {
    final lowerCondition = condition.toLowerCase();
    if (lowerCondition.contains('sun') || lowerCondition.contains('clear')) {
      return 'weather.conditions.sunny'.tr();
    } else if (lowerCondition.contains('rain') || lowerCondition.contains('shower')) {
      return 'weather.conditions.rainy'.tr();
    } else if (lowerCondition.contains('cloud')) {
      return 'weather.conditions.cloudy'.tr();
    } else {
      return 'weather.conditions.unknown'.tr();
    }
  }

  IconData _getWeatherIcon(String condition) {
    switch (condition.toLowerCase()) {
      case 'sunny':
        return Icons.wb_sunny;
      case 'cloudy':
        return Icons.cloud;
      case 'rain':
        return Icons.grain;
      default:
        return Icons.wb_sunny;
    }
  }
}

class TodayTasks extends StatelessWidget {
  final List<Task> tasks;
  final Function(String) onTaskComplete;

  const TodayTasks({
    super.key,
    required this.tasks,
    required this.onTaskComplete,
  });

  @override
  Widget build(BuildContext context) {
    final todayTasks = tasks.where((task) {
      final today = DateTime.now();
      return task.date.year == today.year &&
          task.date.month == today.month &&
          task.date.day == today.day;
    }).toList();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Today\'s tasks',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () {},
                  child: Text('common.view_all'.tr()),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (todayTasks.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'No tasks for today!',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              ...todayTasks.map((task) => _AnimatedTaskTile(
                    task: task,
                    onComplete: () => onTaskComplete(task.taskId),
                  )),
          ],
        ),
      ),
    );
  }
}

class _AnimatedTaskTile extends StatefulWidget {
  final Task task;
  final VoidCallback onComplete;

  const _AnimatedTaskTile({required this.task, required this.onComplete});

  @override
  State<_AnimatedTaskTile> createState() => _AnimatedTaskTileState();
}

class _AnimatedTaskTileState extends State<_AnimatedTaskTile> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fade;
  late Animation<Offset> _slide;
  late ConfettiController _confetti;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween(begin: const Offset(0, 0.05), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
    _confetti = ConfettiController(duration: const Duration(milliseconds: 700));
  }

  @override
  void dispose() {
    _controller.dispose();
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Stack(
          children: [
            ListTile(
              leading: Icon(
                task.status == 'done' ? Icons.check_circle : Icons.radio_button_unchecked,
                color: task.status == 'done' ? Colors.green : Colors.grey,
              ),
              title: Text(
                task.title,
                style: TextStyle(
                  decoration: task.status == 'done' ? TextDecoration.lineThrough : null,
                ),
              ),
              subtitle: Text('task.priority'.tr(namedArgs: {'p': task.priority})),
              trailing: task.status == 'pending'
                  ? ElevatedButton(
                      onPressed: () {
                        widget.onComplete();
                        _confetti.play();
                        final messenger = ScaffoldMessenger.of(context);
                        messenger.clearSnackBars();
                        messenger.clearMaterialBanners();
                        messenger.showMaterialBanner(
                          MaterialBanner(
                            backgroundColor: AppColors.greenLight,
                            leading: const Icon(Icons.check_circle, color: Colors.white),
                            content: const Text(
                              'Task marked done! +5 points',
                              style: TextStyle(color: Colors.white),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => messenger.hideCurrentMaterialBanner(),
                                child: Text('common.dismiss'.tr(), style: const TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        );
                        Future.delayed(const Duration(seconds: 2), () {
                          if (mounted) messenger.hideCurrentMaterialBanner();
                        });
                      },
                      child: Text('task.mark_done'.tr()),
                    )
                  : const Icon(Icons.check, color: Colors.green),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConfettiWidget(
                    confettiController: _confetti,
                    blastDirectionality: BlastDirectionality.explosive,
                    emissionFrequency: 0.0,
                    numberOfParticles: 16,
                    gravity: 0.9,
                    shouldLoop: false,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Removed QuickActionsChips per request

class _GenerateRoadmapCard extends StatelessWidget {
  final Future<void> Function() onGenerate;
  const _GenerateRoadmapCard({required this.onGenerate});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Background image
          Container(
            height: 200,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: NetworkImage('https://images.unsplash.com/photo-1500937386664-56d1dfef3854?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=2070&q=80'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Gradient overlay
          Container(
            height: 200,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.3),
                  Colors.black.withOpacity(0.7),
                ],
              ),
            ),
          ),
          // Content
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'roadmap.create_title'.tr(), 
                    style: TextStyle(
                      fontWeight: FontWeight.bold, 
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'roadmap.create_sub'.tr(),
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: onGenerate,
                    icon: const Icon(Icons.route),
                    label: Text('roadmap.generate'.tr()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// New Home Cards V2
class _CardShell extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? margin;
  const _CardShell({required this.child, this.margin});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 6)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

class _HeaderImage extends StatelessWidget {
  final String url;
  final double height;
  const _HeaderImage({required this.url, this.height = 160});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SizedBox(
          height: height,
          width: double.infinity,
          child: CachedNetworkImage(
            imageUrl: url,
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(color: Colors.grey.shade200),
            errorWidget: (_, __, ___) => Container(color: Colors.grey.shade300),
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black.withOpacity(0.05), Colors.black.withOpacity(0.45)],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TodaysTaskCardV2 extends StatelessWidget {
  final List<Task> tasks;
  const _TodaysTaskCardV2({required this.tasks});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final todayTasks = tasks.where((t) => t.date.year == today.year && t.date.month == today.month && t.date.day == today.day).toList();
    final task = todayTasks.isNotEmpty ? todayTasks.first : null;

    return _CardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _HeaderImage(
            url: 'https://images.unsplash.com/photo-1500937386664-56d1dfef3854?auto=format&fit=crop&w=1200&q=80',
            height: 160,
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('home.todays_task'.tr(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF2E8B57))),
                const SizedBox(height: 6),
                Text(
                  task?.title ?? 'home.no_task'.tr(),
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickCheckCardV2 extends StatefulWidget {
  @override
  State<_QuickCheckCardV2> createState() => _QuickCheckCardV2State();
}

class _QuickCheckCardV2State extends State<_QuickCheckCardV2> {
  final Map<int, String> _answers = {};
  late final PageController _controller;
  final TextEditingController _textController = TextEditingController();
  bool _done = false;

  final List<String> _questionsKeys = const [
    'home.q1',
    'home.q2',
    'home.q3'
  ];

  @override
  void initState() {
    super.initState();
    _controller = PageController();
  }

  @override
  void dispose() {
    _controller.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final questions = _questionsKeys.map((k) => k.tr()).toList();
    final totalPages = questions.length + 2; // narration + done
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      child: _CardShell(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          color: _done ? Colors.grey.shade100 : Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Text('home.quick_check'.tr(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF795548))),
                const SizedBox(height: 12),
                SizedBox(
                  height: 200,
                  child: PageView.builder(
                    controller: _controller,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: totalPages,
                    itemBuilder: (context, index) {
                    if (index < questions.length) {
                      return _questionPage(index, questions[index]);
                    } else if (index == questions.length) {
                      return _narrationPage();
                    } else {
                      return _donePage();
                    }
                  },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _questionPage(int index, String text) {
    final selected = _answers[index];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(text, style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 12),
        Row(
          children: [
            _choiceButton(index, 'common.yes'.tr(), selected == 'common.yes'.tr(), const Color(0xFF4CAF50)),
            const SizedBox(width: 8),
            _choiceButton(index, 'common.no'.tr(), selected == 'common.no'.tr(), const Color(0xFFFFC107)),
          ],
        ),
        const Spacer(),
        Align(
          alignment: Alignment.centerRight,
          child: OutlinedButton.icon(
            onPressed: () => _controller.nextPage(duration: const Duration(milliseconds: 250), curve: Curves.easeOut),
            icon: const Icon(Icons.arrow_forward),
            label: Text('common.next'.tr()),
          ),
        ),
      ],
    );
  }

  Widget _narrationPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('home.tell'.tr()),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _textController,
                decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                minLines: 2,
                maxLines: 4,
              ),
            ),
            IconButton(onPressed: () {}, icon: const Icon(Icons.mic)),
          ],
        ),
        const Spacer(),
        Align(
          alignment: Alignment.centerRight,
          child: OutlinedButton.icon(
            onPressed: () => _controller.nextPage(duration: const Duration(milliseconds: 250), curve: Curves.easeOut),
            icon: const Icon(Icons.arrow_forward),
            label: Text('common.next'.tr()),
          ),
        ),
      ],
    );
  }

  Widget _donePage() {
    return Stack(
      children: [
        Center(
          child: ElevatedButton.icon(
            onPressed: () async {
              if (_done) return;
              setState(() => _done = true);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('toast.done'.tr())));
            },
            icon: const Icon(Icons.check),
            label: Text('home.mark_done'.tr()),
          ),
        ),
      ],
    );
  }

  Widget _choiceButton(int index, String label, bool active, Color color) {
    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        margin: const EdgeInsets.only(right: 6),
        child: OutlinedButton(
          onPressed: () => setState(() => _answers[index] = label),
          style: OutlinedButton.styleFrom(
            foregroundColor: active ? Colors.white : color,
            backgroundColor: active ? color : Colors.white,
            side: BorderSide(color: color),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          child: Text(label, textAlign: TextAlign.center),
        ),
      ),
    );
  }
}

class _ProgressCardV2 extends StatelessWidget {
  final int yearlyPercent; // 0-100
  final List<String> checkpoints;
  final String current;
  const _ProgressCardV2({required this.yearlyPercent, required this.checkpoints, required this.current});

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _HeaderImage(
            url: 'https://images.unsplash.com/photo-1416879595882-3373a0480b5b?auto=format&fit=crop&w=1200&q=80',
            height: 140,
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Text('home.yearly_progress'.tr(args: ['$yearlyPercent']), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: const Color(0xFF4CAF50).withOpacity(0.1), borderRadius: BorderRadius.circular(999)),
                  child: Text('home.growing'.tr(), style: const TextStyle(color: Color(0xFF4CAF50))),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: _VerticalTimeline(checkpoints: checkpoints, current: current),
          ),
        ],
      ),
    );
  }
}

class _VerticalTimeline extends StatelessWidget {
  final List<String> checkpoints;
  final String current;
  const _VerticalTimeline({required this.checkpoints, required this.current});

  @override
  Widget build(BuildContext context) {
    final currentIndex = checkpoints.indexOf(current).clamp(0, checkpoints.length - 1);
    return Column(
      children: List.generate(checkpoints.length, (i) {
        final isCompleted = i < currentIndex;
        final isActive = i == currentIndex;
        final color = isActive ? const Color(0xFF4CAF50) : (isCompleted ? const Color(0xFF795548) : Colors.grey);
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                if (i != checkpoints.length - 1)
                  Container(width: 2, height: 36, color: isCompleted ? color : Colors.grey.shade300),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isActive ? const Color(0xFF4CAF50).withOpacity(0.08) : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                  border: isActive ? Border.all(color: const Color(0xFF4CAF50)) : null,
                ),
                child: Row(
                  children: [
                    Icon(isCompleted ? Icons.check_circle : (isActive ? Icons.radio_button_checked : Icons.radio_button_unchecked), color: color, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(checkpoints[i].tr(), style: TextStyle(color: color, fontWeight: isActive ? FontWeight.w600 : FontWeight.w400))),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _VisualInsightsCardV2 extends StatelessWidget {
  final double waterUsage; // 0..1
  final List<double> cropHealth; // 0..1 values for simple bar chart
  const _VisualInsightsCardV2({required this.waterUsage, required this.cropHealth});

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('home.visual_insights'.tr(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF4CAF50))),
            const SizedBox(height: 12),
            Row(
              children: [
                // Circular water usage
                SizedBox(
                  width: 110,
                  height: 110,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 110,
                        height: 110,
                        child: CircularProgressIndicator(
                          value: waterUsage,
                          strokeWidth: 10,
                          valueColor: const AlwaysStoppedAnimation(Color(0xFF4CAF50)),
                          backgroundColor: const Color(0xFFFFC107).withOpacity(0.25),
                        ),
                      ),
                      const Text('💧', style: TextStyle(fontSize: 20)),
                      Positioned(
                        bottom: 12,
                        child: Text('${(waterUsage * 100).round()}%', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Crop health bars
                Expanded(
                  child: SizedBox(
                    height: 110,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('home.crop_health'.tr(), style: const TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: List.generate(cropHealth.length, (i) {
                              final h = cropHealth[i].clamp(0.0, 1.0);
                              return Expanded(
                                child: Padding(
                                  padding: EdgeInsets.only(right: i == cropHealth.length - 1 ? 0 : 6),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF4CAF50).withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Align(
                                      alignment: Alignment.bottomCenter,
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 350),
                                        curve: Curves.easeOut,
                                        height: h * 90,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF4CAF50),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text('🌱 🌞 💧 🌾', textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TodaysTaskCard extends StatelessWidget {
  final List<Task> tasks;
  const _TodaysTaskCard({required this.tasks});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final todayTasks = tasks.where((t) => t.date.year == today.year && t.date.month == today.month && t.date.day == today.day).toList();
    final task = todayTasks.isNotEmpty ? todayTasks.first : null;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Background image
          Container(
            height: 200,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: NetworkImage('https://images.unsplash.com/photo-1574943320219-553eb213f72d?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Gradient overlay
          Container(
            height: 200,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.3),
                  Colors.black.withOpacity(0.7),
                ],
              ),
            ),
          ),
          // Content
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Today\'s task', 
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (task == null)
                    const Text(
                      'No task scheduled for today.',
                      style: TextStyle(color: Colors.white70),
                    )
                  else ...[
                    Text(
                      task.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Pending',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickCheckCarousel extends StatefulWidget {
  final List<Task> tasks;
  final Future<void> Function(String) onMarkDone;
  const _QuickCheckCarousel({required this.tasks, required this.onMarkDone});

  @override
  State<_QuickCheckCarousel> createState() => _QuickCheckCarouselState();
}

class _QuickCheckCarouselState extends State<_QuickCheckCarousel> {
  late final PageController _controller;
  late final List<String> _questions;
  String _freeText = '';
  late final List<bool?> _answers;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
    // Placeholder; backend will supply dynamic questions
    _questions = const [
      'Was irrigation done today?',
      'Any visible pests?',
      'Is soil moisture adequate?',
    ];
    _answers = List<bool?>.filled(_questions.length, null);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final todayTasks = widget.tasks.where((t) => t.date.year == today.year && t.date.month == today.month && t.date.day == today.day).toList();
    final taskId = todayTasks.isNotEmpty ? todayTasks.first.taskId : null;

    final totalPages = _questions.length + 2; // questions + narration + mark done

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SizedBox(
        height: 260,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('home.quick_check'.tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: PageView.builder(
                physics: const NeverScrollableScrollPhysics(),
                controller: _controller,
                itemCount: totalPages,
                itemBuilder: (context, index) {
                  if (index < _questions.length) {
                    final q = _questions[index];
                    return _QuestionPage(
                      question: q,
                      onAnswered: (val) {
                        _answers[index] = val;
                        final next = index + 1;
                        if (next < totalPages) {
                          _controller.animateToPage(next, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
                        }
                        setState(() {});
                      },
                    );
                  } else if (index == _questions.length) {
                    return _NarrationPage(
                      onChanged: (v) => _freeText = v,
                      onMicTap: () {},
                      onNext: () {
                        final next = index + 1;
                        _controller.animateToPage(next, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
                      },
                    );
                  } else {
                    return _MarkDonePage(
                      onDone: taskId == null ? null : () => widget.onMarkDone(taskId),
                    );
                  }
                },
              ),
            ),
            _Dots(total: totalPages, controller: _controller),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _QuestionPage extends StatelessWidget {
  final String question;
  final ValueChanged<bool> onAnswered;
  const _QuestionPage({required this.question, required this.onAnswered});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(question, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 12),
          Row(
            children: [
              ChoiceChip(label: Text('common.yes'.tr()), selected: false, onSelected: (_) => onAnswered(true)),
              const SizedBox(width: 8),
              ChoiceChip(label: Text('common.no'.tr()), selected: false, onSelected: (_) => onAnswered(false)),
            ],
          )
        ],
      ),
    );
  }
}

class _NarrationPage extends StatelessWidget {
  final ValueChanged<String> onChanged;
  final VoidCallback onMicTap;
  final VoidCallback onNext;
  const _NarrationPage({required this.onChanged, required this.onMicTap, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Tell us what you did today'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: onChanged,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  minLines: 2,
                  maxLines: 4,
                ),
              ),
              IconButton(onPressed: onMicTap, icon: const Icon(Icons.mic)),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: onNext,
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Next'),
            ),
          )
        ],
      ),
    );
  }
}

class _MarkDonePage extends StatelessWidget {
  final VoidCallback? onDone;
  const _MarkDonePage({this.onDone});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton.icon(
        onPressed: onDone,
        icon: const Icon(Icons.check),
        label: const Text('Mark today\'s task as done'),
      ),
    );
  }
}

class _Dots extends StatefulWidget {
  final int total;
  final PageController controller;
  const _Dots({required this.total, required this.controller});

  @override
  State<_Dots> createState() => _DotsState();
}

class _DotsState extends State<_Dots> {
  double _page = 0;
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(() {
      setState(() {
        _page = widget.controller.page ?? 0;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(widget.total, (i) {
        final active = (i - _page).abs() < 0.5;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          height: 6,
          width: active ? 14 : 6,
          decoration: BoxDecoration(
            color: active ? AppColors.green : AppColors.neutralGray,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

class _RoadmapOverviewCard extends StatelessWidget {
  final String phase;
  final List<String> milestones;
  const _RoadmapOverviewCard({required this.phase, required this.milestones});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Top card with image and current phase info
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              // Background image
              Container(
                height: 120,
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage('https://images.unsplash.com/photo-1416879595882-3373a0480b5b?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              // Gradient overlay
              Container(
                height: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.2),
                      Colors.black.withOpacity(0.6),
                    ],
                  ),
                ),
              ),
              // Content
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Roadmap • Current phase: $phase', 
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${milestones.length} milestones to complete',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        // Bottom card with route map
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your Farming Journey',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 16),
                // Vertical continuous route with milestones
                SizedBox(
                  height: 300,
                  child: ListView.builder(
                    itemCount: milestones.length,
                    itemBuilder: (context, index) {
                      final item = milestones[index];
                      final isCurrent = item == phase;
                      final isCompleted = milestones.indexOf(phase) > index;
                      return SizedBox(
                        height: 60,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 40,
                              height: double.infinity,
                              child: CustomPaint(
                                painter: _VerticalNodePainter(
                                  isFirst: index == 0,
                                  isLast: index == milestones.length - 1,
                                  isActiveNode: isCompleted || isCurrent,
                                  isActiveTop: isCompleted,
                                  isActiveBottom: isCompleted,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isCurrent 
                                    ? Colors.green.withOpacity(0.1)
                                    : isCompleted 
                                      ? Colors.blue.withOpacity(0.1)
                                      : Colors.grey.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: isCurrent 
                                    ? Border.all(color: Colors.green, width: 2)
                                    : null,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      isCompleted 
                                        ? Icons.check_circle
                                        : isCurrent 
                                          ? Icons.radio_button_checked
                                          : Icons.radio_button_unchecked,
                                      color: isCompleted 
                                        ? Colors.blue
                                        : isCurrent 
                                          ? Colors.green
                                          : Colors.grey,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        item,
                                        style: TextStyle(
                                          color: isCurrent 
                                            ? Colors.green
                                            : isCompleted 
                                              ? Colors.blue
                                              : Colors.grey,
                                          fontWeight: isCurrent 
                                            ? FontWeight.bold 
                                            : FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _RoutePainter extends CustomPainter {
  final List<String> milestones;
  final String current;
  _RoutePainter({required this.milestones, required this.current});

  @override
  void paint(Canvas canvas, Size size) {
    if (milestones.isEmpty) return;
    final pathPaint = Paint()
      ..color = AppColors.neutralGray
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;
    final activePaint = Paint()
      ..color = AppColors.green
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;
    final nodePaint = Paint()..color = AppColors.neutralGray;
    final nodeActivePaint = Paint()..color = AppColors.green;

    final y = 40.0;
    final margin = 24.0;
    final totalWidth = size.width - margin * 2;
    final step = milestones.length == 1 ? 0.0 : totalWidth / (milestones.length - 1);
    final points = List.generate(milestones.length, (i) => Offset(margin + step * i, y));

    // Base path
    for (int i = 0; i < points.length - 1; i++) {
      canvas.drawLine(points[i], points[i + 1], pathPaint);
    }

    // Active progress up to current
    int currentIndex = milestones.indexOf(current);
    if (currentIndex < 0) currentIndex = 0;
    for (int i = 0; i < currentIndex; i++) {
      canvas.drawLine(points[i], points[i + 1], activePaint);
    }

    // Nodes
    for (int i = 0; i < points.length; i++) {
      final paint = i <= currentIndex ? nodeActivePaint : nodePaint;
      canvas.drawCircle(points[i], 6, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RoutePainter oldDelegate) {
    return oldDelegate.milestones != milestones || oldDelegate.current != current;
  }
}

class _RouteWindowPainter extends CustomPainter {
  final List<String> window;
  final String current;
  _RouteWindowPainter({required this.window, required this.current});

  @override
  void paint(Canvas canvas, Size size) {
    if (window.isEmpty) return;
    final pathPaint = Paint()
      ..color = AppColors.neutralGray
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;
    final activePaint = Paint()
      ..color = AppColors.green
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;
    final nodePaint = Paint()..color = AppColors.neutralGray;
    final nodeActivePaint = Paint()..color = AppColors.green;

    final y = 60.0;
    final margin = 20.0;
    final totalWidth = size.width - margin * 2;
    final step = window.length == 1 ? 0.0 : totalWidth / (window.length - 1);
    final points = List.generate(window.length, (i) => Offset(margin + step * i, y));

    for (int i = 0; i < points.length - 1; i++) {
      canvas.drawLine(points[i], points[i + 1], pathPaint);
    }

    int currentIndex = window.indexOf(current);
    if (currentIndex < 0) currentIndex = 0;
    for (int i = 0; i < currentIndex; i++) {
      canvas.drawLine(points[i], points[i + 1], activePaint);
    }

    for (int i = 0; i < points.length; i++) {
      final paint = i <= currentIndex ? nodeActivePaint : nodePaint;
      canvas.drawCircle(points[i], 6, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RouteWindowPainter oldDelegate) {
    return oldDelegate.window != window || oldDelegate.current != current;
  }
}

class _VerticalNodePainter extends CustomPainter {
  final bool isFirst;
  final bool isLast;
  final bool isActiveNode;
  final bool isActiveTop;
  final bool isActiveBottom;

  _VerticalNodePainter({
    required this.isFirst,
    required this.isLast,
    required this.isActiveNode,
    required this.isActiveTop,
    required this.isActiveBottom,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final nodeY = size.height / 2;
    final top = Offset(centerX, 0);
    final bottom = Offset(centerX, size.height);

    final linePaint = Paint()
      ..color = AppColors.neutralGray
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    final activePaint = Paint()
      ..color = AppColors.green
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    final nodePaint = Paint()..color = isActiveNode ? AppColors.green : AppColors.neutralGray;

    // Draw base lines
    if (!isFirst) canvas.drawLine(top, Offset(centerX, nodeY), linePaint);
    if (!isLast) canvas.drawLine(Offset(centerX, nodeY), bottom, linePaint);

    // Draw active portions
    if (isActiveTop && !isFirst) canvas.drawLine(top, Offset(centerX, nodeY), activePaint);
    if (isActiveBottom && !isLast) canvas.drawLine(Offset(centerX, nodeY), bottom, activePaint);

    // Draw node
    canvas.drawCircle(Offset(centerX, nodeY), 6, nodePaint);
  }

  @override
  bool shouldRepaint(covariant _VerticalNodePainter oldDelegate) {
    return isFirst != oldDelegate.isFirst ||
        isLast != oldDelegate.isLast ||
        isActiveNode != oldDelegate.isActiveNode ||
        isActiveTop != oldDelegate.isActiveTop ||
        isActiveBottom != oldDelegate.isActiveBottom;
  }
}

class _ProgressAnalyticsCard extends StatelessWidget {
  final List<Task> tasks;
  final int totalPoints;
  final int weeklyStreak;
  const _ProgressAnalyticsCard({required this.tasks, required this.totalPoints, required this.weeklyStreak});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final last7 = List.generate(7, (i) => DateTime(now.year, now.month, now.day).subtract(Duration(days: 6 - i)));
    final counts = last7
        .map((d) => tasks.where((t) => t.status == 'done' && t.date.year == d.year && t.date.month == d.month && t.date.day == d.day).length)
        .toList();
    final maxVal = (counts.fold<int>(0, (p, c) => c > p ? c : p)).clamp(1, 999);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('home.your_progress'.tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                _Metric(label: 'Points', value: totalPoints.toString()),
                const SizedBox(width: 16),
                _Metric(label: 'Streak', value: '${weeklyStreak}d'),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 100,
              width: double.infinity,
              child: CustomPaint(
                painter: _BarChartPainter(values: counts, maxValue: maxVal),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: last7.map((d) => Text('${d.day}/${d.month}', style: const TextStyle(fontSize: 10, color: Colors.grey))).toList(),
            )
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label; final String value;
  const _Metric({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.neutralGray,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

class _BarChartPainter extends CustomPainter {
  final List<int> values; final int maxValue;
  _BarChartPainter({required this.values, required this.maxValue});

  @override
  void paint(Canvas canvas, Size size) {
    final barWidth = size.width / (values.length * 2);
    final paintBg = Paint()..color = AppColors.neutralGray;
    final paintActive = Paint()..color = AppColors.green;
    for (int i = 0; i < values.length; i++) {
      final x = (i * 2 + 0.5) * barWidth;
      final h = (values[i] / maxValue) * (size.height - 10);
      final rectBg = Rect.fromLTWH(x, 0, barWidth, size.height - 10);
      final rectVal = Rect.fromLTWH(x, size.height - 10 - h, barWidth, h);
      final r = Radius.circular(6);
      canvas.drawRRect(RRect.fromRectAndRadius(rectBg, r), paintBg);
      canvas.drawRRect(RRect.fromRectAndRadius(rectVal, r), paintActive);
    }
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.maxValue != maxValue;
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

class ChatbotOverlay extends StatefulWidget {
  final VoidCallback? onClose;
  final int voiceDelayMs;
  
  const ChatbotOverlay({super.key, this.onClose, this.voiceDelayMs = 200});

  @override
  State<ChatbotOverlay> createState() => _ChatbotOverlayState();
}

class _ChatbotOverlayState extends State<ChatbotOverlay> with TickerProviderStateMixin {
  late AnimationController _voiceIconController;
  late AnimationController _slideController;
  late Animation<double> _voiceIconAnimation;
  late Animation<Offset> _slideAnimation;
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    // Voice icon animation
    _voiceIconController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _voiceIconAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _voiceIconController, curve: Curves.elasticOut),
    );

    // Slide up animation
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    // Initialize with welcome message and FAQ suggestions
    _initializeChat();

    // Start overlay first, then voice icon after provided delay (post FAB disappearance)
    _slideController.forward();
    Future.delayed(Duration(milliseconds: widget.voiceDelayMs), () {
      if (mounted) _voiceIconController.forward();
    });
  }

  @override
  void dispose() {
    _voiceIconController.dispose();
    _slideController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _initializeChat() {
    _messages.add(ChatMessage(
      text: 'chatbot.welcome_message'.tr(),
      isUser: false,
      timestamp: DateTime.now(),
    ));
  }

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    // Add user message
    _messages.add(ChatMessage(
      text: message,
      isUser: true,
      timestamp: DateTime.now(),
    ));

    _messageController.clear();
    setState(() {
      _isTyping = true;
    });

    // Simulate bot response
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        final response = _getBotResponse(message);
        _messages.add(ChatMessage(
          text: response,
          isUser: false,
          timestamp: DateTime.now(),
        ));
        setState(() {
          _isTyping = false;
        });
      }
    });
  }

  String _getBotResponse(String userMessage) {
    final lowerMessage = userMessage.toLowerCase();
    
    // FAQ responses
    if (lowerMessage.contains('weather') || lowerMessage.contains('rain') || lowerMessage.contains('sun')) {
      return 'faq.answers.weather'.tr();
    } else if (lowerMessage.contains('water') || lowerMessage.contains('irrigation')) {
      return 'faq.answers.irrigation'.tr();
    } else if (lowerMessage.contains('fertilizer') || lowerMessage.contains('fertiliz')) {
      return 'faq.answers.fertilizer'.tr();
    } else if (lowerMessage.contains('pest') || lowerMessage.contains('bug')) {
      return 'faq.answers.pest_control'.tr();
    } else if (lowerMessage.contains('harvest') || lowerMessage.contains('crop')) {
      return 'faq.answers.harvest'.tr();
    } else if (lowerMessage.contains('soil') || lowerMessage.contains('land')) {
      return 'faq.answers.soil_health'.tr();
    } else if (lowerMessage.contains('rotation') || lowerMessage.contains('crop rotation')) {
      return 'faq.answers.crop_rotation'.tr();
    } else if (lowerMessage.contains('government') || lowerMessage.contains('scheme') || lowerMessage.contains('policy')) {
      return 'faq.answers.government_schemes'.tr();
    } else if (lowerMessage.contains('price') || lowerMessage.contains('market')) {
      return 'faq.answers.market_prices'.tr();
    } else if (lowerMessage.contains('disease') || lowerMessage.contains('sick') || lowerMessage.contains('ill')) {
      return 'faq.answers.disease_detection'.tr();
    } else {
      // Default response
      return 'chatbot.default_response'.tr();
    }
  }

  void _startVoiceRecording() {
    // Simulate voice recording
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('voice.started'.tr())),
    );
    
    // Simulate voice input after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        final voiceMessage = "What's the weather forecast for my crops?";
        _messageController.text = voiceMessage;
        _sendMessage();
      }
    });
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.7,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: message.isUser ? Colors.blue[100] : Colors.grey[200],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              message.text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'chatbot.typing'.tr(),
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[600]!),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQSuggestions() {
    final faqQuestions = [
      'faq.questions.weather',
      'faq.questions.irrigation',
      'faq.questions.fertilizer',
      'faq.questions.pest_control',
      'faq.questions.harvest',
      'faq.questions.soil_health',
    ];

    return Container(
      margin: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'faq.title'.tr(),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: faqQuestions.map((question) {
              return ActionChip(
                label: Text(
                  question.tr(),
                  style: const TextStyle(fontSize: 12),
                ),
                onPressed: () {
                  _messageController.text = question.tr();
                  _sendMessage();
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: Material(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            color: Colors.white,
          ),
        child: Column(
          children: [
              // Status bar padding
              SizedBox(height: MediaQuery.of(context).padding.top),
              // Header with close button
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Text(
                      'chatbot.name'.tr(),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () {
                        widget.onClose?.call();
                      },
                      icon: const Icon(Icons.close, color: Colors.black87),
                    ),
                  ],
                ),
              ),
              // Chat content
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          itemCount: _messages.length + (_isTyping ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index < _messages.length) {
                              final message = _messages[index];
                              return _buildMessageBubble(message);
                            } else {
                              return _buildTypingIndicator();
                            }
                          },
                        ),
                      ),
                      // FAQ Suggestions
                      if (_messages.length <= 1) _buildFAQSuggestions(),
                      // Input area
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _messageController,
                                decoration: InputDecoration(
                                  hintText: 'chatbot.search_hint'.tr(),
                                  border: const OutlineInputBorder(),
                                  isDense: true,
                                ),
                                onSubmitted: (_) => _sendMessage(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Voice icon (transformed FAB) with animation
                            AnimatedBuilder(
                              animation: _voiceIconAnimation,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: _voiceIconAnimation.value,
                                  child: Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFF1FA2FF), Color(0xFF12D8A5)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.green.withOpacity(0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(24),
                                        onTap: _startVoiceRecording,
                                        child: const Icon(
                                          Icons.mic,
                                          color: Colors.white,
                                          size: 24,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: _sendMessage,
                              child: Text('chatbot.send'.tr()),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      );
    
  }
}

