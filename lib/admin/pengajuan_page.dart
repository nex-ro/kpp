import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PengajuanPage extends StatefulWidget {
  const PengajuanPage({super.key});

  @override
  State<PengajuanPage> createState() => _PengajuanPageState();
}

class _PengajuanPageState extends State<PengajuanPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Fungsi untuk menampilkan dialog pilih user
  Future<void> _showUserSelectionDialog(
    BuildContext context,
    String pengajuanId,
  ) async {
    List<String> selectedUserIds = [];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Pilih Penerima Pengajuan'),
              content: SizedBox(
                width: double.maxFinite,
                height: 400,
                child: StreamBuilder<QuerySnapshot>(
                  stream: _firestore.collection('users').snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(
                        child: Text('Tidak ada user tersedia'),
                      );
                    }

                    final users = snapshot.data!.docs;

                    return ListView.builder(
                      shrinkWrap: true,
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        final user = users[index];
                        final userId = user.id;
                        final userName = user['name'] ?? 'Unknown';
                        final userEmail = user['email'] ?? '';
                        final userRole = user['role'] ?? 'user';

                        return CheckboxListTile(
                          title: Text(userName),
                          subtitle: Text('$userEmail\nRole: $userRole'),
                          value: selectedUserIds.contains(userId),
                          onChanged: (bool? value) {
                            setState(() {
                              if (value == true) {
                                selectedUserIds.add(userId);
                              } else {
                                selectedUserIds.remove(userId);
                              }
                            });
                          },
                          secondary: CircleAvatar(
                            child: Text(userName[0].toUpperCase()),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: selectedUserIds.isEmpty
                      ? null
                      : () async {
                          await _assignUsersToPengajuan(
                            pengajuanId,
                            selectedUserIds,
                          );
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Berhasil menugaskan ${selectedUserIds.length} user',
                                ),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        },
                  child: const Text('Tugaskan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Fungsi untuk assign users ke pengajuan
  Future<void> _assignUsersToPengajuan(
    String pengajuanId,
    List<String> userIds,
  ) async {
    try {
      await _firestore.collection('pengajuan').doc(pengajuanId).update({
        'assignedTo': userIds,
        'status': 'Assigned',
        'assignedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error assigning users: $e');
    }
  }

  // Fungsi untuk mendapatkan nama user dari ID
  Future<List<String>> _getUserNames(List<dynamic> userIds) async {
    List<String> names = [];
    for (var userId in userIds) {
      try {
        final userDoc = await _firestore.collection('users').doc(userId).get();
        if (userDoc.exists) {
          names.add(userDoc['name'] ?? 'Unknown');
        }
      } catch (e) {
        names.add('Unknown');
      }
    }
    return names;
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
                colors: [Colors.green.shade700, Colors.green.shade500],
              ),
            ),
            child: const SafeArea(
              child: Column(
                children: [
                  Icon(Icons.description, size: 60, color: Colors.white),
                  SizedBox(height: 10),
                  Text(
                    'Manajemen Pengajuan',
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

          // List Pengajuan
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('pengajuan')
                  .orderBy('tanggal', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox, size: 80, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('Tidak ada pengajuan'),
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
                    final keterangan = data['keterangan'] ?? 'ndnnddn';
                    final assignedTo =
                        data['assignedTo'] as List<dynamic>? ?? [];

                    // Color based on status
                    Color statusColor;
                    IconData statusIcon;
                    switch (status.toLowerCase()) {
                      case 'pending':
                        statusColor = Colors.orange;
                        statusIcon = Icons.pending;
                        break;
                      case 'assigned':
                        statusColor = Colors.blue;
                        statusIcon = Icons.assignment_turned_in;
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

                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: () =>
                            _showPengajuanDetail(context, data, pengajuanId),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    statusIcon,
                                    color: statusColor,
                                    size: 28,
                                  ),
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
                              if (assignedTo.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                const Divider(),
                                const Text(
                                  'Ditugaskan kepada:',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                FutureBuilder<List<String>>(
                                  future: _getUserNames(assignedTo),
                                  builder: (context, userSnapshot) {
                                    if (!userSnapshot.hasData) {
                                      return const Text('Loading...');
                                    }
                                    return Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: userSnapshot.data!.map((name) {
                                        return Chip(
                                          avatar: CircleAvatar(
                                            child: Text(name[0].toUpperCase()),
                                          ),
                                          label: Text(name),
                                          backgroundColor: Colors.blue.shade50,
                                        );
                                      }).toList(),
                                    );
                                  },
                                ),
                              ],
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton.icon(
                                    onPressed: () => _showUserSelectionDialog(
                                      context,
                                      pengajuanId,
                                    ),
                                    icon: const Icon(Icons.person_add),
                                    label: Text(
                                      assignedTo.isEmpty
                                          ? 'Tugaskan'
                                          : 'Ubah Tugas',
                                    ),
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
            ),
          ),
        ],
      ),
    );
  }

  // Dialog detail pengajuan
  void _showPengajuanDetail(
    BuildContext context,
    Map<String, dynamic> data,
    String pengajuanId,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Detail Pengajuan'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Jenis', data['jenis'] ?? '-'),
              _buildDetailRow('Status', data['status'] ?? '-'),
              _buildDetailRow('Keterangan', data['keterangan'] ?? '-'),
              _buildDetailRow('File', data['fileName'] ?? '-'),
              if (data['createdAt'] != null)
                _buildDetailRow(
                  'Tanggal',
                  (data['createdAt'] as Timestamp).toDate().toString().split(
                    '.',
                  )[0],
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _showUserSelectionDialog(context, pengajuanId);
            },
            icon: const Icon(Icons.person_add),
            label: const Text('Tugaskan User'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
