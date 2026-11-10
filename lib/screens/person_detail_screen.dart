import 'package:flutter/material.dart';

import '../models/person.dart';
import '../services/auth_service.dart';
import '../services/tree_service.dart';
import '../utils/person_actions.dart';
import '../utils/relations.dart';
import '../widgets/person_info.dart';
import '../widgets/person_sheet.dart';

/// Shaxs haqida to'liq sahifa va qarindoshlari.
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

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Person>>(
      stream: _persons,
      builder: (context, snap) {
        if (snap.hasError) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(child: Text(AuthService.errorMessage(snap.error!))),
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
        return Scaffold(
          appBar: AppBar(
            title: Text(p.fullName),
            actions: [
              IconButton(
                tooltip: 'Tahrirlash',
                icon: const Icon(Icons.edit),
                onPressed: () => showPersonSheet(context,
                    treeId: widget.treeId,
                    personId: p.id,
                    startEditing: true),
              ),
              IconButton(
                tooltip: 'O\'chirish',
                icon: const Icon(Icons.delete_outline),
                onPressed: () async {
                  final deleted = await confirmAndDeletePerson(context,
                      treeId: widget.treeId, person: p, all: rel.all);
                  if (deleted && context.mounted) Navigator.of(context).pop();
                },
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            heroTag: 'addRelative',
            onPressed: () => chooseAndAddRelative(context,
                treeId: widget.treeId, person: p, rel: rel),
            icon: const Icon(Icons.person_add_alt_1),
            label: const Text('Qarindosh'),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            children: [
              PersonHeader(person: p),
              const SizedBox(height: 16),
              PersonInfoCard(person: p),
              RelativesSections(person: p, rel: rel, onTap: _open),
            ],
          ),
        );
      },
    );
  }
}
