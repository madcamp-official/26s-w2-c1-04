// Memory Pager — the app shell, routing, and QA deep-link entry.
//
// [MemoryPagerApp] is the root [MaterialApp] (Cold Press theme, no debug banner).
// It hangs the one global [appState] over the tree via [AppScope] so any screen
// can read it with `AppScope.of(context)` (or the bare `appState` singleton) and
// rebuild on notify.
//
// The home decides what to show from the *already-onboarded* mock session plus
// optional `Uri.base.queryParameters` QA deep-links:
//   - `?route=` ∈ {onboarding, home, album, draw, viewer, diary, report, store,
//                   house, explore, settings, widget}
//   - `?tab=`   ∈ {pet, home, album, diary, more}
// Rules: not onboarded OR route=onboarding → [OnboardingScreen]; a pushable
// route → [AppShell] then push that screen after first frame; otherwise the
// [AppShell] at the requested tab (default the home/pet tab).

import 'package:flutter/material.dart';

import 'core/app_state.dart';
import 'ui/components.dart';
import 'ui/theme.dart';
import 'ui/screens/album.dart';
import 'ui/screens/comm_home.dart';
import 'ui/screens/draw_send.dart';
import 'ui/screens/monthly_report.dart';
import 'ui/screens/onboarding.dart';
import 'ui/screens/pet_diary.dart';
import 'ui/screens/pet_explore.dart';
import 'ui/screens/pet_home.dart';
import 'ui/screens/pet_house.dart';
import 'ui/screens/pet_store.dart';
import 'ui/screens/settings.dart';
import 'ui/screens/viewer.dart';
import 'ui/screens/widget_preview.dart';

// ===========================================================================
// AppScope — hangs the global AppState over the tree.
// ===========================================================================

/// Inherited access to the single [AppState]. Screens read it with
/// `AppScope.of(context)` and rebuild when it notifies (the notifier is the
/// [AppState] itself). The bare global [appState] works too — [AppScope] just
/// gives a context-scoped, rebuild-aware handle.
class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child})
      : super(notifier: state);

  static AppState of(BuildContext context) {
    final scope = context
        .getElementForInheritedWidgetOfExactType<AppScope>()
        ?.widget as AppScope?;
    return scope?.notifier ?? appState;
  }
}

// ===========================================================================
// Navigation helper
// ===========================================================================

/// Push a full-screen [screen] onto the navigator. The house style for reaching
/// any push-target screen from within another:
/// `cpPush(context, const PetStoreScreen())`, i.e.
/// `Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen))`.
Future<T?> cpPush<T>(BuildContext context, Widget screen) =>
    Navigator.of(context).push<T>(MaterialPageRoute<T>(builder: (_) => screen));

// ===========================================================================
// Root app
// ===========================================================================

class MemoryPagerApp extends StatelessWidget {
  const MemoryPagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: appState,
      child: MaterialApp(
        title: 'Memory Pager',
        debugShowCheckedModeBanner: false,
        theme: cpTheme,
        home: const _Home(),
      ),
    );
  }
}

// ===========================================================================
// Home — bootstrap gate + deep-link routing
// ===========================================================================

class _Home extends StatefulWidget {
  const _Home();

  @override
  State<_Home> createState() => _HomeState();
}

class _HomeState extends State<_Home> {
  bool _booted = false;

  @override
  void initState() {
    super.initState();
    // The seeded demo boots asynchronously (register → me → pet → album →
    // widget → live socket). Gate the first meaningful paint on it so we never
    // flash the onboarding screen before `group` lands.
    final f = appState.bootstrapFuture;
    if (f == null) {
      _booted = true;
    } else {
      f.whenComplete(() {
        if (mounted) setState(() => _booted = true);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_booted) {
      return const CpScaffold(
        body: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 1.5, color: cpEuc),
          ),
        ),
      );
    }

    // Rebuild on session changes (e.g. onboarding completing → group set).
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final params = Uri.base.queryParameters;
        final route = params['route'];
        // QA deep-link: preview a chosen pet species (?species=hamster).
        final wantSpecies = params['species'];
        if (wantSpecies != null && wantSpecies != appState.petSpecies) {
          WidgetsBinding.instance.addPostFrameCallback(
              (_) => appState.setPetSpecies(wantSpecies));
        }
        final onboarded = appState.me != null && appState.group != null;

        if (!onboarded || route == 'onboarding') {
          return const OnboardingScreen();
        }

        final tab = _tabIndexFor(route, params['tab']);
        final push = _pushTargetFor(route);
        return AppShell(initialTab: tab, pushOnStart: push);
      },
    );
  }
}

/// Resolve the starting tab. Tab-routes pin the tab directly; otherwise the
/// `?tab=` param decides. The four tabs are: 0 홈(pet home), 1 그림함(album),
/// 2 일기(diary), 3 더보기(more). Tab names map pet/home → 0, album → 1,
/// diary → 2, more → 3 (legacy `comm` also lands on 더보기).
int _tabIndexFor(String? route, String? tab) {
  switch (route) {
    case 'home':
      return 0;
    case 'album':
      return 1;
    case 'diary':
      return 2;
    case 'more':
      return 3;
  }
  switch (tab) {
    case 'album':
      return 1;
    case 'diary':
      return 2;
    case 'more':
    case 'comm':
      return 3;
    case 'pet':
    case 'home':
    default:
      return 0;
  }
}

/// The full-screen screen a pushable deep-link route names, or null for the
/// tab/onboarding routes. `viewer` opens at index 0 by default. `diary` is now
/// a tab (handled by [_tabIndexFor]), so it is not a push target here.
WidgetBuilder? _pushTargetFor(String? route) {
  switch (route) {
    case 'draw':
      return (_) => const DrawSendScreen();
    case 'viewer':
      return (_) => const ViewerScreen(initialIndex: 0);
    case 'report':
      return (_) => const MonthlyReportScreen();
    case 'store':
      return (_) => const PetStoreScreen();
    case 'house':
      return (_) => const PetHouseScreen();
    case 'explore':
      return (_) => const PetExploreScreen();
    case 'settings':
      return (_) => const SettingsScreen();
    case 'widget':
      return (_) => const WidgetPreviewScreen();
    default:
      return null;
  }
}

// ===========================================================================
// AppShell — the four-tab home with a notifications overlay
// ===========================================================================

/// The tabbed home: an [IndexedStack] over the four tab screens with an
/// icon [CpBottomNav] beneath and a transient notifications banner floated on
/// top. Tabs: 0 홈([PetHomeScreen]) · 1 그림함([AlbumScreen]) · 2 일기
/// ([PetDiaryScreen]) · 3 더보기([MoreScreen]). If [pushOnStart] is set, that
/// full-screen route is pushed once after the first frame (the QA deep-link
/// path).
class AppShell extends StatefulWidget {
  const AppShell({super.key, this.initialTab = 0, this.pushOnStart});

  final int initialTab;
  final WidgetBuilder? pushOnStart;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late int _tab = widget.initialTab;

  static const List<Widget> _tabs = [
    PetHomeScreen(),
    AlbumScreen(),
    PetDiaryScreen(),
    MoreScreen(),
  ];

  /// The bottom-nav tabs — Material outlined line icons (never emoji); the
  /// active tab lifts to the filled variant tinted [cpEuc].
  static const List<CpNavItem> _navItems = [
    CpNavItem(icon: Icons.home_outlined, activeIcon: Icons.home, label: '홈'),
    CpNavItem(
      icon: Icons.collections_outlined,
      activeIcon: Icons.collections,
      label: '그림함',
    ),
    CpNavItem(
      icon: Icons.menu_book_outlined,
      activeIcon: Icons.menu_book,
      label: '일기',
    ),
    CpNavItem(
      icon: Icons.favorite_border,
      activeIcon: Icons.favorite,
      label: '더보기',
    ),
  ];

  @override
  void initState() {
    super.initState();
    final push = widget.pushOnStart;
    if (push != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).push(MaterialPageRoute(builder: push));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cpMist,
      body: Stack(
        children: [
          IndexedStack(index: _tab, children: _tabs),
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: SafeArea(bottom: false, child: const _NotificationsBanner()),
          ),
        ],
      ),
      bottomNavigationBar: CpBottomNav(
        current: _tab,
        onTap: (i) => setState(() => _tab = i),
        items: _navItems,
      ),
    );
  }
}

// ===========================================================================
// Notifications banner — top overlay driven by appState.notifications
// ===========================================================================

/// The top-most transient banner: shows the newest [AppNotification] (incoming
/// poke or partner's new doodle) and dismisses it on tap. Purely a surface over
/// `appState.notifications` — it invents nothing when the queue is empty.
class _NotificationsBanner extends StatelessWidget {
  const _NotificationsBanner();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        if (appState.notifications.isEmpty) return const SizedBox.shrink();
        final n = appState.notifications.first;
        // A line icon, never an emoji: a poke rings the bell, a new doodle
        // arrives as a letter, a reward is a snack for the pet.
        final icon = switch (n.kind) {
          NotificationKind.pokeReceived => Icons.notifications_none,
          NotificationKind.doodleNew => Icons.mail_outline,
          NotificationKind.reward => Icons.cookie_outlined,
        };
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
          child: GestureDetector(
            onTap: () => appState.dismissNotification(n.id),
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              decoration: BoxDecoration(
                color: cpPrint,
                borderRadius: BorderRadius.circular(cpRadiusCard),
                border: Border.all(color: cpEucA(0.4)),
                boxShadow: [
                  BoxShadow(
                    color: cpInkA(0.08),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(icon, size: 20, color: cpEuc),
                  const SizedBox(width: 12),
                  Expanded(child: Text(n.text, style: cpSans(size: 13))),
                  const SizedBox(width: 8),
                  Icon(Icons.close, size: 16, color: cpInkA(0.4)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
