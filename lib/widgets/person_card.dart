import 'package:flutter/material.dart';

import '../models/person.dart';

const double kNodeW = 150;
const double kNodeH = 72;

Color genderColor(Gender g) =>
    g == Gender.male ? const Color(0xFF1E88E5) : const Color(0xFFD81B60);

class PersonAvatar extends StatelessWidget {
  const PersonAvatar({super.key, required this.person, this.radius = 20});

  final Person person;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final color = person.isAlive ? genderColor(person.gender) : Colors.grey;
    return CircleAvatar(
      radius: radius,
      backgroundColor: color.withValues(alpha: 0.15),
      foregroundColor: color,
      child: person.initials.isEmpty
          ? Icon(person.gender == Gender.male ? Icons.man : Icons.woman)
          : Text(person.initials,
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: radius * 0.7)),
    );
  }
}

/// Daraxt ichidagi bitta shaxs kartochkasi.
class PersonCard extends StatelessWidget {
  const PersonCard({
    super.key,
    required this.person,
    this.onTap,
    this.highlighted = false,
  });

  final Person person;
  final VoidCallback? onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = person.isAlive ? genderColor(person.gender) : Colors.grey;
    return Material(
      color: scheme.surfaceContainerHighest,
      elevation: highlighted ? 6 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: highlighted ? scheme.primary : color,
          width: highlighted ? 3 : 1.5,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: SizedBox(
          width: kNodeW,
          height: kNodeH,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                PersonAvatar(person: person, radius: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        person.fullName.isEmpty ? '—' : person.fullName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      if (person.lifeSpan.isNotEmpty)
                        Text(
                          person.isAlive
                              ? person.lifeSpan
                              : '${person.lifeSpan} †',
                          style: TextStyle(
                              fontSize: 11, color: scheme.onSurfaceVariant),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
