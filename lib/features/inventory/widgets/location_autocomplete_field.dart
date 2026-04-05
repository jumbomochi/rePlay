import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/inventory_provider.dart';

class LocationAutocompleteField extends ConsumerWidget {
  final TextEditingController controller;
  final void Function(String) onChanged;
  final InputDecoration? decoration;

  const LocationAutocompleteField({
    super.key,
    required this.controller,
    required this.onChanged,
    this.decoration,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.read(databaseProvider);

    return FutureBuilder<List<String>>(
      future: db.getAllLocations(),
      builder: (context, snapshot) {
        final locations = snapshot.data ?? [];

        return Autocomplete<String>(
          optionsBuilder: (textEditingValue) {
            if (textEditingValue.text.isEmpty) return const Iterable.empty();
            final query = textEditingValue.text.toLowerCase();
            return locations.where((loc) => loc.toLowerCase().contains(query));
          },
          onSelected: (value) {
            controller.text = value;
            onChanged(value);
          },
          fieldViewBuilder: (context, fieldController, focusNode, onFieldSubmitted) {
            if (fieldController.text != controller.text) {
              fieldController.text = controller.text;
            }
            return TextFormField(
              controller: fieldController,
              focusNode: focusNode,
              decoration: decoration ?? const InputDecoration(
                labelText: 'Location (optional)',
                prefixIcon: Icon(Icons.location_on),
                hintText: 'e.g., Playroom shelf, Garage bin 2',
              ),
              onChanged: (value) {
                controller.text = value;
                onChanged(value);
              },
            );
          },
        );
      },
    );
  }
}
