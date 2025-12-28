import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  double usedStorage = 0.0; // MB
  final double totalStorage = 5120.0; // 5 GB = 5120 MB

  int approvedCount = 0;
  int pendingCount = 0;
  int rejectedCount = 0;

  bool isLoading = true;
  String? currentUserId;
  String? currentUserName;
  String? currentUserEmail;
  String? currentUserRole;

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
  }

  Future<void> _getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      final userName = prefs.getString('userName') ?? 'User';
      final userEmail = prefs.getString('userEmail') ?? '';
      final userRole = prefs.getString('userRole') ?? 'user';

      if (userId != null) {
        setState(() {
          currentUserId = userId;
          currentUserName = userName;
          currentUserEmail = userEmail;
          currentUserRole = userRole;
        });
        _loadData();
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error getting current user: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _loadData() async {
    if (currentUserId == null || currentUserRole == null) return;

    setState(() {
      isLoading = true;
    });

    try {
      Query submissionsQuery = _firestore.collection('pengajuan');

      // Jika role adalah user, filter hanya dokumen yang assignedTo = userId
      // Jika role adalah admin, ambil semua dokumen
      if (currentUserRole == 'user') {
        submissionsQuery = submissionsQuery.where(
          'assignedTo',
          isEqualTo: currentUserId,
        );
      }

      final submissionsSnapshot = await submissionsQuery.get();

      double totalSize = 0;
      int approved = 0;
      int pending = 0;
      int rejected = 0;

      for (var doc in submissionsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;

        // Calculate storage from fileSize (in bytes, convert to MB)
        if (data['fileSize'] != null) {
          totalSize +=
              (data['fileSize'] / (1024 * 1024)); // Convert bytes to MB
        }

        // Count status berdasarkan field status langsung
        final status = data['status'] ?? 'pending';

        if (status == 'Approved' || status == 'approved') {
          approved++;
        } else if (status == 'Rejected' || status == 'rejected') {
          rejected++;
        } else {
          pending++;
        }
      }

      setState(() {
        usedStorage = totalSize;
        approvedCount = approved;
        pendingCount = pending;
        rejectedCount = rejected;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final storagePercentage = (usedStorage / totalStorage * 100);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF5F7FA), Color(0xFFFFFFFF)],
          ),
        ),
        child: CustomScrollView(
          slivers: [
            // Modern App Bar - Improved Design
            SliverAppBar(
              expandedHeight: 200,
              floating: false,
              pinned: false,
              backgroundColor: Colors.transparent,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF6C63FF),
                        const Color(0xFF5A52D5),
                        const Color(0xFF00D4FF).withOpacity(0.8),
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(40),
                      bottomRight: Radius.circular(40),
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top Section - Logo
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Logo Section
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.25),
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.folder_special_rounded,
                                      color: Colors.white,
                                      size: 32,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'ArsipKu',
                                        style: TextStyle(
                                          fontSize: 26,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        'Document Management',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.white70,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const Spacer(),
                          // Welcome Message
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Selamat Datang, ${currentUserName ?? 'User'}! 👋',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                currentUserRole == 'admin'
                                    ? 'Kelola semua dokumen dengan mudah'
                                    : 'Kelola dokumen Anda dengan mudah',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Content
            SliverToBoxAdapter(
              child: isLoading
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Column(
                          children: [
                            CircularProgressIndicator(color: Color(0xFF6C63FF)),
                            SizedBox(height: 16),
                            Text(
                              'Loading data...',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Storage Card
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFF6C63FF), Color(0xFF5A52D5)],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF6C63FF,
                                  ).withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Storage Usage',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        '${storagePercentage.toStringAsFixed(1)}%',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: LinearProgressIndicator(
                                    value: storagePercentage / 100,
                                    backgroundColor: Colors.white.withOpacity(
                                      0.3,
                                    ),
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                          Color(0xFF10B981),
                                        ),
                                    minHeight: 8,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  '${usedStorage.toStringAsFixed(2)} MB / ${(totalStorage / 1024).toStringAsFixed(1)} GB',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Quick Stats
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  icon: Icons.check_circle,
                                  label: 'Approved',
                                  value: approvedCount.toString(),
                                  color: const Color(0xFF10B981),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildStatCard(
                                  icon: Icons.pending,
                                  label: 'Pending',
                                  value: pendingCount.toString(),
                                  color: const Color(0xFFF59E0B),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildStatCard(
                                  icon: Icons.cancel,
                                  label: 'Rejected',
                                  value: rejectedCount.toString(),
                                  color: const Color(0xFFEF4444),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),

                          // Recent Submissions Header
                          Text(
                            currentUserRole == 'admin'
                                ? 'All Submissions'
                                : 'My Submissions',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Recent Submissions List - Real Time
                          StreamBuilder<QuerySnapshot>(
                            stream: currentUserId != null
                                ? (currentUserRole == 'admin'
                                      ? _firestore
                                            .collection('pengajuan')
                                            .orderBy(
                                              'createdAt',
                                              descending: true,
                                            )
                                            .limit(5)
                                            .snapshots()
                                      : _firestore
                                            .collection('pengajuan')
                                            .where(
                                              'assignedTo',
                                              isEqualTo: currentUserId,
                                            )
                                            .orderBy(
                                              'createdAt',
                                              descending: true,
                                            )
                                            .limit(5)
                                            .snapshots())
                                : null,
                            builder: (context, snapshot) {
                              if (currentUserId == null) {
                                return Container(
                                  padding: const EdgeInsets.all(32),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.login,
                                        size: 64,
                                        color: Colors.grey[300],
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Please login first',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }

                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                  child: CircularProgressIndicator(
                                    color: Color(0xFF6C63FF),
                                  ),
                                );
                              }

                              if (!snapshot.hasData ||
                                  snapshot.data!.docs.isEmpty) {
                                return Container(
                                  padding: const EdgeInsets.all(32),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.inbox,
                                        size: 64,
                                        color: Colors.grey[300],
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'No submissions yet',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Start by creating a new submission',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[500],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }

                              return Column(
                                children: snapshot.data!.docs.map((doc) {
                                  final data =
                                      doc.data() as Map<String, dynamic>;
                                  return _buildSubmissionCard(data, doc.id);
                                }).toList(),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // CARD YANG TIDAK BISA DITEKAN
  Widget _buildSubmissionCard(Map<String, dynamic> data, String docId) {
    final fileName = data['fileName'] ?? 'Unknown';
    final createdAt = data['createdAt'] as Timestamp?;

    // Get status langsung dari field status
    String status = data['status'] ?? 'pending';
    status = status.toLowerCase();

    final dateStr = createdAt != null
        ? _formatDate(createdAt.toDate())
        : 'Unknown date';

    Color statusColor;
    IconData statusIcon;

    switch (status) {
      case 'approved':
        statusColor = const Color(0xFF10B981);
        statusIcon = Icons.check_circle;
        break;
      case 'rejected':
        statusColor = const Color(0xFFEF4444);
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = const Color(0xFFF59E0B);
        statusIcon = Icons.pending;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      // TIDAK ADA Material & InkWell - CARD TIDAK BISA DITEKAN
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF6C63FF).withOpacity(0.2),
                    const Color(0xFF00D4FF).withOpacity(0.2),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.description,
                color: Color(0xFF6C63FF),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fileName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dateStr,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: statusColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(statusIcon, size: 14, color: statusColor),
                  const SizedBox(width: 4),
                  Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  // FUNGSI INI SUDAH TIDAK DIGUNAKAN KARENA CARD TIDAK BISA DITEKAN
  // Tapi tetap disimpan jika nanti ingin diaktifkan kembali
  void _showDetailDialog(
    BuildContext context,
    Map<String, dynamic> data,
    String docId,
  ) {
    final fileName = data['fileName'] ?? 'Unknown';
    final fileSize = data['fileSize'] ?? 0;
    final createdAt = data['createdAt'] as Timestamp?;
    final assignedTo = data['assignedTo'] ?? 'Unknown';
    final assignedAt = data['assignedAt'] as Timestamp?;
    final jenis = data['jenis'] ?? 'Unknown';
    final keterangan = data['keterangan'] ?? 'N/A';

    String status = data['status'] ?? 'pending';
    status = status.toLowerCase();

    final dateStr = createdAt != null
        ? _formatDate(createdAt.toDate())
        : 'Unknown';

    final assignedAtStr = assignedAt != null
        ? _formatDate(assignedAt.toDate())
        : 'N/A';

    final fileSizeMB = (fileSize / (1024 * 1024)).toStringAsFixed(2);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Submission Details',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 20),
                _buildDetailRow('File Name', fileName),
                _buildDetailRow('File Size', '$fileSizeMB MB'),
                _buildDetailRow('Jenis', jenis),
                _buildDetailRow('Keterangan', keterangan),
                _buildDetailRow('Status', status.toUpperCase()),
                _buildDetailRow('Created Date', dateStr),
                _buildDetailRow('Assigned Date', assignedAtStr),
                _buildDetailRow('Assigned To', assignedTo),
                _buildDetailRow('Document ID', docId),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C63FF),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Close',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, color: Color(0xFF1F2937)),
            ),
          ),
        ],
      ),
    );
  }
}
