/// AI Service — placeholder for voice billing and stock management.
///
/// Integration points:
/// - Speech-to-text: use `speech_to_text` package
/// - NLP parsing: integrate with Claude API or on-device model
/// - Language: English + Tamil priority
///
/// To activate, replace the stub methods with real API calls.

class AiService {
  static final AiService _instance = AiService._();
  AiService._();
  static AiService get instance => _instance;

  bool _isListening = false;
  bool get isListening => _isListening;

  /// Parse a voice utterance into billing fields.
  /// Example: "Add 2 kg rice at 80 rupees with 5 percent GST"
  Future<VoiceBillingResult?> parseVoiceBilling(String text) async {
    // TODO: Integrate with Claude API or local NLP
    // Pattern: "add [qty] [unit] [product] at [rate] [with X% GST]"
    final lower = text.toLowerCase();
    final qtyMatch = RegExp(r'(\d+\.?\d*)\s*(kg|g|ltr|ml|pcs|piece|nos)?').firstMatch(lower);
    final rateMatch = RegExp(r'(?:at|for)\s*(?:rs\.?|rupees?)?\s*(\d+\.?\d*)').firstMatch(lower);
    final gstMatch = RegExp(r'(\d+)\s*%?\s*gst').firstMatch(lower);
    final productMatch = RegExp(
      r'(?:add|bill|create)?\s*(?:\d+\.?\d*\s*(?:kg|g|ltr|ml|pcs)?\s+)?(.+?)(?:\s+at|\s+for|\s+with|$)',
    ).firstMatch(lower);

    if (rateMatch == null) return null;

    return VoiceBillingResult(
      productName: productMatch?.group(1)?.trim() ?? '',
      quantity: double.tryParse(qtyMatch?.group(1) ?? '1') ?? 1,
      unit: qtyMatch?.group(2) ?? 'pcs',
      rate: double.tryParse(rateMatch.group(1)!) ?? 0,
      gstPercent: double.tryParse(gstMatch?.group(1) ?? '0') ?? 0,
    );
  }

  /// Parse voice for stock update.
  /// Example: "Update rice stock to 50 kg"
  Future<VoiceStockResult?> parseVoiceStock(String text) async {
    final lower = text.toLowerCase();
    final qtyMatch = RegExp(r'(\d+\.?\d*)\s*(kg|g|ltr|ml|pcs)?').firstMatch(lower);
    final productMatch = RegExp(r'(?:update|set|add)?\s*(.+?)\s+(?:stock|qty|quantity)').firstMatch(lower);

    if (qtyMatch == null) return null;
    return VoiceStockResult(
      productName: productMatch?.group(1)?.trim() ?? '',
      quantity: double.tryParse(qtyMatch.group(1)!) ?? 0,
      unit: qtyMatch.group(2) ?? 'pcs',
    );
  }

  /// Translate text to Tamil (placeholder — integrate with translation API).
  Future<String> translateToTamil(String text) async {
    // TODO: integrate with DeepL / Google Translate API
    return text;
  }

  void startListening(Function(String) onResult) {
    _isListening = true;
    // TODO: integrate speech_to_text package
    // speechToText.listen(onResult: onResult, localeId: 'en_IN');
  }

  void stopListening() {
    _isListening = false;
  }
}

class VoiceBillingResult {
  final String productName;
  final double quantity;
  final String unit;
  final double rate;
  final double gstPercent;

  VoiceBillingResult({
    required this.productName,
    required this.quantity,
    required this.unit,
    required this.rate,
    required this.gstPercent,
  });
}

class VoiceStockResult {
  final String productName;
  final double quantity;
  final String unit;

  VoiceStockResult({
    required this.productName,
    required this.quantity,
    required this.unit,
  });
}
