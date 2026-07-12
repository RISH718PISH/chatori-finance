import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../core/design.dart';
import '../../core/money.dart';
import '../transaction/add_transaction_screen.dart';
import 'hyperpure_actions.dart';
import 'hyperpure_parser.dart';
import 'hyperpure_split_screen.dart';
import 'paytm_parser.dart';

class ScreenshotImportScreen extends ConsumerStatefulWidget {
  const ScreenshotImportScreen({super.key});

  @override
  ConsumerState<ScreenshotImportScreen> createState() =>
      _ScreenshotImportScreenState();
}

class _ScreenshotImportScreenState
    extends ConsumerState<ScreenshotImportScreen> {
  bool _busy = false;
  String? _imagePath;
  ParsedPayment? _paytm;
  ParsedHyperpure? _hyperpure;
  String? _error;
  bool _saving = false;

  Future<void> _pick() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final file = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (file == null) {
        setState(() => _busy = false);
        return;
      }
      final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final result =
          await recognizer.processImage(InputImage.fromFilePath(file.path));
      await recognizer.close();
      setState(() {
        _imagePath = file.path;
        // Hyperpure invoices first; otherwise treat as a payment screenshot.
        if (HyperpureParser.looksLikeHyperpure(result.text)) {
          _hyperpure = HyperpureParser.parse(result.text);
          _paytm = null;
        } else {
          _paytm = PaytmParser.parse(result.text);
          _hyperpure = null;
        }
        _busy = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Could not read the image: $e';
        _busy = false;
      });
    }
  }

  void _reviewPaytm() {
    final p = _paytm;
    if (p == null) return;
    context.push(
      '/add',
      extra: AddPrefill(
        type: p.type ?? 'expense',
        amountPaise: p.amountPaise,
        party: p.party,
        occurredAt: p.dateTime,
        fromScreenshot: true,
        attachmentLocalPath: _imagePath,
      ),
    );
  }

  void _splitHyperpure() {
    final h = _hyperpure;
    if (h == null) return;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => HyperpureSplitScreen(
        parsed: h,
        attachmentLocalPath: _imagePath,
      ),
    ));
  }

  Future<void> _autoSaveHyperpure() async {
    final h = _hyperpure;
    if (h == null || _saving) return;
    setState(() => _saving = true);
    try {
      final result = await saveHyperpureBillAsBatch(
        ref: ref,
        parsed: h,
        attachmentLocalPath: _imagePath,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppSemantics.income,
          duration: const Duration(seconds: 5),
          content: Text(
            'Saved ${result.savedCount} '
            '${result.savedCount == 1 ? 'entry' : 'entries'} · '
            '${result.categories.join(' · ')}',
            style: const TextStyle(color: Colors.white),
          ),
        ));
      context.go('/');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not save: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _reviewHyperpure() {
    final h = _hyperpure;
    if (h == null) return;
    // Build a compact note: invoice # + tax breakdown + up to 5 line items.
    final noteParts = <String>[
      h.invoiceNumber == null ? 'Hyperpure invoice' : 'Hyperpure invoice ${h.invoiceNumber}',
      if (h.taxablePaise != null) 'Taxable ${Money.format(h.taxablePaise!)}',
      if (h.taxPaise != null) 'Tax ${Money.format(h.taxPaise!)}',
    ];
    if (h.items.isNotEmpty) {
      final top = h.items.take(5).map((it) {
        final qty = it.quantity == null
            ? ''
            : ' ${it.quantity! % 1 == 0 ? it.quantity!.toInt() : it.quantity}';
        return '• ${it.description}$qty — ${Money.format(it.amountPaise)}';
      }).join('\n');
      noteParts.add(top);
      if (h.items.length > 5) noteParts.add('… +${h.items.length - 5} more');
    }
    context.push(
      '/add',
      extra: AddPrefill(
        type: 'expense',
        category: h.suggestedCategory,
        amountPaise: h.totalPaise,
        party: 'Hyperpure',
        paymentMode: 'Bank',
        occurredAt: h.invoiceDate,
        notes: noteParts.join('\n'),
        fromScreenshot: true,
        attachmentLocalPath: _imagePath,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan bill / screenshot')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Pick a Paytm/UPI payment screenshot or a Hyperpure invoice photo. '
            'The app reads it on your device and pre-fills a new entry for '
            'you to confirm.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _busy ? null : _pick,
            icon: const Icon(Icons.document_scanner_outlined),
            label: Text(_paytm == null && _hyperpure == null
                ? 'Pick image'
                : 'Pick another'),
          ),
          if (_busy) ...[
            const SizedBox(height: 24),
            const Center(child: CircularProgressIndicator()),
            const SizedBox(height: 8),
            const Center(child: Text('Reading image…')),
          ],
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(_error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          if (_hyperpure != null && !_busy) _hyperpureResult(context, _hyperpure!),
          if (_paytm != null && !_busy) _paytmResult(context, _paytm!),
        ],
      ),
    );
  }

  Widget _imagePreview() {
    if (_imagePath == null) return const SizedBox.shrink();
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.file(File(_imagePath!), height: 180, fit: BoxFit.contain),
    );
  }

  Widget _hyperpureResult(BuildContext context, ParsedHyperpure h) {
    final missingTotal = h.totalPaise == null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        _imagePreview(),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.receipt_long, size: 20),
                    const SizedBox(width: 8),
                    Text('Hyperpure invoice detected',
                        style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
                const Divider(),
                _row('Vendor', h.vendorName),
                _row('Invoice', h.invoiceNumber ?? '—'),
                _row(
                    'Date',
                    h.invoiceDate != null
                        ? DateFormat('d MMM yyyy').format(h.invoiceDate!)
                        : 'today'),
                _row('Taxable',
                    h.taxablePaise != null ? Money.format(h.taxablePaise!) : '—'),
                _row('Tax (GST)',
                    h.taxPaise != null ? Money.format(h.taxPaise!) : '—'),
                _row('Total',
                    h.totalPaise != null ? Money.format(h.totalPaise!) : '—'),
                _row('Category', h.suggestedCategory),
                _row('Payment', 'Bank (editable)'),
                if (missingTotal)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Couldn\'t read the total — edit on the next screen.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.error),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (h.items.isNotEmpty) ...[
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                    child: Text('Items (${h.items.length})',
                        style: Theme.of(context).textTheme.titleSmall),
                  ),
                  const Divider(height: 8),
                  for (final it in h.items) _itemRow(context, it),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 8),
        _rawText(context, h.rawText),
        const SizedBox(height: 12),
        // Auto-save is the primary flow: parse → group by category → batch
        // insert without asking the user to review each row. Review and
        // Save-as-one stay as fallbacks.
        FilledButton.icon(
          onPressed: _saving ? null : _autoSaveHyperpure,
          icon: _saving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.bolt),
          label: Text(_saving ? 'Saving…' : _autoSaveButtonLabel(h)),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _saving ? null : _splitHyperpure,
          icon: const Icon(Icons.tune),
          label: const Text('Review split before saving'),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: _saving ? null : _reviewHyperpure,
          icon: const Icon(Icons.merge_type),
          label: const Text('Save as one entry instead'),
        ),
      ],
    );
  }

  String _autoSaveButtonLabel(ParsedHyperpure h) {
    final n = groupHyperpureItemsByCategory(h.items).length;
    if (n >= 2) return 'Auto-split & save $n entries';
    if (n == 1) return 'Save 1 entry';
    return 'Save entry';
  }

  Widget _itemRow(BuildContext context, HyperpureLineItem it) {
    final qtyUnit = [
      if (it.quantity != null) it.quantity!.toStringAsFixed(
          it.quantity! % 1 == 0 ? 0 : 2),
      if (it.unitPricePaise != null) '× ${Money.format(it.unitPricePaise!)}',
    ].join(' ');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(it.description,
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                if (qtyUnit.isNotEmpty)
                  Text(qtyUnit, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          Text(Money.format(it.amountPaise),
              style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _paytmResult(BuildContext context, ParsedPayment p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        _imagePreview(),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Detected', style: Theme.of(context).textTheme.titleMedium),
                const Divider(),
                _row('Amount',
                    p.amountPaise != null ? Money.format(p.amountPaise!) : '—'),
                _row('Type', p.type ?? 'not sure — pick on next screen'),
                _row('Party', p.party ?? '—'),
                _row(
                    'Date',
                    p.dateTime != null
                        ? DateFormat('d MMM yyyy').format(p.dateTime!)
                        : 'today'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        _rawText(context, p.rawText),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: _reviewPaytm,
          icon: const Icon(Icons.check),
          label: const Text('Review & save'),
        ),
      ],
    );
  }

  Widget _rawText(BuildContext context, String raw) {
    return ExpansionTile(
      title: const Text('Raw text read'),
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(bottom: 12),
      children: [
        Text(raw.isEmpty ? '(no text found)' : raw,
            style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            SizedBox(width: 80, child: Text(label)),
            Expanded(
                child: Text(value,
                    style: const TextStyle(fontWeight: FontWeight.w600))),
          ],
        ),
      );
}
