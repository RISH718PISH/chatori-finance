import 'package:flutter/material.dart';

/// A search box + horizontal category chip row, shared by the long
/// inventory lists (stock, consumption, opening) so a 90-item catalogue is
/// filtered to one category or a name instead of endlessly scrolled.
class CategoryBar extends StatelessWidget {
  const CategoryBar({
    super.key,
    required this.categories,
    required this.selected,
    required this.search,
    required this.onCategory,
    required this.onSearch,
  });

  final List<String> categories;
  final String? selected;
  final TextEditingController search;
  final ValueChanged<String?> onCategory;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: TextField(
            controller: search,
            onChanged: (_) => onSearch(),
            decoration: InputDecoration(
              hintText: 'Search items',
              prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder(),
              isDense: true,
              suffixIcon: search.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        search.clear();
                        onSearch();
                      },
                    ),
            ),
          ),
        ),
        if (categories.isNotEmpty)
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _chip('All', selected == null, () => onCategory(null)),
                for (final c in categories)
                  _chip(c, selected == c, () => onCategory(c)),
              ],
            ),
          ),
      ],
    );
  }

  Widget _chip(String label, bool sel, VoidCallback onTap) => Padding(
        padding: const EdgeInsets.only(right: 6),
        child: FilterChip(
          label: Text(label),
          selected: sel,
          onSelected: (_) => onTap(),
        ),
      );
}
