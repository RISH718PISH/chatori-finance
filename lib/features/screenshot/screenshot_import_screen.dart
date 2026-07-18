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
import '../transaction/transaction_providers.dart';
import 'invoice_ai_client.dart';
import 'invoice_review_screen.dart';
import 'paytm_parser.dart';

/// Entry point for both scanning flows.
///
/// The two are separated deliberately rather than auto-detected: the
/// invoice path makes a paid AI call, so routing a payment screenshot into
/// it by mistake would cost money and return nothing useful.
class ScreenshotImportScreen extends ConsumerStatefulWidget {
  const ScreenshotImportScreen({super.key});

  @override
  ConsumerState<ScreenshotImportScreen> createState() =>
      _ScreenshotImportScreenState();
}

class _ScreenshotImportScreenState
    extends ConsumerState<ScreenshotImportScreen> {
  bool _busy = false;
  String _busyLabel = '';
  String? _imagePath;
  ParsedPayment? _paytm;
  String? _error;

  /// Downscaled on capture: a 1600px JPEG is ~400 KB against ~3 MB for a
  /// raw camera frame. That is less storage burned, a faster upload, and a
  /// cheaper AI call — with no measurable accuracy loss on invoice text.
  Future<XFile?> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              subtitle: const Text('Lay the bill flat, fill the frame'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return null;
    return ImagePicker().pickImage(
      source: source,
      maxWidth: 1600,
      imageQuality: 80,
    );
  }

  Future<String> _ocrText(String path) async {
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final result =
          await recognizer.processImage(InputImage.fromFilePath(path));
      return result.text;
    } finally {
      await recognizer.close();
    }
  }

  // ── Invoice (AI) ───────────────────────────────────────────

  Future<void> _scanInvoice() async {
    setState(() {
      _error = null;
      _paytm = null;
    });
    final file = await _pickImage();
    if (file == null) return;

    setState(() {
      _imagePath = file.path;
      _busy = true;
      _busyLabel = 'Reading the invoice…';
    });

    try {
      // On-device OCR still runs: its text is the offline fallback if the
      // Edge Function cannot be reached.
      final text = await _ocrText(file.path);
      final parsed = await ref
          .read(invoiceAiClientProvider)
          .parseWithFallback(localPath: file.path, ocrText: text);

      if (!mounted) return;
      setState(() => _busy = false);

      if (parsed.items.isEmpty) {
        setState(() => _error =
            'No line items could be read from that photo. Try again with '
            'the bill flat, well lit, and filling the frame.');
        return;
      }

      await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => InvoiceReviewScreen(
          parsed: parsed,
          attachmentLocalPath: file.path,
        ),
      ));
    } on InvoiceParseException catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = e.message;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = 'Could not read the image: $e';
        });
      }
    }
  }

  // ── Payment screenshot (on-device) ─────────────────────────

  Future<void> _scanPayment() async {
    setState(() {
      _error = null;
      _paytm = null;
    });
    final file = await _pickImage();
    if (file == null) return;

    setState(() {
      _imagePath = file.path;
      _busy = true;
      _busyLabel = 'Reading the screenshot…';
    });
    try {
      final text = await _ocrText(file.path);
      if (!mounted) return;
      setState(() {
        _paytm = PaytmParser.parse(text);
        _busy = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = 'Could not read the image: $e';
        });
      }
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

  // ── Build ──────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Scan a supplier bill to capture every line item, or a payment '
            'screenshot to pre-fill a single entry.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _busy ? null : _scanInvoice,
            icon: const Icon(Icons.receipt_long),
            label: const Text('Scan a bill / invoice'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _busy ? null : _scanPayment,
            icon: const Icon(Icons.smartphone),
            label: const Text('Scan a payment screenshot'),
          ),
          if (_busy) ...[
            const SizedBox(height: 28),
            const Center(child: CircularProgressIndicator()),
            const SizedBox(height: 10),
            Center(
              child: Text(_busyLabel,
                  style: Theme.of(context).textTheme.bodyMedium),
            ),
            const SizedBox(height: 4),
            Center(
              child: Text('This can take a few seconds',
                  style: Theme.of(context).textTheme.bodySmall),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 16),
            Card(
              color: AppSemantics.expense.withValues(alpha: 0.08),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                    color: AppSemantics.expense.withValues(alpha: 0.4)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.error_outline,
                        color: AppSemantics.expense, size: 20),
                    const SizedBox(width: 10),
                    Expanded(child: Text(_error!)),
                  ],
                ),
              ),
            ),
          ],
          if (_paytm != null && !_busy) _paymentResult(context, _paytm!),
        ],
      ),
    );
  }

  Widget _paymentResult(BuildContext context, ParsedPayment p) {
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
                Text('Detected',
                    style: Theme.of(context).textTheme.titleMedium),
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
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: _reviewPaytm,
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
