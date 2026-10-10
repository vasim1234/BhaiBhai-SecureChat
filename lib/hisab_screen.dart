import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

// ============ HISAB KITAAB SCREEN ============
class HisabScreen extends StatefulWidget {
  const HisabScreen({super.key});

  @override
  State<HisabScreen> createState() => _HisabScreenState();
}

class _HisabScreenState extends State<HisabScreen> {
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  // ============ ADD ENTRY DIALOG (Screenshot Design) ============
  void _showAddEntryDialog(
      {Map<String, dynamic>? existingEntry, String? docId}) {
    final TextEditingController nameController =
        TextEditingController(text: existingEntry?['personName'] ?? '');
    final TextEditingController phoneController =
        TextEditingController(text: existingEntry?['phoneNumber'] ?? '');
    final TextEditingController amountController = TextEditingController(
        text: existingEntry != null ? existingEntry['amount'].toString() : '');
    final TextEditingController noteController =
        TextEditingController(text: existingEntry?['note'] ?? '');

    String type = existingEntry?['type'] ?? 'diya';
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25)),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      const Row(
                        children: [
                          Text('💰', style: TextStyle(fontSize: 28)),
                          SizedBox(width: 10),
                          Text(
                            'Naya Lena-Dena',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF10B981),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 25),

                      // Bande ka naam label
                      const Text(
                        'BANDE KA NAAM',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Name field + Contacts button
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: nameController,
                              decoration: InputDecoration(
                                hintText: 'Naam likhein',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                      color: Colors.grey[300]!, width: 1),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                      color: Colors.grey[300]!, width: 1),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 14),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          GestureDetector(
                            onTap: () {
                              // Contact picker hata diya — manual entry
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Contact list se number manually daalein'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Column(
                                children: [
                                  Text('📇', style: TextStyle(fontSize: 20)),
                                  SizedBox(height: 2),
                                  Text(
                                    'CONTACTS',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF10B981),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Mobile Number + Amount
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'MOBILE NUMBER',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey,
                                    letterSpacing: 1,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: phoneController,
                                  keyboardType: TextInputType.phone,
                                  decoration: InputDecoration(
                                    hintText: 'Number',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                          color: Colors.grey[300]!, width: 1),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                          color: Colors.grey[300]!, width: 1),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 14),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'AMOUNT (₹)',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey,
                                    letterSpacing: 1,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: amountController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    hintText: '0',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                          color: Color(0xFF10B981),
                                          width: 1.5),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                          color: Color(0xFF10B981),
                                          width: 1.5),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 14),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Wajah / Note
                      const Text(
                        'WAJAH / NOTE',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: noteController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: 'Kis cheez ke paise hain?',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                BorderSide(color: Colors.grey[300]!, width: 1),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                BorderSide(color: Colors.grey[300]!, width: 1),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Type buttons (Diya / Liya)
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () =>
                                  setDialogState(() => type = 'diya'),
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                decoration: BoxDecoration(
                                  color: type == 'diya'
                                      ? const Color(0xFFEF4444)
                                          .withOpacity(0.1)
                                      : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: type == 'diya'
                                        ? const Color(0xFFEF4444)
                                        : Colors.grey[300]!,
                                    width: type == 'diya' ? 2 : 1,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          width: 12,
                                          height: 12,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFFEF4444),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        const Text(
                                          'Diya',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFFEF4444),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'UDHAAR LENE HAIN',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFEF4444),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: () =>
                                  setDialogState(() => type = 'liya'),
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                decoration: BoxDecoration(
                                  color: type == 'liya'
                                      ? const Color(0xFF10B981)
                                          .withOpacity(0.1)
                                      : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: type == 'liya'
                                        ? const Color(0xFF10B981)
                                        : Colors.grey[300]!,
                                    width: type == 'liya' ? 2 : 1,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          width: 12,
                                          height: 12,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFF10B981),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        const Text(
                                          'Liya',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF10B981),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'ADVANCE DENE HAIN',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF10B981),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Save / Cancel
                      Center(
                        child: isSaving
                            ? const CircularProgressIndicator()
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(dialogContext),
                                    child: const Text(
                                      'Cancel',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  ElevatedButton(
                                    onPressed: () async {
                                      if (nameController.text.trim().isEmpty ||
                                          amountController.text.trim().isEmpty) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                              content: Text(
                                                  'Naam aur Amount zaroori hai')),
                                        );
                                        return;
                                      }

                                      setDialogState(() => isSaving = true);

                                      try {
                                        Map<String, dynamic> data = {
                                          'userId': currentUserId,
                                          'personName': nameController.text.trim(),
                                          'phoneNumber':
                                              phoneController.text.trim(),
                                          'amount': double.parse(
                                              amountController.text.trim()),
                                          'type': type,
                                          'date': Timestamp.fromDate(
                                              DateTime.now()),
                                          'note': noteController.text.trim(),
                                          'updatedAt':
                                              FieldValue.serverTimestamp(),
                                        };

                                        if (existingEntry == null) {
                                          data['createdAt'] = FieldValue
                                              .serverTimestamp();
                                          await FirebaseFirestore.instance
                                              .collection('hisab')
                                              .add(data);
                                        } else {
                                          await FirebaseFirestore.instance
                                              .collection('hisab')
                                              .doc(docId)
                                              .update(data);
                                        }

                                        if (dialogContext.mounted) {
                                          Navigator.pop(dialogContext);
                                          ScaffoldMessenger.of(dialogContext)
                                              .showSnackBar(
                                            SnackBar(
                                                content: Text(
                                                    existingEntry == null
                                                        ? 'Hisaab add ho gaya!'
                                                        : 'Hisaab update ho gaya!')),
                                          );
                                        }
                                      } catch (e) {
                                        setDialogState(() => isSaving = false);
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                              content: Text('Error: $e')),
                                        );
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF10B981),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 30, vertical: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: Text(
                                      existingEntry == null ? 'Save' : 'Update',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ============ DELETE ENTRY ============
  Future<void> _deleteEntry(String docId) async {
    bool confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            title: const Text('Delete Karo?'),
            content: const Text('Ye hisaab permanently delete ho jayega.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirm) return;

    await FirebaseFirestore.instance.collection('hisab').doc(docId).delete();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hisaab delete ho gaya')),
      );
    }
  }

  // ============ CALL / WHATSAPP ============
  Future<void> _makeCall(String phone) async {
    final Uri url = Uri.parse('tel:$phone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  Future<void> _openWhatsApp(String phone) async {
    String cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (!cleanPhone.startsWith('91')) cleanPhone = '91$cleanPhone';
    final Uri url = Uri.parse('https://wa.me/$cleanPhone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  // ============ ENTRY DETAIL SHEET ============
  void _showEntryDetail(Map<String, dynamic> entry, String docId) {
    bool isDiya = entry['type'] == 'diya';
    DateTime date = (entry['date'] as Timestamp).toDate();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: isDiya ? Colors.green : Colors.red,
                      child: Text(
                        entry['personName'][0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry['personName'],
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if ((entry['phoneNumber'] ?? '').isNotEmpty)
                            Text(
                              entry['phoneNumber'],
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color:
                        (isDiya ? Colors.green : Colors.red).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isDiya ? Icons.arrow_upward : Icons.arrow_downward,
                        color: isDiya ? Colors.green : Colors.red,
                        size: 30,
                      ),
                      const SizedBox(width: 15),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isDiya ? 'Maine Diya' : 'Maine Liya',
                            style: TextStyle(
                              color: isDiya ? Colors.green : Colors.red,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '₹ ${entry['amount'].toStringAsFixed(0)}',
                            style: TextStyle(
                              color: isDiya ? Colors.green : Colors.red,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 15),
                _buildDetailRow(Icons.calendar_today,
                    DateFormat('dd MMM yyyy').format(date)),
                if ((entry['note'] ?? '').isNotEmpty)
                  _buildDetailRow(Icons.note, entry['note']),
                const SizedBox(height: 20),
                Row(
                  children: [
                    if ((entry['phoneNumber'] ?? '').isNotEmpty) ...[
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(sheetContext);
                            _makeCall(entry['phoneNumber']);
                          },
                          icon: const Icon(Icons.call,
                              color: Color(0xFF4A6CF7)),
                          label: const Text('Call',
                              style: TextStyle(color: Color(0xFF4A6CF7))),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: const BorderSide(color: Color(0xFF4A6CF7)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(sheetContext);
                            _openWhatsApp(entry['phoneNumber']);
                          },
                          icon: const Icon(Icons.chat, color: Colors.green),
                          label: const Text('WhatsApp',
                              style: TextStyle(color: Colors.green)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: const BorderSide(color: Colors.green),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(sheetContext);
                          _showAddEntryDialog(
                              existingEntry: entry, docId: docId);
                        },
                        icon: const Icon(Icons.edit),
                        label: const Text('Edit'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4A6CF7),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(sheetContext);
                          _deleteEntry(docId);
                        },
                        icon: const Icon(Icons.delete),
                        label: const Text('Delete'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  // ============ FETCH ALL ENTRIES ============
  Future<List<Map<String, dynamic>>> _fetchAllEntries() async {
    QuerySnapshot snap = await FirebaseFirestore.instance
        .collection('hisab')
        .where('userId', isEqualTo: currentUserId)
        .get();

    List<Map<String, dynamic>> entries =
        snap.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    entries.sort((a, b) {
      Timestamp ta = a['date'] as Timestamp;
      Timestamp tb = b['date'] as Timestamp;
      return tb.compareTo(ta);
    });
    return entries;
  }

  // ============ PDF EXPORT ============
  Future<void> _exportPDF(List<Map<String, dynamic>> entries) async {
    try {
      double totalDiya = 0;
      double totalLiya = 0;
      for (var entry in entries) {
        double amount = (entry['amount'] as num).toDouble();
        if (entry['type'] == 'diya') {
          totalDiya += amount;
        } else {
          totalLiya += amount;
        }
      }
      double netBalance = totalDiya - totalLiya;

      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return [
              pw.Header(
                level: 0,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Hisaab Kitaab',
                      style: pw.TextStyle(
                        fontSize: 26,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue700,
                      ),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      'Generated: ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now())}',
                      style: const pw.TextStyle(
                        fontSize: 11,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Container(
                padding: const pw.EdgeInsets.all(15),
                decoration: pw.BoxDecoration(
                  color: PdfColors.blue50,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Total Balance: Rs. ${netBalance.abs().toStringAsFixed(0)}',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: netBalance >= 0
                            ? PdfColors.green700
                            : PdfColors.red700,
                      ),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      netBalance >= 0 ? 'Aapko lena hai' : 'Aapko dena hai',
                      style: const pw.TextStyle(
                        fontSize: 12,
                        color: PdfColors.grey700,
                      ),
                    ),
                    pw.SizedBox(height: 10),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'Diya: Rs. ${totalDiya.toStringAsFixed(0)}',
                          style: const pw.TextStyle(
                            fontSize: 13,
                            color: PdfColors.green700,
                          ),
                        ),
                        pw.Text(
                          'Liya: Rs. ${totalLiya.toStringAsFixed(0)}',
                          style: const pw.TextStyle(
                            fontSize: 13,
                            color: PdfColors.red700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Table.fromTextArray(
                headers: [
                  'Naam',
                  'Phone',
                  'Type',
                  'Amount',
                  'Date',
                  'Note'
                ],
                data: entries.map((entry) {
                  DateTime date = (entry['date'] as Timestamp).toDate();
                  return [
                    entry['personName'] ?? '',
                    entry['phoneNumber'] ?? '-',
                    entry['type'] == 'diya' ? 'Diya' : 'Liya',
                    'Rs. ${entry['amount'].toStringAsFixed(0)}',
                    DateFormat('dd MMM yy').format(date),
                    entry['note'] ?? '-',
                  ];
                }).toList(),
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                  fontSize: 11,
                ),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.blue700,
                ),
                cellStyle: const pw.TextStyle(fontSize: 10),
              ),
              pw.SizedBox(height: 20),
              pw.Divider(),
              pw.Text(
                'Bhai Bhai Secure Chat - Hisaab Kitaab',
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey600,
                ),
              ),
            ];
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'hisaab_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
    } catch (e) {
      debugPrint('Error exporting PDF: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF error: $e')),
        );
      }
    }
  }

  // ============ SEND VIA WHATSAPP ============
  Future<void> _sendHisabViaWhatsApp(
      List<Map<String, dynamic>> entries, String phone) async {
    try {
      double totalDiya = 0;
      double totalLiya = 0;
      for (var entry in entries) {
        double amount = (entry['amount'] as num).toDouble();
        if (entry['type'] == 'diya') {
          totalDiya += amount;
        } else {
          totalLiya += amount;
        }
      }

      String message = '📋 *Hisaab Kitaab*\n\n';
      message += '💰 *Total Diya:* ₹ ${totalDiya.toStringAsFixed(0)}\n';
      message += '💰 *Total Liya:* ₹ ${totalLiya.toStringAsFixed(0)}\n';
      message +=
          '📊 *Balance:* ₹ ${(totalDiya - totalLiya).abs().toStringAsFixed(0)}\n';
      message +=
          '${(totalDiya - totalLiya) >= 0 ? "✅ Aapko lena hai" : "🔴 Aapko dena hai"}\n\n';
      message += '--- *Details* ---\n';

      for (var entry in entries) {
        DateTime date = (entry['date'] as Timestamp).toDate();
        String emoji = entry['type'] == 'diya' ? '🟢' : '🔴';
        message +=
            '$emoji ${entry['personName']} - ₹ ${entry['amount'].toStringAsFixed(0)} (${DateFormat('dd MMM').format(date)})\n';
      }

      String cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
      if (!cleanPhone.startsWith('91')) cleanPhone = '91$cleanPhone';

      final Uri url = Uri.parse(
        'https://wa.me/$cleanPhone?text=${Uri.encodeComponent(message)}',
      );

      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('WhatsApp error: $e');
    }
  }

  // ============ PDF BUTTON HANDLER ============
  Future<void> _handlePDFExport() async {
    List<Map<String, dynamic>> entries = await _fetchAllEntries();
    if (entries.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Koi hisaab nahi hai')),
        );
      }
      return;
    }
    await _exportPDF(entries);
  }

  // ============ WHATSAPP SHARE BUTTON ============
  Future<void> _handleWhatsAppShare() async {
    List<Map<String, dynamic>> entries = await _fetchAllEntries();
    if (entries.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Koi hisaab nahi hai')),
        );
      }
      return;
    }

    final TextEditingController phoneController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('WhatsApp Number'),
        content: TextField(
          controller: phoneController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: 'Phone Number',
            prefixIcon: const Icon(Icons.phone),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (phoneController.text.trim().isEmpty) return;
              Navigator.pop(dialogContext);
              _sendHisabViaWhatsApp(entries, phoneController.text.trim());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text('Hisaab Kitaab'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf, color: Color(0xFF4A6CF7)),
            tooltip: 'PDF Save',
            onPressed: _handlePDFExport,
          ),
          IconButton(
            icon: const Icon(Icons.share, color: Colors.green),
            tooltip: 'WhatsApp pe bhejo',
            onPressed: _handleWhatsAppShare,
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('hisab')
            .where('userId', isEqualTo: currentUserId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          List<Map<String, dynamic>> allEntries = snapshot.data!.docs.map((doc) {
            var data = doc.data() as Map<String, dynamic>;
            data['docId'] = doc.id;
            return data;
          }).toList();

          allEntries.sort((a, b) {
            Timestamp ta = a['date'] as Timestamp;
            Timestamp tb = b['date'] as Timestamp;
            return tb.compareTo(ta);
          });

          double totalDiya = 0;
          double totalLiya = 0;
          for (var entry in allEntries) {
            double amount = (entry['amount'] as num).toDouble();
            if (entry['type'] == 'diya') {
              totalDiya += amount;
            } else {
              totalLiya += amount;
            }
          }
          double netBalance = totalDiya - totalLiya;

          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              _buildBalanceCard(totalDiya, totalLiya, netBalance),
              const SizedBox(height: 20),
              _buildEntryTileList(allEntries),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF667EEA),
        onPressed: () => _showAddEntryDialog(),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Naya Hisaab',
            style:
                TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildEntryTileList(List<Map<String, dynamic>> entries) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'ENTRIES',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
                letterSpacing: 1.2,
              ),
            ),
            Row(
              children: [
                Text(
                  'AAPNE DIYE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.red[400],
                  ),
                ),
                const SizedBox(width: 20),
                Text(
                  'AAPNE LIYE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[400],
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...entries.map((entry) => _buildEntryTile(entry)).toList(),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: const Color(0xFF667EEA).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.receipt_long,
              size: 60,
              color: Color(0xFF667EEA),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Abhi koi hisaab nahi hai',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 5),
          const Text(
            'Neeche + dabao aur naya hisaab add karo!',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(
      double totalDiya, double totalLiya, double netBalance) {
    bool isPositive = netBalance >= 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4A6CF7), Color(0xFF8B5CF6)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4A6CF7).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Total Balance',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            '₹ ${netBalance.abs().toStringAsFixed(0)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            isPositive ? 'Aapko lena hai' : 'Aapko dena hai',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.arrow_upward,
                              color: Colors.greenAccent, size: 14),
                          SizedBox(width: 4),
                          Text(
                            'Diya',
                            style: TextStyle(
                                color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '₹ ${totalDiya.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.arrow_downward,
                              color: Colors.redAccent, size: 14),
                          SizedBox(width: 4),
                          Text(
                            'Liya',
                            style: TextStyle(
                                color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '₹ ${totalLiya.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEntryTile(Map<String, dynamic> entry) {
    bool isDiya = entry['type'] == 'diya';
    DateTime date = (entry['date'] as Timestamp).toDate();

    return GestureDetector(
      onTap: () => _showEntryDetail(entry, entry['docId']),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: isDiya ? Colors.red : Colors.green,
              child: Text(
                entry['personName'][0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry['personName'],
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${DateFormat('dd MMM yy').format(date)} • ${DateFormat('hh:mm a').format(date)}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 11,
                    ),
                  ),
                  if ((entry['note'] ?? '').isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      entry['note'],
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            Text(
              '₹ ${entry['amount'].toStringAsFixed(0)}',
              style: TextStyle(
                color: isDiya ? Colors.red : Colors.green,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
