import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/person.dart';
import '../utils/relations.dart';
import 'person_card.dart';

/// Avatar, ism va qisqa izoh (jinsi, yoshi).
class PersonHeader extends StatelessWidget {
  const PersonHeader({super.key, required this.person, this.trailing});

  final Person person;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final p = person;
    final age = p.age;
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        PersonAvatar(person: p, radius: 30),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(p.fullName,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(
                [
                  p.gender.label,
                  if (age != null)
                    p.isAlive ? '$age yosh' : '$age yoshda vafot etgan',
                ].join(' · '),
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

/// Sana, joy, kasb va "Shaxs haqida" bo'limi.
class PersonInfoCard extends StatelessWidget {
  const PersonInfoCard({super.key, required this.person});

  final Person person;

  @override
  Widget build(BuildContext context) {
    final p = person;
    final df = DateFormat('dd.MM.yyyy');
    final scheme = Theme.of(context).colorScheme;
    final hasBio = p.bio != null && p.bio!.trim().isNotEmpty;

    Widget tile(IconData icon, String label, String? value) => ListTile(
          dense: true,
          leading: Icon(icon),
          title: Text(label),
          subtitle: Text(
            value == null || value.isEmpty ? 'Kiritilmagan' : value,
            style: TextStyle(
              color: value == null || value.isEmpty
                  ? scheme.outline
                  : scheme.onSurface,
            ),
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          margin: EdgeInsets.zero,
          child: Column(
            children: [
              tile(Icons.cake, 'Tug\'ilgan sana',
                  p.birthDate == null ? null : df.format(p.birthDate!)),
              if (!p.isAlive)
                tile(Icons.local_florist, 'Vafot etgan sana',
                    df.format(p.deathDate!)),
              tile(Icons.place, 'Tug\'ilgan joyi', p.birthPlace),
              tile(Icons.work_outline, 'Kasbi', p.occupation),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.notes, size: 20),
                    const SizedBox(width: 8),
                    Text('Shaxs haqida',
                        style: Theme.of(context).textTheme.titleSmall),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  hasBio ? p.bio!.trim() : 'Ma\'lumot kiritilmagan',
                  style: TextStyle(
                    color: hasBio ? scheme.onSurface : scheme.outline,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Barcha qarindoshlik bo'limlari (bo'sh bo'limlar ko'rsatilmaydi).
class RelativesSections extends StatelessWidget {
  const RelativesSections({
    super.key,
    required this.person,
    required this.rel,
    required this.onTap,
  });

  final Person person;
  final Relations rel;
  final ValueChanged<Person> onTap;

  @override
  Widget build(BuildContext context) {
    final p = person;
    final sections = <(String, List<Person>)>[
      ('Ota-onasi', rel.parents(p)),
      ('Turmush o\'rtog\'i', rel.spouses(p)),
      ('Farzandlari', rel.children(p)),
      ('Aka-uka / opa-singillari', rel.siblings(p)),
      ('Bobo-buvilari', rel.grandparents(p)),
      ('Nevaralari', rel.grandchildren(p)),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (title, people) in sections)
          if (people.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$title (${people.length})',
                      style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final r in people)
                        ActionChip(
                          avatar: PersonAvatar(person: r, radius: 12),
                          label: Text(r.fullName),
                          onPressed: () => onTap(r),
                        ),
                    ],
                  ),
                ],
              ),
            ),
      ],
    );
  }
}
