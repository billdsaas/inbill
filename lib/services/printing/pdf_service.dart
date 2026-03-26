import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import '../../data/models/invoice.dart';
import '../../data/models/business.dart';
import '../../core/utils/currency_formatter.dart';

class PdfService {
  static Future<File> generateInvoice(Invoice invoice, Business business) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.notoSansRegular();
    final fontBold = await PdfGoogleFonts.notoSansBold();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildHeader(business, invoice, font, fontBold),
            pw.SizedBox(height: 24),
            _buildCustomerSection(invoice, font, fontBold),
            pw.SizedBox(height: 16),
            _buildItemsTable(invoice, font, fontBold),
            pw.SizedBox(height: 16),
            _buildTotals(invoice, font, fontBold),
            pw.SizedBox(height: 24),
            _buildPaymentSection(invoice, business, font, fontBold),
            pw.Spacer(),
            _buildFooter(business, font),
          ],
        ),
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/inbill/invoices/${invoice.invoiceNumber}.pdf');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  static pw.Widget _buildHeader(Business business, Invoice invoice, pw.Font font, pw.Font bold) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(business.name, style: pw.TextStyle(font: bold, fontSize: 22)),
            pw.SizedBox(height: 4),
            pw.Text(business.address, style: pw.TextStyle(font: font, fontSize: 10)),
            pw.Text('${business.city}, ${business.state} - ${business.pincode}',
                style: pw.TextStyle(font: font, fontSize: 10)),
            pw.Text('Phone: ${business.phone}', style: pw.TextStyle(font: font, fontSize: 10)),
            if (business.gstin.isNotEmpty)
              pw.Text('GSTIN: ${business.gstin}', style: pw.TextStyle(font: font, fontSize: 10)),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text('INVOICE', style: pw.TextStyle(font: bold, fontSize: 18, color: PdfColors.green800)),
            pw.SizedBox(height: 4),
            pw.Text(invoice.invoiceNumber, style: pw.TextStyle(font: bold, fontSize: 14)),
            pw.Text('Date: ${DateFormatter.formatDate(invoice.invoiceDate)}',
                style: pw.TextStyle(font: font, fontSize: 10)),
            pw.Text('Due: ${DateFormatter.formatDate(invoice.dueDate)}',
                style: pw.TextStyle(font: font, fontSize: 10)),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: pw.BoxDecoration(
                color: _statusColor(invoice.status),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
              ),
              child: pw.Text(
                invoice.status.name.toUpperCase(),
                style: pw.TextStyle(font: bold, fontSize: 9, color: PdfColors.white),
              ),
            ),
          ],
        ),
      ],
    );
  }

  static PdfColor _statusColor(InvoiceStatus status) {
    switch (status) {
      case InvoiceStatus.paid:
        return PdfColors.green700;
      case InvoiceStatus.partial:
        return PdfColors.orange700;
      case InvoiceStatus.pending:
        return PdfColors.blue700;
      case InvoiceStatus.cancelled:
        return PdfColors.red700;
      default:
        return PdfColors.grey700;
    }
  }

  static pw.Widget _buildCustomerSection(Invoice invoice, pw.Font font, pw.Font bold) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Bill To', style: pw.TextStyle(font: bold, fontSize: 10, color: PdfColors.grey600)),
          pw.SizedBox(height: 4),
          pw.Text(invoice.customerName, style: pw.TextStyle(font: bold, fontSize: 13)),
          if (invoice.customerPhone.isNotEmpty)
            pw.Text('Phone: ${invoice.customerPhone}', style: pw.TextStyle(font: font, fontSize: 10)),
          if (invoice.customerAddress.isNotEmpty)
            pw.Text(invoice.customerAddress, style: pw.TextStyle(font: font, fontSize: 10)),
        ],
      ),
    );
  }

  static pw.Widget _buildItemsTable(Invoice invoice, pw.Font font, pw.Font bold) {
    return pw.TableHelper.fromTextArray(
      headers: ['#', 'Item', 'Qty', 'Rate', 'Disc%', 'GST%', 'Amount'],
      headerStyle: pw.TextStyle(font: bold, fontSize: 10, color: PdfColors.white),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.green800),
      cellStyle: pw.TextStyle(font: font, fontSize: 10),
      cellAlignments: {
        0: pw.Alignment.center,
        1: pw.Alignment.centerLeft,
        2: pw.Alignment.center,
        3: pw.Alignment.centerRight,
        4: pw.Alignment.center,
        5: pw.Alignment.center,
        6: pw.Alignment.centerRight,
      },
      data: invoice.items.asMap().entries.map((e) {
        final i = e.value;
        return [
          '${e.key + 1}',
          '${i.productName}\n${i.unit}',
          i.quantity.toStringAsFixed(i.quantity == i.quantity.roundToDouble() ? 0 : 2),
          CurrencyFormatter.format(i.rate),
          i.discount > 0 ? '${i.discount.toStringAsFixed(0)}%' : '-',
          i.gstPercent > 0 ? '${i.gstPercent.toStringAsFixed(0)}%' : '-',
          CurrencyFormatter.format(i.total),
        ];
      }).toList(),
    );
  }

  static pw.Widget _buildTotals(Invoice invoice, pw.Font font, pw.Font bold) {
    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.Container(
        width: 200,
        child: pw.Column(
          children: [
            _totalRow('Subtotal', invoice.subtotal, font, bold),
            if (invoice.totalDiscount > 0)
              _totalRow('Discount', -invoice.totalDiscount, font, bold, isNegative: true),
            if (invoice.totalGst > 0)
              _totalRow('GST', invoice.totalGst, font, bold),
            pw.Divider(thickness: 1),
            _totalRow('Grand Total', invoice.grandTotal, font, bold, isBold: true),
            if (invoice.amountPaid > 0)
              _totalRow('Paid', invoice.amountPaid, font, bold),
            if (invoice.amountDue > 0)
              _totalRow('Balance Due', invoice.amountDue, font, bold, highlight: true),
          ],
        ),
      ),
    );
  }

  static pw.Widget _totalRow(String label, double amount, pw.Font font, pw.Font bold,
      {bool isBold = false, bool isNegative = false, bool highlight = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      color: highlight ? PdfColors.orange50 : null,
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(font: isBold ? bold : font, fontSize: 11)),
          pw.Text(
            isNegative ? '-${CurrencyFormatter.format(amount.abs())}' : CurrencyFormatter.format(amount),
            style: pw.TextStyle(font: isBold ? bold : font, fontSize: 11),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildPaymentSection(Invoice invoice, Business business, pw.Font font, pw.Font bold) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Payment Mode', style: pw.TextStyle(font: bold, fontSize: 10)),
            pw.Text(invoice.paymentMode, style: pw.TextStyle(font: font, fontSize: 10)),
            if (business.upiId.isNotEmpty) ...[
              pw.SizedBox(height: 4),
              pw.Text('UPI: ${business.upiId}', style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.grey600)),
            ],
          ],
        ),
        if (invoice.notes.isNotEmpty)
          pw.Container(
            constraints: const pw.BoxConstraints(maxWidth: 200),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Notes', style: pw.TextStyle(font: bold, fontSize: 10)),
                pw.Text(invoice.notes, style: pw.TextStyle(font: font, fontSize: 10)),
              ],
            ),
          ),
      ],
    );
  }

  static pw.Widget _buildFooter(Business business, pw.Font font) {
    return pw.Column(
      children: [
        pw.Divider(),
        pw.SizedBox(height: 4),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Thank you for your business!', style: pw.TextStyle(font: font, fontSize: 10)),
            pw.Text('Generated by Inbill', style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.grey500)),
          ],
        ),
      ],
    );
  }

  /// Opens system print dialog
  static Future<void> printInvoice(Invoice invoice, Business business) async {
    final file = await generateInvoice(invoice, business);
    await Printing.layoutPdf(
      onLayout: (_) async => await file.readAsBytes(),
    );
  }

  /// Share invoice as file
  static Future<File> getInvoiceFile(Invoice invoice, Business business) async {
    return generateInvoice(invoice, business);
  }
}
