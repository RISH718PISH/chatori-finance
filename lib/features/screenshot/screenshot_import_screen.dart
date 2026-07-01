import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../core/money.dart';
import '../transaction/add_transaction_screen.dart';
import 'paytm_parser.dart';

class ScreenshotImportScreen extends StatefulWidget {
  const ScreenshotImportScreen({super.key});

  @override
  State<ScreenshotImportScreen> createState() => _ScreenshotImportScreenState();
}

class _ScreenshotImportScreenState extends State<ScreenshotImportScreen> {
  bool _busy = false;
  String? _imagePath;
  ParsedPayment? _parsed;
  String? _error;

  Future<void> _pick() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final file =
          await ImagePicker().pickImage(source: ImageSource.gallery);
      if (file == null) {
        setState(() => _busy = false);
        return;
      }
      final recognizer =
          TextRecognizer(script: TextRecognitionScript.latin);
      final result =
          await recognizer.processImage(InputImage.fromFilePath(file.path));
      await recognizer.close();
      setState(() {
        _imagePath = file.path;
        _parsed = PaytmParser.parse(result.text);
        _busy = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Could not read the screenshot: $e';
        _busy = false;
      });
    }
  }

  void _review() {
    final p = _parsed;
    if (p == null) return;
    context.push(
      '/add',
      extra: AddPrefill(
        type: p.type ?? 'expense',
        amountPaise: p.amountPaise,
        party: p.party,
        fromScreenshot: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Import Paytm Screenshot')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Pick a Paytm / UPI payment screenshot. The app reads it on your '
            'device and pre-fills a new entry for you to confirm.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _busy ? null : _pick,
            icon: const Icon(Icons.image_outlined),
            label: Text(_parsed == null ? 'Pick screenshot' : 'Pick another'),
          ),
          if (_busy) ...[
            const SizedBox(height: 24),
            const Center(child: CircularProgressIndicator()),
            const SizedBox(height: 8),
            const Center(child: Text('Reading screenshot…')),
          ],
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(_error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          if (_parsed != null && !_busy) _result(context, _parsed!),
        ],
      ),
    );
  }

  Widget _result(BuildContext context, ParsedPayment p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        if (_imagePath != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(File(_imagePath!),
                height: 180, fit: BoxFit.contain),
          ),
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
        ExpansionTile(
          title: const Text('Raw text read'),
          tilePadding: EdgeInsets.zero,
          childrenPadding: const EdgeInsets.only(bottom: 12),
          children: [
            Text(p.rawText.isEmpty ? '(no text found)' : p.rawText,
                style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: _review,
          icon: const Icon(Icons.check),
          label: const Text('Review & save'),
        ),
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
