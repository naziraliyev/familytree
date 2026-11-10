import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/family_tree.dart';
import '../models/person.dart';
import '../utils/relations.dart';

/// Firestore bilan ishlash.
///
/// Tuzilma:
///   trees/{treeId}                 — name, description, ownerId, members[]
///   trees/{treeId}/persons/{id}    — Person maydonlari
class TreeService {
  TreeService(this._db);

  /// Ilovadagi yagona nusxa. Testlarda soxta baza bilan almashtiriladi.
  static TreeService instance = TreeService(FirebaseFirestore.instance);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _trees =>
      _db.collection('trees');

  CollectionReference<Map<String, dynamic>> _persons(String treeId) =>
      _trees.doc(treeId).collection('persons');

  // ---------------- Daraxtlar ----------------

  Stream<List<FamilyTree>> watchTrees(String uid) {
    return _trees.where('members', arrayContains: uid).snapshots().map((s) {
      final list = s.docs.map(FamilyTree.fromDoc).toList();
      list.sort((a, b) => (b.createdAt ?? DateTime(2100))
          .compareTo(a.createdAt ?? DateTime(2100)));
      return list;
    });
  }

  Stream<FamilyTree?> watchTree(String treeId) => _trees
      .doc(treeId)
      .snapshots()
      .map((d) => d.exists ? FamilyTree.fromDoc(d) : null);

  Future<String> createTree({
    required String uid,
    required String name,
    String description = '',
  }) async {
    final ref = await _trees.add({
      'name': name.trim(),
      'description': description.trim(),
      'ownerId': uid,
      'members': [uid],
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Future<void> updateTree(String treeId,
      {required String name, String description = ''}) {
    return _trees.doc(treeId).update({
      'name': name.trim(),
      'description': description.trim(),
    });
  }

  /// Daraxt ID (ulashish kodi) orqali qo'shilish.
  Future<void> joinTree(String treeId, String uid) {
    return _trees.doc(treeId.trim()).update({
      'members': FieldValue.arrayUnion([uid]),
    });
  }

  Future<void> leaveTree(String treeId, String uid) {
    return _trees.doc(treeId).update({
      'members': FieldValue.arrayRemove([uid]),
    });
  }

  /// Daraxtni va undagi barcha shaxslarni o'chiradi (faqat egasi).
  Future<void> deleteTree(String treeId) async {
    final persons = await _persons(treeId).get();
    final docs = persons.docs;
    for (var i = 0; i < docs.length; i += 400) {
      final batch = _db.batch();
      for (final d in docs.skip(i).take(400)) {
        batch.delete(d.reference);
      }
      await batch.commit();
    }
    await _trees.doc(treeId).delete();
  }

  // ---------------- Shaxslar ----------------

  Stream<List<Person>> watchPersons(String treeId) {
    return _persons(treeId).snapshots().map((s) {
      final list = s.docs.map(Person.fromDoc).toList();
      list.sort((a, b) => a.fullName.toLowerCase().compareTo(
            b.fullName.toLowerCase(),
          ));
      return list;
    });
  }

  /// Yangi shaxs qo'shadi. Turmush o'rtoqlik ikki tomonlama yoziladi.
  /// [linkAsParentOf] berilsa, yangi shaxs o'sha odamning otasi/onasi bo'ladi.
  Future<String> addPerson(
    String treeId,
    Person p, {
    String? linkAsParentOf,
  }) async {
    final col = _persons(treeId);
    final ref = col.doc();
    final batch = _db.batch();
    batch.set(ref, {
      ...p.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    for (final s in p.spouseIds) {
      batch.update(col.doc(s), {
        'spouseIds': FieldValue.arrayUnion([ref.id]),
      });
    }
    if (linkAsParentOf != null) {
      batch.update(col.doc(linkAsParentOf), {
        p.gender == Gender.male ? 'fatherId' : 'motherId': ref.id,
      });
    }
    await batch.commit();
    return ref.id;
  }

  Future<void> updatePerson(String treeId, Person old, Person updated) async {
    final col = _persons(treeId);
    final batch = _db.batch();
    batch.update(col.doc(old.id), updated.toMap());

    final before = old.spouseIds.toSet();
    final after = updated.spouseIds.toSet();
    for (final s in after.difference(before)) {
      batch.update(col.doc(s), {
        'spouseIds': FieldValue.arrayUnion([old.id]),
      });
    }
    for (final s in before.difference(after)) {
      batch.update(col.doc(s), {
        'spouseIds': FieldValue.arrayRemove([old.id]),
      });
    }
    await batch.commit();
  }

  /// Shaxsni o'chiradi va unga bo'lgan barcha havolalarni tozalaydi.
  Future<void> deletePerson(
      String treeId, Person p, List<Person> allPersons) async {
    final col = _persons(treeId);
    final rel = Relations(allPersons);
    final batch = _db.batch();
    batch.delete(col.doc(p.id));
    for (final c in rel.children(p)) {
      batch.update(col.doc(c.id), {
        if (c.fatherId == p.id) 'fatherId': null,
        if (c.motherId == p.id) 'motherId': null,
      });
    }
    for (final s in rel.spouses(p)) {
      batch.update(col.doc(s.id), {
        'spouseIds': FieldValue.arrayRemove([p.id]),
      });
    }
    await batch.commit();
  }
}
