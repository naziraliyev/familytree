import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

enum Gender { male, female }

extension GenderX on Gender {
  String get label => this == Gender.male ? 'Erkak' : 'Ayol';
  Gender get opposite => this == Gender.male ? Gender.female : Gender.male;
}

/// Oila daraxtidagi bitta shaxs.
/// Firestore: trees/{treeId}/persons/{personId}
class Person {
  Person({
    this.id = '',
    required this.firstName,
    this.lastName = '',
    required this.gender,
    this.birthDate,
    this.deathDate,
    this.birthPlace,
    this.occupation,
    this.bio,
    this.fatherId,
    this.motherId,
    List<String>? spouseIds,
  }) : spouseIds = spouseIds ?? const [];

  final String id;
  final String firstName;
  final String lastName;
  final Gender gender;
  final DateTime? birthDate;
  final DateTime? deathDate;
  final String? birthPlace;
  final String? occupation;
  final String? bio;
  final String? fatherId;
  final String? motherId;
  final List<String> spouseIds;

  String get fullName => '$firstName $lastName'.trim();
  bool get isAlive => deathDate == null;

  String get initials {
    final a = firstName.isNotEmpty ? firstName[0] : '';
    final b = lastName.isNotEmpty ? lastName[0] : '';
    return (a + b).toUpperCase();
  }

  /// Masalan: "1950 – 2010" yoki "1985 –"
  String get lifeSpan {
    final y = DateFormat('yyyy');
    final b = birthDate != null ? y.format(birthDate!) : '?';
    if (deathDate != null) return '$b – ${y.format(deathDate!)}';
    return birthDate == null ? '' : '$b –';
  }

  int? get age {
    if (birthDate == null) return null;
    final end = deathDate ?? DateTime.now();
    var years = end.year - birthDate!.year;
    if (end.month < birthDate!.month ||
        (end.month == birthDate!.month && end.day < birthDate!.day)) {
      years--;
    }
    return years < 0 ? null : years;
  }

  factory Person.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const <String, dynamic>{};
    return Person(
      id: doc.id,
      firstName: d['firstName'] as String? ?? '',
      lastName: d['lastName'] as String? ?? '',
      gender: d['gender'] == 'female' ? Gender.female : Gender.male,
      birthDate: (d['birthDate'] as Timestamp?)?.toDate(),
      deathDate: (d['deathDate'] as Timestamp?)?.toDate(),
      birthPlace: d['birthPlace'] as String?,
      occupation: d['occupation'] as String?,
      bio: d['bio'] as String?,
      fatherId: d['fatherId'] as String?,
      motherId: d['motherId'] as String?,
      spouseIds: List<String>.from(d['spouseIds'] as List? ?? const []),
    );
  }

  Map<String, dynamic> toMap() => {
        'firstName': firstName,
        'lastName': lastName,
        'gender': gender.name,
        'birthDate': birthDate == null ? null : Timestamp.fromDate(birthDate!),
        'deathDate': deathDate == null ? null : Timestamp.fromDate(deathDate!),
        'birthPlace': birthPlace,
        'occupation': occupation,
        'bio': bio,
        'fatherId': fatherId,
        'motherId': motherId,
        'spouseIds': spouseIds,
        'updatedAt': FieldValue.serverTimestamp(),
      };
}
