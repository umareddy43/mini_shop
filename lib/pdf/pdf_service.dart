import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../core/constants/app_constants.dart';
import '../core/utils/formatters.dart';
import '../models/order.dart';
import '../models/payment.dart';
import '../repositories/customer_repository.dart';

/// Generates and exports PDF documents: individual order bills and
/// per-customer khata statements. Kept separate from [PrinterService] -
/// PDFs are for sharing/emailing/archiving, receipts are for the counter
/// thermal printer.
class PdfService {
  /// Builds a clean A4/letter-friendly bill PDF for a single order.
  Future<Uint8List> generateOrderBill(Order order) async {
    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              pw.SizedBox(height: 16),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Bill To:',
                          style: pw.TextStyle(
                              fontSize: 10, color: PdfColors.grey700)),
                      pw.Text(order.customerName ?? '-',
                          style: pw.TextStyle(
                              fontSize: 13, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      if (order.id != null)
                        pw.Text('Bill No: #${order.id}',
                            style: const pw.TextStyle(fontSize: 11)),
                      pw.Text('Date: ${Formatters.dateTime(order.date)}',
                          style: const pw.TextStyle(fontSize: 11)),
                      pw.Text('Status: ${order.status.label}',
                          style: const pw.TextStyle(fontSize: 11)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
              _buildItemsTable(order),
              pw.SizedBox(height: 12),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.green50,
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Text(
                    'Grand Total: ${Formatters.currency(order.totalAmount)}',
                    style: pw.TextStyle(
                        fontSize: 14, fontWeight: pw.FontWeight.bold),
                  ),
                ),
              ),
              pw.Spacer(),
              pw.Divider(),
              pw.Center(
                child: pw.Text('Thank you for shopping with us!',
                    style: pw.TextStyle(
                        fontSize: 11, fontStyle: pw.FontStyle.italic)),
              ),
            ],
          );
        },
      ),
    );

    return doc.save();
  }

  /// Builds a khata statement PDF for a customer: every order plus every
  /// payment, plus the running due summary.
  Future<Uint8List> generateKhataStatement({
    required CustomerWithKhata khata,
    required List<Order> orders,
    required List<Payment> payments,
  }) async {
    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => context.pageNumber == 1
            ? _buildHeader()
            : pw.SizedBox.shrink(),
        build: (context) => [
          pw.SizedBox(height: 16),
          pw.Text('Khata Statement',
              style:
                  pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Text('Customer: ${khata.customer.name}',
              style: const pw.TextStyle(fontSize: 12)),
          if (khata.customer.phone != null)
            pw.Text('Phone: ${khata.customer.phone}',
                style: const pw.TextStyle(fontSize: 11)),
          pw.SizedBox(height: 16),
          _buildKhataSummaryRow(khata),
          pw.SizedBox(height: 20),
          pw.Text('Order History',
              style:
                  pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellAlignment: pw.Alignment.centerLeft,
            headers: ['Date', 'Bill No', 'Status', 'Amount'],
            data: orders
                .map((o) => [
                      Formatters.date(o.date),
                      '#${o.id}',
                      o.status.label,
                      Formatters.currency(o.totalAmount),
                    ])
                .toList(),
          ),
          pw.SizedBox(height: 20),
          pw.Text('Payment History',
              style:
                  pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellAlignment: pw.Alignment.centerLeft,
            headers: ['Date', 'Mode', 'Remarks', 'Amount'],
            data: payments
                .map((p) => [
                      Formatters.date(p.paymentDate),
                      p.paymentMode.label,
                      p.remarks ?? '-',
                      Formatters.currency(p.amount),
                    ])
                .toList(),
          ),
        ],
      ),
    );

    return doc.save();
  }

  pw.Widget _buildHeader() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(AppConstants.shopName,
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
        pw.Text(AppConstants.shopAddress,
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
        pw.Text(AppConstants.shopPhone,
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
        pw.Divider(thickness: 1.2),
      ],
    );
  }

  pw.Widget _buildItemsTable(Order order) {
    return pw.TableHelper.fromTextArray(
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
      cellAlignment: pw.Alignment.centerLeft,
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(1.4),
        2: const pw.FlexColumnWidth(1.6),
        3: const pw.FlexColumnWidth(1.8),
      },
      headers: ['Item', 'Qty', 'Rate', 'Subtotal'],
      data: order.items
          .map((line) => [
                '${line.itemName ?? ''} (${line.itemUnit ?? ''})',
                '${line.quantity}',
                Formatters.currency(line.price),
                Formatters.currency(line.subtotal),
              ])
          .toList(),
    );
  }

  pw.Widget _buildKhataSummaryRow(CustomerWithKhata khata) {
    pw.Widget summaryBox(String label, String value, PdfColor color) => pw.Expanded(
          child: pw.Container(
            padding: const pw.EdgeInsets.all(10),
            margin: const pw.EdgeInsets.symmetric(horizontal: 4),
            decoration: pw.BoxDecoration(
              color: color,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(label,
                    style: const pw.TextStyle(
                        fontSize: 9, color: PdfColors.grey700)),
                pw.SizedBox(height: 2),
                pw.Text(value,
                    style: pw.TextStyle(
                        fontSize: 12, fontWeight: pw.FontWeight.bold)),
              ],
            ),
          ),
        );

    return pw.Row(
      children: [
        summaryBox('Total Due', Formatters.currency(khata.totalOrdered),
            PdfColors.blue50),
        summaryBox('Total Paid', Formatters.currency(khata.totalPaid),
            PdfColors.green50),
        summaryBox('Outstanding', Formatters.currency(khata.pendingAmount),
            PdfColors.red50),
      ],
    );
  }

  /// Opens the OS print dialog / print preview for the given bytes.
  Future<void> printBytes(Uint8List bytes, {String docName = 'Document'}) {
    return Printing.layoutPdf(
      onLayout: (_) async => bytes,
      name: docName,
    );
  }

  /// Opens the OS share sheet so the PDF can be sent via WhatsApp, email,
  /// etc.
  Future<void> shareBytes(Uint8List bytes, {String fileName = 'document.pdf'}) {
    return Printing.sharePdf(bytes: bytes, filename: fileName);
  }
}
