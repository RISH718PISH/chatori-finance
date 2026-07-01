import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// A tappable date row that opens a calendar picker.
class DateField extends StatefulWidget {
  const DateField({
    super.key,
    required this.label,
    required this.initial,
    required this.onChanged,
  });

  final String label;
  final DateTime initial;
  final ValueChanged<DateTime> onChanged;

  @override
  State<DateField> createState() => _DateFieldState();
}

class _DateFieldState extends State<DateField> {
  late DateTime _value = widget.initial;

  Future<void> _pick() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _value,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) {
      setState(() => _value = picked);
      widget.onChanged(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final isToday = _value.year == today.year &&
        _value.month == today.month &&
        _value.day == today.day;
    return InkWell(
      onTap: _pick,
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: widget.label,
          border: const OutlineInputBorder(),
          prefixIcon: const Icon(Icons.event),
          isDense: true,
        ),
        child: Text(isToday
            ? 'Today (${DateFormat('d MMM yyyy').format(_value)})'
            : DateFormat('EEE, d MMM yyyy').format(_value)),
      ),
    );
  }
}
