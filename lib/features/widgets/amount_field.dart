import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A rupee text input that reports its value in paise via [onChanged].
class AmountField extends StatefulWidget {
  const AmountField({
    super.key,
    required this.label,
    required this.onChanged,
    this.initialPaise = 0,
  });

  final String label;
  final ValueChanged<int> onChanged;
  final int initialPaise;

  @override
  State<AmountField> createState() => _AmountFieldState();
}

class _AmountFieldState extends State<AmountField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialPaise > 0
        ? (widget.initialPaise / 100).toStringAsFixed(2)
        : '',
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String text) {
    final rupees = double.tryParse(text.trim());
    widget.onChanged(rupees == null ? 0 : (rupees * 100).round());
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
      ],
      decoration: InputDecoration(
        labelText: widget.label,
        prefixText: '₹ ',
        border: const OutlineInputBorder(),
      ),
      onChanged: _onChanged,
    );
  }
}
