import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/family_tree.dart';
import '../services/auth_service.dart';
import '../services/tree_service.dart';
import '../widgets/dialogs.dart';
import 'tree_screen.dart';

/// Foydalanuvchining barcha oila daraxtlari.
class TreesScreen extends StatefulWidget {
  const TreesScreen({super.key, required this.user});

  final User user;

  @override
  State<TreesScreen> createState() => _TreesScreenState();
}

class _TreesScreenState extends State<TreesScreen> {
  final _service = TreeService.instance;
  late final Stream<List<FamilyTree>> _trees =
      _service.watchTrees(widget.user.uid);

  String get _uid => widget.user.uid;

  Future<void> _run(Future<void> Function() action, [String? ok]) async {
    try {
      await action();
      if (ok != null && mounted) showSnack(context, ok);
    } catch (e) {
      if (mounted) showSnack(context, AuthService.errorMessage(e));
    }
  }

  Future<void> _create() async {
    final values = await showInputDialog(
      context,
      title: 'Yangi oila daraxti',
      labels: const ['Daraxt nomi (masalan: Karimovlar oilasi)', 'Izoh'],
      okText: 'Yaratish',
    );
    if (values == null) return;
    await _run(
      () => _service.createTree(
          uid: _uid, name: values[0], description: values[1]),
      'Daraxt yaratildi',
    );
  }

  Future<void> _join() async {
    final values = await showInputDialog(
      context,
      title: 'Daraxtga qo\'shilish',
      labels: const ['Daraxt kodi (ID)'],
      okText: 'Qo\'shilish',
    );
    if (values == null) return;
    await _run(() => _service.joinTree(values[0], _uid),
        'Daraxtga muvaffaqiyatli qo\'shildingiz');
  }

  Future<void> _edit(FamilyTree t) async {
    final values = await showInputDialog(
      context,
      title: 'Daraxtni tahrirlash',
      labels: const ['Daraxt nomi', 'Izoh'],
      initialValues: [t.name, t.description],
    );
    if (values == null) return;
    await _run(() =>
        _service.updateTree(t.id, name: values[0], description: values[1]));
  }

  Future<void> _delete(FamilyTree t) async {
    final ok = await showConfirmDialog(
      context,
      title: 'Daraxtni o\'chirish',
      message:
          '"${t.name}" va undagi barcha shaxslar butunlay o\'chiriladi. Davom etasizmi?',
      okText: 'O\'chirish',
      destructive: true,
    );
    if (ok) await _run(() => _service.deleteTree(t.id), 'Daraxt o\'chirildi');
  }

  Future<void> _leave(FamilyTree t) async {
    final ok = await showConfirmDialog(
      context,
      title: 'Daraxtdan chiqish',
      message: '"${t.name}" daraxtidan chiqasizmi?',
      okText: 'Chiqish',
    );
    if (ok) await _run(() => _service.leaveTree(t.id, _uid));
  }

  Future<void> _signOut() async {
    final ok = await showConfirmDialog(
      context,
      title: 'Chiqish',
      message: 'Hisobingizdan chiqasizmi?',
      okText: 'Chiqish',
    );
    if (ok) await AuthService.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.user.displayName;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Oila daraxtlarim'),
        actions: [
          IconButton(
            tooltip: 'Kod orqali qo\'shilish',
            icon: const Icon(Icons.group_add),
            onPressed: _join,
          ),
          IconButton(
            tooltip: 'Hisobdan chiqish',
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _create,
        icon: const Icon(Icons.add),
        label: const Text('Yangi daraxt'),
      ),
      body: StreamBuilder<List<FamilyTree>>(
        stream: _trees,
        builder: (context, snap) {
          if (snap.hasError) {
            return _Message(
              icon: Icons.error_outline,
              text: 'Xatolik: ${AuthService.errorMessage(snap.error!)}',
            );
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final trees = snap.data!;
          if (trees.isEmpty) {
            return _Message(
              icon: Icons.park_outlined,
              text: 'Salom${name == null || name.isEmpty ? '' : ', $name'}!\n'
                  'Hali oila daraxtingiz yo\'q.\n'
                  '"Yangi daraxt" tugmasini bosing yoki kod orqali qo\'shiling.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
            itemCount: trees.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final t = trees[i];
              final owner = t.isOwner(_uid);
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
                    child: const Icon(Icons.account_tree),
                  ),
                  title: Text(t.name,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text([
                    if (t.description.isNotEmpty) t.description,
                    '${t.members.length} a\'zo${owner ? ' · siz egasisiz' : ''}',
                  ].join('\n')),
                  isThreeLine: t.description.isNotEmpty,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TreeScreen(tree: t, uid: _uid),
                    ),
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (v) {
                      if (v == 'edit') _edit(t);
                      if (v == 'delete') _delete(t);
                      if (v == 'leave') _leave(t);
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                          value: 'edit', child: Text('Tahrirlash')),
                      if (owner)
                        const PopupMenuItem(
                            value: 'delete', child: Text('O\'chirish'))
                      else
                        const PopupMenuItem(
                            value: 'leave', child: Text('Daraxtdan chiqish')),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 72, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 16),
            Text(text, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
