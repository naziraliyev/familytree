import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:family_tree/models/person.dart';
import 'package:family_tree/services/tree_service.dart';
import 'package:family_tree/widgets/family_tree_view.dart';
import 'package:family_tree/widgets/person_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore db;

  setUp(() async {
    db = FakeFirebaseFirestore();
    TreeService.instance = TreeService(db);
    final persons = db.collection('trees').doc('t1').collection('persons');
    await persons.doc('p1').set({
      'firstName': 'Akmal',
      'lastName': 'Karimov',
      'gender': 'male',
      'spouseIds': <String>[],
    });
    await persons.doc('p2').set({
      'firstName': 'Jasur',
      'lastName': 'Karimov',
      'gender': 'male',
      'fatherId': 'p1',
      'spouseIds': <String>[],
    });
  });

  Future<void> openSheet(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (ctx) => Center(
            child: ElevatedButton(
              onPressed: () =>
                  showPersonSheet(ctx, treeId: 't1', personId: 'p1'),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  /// Uzun formada pastdagi elementgacha aylantiradi.
  Future<void> reveal(WidgetTester tester, Finder f) async {
    await tester.dragUntilVisible(
        f, find.byType(ListView).first, const Offset(0, -150));
    await tester.pumpAndSettle();
  }

  testWidgets('shaxs oynasi ma\'lumot va qarindoshlarni ko\'rsatadi',
      (tester) async {
    await openSheet(tester);
    expect(find.text('Akmal Karimov'), findsOneWidget);
    expect(find.text('Ma\'lumot kiritilmagan'), findsOneWidget);
    expect(find.text('Farzandlari (1)'), findsOneWidget);
    expect(find.text('Jasur Karimov'), findsOneWidget);
  });

  testWidgets('Tahrirlash shu oynaning o\'zida ishlaydi va saqlaydi',
      (tester) async {
    await openSheet(tester);

    await tester.tap(find.text('Tahrirlash'));
    await tester.pumpAndSettle();

    // Tahrirlash rejimi: forma shu oynada ochildi
    expect(find.text('Akmal Karimov — tahrirlash'), findsOneWidget);
    final job = find.widgetWithText(TextFormField, 'Kasbi');
    await reveal(tester, job);
    await tester.enterText(job, 'O\'qituvchi');
    final bio = find.widgetWithText(TextFormField, 'Shaxs haqida ma\'lumot');
    await reveal(tester, bio);
    await tester.enterText(bio, 'Mehribon ota, bog\'bon.');

    final save = find.text('Saqlash');
    await reveal(tester, save);
    await tester.tap(save);
    await tester.pumpAndSettle();

    // Bazaga yozildi
    final doc = await db
        .collection('trees')
        .doc('t1')
        .collection('persons')
        .doc('p1')
        .get();
    expect(doc['occupation'], 'O\'qituvchi');
    expect(doc['bio'], 'Mehribon ota, bog\'bon.');

    // Ko'rish rejimiga qaytdi va yangi ma'lumot ko'rinadi
    expect(find.text('Saqlash'), findsNothing);
    expect(find.text('Mehribon ota, bog\'bon.'), findsOneWidget);
    expect(find.text('O\'qituvchi'), findsOneWidget);

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('Bekor qilish o\'zgarishsiz ko\'rish rejimiga qaytaradi',
      (tester) async {
    await openSheet(tester);
    await tester.tap(find.text('Tahrirlash'));
    await tester.pumpAndSettle();
    final cancel = find.text('Bekor qilish');
    await reveal(tester, cancel);
    await tester.tap(cancel);
    await tester.pumpAndSettle();
    expect(find.text('Saqlash'), findsNothing);
    expect(find.text('Ma\'lumot kiritilmagan'), findsOneWidget);
  });

  testWidgets('daraxtdagi kartochka bosilganda callback chaqiriladi',
      (tester) async {
    Person? tapped;
    final persons = [
      Person(id: 'f', firstName: 'Ota', gender: Gender.male, spouseIds: ['m']),
      Person(id: 'm', firstName: 'Ona', gender: Gender.female),
      Person(
          id: 'c',
          firstName: 'Bola',
          gender: Gender.male,
          fatherId: 'f',
          motherId: 'm'),
    ];
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: FamilyTreeView(persons: persons, onPersonTap: (p) => tapped = p),
      ),
    ));
    await tester.tap(find.text('Bola'));
    expect(tapped?.id, 'c');
  });
}
