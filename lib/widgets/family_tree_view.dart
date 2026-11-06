import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/person.dart';
import 'person_card.dart';

const double _hGap = 28; // oilalar orasidagi gorizontal masofa
const double _coupleGap = 30; // er-xotin orasidagi masofa
const double _vGap = 80; // avlodlar orasidagi vertikal masofa
const double _margin = 40;

class _TreeLayout {
  _TreeLayout(this.positions, this.size, this.spouses);

  /// Har bir shaxs kartochkasining yuqori-chap burchagi.
  final Map<String, Offset> positions;
  final Size size;
  final Map<String, Set<String>> spouses;
}

/// Avlodlar bo'yicha joylashtirish:
/// 1) har bir shaxsga avlod (qator) raqami beriladi;
/// 2) er-xotinlar bir qatorga tushiriladi va yonma-yon turadi;
/// 3) farzandlar ota-onasining o'rtasi ostiga joylashtiriladi.
_TreeLayout _computeLayout(List<Person> persons) {
  final byId = {for (final p in persons) p.id: p};

  final spouses = <String, Set<String>>{for (final p in persons) p.id: {}};
  for (final p in persons) {
    for (final s in p.spouseIds) {
      if (s != p.id && byId.containsKey(s)) {
        spouses[p.id]!.add(s);
        spouses[s]!.add(p.id);
      }
    }
  }

  List<String> parentIds(Person p) => [p.fatherId, p.motherId]
      .whereType<String>()
      .where(byId.containsKey)
      .toList();

  // --- 1. Avlodlarni hisoblash (faqat oshib boradi, sikldan himoyalangan) ---
  final gen = {for (final p in persons) p.id: 0};
  for (var iter = 0; iter < persons.length + 5; iter++) {
    var changed = false;
    void raise(String id, int value) {
      if (value > gen[id]!) {
        gen[id] = value;
        changed = true;
      }
    }

    for (final p in persons) {
      for (final pid in parentIds(p)) {
        raise(p.id, gen[pid]! + 1); // farzand ota-onadan pastda
        raise(pid, gen[p.id]! - 1); // ota-ona farzandga yaqin
      }
      for (final s in spouses[p.id]!) {
        raise(p.id, gen[s]!); // er-xotin bir qatorda
      }
    }
    if (!changed) break;
  }
  final minGen = gen.values.isEmpty ? 0 : gen.values.reduce(math.min);
  gen.updateAll((_, v) => v - minGen);

  // --- 2. Qatorlar bo'yicha guruhlash ---
  final rows = <int, List<String>>{};
  for (final p in persons) {
    rows.putIfAbsent(gen[p.id]!, () => []).add(p.id);
  }
  final levels = rows.keys.toList()..sort();

  final positions = <String, Offset>{};
  final centerX = <String, double>{};
  var maxRight = _margin;

  for (final level in levels) {
    final ids = rows[level]!
      ..sort((a, b) => (byId[a]!.birthDate ?? DateTime(9999))
          .compareTo(byId[b]!.birthDate ?? DateTime(9999)));

    // Er-xotinlarni bitta blokka yig'ish
    final used = <String>{};
    final blocks = <List<String>>[];
    for (final id in ids) {
      if (used.contains(id)) continue;
      final block = <String>[];
      final stack = [id];
      while (stack.isNotEmpty) {
        final cur = stack.removeLast();
        if (!used.add(cur)) continue;
        block.add(cur);
        for (final s in spouses[cur]!) {
          if (gen[s] == level && !used.contains(s)) stack.add(s);
        }
      }
      block.sort(
          (a, b) => byId[a]!.gender.index.compareTo(byId[b]!.gender.index));
      blocks.add(block);
    }

    // Har bir blok uchun ota-onalar markazi (istalgan X)
    double? desiredX(List<String> block) {
      final xs = <double>[];
      for (final id in block) {
        for (final pid in parentIds(byId[id]!)) {
          final x = centerX[pid];
          if (x != null) xs.add(x);
        }
      }
      if (xs.isEmpty) return null;
      return xs.reduce((a, b) => a + b) / xs.length;
    }

    final items = [
      for (var i = 0; i < blocks.length; i++)
        (block: blocks[i], want: desiredX(blocks[i]), index: i),
    ];
    items.sort((a, b) {
      final wa = a.want, wb = b.want;
      if (wa == null && wb == null) return a.index.compareTo(b.index);
      if (wa == null) return 1;
      if (wb == null) return -1;
      return wa.compareTo(wb);
    });

    final y = _margin + level * (kNodeH + _vGap);
    var cursor = _margin;
    for (final item in items) {
      final n = item.block.length;
      final width = n * kNodeW + (n - 1) * _coupleGap;
      final want = item.want;
      final start = want == null ? cursor : math.max(cursor, want - width / 2);
      for (var k = 0; k < n; k++) {
        final x = start + k * (kNodeW + _coupleGap);
        positions[item.block[k]] = Offset(x, y);
        centerX[item.block[k]] = x + kNodeW / 2;
      }
      cursor = start + width + _hGap;
      maxRight = math.max(maxRight, start + width);
    }
  }

  final maxLevel = levels.isEmpty ? 0 : levels.last;
  final size = Size(
    maxRight + _margin,
    _margin * 2 + (maxLevel + 1) * kNodeH + maxLevel * _vGap,
  );
  return _TreeLayout(positions, size, spouses);
}

/// Oila daraxtini chizadi. Barmoq bilan surish va kattalashtirish mumkin.
class FamilyTreeView extends StatefulWidget {
  const FamilyTreeView({
    super.key,
    required this.persons,
    required this.onPersonTap,
    this.highlightedId,
  });

  final List<Person> persons;
  final ValueChanged<Person> onPersonTap;
  final String? highlightedId;

  @override
  State<FamilyTreeView> createState() => _FamilyTreeViewState();
}

class _FamilyTreeViewState extends State<FamilyTreeView> {
  final _controller = TransformationController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final layout = _computeLayout(widget.persons);
    final scheme = Theme.of(context).colorScheme;

    return Stack(
      children: [
        InteractiveViewer(
          transformationController: _controller,
          constrained: false,
          minScale: 0.2,
          maxScale: 2.5,
          boundaryMargin: const EdgeInsets.all(300),
          child: SizedBox(
            width: layout.size.width,
            height: layout.size.height,
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _LinesPainter(
                      persons: widget.persons,
                      layout: layout,
                      lineColor: scheme.outline,
                      spouseColor: Colors.red.shade300,
                    ),
                  ),
                ),
                for (final p in widget.persons)
                  if (layout.positions[p.id] != null)
                    Positioned(
                      left: layout.positions[p.id]!.dx,
                      top: layout.positions[p.id]!.dy,
                      child: PersonCard(
                        person: p,
                        highlighted: p.id == widget.highlightedId,
                        onTap: () => widget.onPersonTap(p),
                      ),
                    ),
              ],
            ),
          ),
        ),
        Positioned(
          right: 12,
          bottom: 12,
          child: FloatingActionButton.small(
            heroTag: 'resetZoom',
            tooltip: 'Boshlang\'ich ko\'rinish',
            onPressed: () => _controller.value = Matrix4.identity(),
            child: const Icon(Icons.center_focus_strong),
          ),
        ),
      ],
    );
  }
}

class _LinesPainter extends CustomPainter {
  _LinesPainter({
    required this.persons,
    required this.layout,
    required this.lineColor,
    required this.spouseColor,
  });

  final List<Person> persons;
  final _TreeLayout layout;
  final Color lineColor;
  final Color spouseColor;

  @override
  void paint(Canvas canvas, Size size) {
    final pos = layout.positions;
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;
    final spousePaint = Paint()
      ..color = spouseColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    // Er-xotin chiziqlari
    final drawn = <String>{};
    layout.spouses.forEach((a, set) {
      for (final b in set) {
        final key = a.compareTo(b) < 0 ? '$a|$b' : '$b|$a';
        if (!drawn.add(key)) continue;
        final pa = pos[a], pb = pos[b];
        if (pa == null || pb == null || pa.dy != pb.dy) continue;
        final y = pa.dy + kNodeH / 2;
        canvas.drawLine(Offset(pa.dx + kNodeW / 2, y),
            Offset(pb.dx + kNodeW / 2, y), spousePaint);
      }
    });

    // Ota-ona → farzand chiziqlari
    for (final c in persons) {
      final cp = pos[c.id];
      if (cp == null) continue;
      final f = c.fatherId == null ? null : pos[c.fatherId];
      final m = c.motherId == null ? null : pos[c.motherId];

      Offset start;
      if (f != null && m != null && f.dy == m.dy) {
        start = Offset((f.dx + m.dx) / 2 + kNodeW / 2, f.dy + kNodeH / 2);
      } else {
        final parent = f ?? m;
        if (parent == null) continue;
        start = Offset(parent.dx + kNodeW / 2, parent.dy + kNodeH);
      }
      final end = Offset(cp.dx + kNodeW / 2, cp.dy);
      final midY = end.dy - _vGap / 2;

      final path = Path()
        ..moveTo(start.dx, start.dy)
        ..lineTo(start.dx, midY)
        ..lineTo(end.dx, midY)
        ..lineTo(end.dx, end.dy);
      canvas.drawPath(path, linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _LinesPainter old) => true;
}
