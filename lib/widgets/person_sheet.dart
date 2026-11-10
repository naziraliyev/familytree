import 'package:flutter/material.dart';

import '../models/person.dart';
import '../screens/person_detail_screen.dart';
import '../services/auth_service.dart';
import '../services/tree_service.dart';
import '../utils/person_actions.dart';
import '../utils/relations.dart';
import 'person_form.dart';
import 'person_info.dart';

/// Shaxs ustiga bosilganda ochiladigan oyna.
/// Ma'lumotlarni ko'rsatadi; "Tahrirlash" bosilsa shu oynaning o'zida
/// tahrirlash formasiga o'tadi.
Future<void> showPersonSheet(
  BuildContext context, {
  required String treeId,
  required String personId,
  bool startEditing = false,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => PersonSheet(
      treeId: treeId,
      personId: personId,
      startEditing: startEditing,
    ),
  );
}

class PersonSheet extends StatefulWidget {
  const PersonSheet({
    super.key,
    required this.treeId,
    required this.personId,
    this.startEditing = false,
  });

  final String treeId;
  final String personId;
  final bool startEditing;

  @override
  State<PersonSheet> createState() => _PersonSheetState();
}

class _PersonSheetState extends State<PersonSheet> {
  late final Stream<List<Person>> _persons =
      TreeService.instance.watchPersons(widget.treeId);

  /// Qarindosh chipiga bosilsa, oyna o'sha shaxsga o'tadi.
  late String _id = widget.personId;
  late bool _editing = widget.startEditing;

  final _sheet = DraggableScrollableController();

  @override
  void dispose() {
    _sheet.dispose();
    super.dispose();
  }

  void _showPerson(Person p) => setState(() {
        _id = p.id;
        _editing = false;
      });

  void _startEdit() {
    setState(() => _editing = true);
    // Formaga joy bo'lishi uchun oynani kengaytiramiz
    if (_sheet.isAttached && _sheet.size < 0.9) {
      _sheet.animateTo(0.92,
          duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      controller: _sheet,
      expand: false,
      initialChildSize: _editing ? 0.92 : 0.65,
      minChildSize: 0.35,
      maxChildSize: 0.95,
      builder: (context, scroll) => StreamBuilder<List<Person>>(
        stream: _persons,
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text(AuthService.errorMessage(snap.error!)));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final rel = Relations(snap.data!);
          final p = rel.get(_id);
          if (p == null) {
            return const Center(child: Text('Shaxs topilmadi'));
          }
          // Animatsiyasiz almashtiramiz: oynaning skroll boshqaruvchisi
          // bir vaqtda faqat bitta ro'yxatga ulangan bo'lishi kerak.
          return _editing
              ? _editView(p, rel, scroll)
              : _infoView(p, rel, scroll);
        },
      ),
    );
  }

  // ------------------------- Ko'rish rejimi -------------------------

  Widget _infoView(Person p, Relations rel, ScrollController scroll) {
    return ListView(
      key: ValueKey('view-${p.id}'),
      controller: scroll,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        PersonHeader(
          person: p,
          trailing: IconButton.filledTonal(
            tooltip: 'Tahrirlash',
            icon: const Icon(Icons.edit),
            onPressed: _startEdit,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: _startEdit,
                icon: const Icon(Icons.edit),
                label: const Text('Tahrirlash'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => chooseAndAddRelative(context,
                    treeId: widget.treeId, person: p, rel: rel),
                icon: const Icon(Icons.person_add_alt_1),
                label: const Text('Qarindosh'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        PersonInfoCard(person: p),
        RelativesSections(person: p, rel: rel, onTap: _showPerson),
        const SizedBox(height: 16),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          children: [
            TextButton.icon(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => PersonDetailScreen(
                    treeId: widget.treeId, personId: p.id),
              )),
              icon: const Icon(Icons.open_in_full),
              label: const Text('To\'liq sahifa'),
            ),
            TextButton.icon(
              style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error),
              onPressed: () async {
                final deleted = await confirmAndDeletePerson(context,
                    treeId: widget.treeId, person: p, all: rel.all);
                if (deleted && mounted) Navigator.of(context).pop();
              },
              icon: const Icon(Icons.delete_outline),
              label: const Text('O\'chirish'),
            ),
          ],
        ),
      ],
    );
  }

  // ------------------------ Tahrirlash rejimi ------------------------

  Widget _editView(Person p, Relations rel, ScrollController scroll) {
    return PersonForm(
      key: ValueKey('edit-${p.id}'),
      treeId: widget.treeId,
      allPersons: rel.all,
      initial: p,
      scrollController: scroll,
      header: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          children: [
            const Icon(Icons.edit),
            const SizedBox(width: 8),
            Expanded(
              child: Text('${p.fullName} — tahrirlash',
                  style: Theme.of(context).textTheme.titleMedium),
            ),
          ],
        ),
      ),
      onCancel: () => setState(() => _editing = false),
      onSaved: () => setState(() => _editing = false),
    );
  }
}
