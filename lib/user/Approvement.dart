import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';

class ApprovalPage extends StatefulWidget {
  final String currentUserId;

  const ApprovalPage({super.key, required this.currentUserId});

  @override
  State<ApprovalPage> createState() => _ApprovalPageState();
}

class _ApprovalPageState extends State<ApprovalPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String get currentUserId => widget.currentUserId;

  // Fungsi untuk approve pengajuan
  Future<void> _approvePengajuan(
    String pengajuanId,
    Map<String, dynamic> data,
  ) async {
    try {
      final assignedTo = List<String>.from(data['assignedTo'] ?? []);
      final approvals = Map<String, dynamic>.from(data['approvals'] ?? {});

      // Tandai user ini sudah approve
      approvals[currentUserId] = {
        'status': 'approved',
        'timestamp': FieldValue.serverTimestamp(),
      };

      // Cek apakah semua user sudah approve
      bool allApproved = true;
      for (String userId in assignedTo) {
        if (!approvals.containsKey(userId) ||
            approvals[userId]['status'] != 'approved') {
          allApproved = false;
          break;
        }
      }

      // Update dokumen
      await _firestore.collection('pengajuan').doc(pengajuanId).update({
        'approvals': approvals,
        'status': allApproved ? 'Approved' : 'In Review',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              allApproved
                  ? 'Pengajuan disetujui semua! Status: Approved'
                  : 'Anda telah menyetujui pengajuan ini',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // Fungsi untuk reject pengajuan
  Future<void> _rejectPengajuan(String pengajuanId, String reason) async {
    try {
      final approvals = {
        currentUserId: {
          'status': 'rejected',
          'reason': reason,
          'timestamp': FieldValue.serverTimestamp(),
        },
      };

      await _firestore.collection('pengajuan').doc(pengajuanId).update({
        'approvals': approvals,
        'status': 'Rejected',
        'rejectedBy': currentUserId,
        'rejectionReason': reason,
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pengajuan ditolak!'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // Dialog untuk reject dengan alasan
  void _showRejectDialog(String pengajuanId, Map<String, dynamic> data) {
    final TextEditingController reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tolak Pengajuan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Anda yakin ingin menolak pengajuan ini?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Alasan Penolakan',
                hintText: 'Masukkan alasan penolakan...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Alasan penolakan harus diisi'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }
              _rejectPengajuan(pengajuanId, reasonController.text.trim());
            },
            child: const Text('Tolak'),
          ),
        ],
      ),
    );
  }

  // Fungsi untuk mendapatkan status approval user saat ini
  String _getUserApprovalStatus(Map<String, dynamic> data) {
    final approvals = data['approvals'] as Map<String, dynamic>?;
    if (approvals == null || !approvals.containsKey(currentUserId)) {
      return 'pending';
    }
    return approvals[currentUserId]['status'] ?? 'pending';
  }

  // Fungsi untuk mendapatkan nama user dari ID
  Future<String> _getUserName(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        return userDoc['name'] ?? 'Unknown';
      }
    } catch (e) {
      print('Error getting user name: $e');
    }
    return 'Unknown';
  }

  // Widget untuk menampilkan file attachment
  Widget _buildFilePreview(Map<String, dynamic> data) {
    final filePath = data['filePath'] as String?;
    final fileName = data['fileName'] as String?;

    if (filePath == null || filePath.isEmpty) {
      return const SizedBox.shrink();
    }

    final isImage =
        fileName?.toLowerCase().endsWith('.jpg') == true ||
        fileName?.toLowerCase().endsWith('.jpeg') == true ||
        fileName?.toLowerCase().endsWith('.png') == true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        const Text(
          'Lampiran:',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _showFileDialog(filePath, fileName ?? 'File', isImage),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(
                  isImage ? Icons.image : Icons.attach_file,
                  color: Colors.blue,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fileName ?? 'File',
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        'Tap untuk melihat',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, size: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Dialog untuk menampilkan file
  void _showFileDialog(String filePath, String fileName, bool isImage) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                title: Text(fileName),
                automaticallyImplyLeading: false,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              Expanded(
                child: isImage
                    ? InteractiveViewer(
                        child: Image.file(
                          File(filePath),
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.error_outline,
                                    size: 48,
                                    color: Colors.red,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Tidak dapat memuat gambar',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    filePath,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[500],
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      )
                    : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.insert_drive_file,
                              size: 64,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              fileName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'File path: $filePath',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget untuk menampilkan status approval dari setiap user
  Widget _buildApprovalStatus(Map<String, dynamic> data) {
    final assignedTo = List<String>.from(data['assignedTo'] ?? []);
    final approvals = Map<String, dynamic>.from(data['approvals'] ?? {});

    if (assignedTo.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        const Text(
          'Status Approval:',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...assignedTo.map((userId) {
          final userApproval = approvals[userId];
          final status = userApproval?['status'] ?? 'pending';

          IconData icon;
          Color color;
          String statusText;

          switch (status) {
            case 'approved':
              icon = Icons.check_circle;
              color = Colors.green;
              statusText = 'Disetujui';
              break;
            case 'rejected':
              icon = Icons.cancel;
              color = Colors.red;
              statusText = 'Ditolak';
              break;
            default:
              icon = Icons.pending;
              color = Colors.orange;
              statusText = 'Menunggu';
          }

          return FutureBuilder<String>(
            future: _getUserName(userId),
            builder: (context, snapshot) {
              final userName = snapshot.data ?? 'Loading...';
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(icon, color: color, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        userName,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          color: color,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        }).toList(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Header Section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade700, Colors.blue.shade500],
              ),
            ),
            child: const SafeArea(
              child: Column(
                children: [
                  Icon(Icons.approval, size: 60, color: Colors.white),
                  SizedBox(height: 10),
                  Text(
                    'Approval Pengajuan',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // List Pengajuan yang perlu diapprove
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('pengajuan')
                  .where('assignedTo', arrayContains: currentUserId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 80,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text('Error: ${snapshot.error}'),
                      ],
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox, size: 80, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('Tidak ada pengajuan untuk Anda'),
                      ],
                    ),
                  );
                }

                final pengajuanList = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: pengajuanList.length,
                  itemBuilder: (context, index) {
                    final pengajuan = pengajuanList[index];
                    final data = pengajuan.data() as Map<String, dynamic>;
                    final pengajuanId = pengajuan.id;

                    final jenis = data['jenis'] ?? 'Unknown';
                    final status = data['status'] ?? 'Pending';
                    final keterangan = data['keterangan'] ?? '';
                    final userApprovalStatus = _getUserApprovalStatus(data);

                    // Color based on status
                    Color statusColor;
                    IconData statusIcon;
                    switch (status.toLowerCase()) {
                      case 'pending':
                      case 'assigned':
                      case 'in review':
                        statusColor = Colors.orange;
                        statusIcon = Icons.pending;
                        break;
                      case 'approved':
                        statusColor = Colors.green;
                        statusIcon = Icons.check_circle;
                        break;
                      case 'rejected':
                        statusColor = Colors.red;
                        statusIcon = Icons.cancel;
                        break;
                      default:
                        statusColor = Colors.grey;
                        statusIcon = Icons.help;
                    }

                    // Cek apakah user sudah memberikan keputusan
                    final hasDecided = userApprovalStatus != 'pending';

                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(statusIcon, color: statusColor, size: 28),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        jenis,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (keterangan.isNotEmpty)
                                        Text(
                                          keterangan,
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 12,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    status,
                                    style: TextStyle(
                                      color: statusColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            // Tampilkan file attachment
                            _buildFilePreview(data),

                            _buildApprovalStatus(data),

                            // Action Buttons
                            if (!hasDecided &&
                                status != 'Rejected' &&
                                status != 'Approved') ...[
                              const SizedBox(height: 16),
                              const Divider(),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: () =>
                                        _showRejectDialog(pengajuanId, data),
                                    icon: const Icon(Icons.close),
                                    label: const Text('Tolak'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.red,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton.icon(
                                    onPressed: () =>
                                        _approvePengajuan(pengajuanId, data),
                                    icon: const Icon(Icons.check),
                                    label: const Text('Setujui'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ] else if (hasDecided) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: userApprovalStatus == 'approved'
                                      ? Colors.green.withOpacity(0.1)
                                      : Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      userApprovalStatus == 'approved'
                                          ? Icons.check_circle
                                          : Icons.cancel,
                                      color: userApprovalStatus == 'approved'
                                          ? Colors.green
                                          : Colors.red,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      userApprovalStatus == 'approved'
                                          ? 'Anda telah menyetujui pengajuan ini'
                                          : 'Anda telah menolak pengajuan ini',
                                      style: TextStyle(
                                        color: userApprovalStatus == 'approved'
                                            ? Colors.green
                                            : Colors.red,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
