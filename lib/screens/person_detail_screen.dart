import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/person.dart';
import '../services/auth_service.dart';
import '../services/tree_service.dart';
import '../utils/relations.dart';
import '../widgets/dialogs.dart';
import '../widgets/person_card.dart';
import 'person_form_screen.dart';

/// Shaxs haqida to'liq ma'lumot va qarindoshlari.
class PersonDetailScreen extends StatefulWidget {
  const PersonDetailScreen({
    super.key,
    required this.treeId,
    required this.personId,
  });

  final String treeId;
  final String personId;

  @override
  State<PersonDetailScreen> createState() => _PersonDetailScreenState();
}

class _PersonDetailScreenState extends State<PersonDetailScreen> {
  late final Stream<List<Person>> _persons =
      TreeService.instance.watchPersons(widget.treeId);

  void _open(Person p) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            PersonDetailScreen(treeId: widget.treeId, personId: p.id),
      ),
    );
  }

  void _form(
    List<Person> all, {
    Person? initial,
    Gender? gender,
    String? fatherId,
    String? motherId,
    String? spouseId,
    String? linkAsParentOf,
    String? title,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PersonFormScreen(
          treeId: widget.treeId,
          allPersons: all,
          initial: initial,
          presetGender: gender,
          presetFatherId: fatherId,
          presetMotherId: motherId,
          presetSpouseId: spouseId,
          linkAsParentOf: linkAsParentOf,
          title: title,
        ),
      ),
    );
  }

  void _addRelative(String kind, Person p, Relations rel) {
    final all = rel.all;
    switch (kind) {
      case 'father':
        _form(all,
            gender: Gender.male,
            spouseId: p.motherId,
            linkAsParentOf: p.id,
            title: '${p.firstName}ning otasi');
      case 'mother':
        _form(all,
            gender: Gender.female,
            spouseId: p.fatherId,
            linkAsParentOf: p.id,
            title: '${p.firstName}ning onasi');
      case 'spouse':
        _form(all,
            gender: p.gender.opposite,
            spouseId: p.id,
            title: '${p.firstName}ning turmush o\'rtog\'i');
      case 'child':
        final partner = rel
            .spouses(p)
            .where((s) => s.gender != p.gender)
            .cast<Person?>()
            .firstWhere((_) => true, orElse: () => null);
        final isMale = p.gender == Gender.male;
        _form(all,
            fatherId: isMale ? p.id : partner?.id,
            motherId: isMale ? partner?.id : p.id,
            title: '${p.firstName}ning farzandi');
    }
  }

  Future<void> _chooseRelative(Person p, Relations rel) async {
    final kind = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.man),
              title: const Text('Ota qo\'shish'),
              enabled: rel.father(p) == null,
              onTap: () => Navigator.pop(ctx, 'father'),
            ),
            ListTile(
              leading: const Icon(Icons.woman),
              title: const Text('Ona qo\'shish'),
              enabled: rel.mother(p) == null,
              onTap: () => Navigator.pop(ctx, 'mother'),
            ),
            ListTile(
              leading: const Icon(Icons.favorite),
              title: const Text('Turmush o\'rtog\'i qo\'shish'),
              onTap: () => Navigator.pop(ctx, 'spouse'),
            ),
            ListTile(
              leading: const Icon(Icons.child_care),
              title: const Text('Farzand qo\'shish'),
              onTap: () => Navigator.pop(ctx, 'child'),
            ),
          ],
        ),
      ),
    );
    if (kind != null) _addRelative(kind, p, rel);
  }

  Future<void> _delete(Person p, List<Person> all) async {
    final ok = await showConfirmDialog(
      context,
      title: 'Shaxsni o\'chirish',
      message:
          '${p.fullName} o\'chiriladi. Uning qarindoshlik bog\'lanishlari ham uziladi.',
      okText: 'O\'chirish',
      destructive: true,
    );
    if (!ok) return;
    try {
      await TreeService.instance.deletePerson(widget.treeId, p, all);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) showSnack(context, AuthService.errorMessage(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Person>>(
      stream: _persons,
      builder: (context, snap) {
        if (snap.hasError) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(
                child: Text(AuthService.errorMessage(snap.error!))),
          );
        }
        if (!snap.hasData) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        final rel = Relations(snap.data!);
        final p = rel.get(widget.personId);
        if (p == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Shaxs topilmadi')),
          );
        }
        return _content(p, rel);
      },
    );
  }

  Widget _content(Person p, Relations rel) {
    final df = DateFormat('dd.MM.yyyy');
    final scheme = Theme.of(context).colorScheme;
    final age = p.age;

    return Scaffold(
      appBar: AppBar(
        title: Text(p.fullName),
        actions: [
          IconButton(
            tooltip: 'Tahrirlash',
            icon: const Icon(Icons.edit),
            onPressed: () => _form(rel.all, initial: p),
          ),
          IconButton(
            tooltip: 'O\'chirish',
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _delete(p, rel.all),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'addRelative',
        onPressed: () => _chooseRelative(p, rel),
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Qarindosh'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: [
          Center(child: PersonAvatar(person: p, radius: 44)),
          const SizedBox(height: 12),
          Text(p.fullName,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(
            [
              p.gender.label,
              if (age != null) p.isAlive ? '$age yosh' : '$age yoshda vafot etgan',
            ].join(' · '),
            textAlign: TextAlign.center,
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                _info(Icons.cake, 'Tug\'ilgan sana',
                    p.birthDate == null ? null : df.format(p.birthDate!)),
                _info(Icons.place, 'Tug\'ilgan joy', p.birthPlace),
                if (!p.isAlive)
                  _info(Icons.local_florist, 'Vafot etgan sana',
                      df.format(p.deathDate!)),
                if (p.bio != null && p.bio!.isNotEmpty)
                  _info(Icons.notes, 'Tarjimai hol', p.bio),
              ],
            ),
          ),
          _section('Ota-onasi', rel.parents(p)),
          _section('Turmush o\'rtog\'i', rel.spouses(p)),
          _section('Farzandlari', rel.children(p)),
          _section('Aka-uka / opa-singillari', rel.siblings(p)),
          _section('Bobo-buvilari', rel.grandparents(p)),
          _section('Nevaralari', rel.grandchildren(p)),
        ],
      ),
    );
  }

  Widget _info(IconData icon, String label, String? value) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      subtitle: Text(value == null || value.isEmpty ? 'Kiritilmagan' : value),
    );
  }

  Widget _section(String title, List<Person> people) {
    if (people.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$title (${people.length})',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final r in people)
                ActionChip(
                  avatar: PersonAvatar(person: r, radius: 12),
                  label: Text(r.fullName),
                  onPressed: () => _open(r),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
