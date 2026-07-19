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

    final FunctionResponse res;
    try {
      res = await _client.functions.invoke(
        _functionName,
        body: {
          'image_base64': base64Encode(bytes),
          'media_type': _mediaTypeFor(localPath),
        },
      );
    } on FunctionException catch (e) {
      // A non-2xx from the function arrives as an exception, NOT as
      // res.data. Without this branch every configuration problem — a bad
      // API key, no credit — was swallowed by the caller's catch-all and
      // silently degraded to the offline parser, which is exactly the
      // failure the user cannot diagnose.
      throw InvoiceParseException(_friendlyError(_asMap(e.details)));
    }

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

  Map<String, dynamic> _asMap(Object? details) {
    if (details is Map) return Map<String, dynamic>.from(details);
    if (details is String) {
      try {
        final decoded = jsonDecode(details);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {/* fall through */}
      return {'error': details};
    }
    return {'error': details?.toString() ?? 'Unknown error'};
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
    final detail = map['detail']?.toString() ?? '';
    final status = map['status'];
    final haystack = '$err $detail';

    if (err.contains('ANTHROPIC_API_KEY')) {
      return 'The invoice reader is not set up yet. Add a secret named '
          'ANTHROPIC_API_KEY under Supabase → Edge Functions → Secrets.';
    }
    if (haystack.contains('invalid x-api-key') ||
        haystack.contains('authentication_error') ||
        status == 401 ||
        status == 403) {
      return 'Anthropic rejected the API key. The saved value is not a valid '
          'key — real ones begin with "sk-ant-api03-". Create one at '
          'console.anthropic.com and re-save the ANTHROPIC_API_KEY secret.';
    }
    if (haystack.contains('credit') || haystack.contains('billing')) {
      return 'The Anthropic account has no credit left. Top it up in the '
          'Anthropic console, then try again.';
    }
    if (status == 429) {
      return 'Rate limited by Anthropic. Wait a moment and try again.';
    }
    if (status == 404) {
      return 'The invoice reader is not deployed. Run: '
          'supabase functions deploy parse-invoice';
    }
    return detail.isEmpty ? err : '$err — $detail';
  }
}
