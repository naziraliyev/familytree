import 'package:cloud_firestore/cloud_firestore.dart';

/// Bitta oila daraxti. Firestore: trees/{treeId}
class FamilyTree {
  FamilyTree({
    required this.id,
    required this.name,
    this.description = '',
    required this.ownerId,
    required this.members,
    this.createdAt,
  });

  final String id;
  final String name;
  final String description;
  final String ownerId;
  final List<String> members;
  final DateTime? createdAt;

  bool isOwner(String uid) => ownerId == uid;

  factory FamilyTree.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const <String, dynamic>{};
    return FamilyTree(
      id: doc.id,
      name: d['name'] as String? ?? 'Nomsiz daraxt',
      description: d['description'] as String? ?? '',
      ownerId: d['ownerId'] as String? ?? '',
      members: List<String>.from(d['members'] as List? ?? const []),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
