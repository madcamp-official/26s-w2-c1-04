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
//   - `?tab=`   ∈ {pet, album, comm}
// Rules: not onboarded OR route=onboarding → [OnboardingScreen]; a pushable
// route → [AppShell] then push that screen after first frame; otherwise the
// [AppShell] at the requested tab (default the pet tab).

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

/// Resolve the starting tab. The tab-routes `home`/`album` pin the tab
/// directly; otherwise the `?tab=` param decides (pet → 0, album → 1, comm → 2).
int _tabIndexFor(String? route, String? tab) {
  switch (route) {
    case 'home':
      return 0;
    case 'album':
      return 1;
  }
  switch (tab) {
    case 'album':
      return 1;
    case 'comm':
      return 2;
    case 'pet':
    default:
      return 0;
  }
}

/// The full-screen screen a pushable deep-link route names, or null for the
/// tab/onboarding routes. `viewer` opens at index 0 by default.
WidgetBuilder? _pushTargetFor(String? route) {
  switch (route) {
    case 'draw':
      return (_) => const DrawSendScreen();
    case 'viewer':
      return (_) => const ViewerScreen(initialIndex: 0);
    case 'diary':
      return (_) => const PetDiaryScreen();
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
// AppShell — the three-tab home with a notifications overlay
// ===========================================================================

/// The tabbed home: an [IndexedStack] over the three tab screens with a
/// [CpBottomNav] beneath and a transient notifications banner floated on top.
/// If [pushOnStart] is set, that full-screen route is pushed once after the
/// first frame (the QA deep-link path).
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
    CommHomeScreen(),
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
        final glyph =
            n.kind == NotificationKind.pokeReceived ? '👉' : '✏️';
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
          child: GestureDetector(
            onTap: () => appState.dismissNotification(n.id),
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: cpPrint,
                borderRadius: BorderRadius.circular(2),
                border: Border.all(color: cpEucA(0.5), width: 0.5),
                boxShadow: [
                  BoxShadow(
                    color: cpInkA(0.08),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Text(glyph, style: const TextStyle(fontSize: 16)),
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
