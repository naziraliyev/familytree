import '../models/person.dart';

/// Shaxslar ro'yxatidan qarindoshlik bog'lanishlarini hisoblaydi.
class Relations {
  Relations(this.all) : byId = {for (final p in all) p.id: p};

  final List<Person> all;
  final Map<String, Person> byId;

  Person? get(String? id) => id == null ? null : byId[id];

  Person? father(Person p) => get(p.fatherId);
  Person? mother(Person p) => get(p.motherId);

  List<Person> parents(Person p) =>
      [father(p), mother(p)].whereType<Person>().toList();

  List<Person> children(Person p) {
    final list =
        all.where((c) => c.fatherId == p.id || c.motherId == p.id).toList();
    list.sort(_byBirth);
    return list;
  }

  /// Ikki tomonlama: p.spouseIds va boshqalarning spouseIds'ida p bo'lsa.
  List<Person> spouses(Person p) {
    final ids = <String>{
      ...p.spouseIds,
      ...all.where((o) => o.spouseIds.contains(p.id)).map((o) => o.id),
    }..remove(p.id);
    return ids.map(get).whereType<Person>().toList();
  }

  List<Person> siblings(Person p) {
    final list = all.where((o) {
      if (o.id == p.id) return false;
      final sameFather = p.fatherId != null && o.fatherId == p.fatherId;
      final sameMother = p.motherId != null && o.motherId == p.motherId;
      return sameFather || sameMother;
    }).toList();
    list.sort(_byBirth);
    return list;
  }

  List<Person> grandparents(Person p) =>
      parents(p).expand(parents).toSet().toList();

  List<Person> grandchildren(Person p) =>
      children(p).expand(children).toSet().toList();

  /// [p] ning barcha avlodlari (ota-ona qilib tanlab bo'lmaydiganlar).
  Set<String> descendantIds(Person p) {
    final result = <String>{};
    final stack = [p];
    while (stack.isNotEmpty) {
      final cur = stack.removeLast();
      for (final c in children(cur)) {
        if (result.add(c.id)) stack.add(c);
      }
    }
    return result;
  }

  static int _byBirth(Person a, Person b) {
    final da = a.birthDate ?? DateTime(9999);
    final db = b.birthDate ?? DateTime(9999);
    return da.compareTo(db);
  }
}
