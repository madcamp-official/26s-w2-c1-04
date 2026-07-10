// Memory Pager — Album (tab 1 · '사진첩').
//
// The doodle log with a date/type sort toggle and a content-type filter, over
// the cursor-paged [appState.album]. Deleted (expired) doodles are already gone
// from the album (the repo excludes them and [DoodleExpired] drops them); still
// counting-down / unviewed ephemerals stay, marked, until they self-destruct.
//
// A tap on a row opens the [ViewerScreen] at that doodle's index *in the real
// album* (not the reordered display list), so the pager lands on the right one.
// Scrolling near the bottom pulls the next page via the shared cursor.
//
// This is a tab screen: it renders inside the app shell's IndexedStack and adds
// no bottom nav of its own (the shell supplies [CpBottomNav]).

import 'package:flutter/material.dart';

import '../../core/app_state.dart';
import '../../core/models.dart';
import '../components.dart';
import '../theme.dart';
import 'viewer.dart';

class AlbumScreen extends StatefulWidget {
  const AlbumScreen({super.key});

  @override
  State<AlbumScreen> createState() => _AlbumScreenState();
}

class _AlbumScreenState extends State<AlbumScreen> {
  final ScrollController _scroll = ScrollController();

  /// Sort toggle: date-grouped (true) vs type-grouped (false).
  bool _byDate = true;

  /// Content-type filter; null = 전체. Drives `appState.loadAlbum(contentType:)`.
  ContentType? _typeFilter;

  /// Guards against stacking duplicate post-frame underflow checks.
  bool _underflowScheduled = false;

  static const List<(String, ContentType?)> _filters = [
    ('전체', null),
    ('사진', ContentType.photo),
    ('텍스트', ContentType.text),
    ('그림', ContentType.drawing),
  ];

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  // -- paging ---------------------------------------------------------------

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final p = _scroll.position;
    if (p.pixels >= p.maxScrollExtent - 320) _loadMore();
  }

  void _loadMore() {
    // loadAlbum flips albumLoading synchronously before its first await and
    // guards on it, so a burst of scroll ticks can't double-fetch.
    if (appState.albumHasMore && !appState.albumLoading) {
      appState.loadAlbum(contentType: _typeFilter);
    }
  }

  /// When the loaded page doesn't fill the viewport there's nothing to scroll,
  /// so nudge the next page after layout — self-limiting (stops once the list
  /// scrolls or `albumHasMore` goes false).
  void _scheduleUnderflowCheck() {
    if (_underflowScheduled) return;
    _underflowScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _underflowScheduled = false;
      if (!mounted) return;
      if (!appState.albumHasMore || appState.albumLoading) return;
      if (_scroll.hasClients && _scroll.position.maxScrollExtent <= 0) {
        _loadMore();
      }
    });
  }

  void _applyFilter(ContentType? type) {
    setState(() => _typeFilter = type);
    // Reset resets the shared cursor + album, then reloads from the top for the
    // chosen type. REST is the source of truth; the notify repaints us.
    appState.loadAlbum(reset: true, contentType: type);
  }

  void _openAt(int albumIndex) {
    // Full-screen push target with its own back affordance (the house style).
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ViewerScreen(initialIndex: albumIndex),
      ),
    );
  }

  // -- display model --------------------------------------------------------

  /// Reorganize the real [album] into header + row entries for the current sort.
  /// Every row carries its index in the *real* album so the viewer opens right.
  List<_Entry> _entriesFor(List<Doodle> album) {
    final out = <_Entry>[];
    if (_byDate) {
      int? lastKey;
      for (var i = 0; i < album.length; i++) {
        final d = album[i];
        final t = d.createdAt;
        final key = t.year * 10000 + t.month * 100 + t.day;
        if (key != lastKey) {
          out.add(_HeaderEntry(_dateLabel(t)));
          lastKey = key;
        }
        out.add(_RowEntry(d, i));
      }
    } else {
      const order = [ContentType.photo, ContentType.drawing, ContentType.text];
      for (final type in order) {
        final rows = <_RowEntry>[];
        for (var i = 0; i < album.length; i++) {
          if (album[i].contentType == type) rows.add(_RowEntry(album[i], i));
        }
        if (rows.isNotEmpty) {
          out.add(_HeaderEntry(_typeLabel(type)));
          out.addAll(rows);
        }
      }
    }
    return out;
  }

  String _dateLabel(DateTime d) => '${d.month}월 ${d.day}일';

  String _typeLabel(ContentType t) => switch (t) {
        ContentType.photo => '사진',
        ContentType.drawing => '그림',
        ContentType.text => '텍스트',
      };

  /// Real display name for a sender id (partner nickname preferred). Reads only
  /// live session data — never invents a name.
  String _senderName(String senderId) {
    final me = appState.me;
    if (me != null && me.id == senderId) return me.displayName;
    final g = appState.group;
    if (g != null) {
      for (final m in g.members) {
        if (m.userId == senderId) return m.nickname ?? m.displayName;
      }
    }
    return '상대';
  }

  // -- build ----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        return CpScaffold(
          title: '사진첩',
          actions: [
            CpSortToggle(
              byDate: _byDate,
              onTap: () => setState(() => _byDate = !_byDate),
            ),
          ],
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              CpChipRow(
                children: [
                  for (final (label, type) in _filters)
                    CpFilterChip(
                      label: label,
                      selected: _typeFilter == type,
                      onTap: () => _applyFilter(type),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Expanded(child: _body()),
            ],
          ),
        );
      },
    );
  }

  Widget _body() {
    final album = appState.album;
    final loading = appState.albumLoading;

    if (album.isEmpty) {
      if (loading) {
        return const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child:
                CircularProgressIndicator(strokeWidth: 1.5, color: cpEuc),
          ),
        );
      }
      return CpEmptyState(
        icon: Icons.image_outlined,
        text: _typeFilter == null
            ? '아직 낙서가 없어요\n첫 낙서를 남겨보세요'
            : '이 유형의 낙서가 없어요\n다른 필터를 눌러보세요',
      );
    }

    if (appState.albumHasMore && !loading) _scheduleUnderflowCheck();

    final entries = _entriesFor(album);
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(28, 4, 28, 36),
      itemCount: entries.length + 1,
      itemBuilder: (context, i) {
        if (i == entries.length) return _footer();
        final e = entries[i];
        if (e is _HeaderEntry) return _sectionHeader(e.label, first: i == 0);
        final row = e as _RowEntry;
        return _AlbumRow(
          doodle: row.doodle,
          senderName: _senderName(row.doodle.senderId),
          dateLabel: _dateLabel(row.doodle.createdAt),
          onTap: () => _openAt(row.albumIndex),
        );
      },
    );
  }

  Widget _sectionHeader(String label, {required bool first}) {
    return Padding(
      padding: EdgeInsets.fromLTRB(2, first ? 2 : 22, 2, 12),
      child: Row(
        children: [
          CpEyebrow(label),
          const SizedBox(width: 12),
          const Expanded(child: CpHair(opacity: 0.08)),
        ],
      ),
    );
  }

  Widget _footer() {
    if (appState.albumLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 22),
        child: Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child:
                CircularProgressIndicator(strokeWidth: 1.5, color: cpEuc),
          ),
        ),
      );
    }
    if (!appState.albumHasMore) {
      return Padding(
        padding: const EdgeInsets.only(top: 26),
        child: Center(child: CpEyebrow('처음부터 여기까지', size: 9)),
      );
    }
    return const SizedBox(height: 8);
  }
}

// ---------------------------------------------------------------------------
// Display entries
// ---------------------------------------------------------------------------

sealed class _Entry {
  const _Entry();
}

class _HeaderEntry extends _Entry {
  const _HeaderEntry(this.label);
  final String label;
}

class _RowEntry extends _Entry {
  const _RowEntry(this.doodle, this.albumIndex);
  final Doodle doodle;

  /// Index in the *real* [AppState.album] (what the viewer pages over).
  final int albumIndex;
}

// ---------------------------------------------------------------------------
// One matted log row
// ---------------------------------------------------------------------------

class _AlbumRow extends StatelessWidget {
  const _AlbumRow({
    required this.doodle,
    required this.senderName,
    required this.dateLabel,
    required this.onTap,
  });

  final Doodle doodle;
  final String senderName;
  final String dateLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final unviewed = !doodle.viewedByMe;
    final (preview, placeholder) = _preview(doodle);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: CpMatted(
          mat: 14,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CpDoodleThumb(doodle, size: 56, active: unviewed),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      preview,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: cpSans(
                        size: 14,
                        color: placeholder ? cpInkA(0.5) : cpInk,
                        weight: FontWeight.w500,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Row(
                      children: [
                        if (unviewed) ...[
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: cpEuc,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Flexible(
                          child: Text(
                            '$senderName · $dateLabel',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: cpSans(size: 12, color: cpInkA(0.5)),
                          ),
                        ),
                        if (doodle.mode == SendMode.ephemeral) ...[
                          const SizedBox(width: 10),
                          const _EphemeralBadge(),
                        ],
                        if (doodle.replyCount > 0) ...[
                          const SizedBox(width: 10),
                          Text(
                            '답장 ${doodle.replyCount}',
                            style: cpSans(
                              size: 11,
                              color: cpEucA(0.9),
                              weight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
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

  /// The preview line and whether it's a dimmed type descriptor (a placeholder,
  /// not fabricated content). Photo/drawing carry no inline caption here, so we
  /// name the *kind* honestly instead of inventing text.
  (String, bool) _preview(Doodle d) {
    switch (d.contentType) {
      case ContentType.text:
        final body = d.textBody?.trim() ?? '';
        return body.isEmpty ? ('내용 없음', true) : (body, false);
      case ContentType.photo:
        return ('사진', true);
      case ContentType.drawing:
        return ('그림', true);
    }
  }
}

/// A quiet eucalyptus keyline badge marking a 사라지기(ephemeral) doodle.
class _EphemeralBadge extends StatelessWidget {
  const _EphemeralBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(1),
        border: Border.all(color: cpEucA(0.5), width: 0.5),
      ),
      child: Text(
        '사라지기',
        style: cpSans(size: 9, color: cpEuc, weight: FontWeight.w600, spacing: 0.8),
      ),
    );
  }
}
