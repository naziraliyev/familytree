import 'package:family_tree/models/person.dart';
import 'package:family_tree/utils/relations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final father = Person(
      id: 'f', firstName: 'Akmal', lastName: 'Karimov', gender: Gender.male,
      spouseIds: ['m']);
  final mother =
      Person(id: 'm', firstName: 'Dilnoza', gender: Gender.female);
  final son = Person(
      id: 's', firstName: 'Jasur', gender: Gender.male,
      fatherId: 'f', motherId: 'm', birthDate: DateTime(2000, 5, 1));
  final daughter = Person(
      id: 'd', firstName: 'Madina', gender: Gender.female,
      fatherId: 'f', motherId: 'm', birthDate: DateTime(2003, 1, 1));

  final rel = Relations([father, mother, son, daughter]);

  test('ota-ona va farzandlar', () {
    expect(rel.parents(son).map((p) => p.id), containsAll(['f', 'm']));
    expect(rel.children(father).map((p) => p.id), ['s', 'd']);
  });

  test('turmush o\'rtog\'i ikki tomonlama', () {
    expect(rel.spouses(mother).single.id, 'f');
    expect(rel.spouses(father).single.id, 'm');
  });

  test('aka-singil', () {
    expect(rel.siblings(son).single.id, 'd');
  });

  test('avlodlar', () {
    expect(rel.descendantIds(father), {'s', 'd'});
  });

  test('lifeSpan', () {
    expect(son.lifeSpan, '2000 –');
    expect(father.fullName, 'Akmal Karimov');
  });
}
