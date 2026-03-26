import 'package:url_launcher/url_launcher.dart';
import '../../data/models/invoice.dart';
import '../../data/models/business.dart';
import '../../core/utils/currency_formatter.dart';

/// WhatsApp messaging service.
/// Uses the wa.me deep link — works on macOS and Windows via browser/WhatsApp desktop.
class WhatsAppService {
  static Future<bool> sendInvoice(Invoice invoice, Business business) async {
    final message = _buildInvoiceMessage(invoice, business);
    return _launch(invoice.customerPhone, message);
  }

  static Future<bool> sendDailySummary({
    required String phone,
    required Business business,
    required double revenue,
    required double collected,
    required int invoiceCount,
    required DateTime date,
  }) async {
    final message = '''📊 *Daily Sales Summary - ${DateFormatter.formatDate(date)}*
Business: ${business.name}

✅ Total Sales: ${CurrencyFormatter.format(revenue)}
💵 Collected: ${CurrencyFormatter.format(collected)}
📋 Invoices: $invoiceCount

_Powered by Inbill_''';

    return _launch(phone, message);
  }

  static Future<bool> sendBulkMessage({
    required String phone,
    required String message,
  }) async {
    return _launch(phone, message);
  }

  static String _buildInvoiceMessage(Invoice invoice, Business business) {
    final items = invoice.items.map((item) {
      return '  • ${item.productName} × ${item.quantity} = ${CurrencyFormatter.format(item.total)}';
    }).join('\n');

    return '''🧾 *Invoice from ${business.name}*
Invoice #: *${invoice.invoiceNumber}*
Date: ${DateFormatter.formatDate(invoice.invoiceDate)}

*Items:*
$items

---
Subtotal: ${CurrencyFormatter.format(invoice.subtotal)}
${invoice.totalDiscount > 0 ? 'Discount: -${CurrencyFormatter.format(invoice.totalDiscount)}\n' : ''}${invoice.totalGst > 0 ? 'GST: ${CurrencyFormatter.format(invoice.totalGst)}\n' : ''}*Total: ${CurrencyFormatter.format(invoice.grandTotal)}*
${invoice.amountDue > 0 ? '⚠️ Balance Due: ${CurrencyFormatter.format(invoice.amountDue)}' : '✅ Paid'}

Payment: ${invoice.paymentMode}
${business.upiId.isNotEmpty ? 'UPI: ${business.upiId}' : ''}

Thank you for your business! 🙏''';
  }

  static Future<bool> _launch(String phone, String message) async {
    // Clean phone number
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final withCode = cleanPhone.startsWith('+') ? cleanPhone : '+91$cleanPhone';
    final encoded = Uri.encodeComponent(message);
    final url = Uri.parse('https://wa.me/$withCode?text=$encoded');
    try {
      return await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}
