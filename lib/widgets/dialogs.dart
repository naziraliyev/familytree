import 'package:flutter/material.dart';

import '../models/person.dart';
import 'person_card.dart';

/// Bir nechta matn maydonli dialog. Bekor qilinsa null qaytaradi.
Future<List<String>?> showInputDialog(
  BuildContext context, {
  required String title,
  required List<String> labels,
  List<String>? initialValues,
  String okText = 'Saqlash',
}) {
  return showDialog<List<String>>(
    context: context,
    builder: (_) => _InputDialog(
      title: title,
      labels: labels,
      initialValues: initialValues,
      okText: okText,
    ),
  );
}

class _InputDialog extends StatefulWidget {
  const _InputDialog({
    required this.title,
    required this.labels,
    required this.okText,
    this.initialValues,
  });

  final String title;
  final List<String> labels;
  final List<String>? initialValues;
  final String okText;

  @override
  State<_InputDialog> createState() => _InputDialogState();
}

class _InputDialogState extends State<_InputDialog> {
  late final List<TextEditingController> _controllers = [
    for (var i = 0; i < widget.labels.length; i++)
      TextEditingController(
        text: (widget.initialValues != null &&
                i < widget.initialValues!.length)
            ? widget.initialValues![i]
            : '',
      ),
  ];
  String? _error;

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _submit() {
    if (_controllers.first.text.trim().isEmpty) {
      setState(() => _error = 'Bu maydon to\'ldirilishi shart');
      return;
    }
    Navigator.pop(context, _controllers.map((c) => c.text.trim()).toList());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < widget.labels.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TextField(
                controller: _controllers[i],
                autofocus: i == 0,
                decoration: InputDecoration(
                  labelText: widget.labels[i],
                  errorText: i == 0 ? _error : null,
                ),
                onSubmitted: (_) => _submit(),
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Bekor qilish'),
        ),
        FilledButton(onPressed: _submit, child: Text(widget.okText)),
      ],
    );
  }
}

Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String okText = 'Ha',
  bool destructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Yo\'q'),
        ),
        FilledButton(
          style: destructive
              ? FilledButton.styleFrom(
                  backgroundColor: Theme.of(ctx).colorScheme.error,
                  foregroundColor: Theme.of(ctx).colorScheme.onError,
                )
              : null,
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(okText),
        ),
      ],
    ),
  );
  return result ?? false;
}

void showSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

/// Ro'yxatdan shaxs tanlash oynasi (qidiruv bilan).
Future<Person?> showPersonPicker(
  BuildContext context, {
  required String title,
  required List<Person> candidates,
}) {
  return showModalBottomSheet<Person>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _PersonPickerSheet(title: title, candidates: candidates),
  );
}

class _PersonPickerSheet extends StatefulWidget {
  const _PersonPickerSheet({required this.title, required this.candidates});

  final String title;
  final List<Person> candidates;

  @override
  State<_PersonPickerSheet> createState() => _PersonPickerSheetState();
}

class _PersonPickerSheetState extends State<_PersonPickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final q = _query.toLowerCase();
    final list = widget.candidates
        .where((p) => p.fullName.toLowerCase().contains(q))
        .toList();
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.7,
      child: Column(
        children: [
          Text(widget.title, style: Theme.of(context).textTheme.titleMedium),
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Qidirish...',
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: list.isEmpty
                ? const Center(child: Text('Mos shaxs topilmadi'))
                : ListView.builder(
                    itemCount: list.length,
                    itemBuilder: (_, i) {
                      final p = list[i];
                      return ListTile(
                        leading: PersonAvatar(person: p),
                        title: Text(p.fullName),
                        subtitle:
                            p.lifeSpan.isEmpty ? null : Text(p.lifeSpan),
                        onTap: () => Navigator.pop(context, p),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
