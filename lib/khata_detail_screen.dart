import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

// ============ KHATA DETAIL SCREEN (Bande Ka Pura Hisaab) ============
class KhataDetailScreen extends StatefulWidget {
  final String khataId;
  final String personName;
  final String phoneNumber;

  const KhataDetailScreen({
    super.key,
    required this.khataId,
    required this.personName,
    required this.phoneNumber,
  });

  @override
  State<KhataDetailScreen> createState() => _KhataDetailScreenState();
}

class _KhataDetailScreenState extends State<KhataDetailScreen> {
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  // ============ ADD ENTRY ============
  void _showAddEntryDialog({Map<String, dynamic>? existingEntry, String? docId}) {
    final TextEditingController amountController = TextEditingController(
        text: existingEntry != null ? existingEntry['amount'].toString() : '');
    final TextEditingController noteController =
        TextEditingController(text: existingEntry?['note'] ?? '');

    String type = existingEntry?['type'] ?? 'diya';
    DateTime selectedDate = existingEntry != null
        ? (existingEntry['date'] as Timestamp).toDate()
        : DateTime.now();
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
                      Row(
                        children: [
                          const Text('💰', style: TextStyle(fontSize: 24)),
                          const SizedBox(width: 10),
                          Text(
                            existingEntry == null
                                ? 'Naya Entry'
                                : 'Edit Entry',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF10B981),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.personName,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Amount + Date
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: amountController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Amount (₹)',
                                prefixIcon: const Icon(Icons.currency_rupee),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final DateTime? picked = await showDatePicker(
                                  context: context,
                                  initialDate: selectedDate,
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime.now(),
                                );
                                if (picked != null) {
                                  setDialogState(() => selectedDate = picked);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 16),
                                decoration: BoxDecoration(
                                  border:
                                      Border.all(color: Colors.grey[400]!),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.calendar_today,
                                        color: Colors.grey, size: 18),
                                    const SizedBox(width: 8),
                                    Text(
                                      DateFormat('dd MMM')
                                          .format(selectedDate),
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      // Note
                      TextField(
                        controller: noteController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: 'Wajah / Note',
                          hintText: 'Kis cheez ke paise hain?',
                          prefixIcon: const Icon(Icons.note),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Type buttons
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setDialogState(() => type = 'diya'),
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
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
                                          width: 10,
                                          height: 10,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFFEF4444),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        const Text(
                                          'Diya',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFFEF4444),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    const Text(
                                      'MAINE DIYA',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFEF4444),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setDialogState(() => type = 'liya'),
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
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
                                          width: 10,
                                          height: 10,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFF10B981),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        const Text(
                                          'Liya',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF10B981),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    const Text(
                                      'MAINE LIYA',
                                      style: TextStyle(
                                        fontSize: 9,
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: isSaving
                                ? null
                                : () async {
                                    if (amountController.text.trim().isEmpty) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content:
                                                Text('Amount zaroori hai')),
                                      );
                                      return;
                                    }

                                    setDialogState(() => isSaving = true);

                                    try {
                                      Map<String, dynamic> data = {
                                        'userId': currentUserId,
                                        'khataId': widget.khataId,
                                        'personName': widget.personName,
                                        'phoneNumber': widget.phoneNumber,
                                        'amount': double.parse(
                                            amountController.text.trim()),
                                        'type': type,
                                        'date': Timestamp.fromDate(
                                            selectedDate),
                                        'note': noteController.text.trim(),
                                        'isSettled': false,
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
                                                      ? 'Entry add ho gayi!'
                                                      : 'Entry update ho gayi!')),
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
                                  horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: isSaving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white),
                                  )
                                : Text(
                                    existingEntry == null ? 'Add' : 'Update'),
                          ),
                        ],
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

  // ============ SETTLE ENTRY ============
  Future<void> _settleEntry(String docId) async {
    bool confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            title: const Text('Settle Karo?'),
            content: const Text(
                'Ye entry settled ho jayegi aur balance se minus ho jayegi.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Settle'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirm) return;

    await FirebaseFirestore.instance.collection('hisab').doc(docId).update({
      'isSettled': true,
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Entry settled ho gayi')),
      );
    }
  }

  // ============ UNSETTLE ENTRY ============
  Future<void> _unsettleEntry(String docId) async {
    await FirebaseFirestore.instance.collection('hisab').doc(docId).update({
      'isSettled': false,
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Entry unsettled ho gayi')),
      );
    }
  }

  // ============ DELETE ENTRY ============
  Future<void> _deleteEntry(String docId) async {
    bool confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            title: const Text('Delete Karo?'),
            content: const Text('Ye entry permanently delete ho jayegi.'),
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
        const SnackBar(content: Text('Entry delete ho gayi')),
      );
    }
  }

  // ============ CALL / WHATSAPP ============
  Future<void> _makeCall() async {
    if (widget.phoneNumber.isEmpty) return;
    final Uri url = Uri.parse('tel:${widget.phoneNumber}');
    if (await canLaunchUrl(url)) await launchUrl(url);
  }

  Future<void> _openWhatsApp() async {
    if (widget.phoneNumber.isEmpty) return;
    String cleanPhone = widget.phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
    if (!cleanPhone.startsWith('91')) cleanPhone = '91$cleanPhone';
    final Uri url = Uri.parse('https://wa.me/$cleanPhone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  // ============ ENTRY OPTIONS ============
  void _showEntryOptions(Map<String, dynamic> entry, String docId) {
    bool isSettled = entry['isSettled'] == true;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 15),
              if (!isSettled)
                ListTile(
                  leading: const Icon(Icons.check_circle, color: Colors.green),
                  title: const Text('Mark as Settled'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _settleEntry(docId);
                  },
                )
              else
                ListTile(
                  leading: const Icon(Icons.undo, color: Colors.orange),
                  title: const Text('Mark as Unsettled'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _unsettleEntry(docId);
                  },
                ),
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.blue),
                title: const Text('Edit'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showAddEntryDialog(existingEntry: entry, docId: docId);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _deleteEntry(docId);
                },
              ),
              const SizedBox(height: 15),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFF10B981),
              child: Text(
                widget.personName[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
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
                    widget.personName,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  if (widget.phoneNumber.isNotEmpty)
                    Text(
                      widget.phoneNumber,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (widget.phoneNumber.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.call, color: Color(0xFF4A6CF7)),
              onPressed: _makeCall,
            ),
          if (widget.phoneNumber.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.chat, color: Colors.green),
              onPressed: _openWhatsApp,
            ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('hisab')
            .where('khataId', isEqualTo: widget.khataId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          List<Map<String, dynamic>> allEntries = [];
          if (snapshot.hasData) {
            allEntries = snapshot.data!.docs.map((doc) {
              var data = doc.data() as Map<String, dynamic>;
              data['docId'] = doc.id;
              return data;
            }).toList();

            allEntries.sort((a, b) {
              Timestamp ta = a['date'] as Timestamp;
              Timestamp tb = b['date'] as Timestamp;
              return tb.compareTo(ta);
            });
          }

          // Balance calculate (sirf unsettled)
          double totalDiya = 0;
          double totalLiya = 0;
          for (var entry in allEntries) {
            if (entry['isSettled'] == true) continue;
            double amount = (entry['amount'] as num).toDouble();
            if (entry['type'] == 'diya') {
              totalDiya += amount;
            } else {
              totalLiya += amount;
            }
          }
          double netBalance = totalDiya - totalLiya;
          bool isPositive = netBalance >= 0;

          return Column(
            children: [
              // Balance Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                color: Colors.white,
                child: Column(
                  children: [
                    Text(
                      netBalance == 0
                          ? 'SETTLED'
                          : (isPositive
                              ? 'AAPKO LENE HAIN'
                              : 'AAPKO DENE HAIN'),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: netBalance == 0
                            ? Colors.grey
                            : (isPositive ? Colors.green : Colors.red),
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '₹ ${netBalance.abs().toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        color: netBalance == 0
                            ? Colors.grey
                            : (isPositive ? Colors.green : Colors.red),
                      ),
                    ),
                    const SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Total Diya: ₹ ${totalDiya.toStringAsFixed(0)}',
                          style: const TextStyle(
                              color: Colors.red, fontSize: 12),
                        ),
                        const SizedBox(width: 20),
                        Text(
                          'Total Liya: ₹ ${totalLiya.toStringAsFixed(0)}',
                          style: const TextStyle(
                              color: Colors.green, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Entries list
              Expanded(
                child: allEntries.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: allEntries.length,
                        itemBuilder: (context, index) {
                          return _buildEntryTile(allEntries[index]);
                        },
                      ),
              ),

              // Bottom buttons
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // Diya entry
                          final controller = TextEditingController();
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20)),
                              title: const Text('Maine Diya'),
                              content: TextField(
                                controller: controller,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Amount (₹)',
                                  prefixIcon: Icon(Icons.currency_rupee),
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  onPressed: () async {
                                    if (controller.text.trim().isEmpty) return;
                                    await FirebaseFirestore.instance
                                        .collection('hisab')
                                        .add({
                                      'userId': currentUserId,
                                      'khataId': widget.khataId,
                                      'personName': widget.personName,
                                      'phoneNumber': widget.phoneNumber,
                                      'amount': double.parse(
                                          controller.text.trim()),
                                      'type': 'diya',
                                      'date': FieldValue.serverTimestamp(),
                                      'note': '',
                                      'isSettled': false,
                                      'createdAt':
                                          FieldValue.serverTimestamp(),
                                    });
                                    if (context.mounted) {
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                'Diya entry add ho gayi!')),
                                      );
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFEF4444),
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Add'),
                                ),
                              ],
                            ),
                          );
                        },
                        icon: const Icon(Icons.arrow_upward),
                        label: const Text('AAPNE DIYE ₹'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEF4444),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
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
                          // Liya entry
                          final controller = TextEditingController();
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20)),
                              title: const Text('Maine Liya'),
                              content: TextField(
                                controller: controller,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Amount (₹)',
                                  prefixIcon: Icon(Icons.currency_rupee),
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  onPressed: () async {
                                    if (controller.text.trim().isEmpty) return;
                                    await FirebaseFirestore.instance
                                        .collection('hisab')
                                        .add({
                                      'userId': currentUserId,
                                      'khataId': widget.khataId,
                                      'personName': widget.personName,
                                      'phoneNumber': widget.phoneNumber,
                                      'amount': double.parse(
                                          controller.text.trim()),
                                      'type': 'liya',
                                      'date': FieldValue.serverTimestamp(),
                                      'note': '',
                                      'isSettled': false,
                                      'createdAt':
                                          FieldValue.serverTimestamp(),
                                    });
                                    if (context.mounted) {
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                'Liya entry add ho gayi!')),
                                      );
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF10B981),
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Add'),
                                ),
                              ],
                            ),
                          );
                        },
                        icon: const Icon(Icons.arrow_downward),
                        label: const Text('AAPNE LIYE ₹'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long, size: 60, color: Colors.grey[400]),
          const SizedBox(height: 15),
          Text(
            'Abhi koi entry nahi hai',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Neeche buttons se entry add karo',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildEntryTile(Map<String, dynamic> entry) {
    bool isDiya = entry['type'] == 'diya';
    bool isSettled = entry['isSettled'] == true;
    DateTime date = (entry['date'] as Timestamp).toDate();
    String docId = entry['docId'];

    return GestureDetector(
      onTap: () => _showEntryOptions(entry, docId),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSettled ? Colors.grey[100] : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: isSettled
              ? Border.all(color: Colors.grey[300]!, width: 1)
              : null,
          boxShadow: isSettled
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          children: [
            // Type indicator
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDiya
                    ? const Color(0xFFEF4444).withOpacity(0.1)
                    : const Color(0xFF10B981).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isDiya ? Icons.arrow_upward : Icons.arrow_downward,
                color:
                    isDiya ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            // Date + Note
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${DateFormat('dd MMM yy').format(date)} • ${DateFormat('hh:mm a').format(date)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                  if ((entry['note'] ?? '').isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      entry['note'],
                      style: TextStyle(
                        fontSize: 13,
                        color: isSettled
                            ? Colors.grey[500]
                            : Colors.grey[800],
                        fontWeight: FontWeight.w500,
                        decoration:
                            isSettled ? TextDecoration.lineThrough : null,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            // Amount
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹ ${entry['amount'].toStringAsFixed(0)}',
                  style: TextStyle(
                    color: isSettled
                        ? Colors.grey[500]
                        : (isDiya
                            ? const Color(0xFFEF4444)
                            : const Color(0xFF10B981)),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    decoration:
                        isSettled ? TextDecoration.lineThrough : null,
                  ),
                ),
                if (isSettled)
                  const Text(
                    'Settled',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
