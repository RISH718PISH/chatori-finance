import 'dart:convert';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'ai_parsed_invoice.dart';
import 'hyperpure_parser.dart';

/// Thrown when the Edge Function is reachable but refuses the request in a
/// way the user can act on (missing key, no API credit).
class InvoiceParseException implements Exception {
  final String message;
  const InvoiceParseException(this.message);
  @override
  String toString() => message;
}

/// Sends an invoice photo to the `parse-invoice` Edge Function and returns
/// structured line items.
///
/// The Anthropic API key lives in Supabase's secret store and is read by
/// the function at runtime — it is never bundled into the APK, which is
/// the whole reason this goes through an Edge Function rather than calling
/// the API directly from the app.
class InvoiceAiClient {
  InvoiceAiClient(this._client);
  final SupabaseClient _client;

  static const _functionName = 'parse-invoice';

  Future<AiParsedInvoice> parseImage(String localPath) async {
    final file = File(localPath);
    final bytes = await file.readAsBytes();

    final res = await _client.functions.invoke(
      _functionName,
      body: {
        'image_base64': base64Encode(bytes),
        'media_type': _mediaTypeFor(localPath),
      },
    );

    final data = res.data;
    if (data is! Map) {
      throw const InvoiceParseException(
          'Unexpected response from the invoice reader.');
    }
    final map = Map<String, dynamic>.from(data);

    if (map['error'] != null) {
      throw InvoiceParseException(_friendlyError(map));
    }
    return AiParsedInvoice.fromJson(map);
  }

  /// Cloud parse with a graceful degrade to the legacy on-device parser.
  ///
  /// The fallback exists for genuine offline use only. It reconstructs a
  /// table from flattened text and is materially less accurate, so the
  /// result is flagged [AiParsedInvoice.isFallback] and the UI warns.
  Future<AiParsedInvoice> parseWithFallback({
    required String localPath,
    required String ocrText,
  }) async {
    try {
      return await parseImage(localPath);
    } on InvoiceParseException {
      rethrow; // Actionable — surface it rather than silently degrading.
    } catch (_) {
      return _fromLegacyParser(ocrText);
    }
  }

  AiParsedInvoice _fromLegacyParser(String ocrText) {
    final legacy = HyperpureParser.parse(ocrText);
    final items = [
      for (final it in legacy.items)
        AiInvoiceItem(
          description: it.description,
          qty: it.quantity,
          unitPricePaise: it.unitPricePaise,
          amountPaise: it.amountPaise,
          category: HyperpureParser.categoryOfItem(it),
          // The legacy path cannot express confidence; mark every row as
          // needing review rather than implying accuracy it does not have.
          confidence: 0.3,
        ),
    ];
    final sum = items.fold<int>(0, (s, it) => s + it.amountPaise);
    final total = legacy.totalPaise;
    return AiParsedInvoice(
      vendorName: legacy.vendorName,
      invoiceNumber: legacy.invoiceNumber,
      invoiceDate: legacy.invoiceDate,
      taxPaise: legacy.taxPaise,
      subtotalPaise: legacy.taxablePaise,
      totalPaise: total,
      items: items,
      reconciliation: InvoiceReconciliation(
        itemsSumPaise: sum,
        totalUnknown: total == null,
        differencePaise: total == null ? null : total - sum,
        balanced: total != null && total == sum,
      ),
      isFallback: true,
    );
  }

  String _mediaTypeFor(String path) {
    final p = path.toLowerCase();
    if (p.endsWith('.png')) return 'image/png';
    if (p.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  String _friendlyError(Map<String, dynamic> map) {
    final err = map['error']?.toString() ?? 'Unknown error';
    final status = map['status'];
    if (err.contains('ANTHROPIC_API_KEY')) {
      return 'The invoice reader is not configured yet. Add ANTHROPIC_API_KEY '
          'under Supabase → Edge Functions → Secrets.';
    }
    if (status == 401 || status == 403) {
      return 'The Anthropic API key was rejected. Check it is valid and active.';
    }
    if (status == 429) {
      return 'Rate limited by Anthropic. Wait a moment and try again.';
    }
    if (status == 400 && err.contains('credit')) {
      return 'Anthropic account is out of credit. Top up in the Anthropic console.';
    }
    return err;
  }
}
