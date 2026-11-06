import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/family_tree.dart';
import '../models/person.dart';
import '../services/auth_service.dart';
import '../services/tree_service.dart';
import '../widgets/dialogs.dart';
import '../widgets/family_tree_view.dart';
import '../widgets/person_card.dart';
import 'person_detail_screen.dart';
import 'person_form_screen.dart';

/// Bitta oila daraxti: vizual ko'rinish va ro'yxat.
class TreeScreen extends StatefulWidget {
  const TreeScreen({super.key, required this.tree, required this.uid});

  final FamilyTree tree;
  final String uid;

  @override
  State<TreeScreen> createState() => _TreeScreenState();
}

class _TreeScreenState extends State<TreeScreen> {
  late final Stream<List<Person>> _persons =
      TreeService.instance.watchPersons(widget.tree.id);
  String _query = '';

  void _openPerson(Person p) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            PersonDetailScreen(treeId: widget.tree.id, personId: p.id),
      ),
    );
  }

  void _addPerson(List<Person> persons) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            PersonFormScreen(treeId: widget.tree.id, allPersons: persons),
      ),
    );
  }

  void _share() {
    final id = widget.tree.id;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Daraxtni ulashish'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
                'Qarindoshlaringizga shu kodni yuboring. Ular "Kod orqali '
                'qo\'shilish" tugmasi orqali daraxtni birga tahrirlay oladi.'),
            const SizedBox(height: 16),
            SelectableText(id,
                style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Yopish')),
          FilledButton.icon(
            icon: const Icon(Icons.copy),
            label: const Text('Nusxalash'),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: id));
              if (ctx.mounted) Navigator.pop(ctx);
              if (mounted) showSnack(context, 'Kod nusxalandi');
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Person>>(
      stream: _persons,
      builder: (context, snap) {
        final persons = snap.data ?? const <Person>[];
        return DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: AppBar(
              title: Text(widget.tree.name),
              actions: [
                IconButton(
                  tooltip: 'Ulashish',
                  icon: const Icon(Icons.share),
                  onPressed: _share,
                ),
              ],
              bottom: TabBar(tabs: [
                const Tab(icon: Icon(Icons.account_tree), text: 'Daraxt'),
                Tab(
                    icon: const Icon(Icons.list),
                    text: 'Ro\'yxat (${persons.length})'),
              ]),
            ),
            floatingActionButton: snap.hasData
                ? FloatingActionButton(
                    heroTag: 'addPerson',
                    tooltip: 'Shaxs qo\'shish',
                    onPressed: () => _addPerson(persons),
                    child: const Icon(Icons.person_add),
                  )
                : null,
            body: _body(snap, persons),
          ),
        );
      },
    );
  }

  Widget _body(AsyncSnapshot<List<Person>> snap, List<Person> persons) {
    if (snap.hasError) {
      return Center(
          child: Text('Xatolik: ${AuthService.errorMessage(snap.error!)}'));
    }
    if (!snap.hasData) {
      return const Center(child: CircularProgressIndicator());
    }
    if (persons.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.family_restroom,
                  size: 80, color: Theme.of(context).colorScheme.outline),
              const SizedBox(height: 16),
              const Text(
                'Daraxt hali bo\'sh.\nBirinchi shaxsni (masalan, o\'zingizni) qo\'shing.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => _addPerson(persons),
                icon: const Icon(Icons.person_add),
                label: const Text('Shaxs qo\'shish'),
              ),
            ],
          ),
        ),
      );
    }
    return TabBarView(
      // Daraxtni surish tab almashishi bilan to'qnashmasligi uchun
      physics: const NeverScrollableScrollPhysics(),
      children: [
        FamilyTreeView(persons: persons, onPersonTap: _openPerson),
        _list(persons),
      ],
    );
  }

  Widget _list(List<Person> persons) {
    final q = _query.toLowerCase();
    final filtered =
        persons.where((p) => p.fullName.toLowerCase().contains(q)).toList();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Ism bo\'yicha qidirish',
            ),
            onChanged: (v) => setState(() => _query = v),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 88),
            itemCount: filtered.length,
            itemBuilder: (_, i) {
              final p = filtered[i];
              return ListTile(
                leading: PersonAvatar(person: p),
                title: Text(p.fullName),
                subtitle: Text([
                  p.gender.label,
                  if (p.lifeSpan.isNotEmpty) p.lifeSpan,
                  if (p.birthPlace != null && p.birthPlace!.isNotEmpty)
                    p.birthPlace!,
                ].join(' · ')),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _openPerson(p),
              );
            },
          ),
        ),
      ],
    );
  }
}
