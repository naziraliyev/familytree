import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/person.dart';
import '../services/auth_service.dart';
import '../services/tree_service.dart';
import '../utils/relations.dart';
import '../widgets/dialogs.dart';
import '../widgets/person_card.dart';

/// Shaxs qo'shish yoki tahrirlash.
class PersonFormScreen extends StatefulWidget {
  const PersonFormScreen({
    super.key,
    required this.treeId,
    required this.allPersons,
    this.initial,
    this.presetGender,
    this.presetFatherId,
    this.presetMotherId,
    this.presetSpouseId,
    this.linkAsParentOf,
    this.title,
  });

  final String treeId;
  final List<Person> allPersons;
  final Person? initial;
  final Gender? presetGender;
  final String? presetFatherId;
  final String? presetMotherId;
  final String? presetSpouseId;

  /// Yangi shaxs shu ID egasining otasi/onasi sifatida bog'lanadi.
  final String? linkAsParentOf;
  final String? title;

  @override
  State<PersonFormScreen> createState() => _PersonFormScreenState();
}

class _PersonFormScreenState extends State<PersonFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _df = DateFormat('dd.MM.yyyy');

  Person? get _init => widget.initial;
  late final _firstName = TextEditingController(text: _init?.firstName);
  late final _lastName = TextEditingController(text: _init?.lastName);
  late final _birthPlace = TextEditingController(text: _init?.birthPlace);
  late final _bio = TextEditingController(text: _init?.bio);

  late Gender _gender = _init?.gender ?? widget.presetGender ?? Gender.male;
  late DateTime? _birth = _init?.birthDate;
  late DateTime? _death = _init?.deathDate;
  late bool _deceased = _init?.deathDate != null;
  late String? _fatherId = _init?.fatherId ?? widget.presetFatherId;
  late String? _motherId = _init?.motherId ?? widget.presetMotherId;
  late final Set<String> _spouses = {
    ...?_init?.spouseIds,
    if (widget.presetSpouseId != null) widget.presetSpouseId!,
  };
  bool _saving = false;

  late final Relations _rel = Relations(widget.allPersons);

  bool get _isEdit => _init != null;

  /// O'zi va avlodlari ota-ona bo'la olmaydi.
  late final Set<String> _forbiddenParents = _computeForbidden();

  Set<String> _computeForbidden() {
    final p = widget.initial;
    if (p == null) return <String>{};
    return {p.id, ..._rel.descendantIds(p)};
  }

  @override
  void initState() {
    super.initState();
    // Familiyani ota-onadan avtomatik olish
    if (!_isEdit && _lastName.text.isEmpty) {
      final f = _rel.get(_fatherId);
      if (f != null) _lastName.text = f.lastName;
    }
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _birthPlace.dispose();
    _bio.dispose();
    super.dispose();
  }

  Future<DateTime?> _pickDate(DateTime? current) {
    final now = DateTime.now();
    return showDatePicker(
      context: context,
      initialDate: current ?? DateTime(now.year - 30),
      firstDate: DateTime(1000),
      lastDate: now,
      helpText: 'Sanani tanlang',
    );
  }

  Future<void> _pickParent(bool father) async {
    final candidates = widget.allPersons
        .where((p) =>
            p.gender == (father ? Gender.male : Gender.female) &&
            !_forbiddenParents.contains(p.id))
        .toList();
    final picked = await showPersonPicker(
      context,
      title: father ? 'Otasini tanlang' : 'Onasini tanlang',
      candidates: candidates,
    );
    if (picked == null) return;
    setState(() {
      if (father) {
        _fatherId = picked.id;
        if (_lastName.text.isEmpty) _lastName.text = picked.lastName;
        // Onasi tanlanmagan bo'lsa, otaning rafiqasini taklif qilamiz
        _motherId ??= _rel
            .spouses(picked)
            .where((s) => s.gender == Gender.female)
            .map((s) => s.id)
            .cast<String?>()
            .firstWhere((_) => true, orElse: () => null);
      } else {
        _motherId = picked.id;
        _fatherId ??= _rel
            .spouses(picked)
            .where((s) => s.gender == Gender.male)
            .map((s) => s.id)
            .cast<String?>()
            .firstWhere((_) => true, orElse: () => null);
      }
    });
  }

  Future<void> _pickSpouse() async {
    final candidates = widget.allPersons
        .where((p) => p.id != _init?.id && !_spouses.contains(p.id))
        .toList();
    final picked = await showPersonPicker(
      context,
      title: 'Turmush o\'rtog\'ini tanlang',
      candidates: candidates,
    );
    if (picked != null) setState(() => _spouses.add(picked.id));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_deceased && _death == null) {
      showSnack(context, 'Vafot etgan sanani kiriting.');
      return;
    }
    if (_birth != null && _death != null && _death!.isBefore(_birth!)) {
      showSnack(context, 'Vafot sanasi tug\'ilgan sanadan oldin bo\'lishi mumkin emas.');
      return;
    }

    final person = Person(
      id: _init?.id ?? '',
      firstName: _firstName.text.trim(),
      lastName: _lastName.text.trim(),
      gender: _gender,
      birthDate: _birth,
      deathDate: _deceased ? _death : null,
      birthPlace: _birthPlace.text.trim().isEmpty ? null : _birthPlace.text.trim(),
      bio: _bio.text.trim().isEmpty ? null : _bio.text.trim(),
      fatherId: _fatherId,
      motherId: _motherId,
      spouseIds: _spouses.toList(),
    );

    setState(() => _saving = true);
    try {
      final service = TreeService.instance;
      final old = widget.initial;
      if (old != null) {
        await service.updatePerson(widget.treeId, old, person);
      } else {
        await service.addPerson(widget.treeId, person,
            linkAsParentOf: widget.linkAsParentOf);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        showSnack(context, AuthService.errorMessage(e));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title ??
            (_isEdit ? 'Tahrirlash' : 'Yangi shaxs')),
        actions: [
          IconButton(
            tooltip: 'Saqlash',
            icon: const Icon(Icons.check),
            onPressed: _saving ? null : _save,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _firstName,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Ismi *'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Ismni kiriting' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _lastName,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Familiyasi'),
            ),
            const SizedBox(height: 16),
            SegmentedButton<Gender>(
              segments: const [
                ButtonSegment(
                    value: Gender.male,
                    icon: Icon(Icons.man),
                    label: Text('Erkak')),
                ButtonSegment(
                    value: Gender.female,
                    icon: Icon(Icons.woman),
                    label: Text('Ayol')),
              ],
              selected: {_gender},
              onSelectionChanged: (s) => setState(() => _gender = s.first),
            ),
            const SizedBox(height: 8),
            _dateTile(
              icon: Icons.cake,
              label: 'Tug\'ilgan sana',
              value: _birth,
              onPick: () async {
                final d = await _pickDate(_birth);
                if (d != null) setState(() => _birth = d);
              },
              onClear: () => setState(() => _birth = null),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: const Icon(Icons.local_florist),
              title: const Text('Vafot etgan'),
              value: _deceased,
              onChanged: (v) => setState(() => _deceased = v),
            ),
            if (_deceased)
              _dateTile(
                icon: Icons.event,
                label: 'Vafot etgan sana',
                value: _death,
                onPick: () async {
                  final d = await _pickDate(_death ?? _birth);
                  if (d != null) setState(() => _death = d);
                },
                onClear: () => setState(() => _death = null),
              ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _birthPlace,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Tug\'ilgan joyi',
                prefixIcon: Icon(Icons.place),
              ),
            ),
            const SizedBox(height: 24),
            Text('Qarindoshlik',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            _relativeTile(
              label: 'Otasi',
              icon: Icons.man,
              personId: _fatherId,
              onPick: () => _pickParent(true),
              onClear: () => setState(() => _fatherId = null),
            ),
            _relativeTile(
              label: 'Onasi',
              icon: Icons.woman,
              personId: _motherId,
              onPick: () => _pickParent(false),
              onClear: () => setState(() => _motherId = null),
            ),
            const SizedBox(height: 8),
            const Text('Turmush o\'rtog\'i'),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final id in _spouses)
                  if (_rel.get(id) != null)
                    InputChip(
                      avatar: PersonAvatar(person: _rel.get(id)!, radius: 12),
                      label: Text(_rel.get(id)!.fullName),
                      onDeleted: () => setState(() => _spouses.remove(id)),
                    ),
                ActionChip(
                  avatar: const Icon(Icons.add),
                  label: const Text('Tanlash'),
                  onPressed: _pickSpouse,
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _bio,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Tarjimai hol / izoh',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16)),
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.save),
              label: const Text('Saqlash'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dateTile({
    required IconData icon,
    required String label,
    required DateTime? value,
    required VoidCallback onPick,
    required VoidCallback onClear,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(label),
      subtitle: Text(value == null ? 'Tanlanmagan' : _df.format(value)),
      onTap: onPick,
      trailing: value == null
          ? const Icon(Icons.calendar_month)
          : IconButton(icon: const Icon(Icons.clear), onPressed: onClear),
    );
  }

  Widget _relativeTile({
    required String label,
    required IconData icon,
    required String? personId,
    required VoidCallback onPick,
    required VoidCallback onClear,
  }) {
    final p = _rel.get(personId);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: p == null ? Icon(icon) : PersonAvatar(person: p),
      title: Text(label),
      subtitle: Text(p?.fullName ?? 'Tanlanmagan'),
      onTap: onPick,
      trailing: p == null
          ? const Icon(Icons.chevron_right)
          : IconButton(icon: const Icon(Icons.clear), onPressed: onClear),
    );
  }
}
