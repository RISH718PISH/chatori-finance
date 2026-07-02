import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../core/money.dart';
import '../transaction/add_transaction_screen.dart';
import 'hyperpure_parser.dart';
import 'paytm_parser.dart';

class ScreenshotImportScreen extends StatefulWidget {
  const ScreenshotImportScreen({super.key});

  @override
  State<ScreenshotImportScreen> createState() => _ScreenshotImportScreenState();
}

class _ScreenshotImportScreenState extends State<ScreenshotImportScreen> {
  bool _busy = false;
  String? _imagePath;
  ParsedPayment? _paytm;
  ParsedHyperpure? _hyperpure;
  String? _error;

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

  void _reviewHyperpure() {
    final h = _hyperpure;
    if (h == null) return;
    context.push(
      '/add',
      extra: AddPrefill(
        type: 'expense',
        category: h.suggestedCategory,
        amountPaise: h.totalPaise,
        party: 'Hyperpure',
        paymentMode: 'Bank',
        occurredAt: h.invoiceDate,
        notes: h.invoiceNumber == null
            ? 'Hyperpure invoice'
            : 'Hyperpure invoice ${h.invoiceNumber}',
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
                _row('Invoice', h.invoiceNumber ?? '—'),
                _row('Date',
                    h.invoiceDate != null
                        ? DateFormat('d MMM yyyy').format(h.invoiceDate!)
                        : 'today'),
                _row('Total',
                    h.totalPaise != null ? Money.format(h.totalPaise!) : '—'),
                _row('Category', h.suggestedCategory),
                _row('Payment', 'Bank (editable)'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        _rawText(context, h.rawText),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: _reviewHyperpure,
          icon: const Icon(Icons.check),
          label: const Text('Review & save'),
        ),
      ],
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
