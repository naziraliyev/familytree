import 'package:flutter/material.dart';

import '../models/person.dart';
import '../screens/person_form_screen.dart';
import '../services/auth_service.dart';
import '../services/tree_service.dart';
import '../widgets/dialogs.dart';
import 'relations.dart';

/// Shaxs qo'shish/tahrirlash sahifasini ochadi.
void openPersonForm(
  BuildContext context, {
  required String treeId,
  required List<Person> all,
  Person? initial,
  Gender? gender,
  String? fatherId,
  String? motherId,
  String? spouseId,
  String? linkAsParentOf,
  String? title,
}) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => PersonFormScreen(
        treeId: treeId,
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

/// "Kimni qo'shamiz?" menyusini ko'rsatib, tegishli formani ochadi.
/// Bog'lanishlar (ota/ona/turmush o'rtog'i) avtomatik to'ldiriladi.
Future<void> chooseAndAddRelative(
  BuildContext context, {
  required String treeId,
  required Person person,
  required Relations rel,
}) async {
  final p = person;
  final kind = await showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('${p.firstName}ga qarindosh qo\'shish',
              style: Theme.of(ctx).textTheme.titleMedium),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.man),
            title: const Text('Otasi'),
            enabled: rel.father(p) == null,
            onTap: () => Navigator.pop(ctx, 'father'),
          ),
          ListTile(
            leading: const Icon(Icons.woman),
            title: const Text('Onasi'),
            enabled: rel.mother(p) == null,
            onTap: () => Navigator.pop(ctx, 'mother'),
          ),
          ListTile(
            leading: const Icon(Icons.favorite),
            title: const Text('Turmush o\'rtog\'i'),
            onTap: () => Navigator.pop(ctx, 'spouse'),
          ),
          ListTile(
            leading: const Icon(Icons.child_care),
            title: const Text('Farzandi'),
            onTap: () => Navigator.pop(ctx, 'child'),
          ),
        ],
      ),
    ),
  );
  if (kind == null || !context.mounted) return;

  final all = rel.all;
  switch (kind) {
    case 'father':
      openPersonForm(context,
          treeId: treeId,
          all: all,
          gender: Gender.male,
          spouseId: p.motherId,
          linkAsParentOf: p.id,
          title: '${p.firstName}ning otasi');
    case 'mother':
      openPersonForm(context,
          treeId: treeId,
          all: all,
          gender: Gender.female,
          spouseId: p.fatherId,
          linkAsParentOf: p.id,
          title: '${p.firstName}ning onasi');
    case 'spouse':
      openPersonForm(context,
          treeId: treeId,
          all: all,
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
      openPersonForm(context,
          treeId: treeId,
          all: all,
          fatherId: isMale ? p.id : partner?.id,
          motherId: isMale ? partner?.id : p.id,
          title: '${p.firstName}ning farzandi');
  }
}

/// Tasdiqlab, shaxsni o'chiradi. O'chirilsa true qaytaradi.
Future<bool> confirmAndDeletePerson(
  BuildContext context, {
  required String treeId,
  required Person person,
  required List<Person> all,
}) async {
  final ok = await showConfirmDialog(
    context,
    title: 'Shaxsni o\'chirish',
    message: '${person.fullName} o\'chiriladi. Uning qarindoshlik '
        'bog\'lanishlari ham uziladi.',
    okText: 'O\'chirish',
    destructive: true,
  );
  if (!ok) return false;
  try {
    await TreeService.instance.deletePerson(treeId, person, all);
    return true;
  } catch (e) {
    if (context.mounted) showSnack(context, AuthService.errorMessage(e));
    return false;
  }
}
