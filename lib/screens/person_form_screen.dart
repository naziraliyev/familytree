import 'package:flutter/material.dart';

import '../models/person.dart';
import '../widgets/person_form.dart';

/// Shaxs qo'shish yoki tahrirlash sahifasi.
class PersonFormScreen extends StatelessWidget {
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
  final String? linkAsParentOf;
  final String? title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title ?? (initial != null ? 'Tahrirlash' : 'Yangi shaxs')),
      ),
      body: PersonForm(
        treeId: treeId,
        allPersons: allPersons,
        initial: initial,
        presetGender: presetGender,
        presetFatherId: presetFatherId,
        presetMotherId: presetMotherId,
        presetSpouseId: presetSpouseId,
        linkAsParentOf: linkAsParentOf,
        onSaved: () => Navigator.pop(context),
      ),
    );
  }
}
