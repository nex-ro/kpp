import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Color Palette untuk ArsipKu
class AppColors {
  // Primary Colors - Modern Blue & Purple Gradient
  static const Color primary = Color(0xFF6C63FF);
  static const Color primaryLight = Color(0xFF8F87FF);
  static const Color primaryDark = Color(0xFF4B44CC);

  // Secondary Colors
  static const Color secondary = Color(0xFF00D4FF);
  static const Color secondaryLight = Color(0xFF5CE1FF);

  // Status Colors
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFF34D399);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFBBF24);
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFF87171);

  // Neutral Colors
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardShadow = Color(0x1A000000);

  // Text Colors
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textTertiary = Color(0xFF94A3B8);

  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient headerGradient = LinearGradient(
    colors: [primary, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class ApprovalPage extends StatefulWidget {
  const ApprovalPage({super.key, required this.currentUserId});

  final String currentUserId;

  @override
  State<ApprovalPage> createState() => _ApprovalPageState();
}

class _ApprovalPageState extends State<ApprovalPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending':
      case 'In Review':
        return AppColors.warning;
      case 'Approved':
        return AppColors.success;
      case 'Rejected':
        return AppColors.error;
      default:
        return AppColors.textTertiary;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Pending':
      case 'In Review':
        return Icons.pending_rounded;
      case 'Approved':
        return Icons.check_circle_rounded;
      case 'Rejected':
        return Icons.cancel_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  void _showDetailDialog(
    BuildContext context,
    Map<String, dynamic> data,
    String docId,
  ) {
    final jenis = data['jenis'] as String;
    final keterangan = data['keterangan'] as String? ?? '';
    final fileUrl = data['fileUrl'] as String?;
    final fileSize = data['fileSize'] as int;
    final status = data['status'] as String;
    final tanggal = (data['tanggal'] as Timestamp?)?.toDate();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.description_rounded, color: Colors.white),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Detail Pengajuan',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Jenis Pengajuan
                      _buildInfoRow(
                        Icons.category_rounded,
                        'Jenis Pengajuan',
                        jenis,
                      ),
                      const SizedBox(height: 12),

                      // Keterangan
                      if (keterangan.isNotEmpty) ...[
                        _buildInfoRow(
                          Icons.notes_rounded,
                          'Keterangan',
                          keterangan,
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Status
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.textTertiary.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _getStatusColor(status).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                _getStatusIcon(status),
                                color: _getStatusColor(status),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Status',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textTertiary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    status,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: _getStatusColor(status),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Ukuran File
                      _buildInfoRow(
                        Icons.storage_rounded,
                        'Ukuran File',
                        _formatFileSize(fileSize),
                      ),
                      const SizedBox(height: 12),

                      // Tanggal
                      if (tanggal != null)
                        _buildInfoRow(
                          Icons.access_time_rounded,
                          'Tanggal Pengajuan',
                          '${tanggal.day}/${tanggal.month}/${tanggal.year} ${tanggal.hour}:${tanggal.minute.toString().padLeft(2, '0')}',
                        ),

                      // Preview Image
                      if (fileUrl != null) ...[
                        const SizedBox(height: 20),
                        const Divider(),
                        const SizedBox(height: 20),
                        const Text(
                          'Preview File',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            fileUrl,
                            fit: BoxFit.contain,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                height: 200,
                                alignment: Alignment.center,
                                child: CircularProgressIndicator(
                                  value:
                                      loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                      : null,
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                        AppColors.primary,
                                      ),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 150,
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: AppColors.error.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.error_outline_rounded,
                                      color: AppColors.error,
                                      size: 48,
                                    ),
                                    SizedBox(height: 12),
                                    Text(
                                      'Gagal memuat preview',
                                      style: TextStyle(
                                        color: AppColors.error,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Action Buttons (hanya jika status Pending)
              if (status == 'Pending')
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    border: Border(
                      top: BorderSide(
                        color: AppColors.textTertiary.withOpacity(0.3),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            await _updateStatus(docId, 'Rejected');
                            if (context.mounted) Navigator.pop(context);
                          },
                          icon: const Icon(Icons.close_rounded, size: 20),
                          label: const Text(
                            'Tolak',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.error,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            await _updateStatus(docId, 'Approved');
                            if (context.mounted) Navigator.pop(context);
                          },
                          icon: const Icon(Icons.check_rounded, size: 20),
                          label: const Text(
                            'Setujui',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 0,
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
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.textTertiary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textTertiary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateStatus(String docId, String newStatus) async {
    try {
      await _firestore.collection('pengajuan').doc(docId).update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  newStatus == 'Approved' ? Icons.check_circle : Icons.cancel,
                  color: Colors.white,
                ),
                const SizedBox(width: 12),
                Text(
                  newStatus == 'Approved'
                      ? 'Pengajuan disetujui'
                      : 'Pengajuan ditolak',
                ),
              ],
            ),
            backgroundColor: newStatus == 'Approved'
                ? AppColors.success
                : AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Error: ${e.toString()}')),
              ],
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Header Section dengan gradient modern - FULL HEIGHT
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 50, 20, 24),
            decoration: const BoxDecoration(
              gradient: AppColors.headerGradient,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            child: Column(
              children: [
                // Logo/Icon dengan efek modern
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.approval_rounded,
                    size: 48,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                // Nama Aplikasi
                const Text(
                  'ArsipKu',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                // Subtitle
                Text(
                  'Approval Pengajuan',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.9),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
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
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 50,
                          height: 50,
                          child: CircularProgressIndicator(
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.primary,
                            ),
                            strokeWidth: 3,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Memuat data...',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.error.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.error_outline_rounded,
                              size: 64,
                              color: AppColors.error,
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Terjadi Kesalahan',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Error: ${snapshot.error}',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.folder_open_rounded,
                            size: 80,
                            color: AppColors.primary.withOpacity(0.5),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Tidak Ada Pengajuan',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Belum ada pengajuan yang perlu Anda review',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final doc = snapshot.data!.docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final jenis = data['jenis'] as String;
                    final keterangan = data['keterangan'] as String? ?? '';
                    final status = data['status'] as String;
                    final tanggal = (data['tanggal'] as Timestamp?)?.toDate();

                    final statusColor = _getStatusColor(status);
                    final statusIcon = _getStatusIcon(status);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.cardShadow,
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => _showDetailDialog(context, data, doc.id),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: statusColor.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        statusIcon,
                                        color: statusColor,
                                        size: 28,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            jenis,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                          if (keterangan.isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              keterangan,
                                              style: TextStyle(
                                                color: AppColors.textSecondary,
                                                fontSize: 13,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: statusColor.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: statusColor.withOpacity(0.3),
                                          width: 1,
                                        ),
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
                                if (tanggal != null) ...[
                                  const SizedBox(height: 12),
                                  Divider(
                                    color: AppColors.textTertiary.withOpacity(
                                      0.3,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.access_time_rounded,
                                        size: 16,
                                        color: AppColors.textTertiary,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${tanggal.day}/${tanggal.month}/${tanggal.year} ${tanggal.hour}:${tanggal.minute.toString().padLeft(2, '0')}',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: AppColors.textSecondary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const Spacer(),
                                      Icon(
                                        Icons.arrow_forward_ios_rounded,
                                        size: 14,
                                        color: AppColors.textTertiary,
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
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
}
