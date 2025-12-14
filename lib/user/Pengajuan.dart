import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

// Color Palette untuk ArsipKu (sama dengan ApprovalPage)
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

class PengajuanPage extends StatefulWidget {
  const PengajuanPage({super.key});

  @override
  State<PengajuanPage> createState() => _PengajuanPageState();
}

class _PengajuanPageState extends State<PengajuanPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  final List<String> _jenisPengajuan = [
    'Request budget / petty cash',
    'Surat jalan',
    'Laporan panen / laporan harian',
    'FP, CS, plantation, planning',
  ];

  Future<String> _uploadFileToStorage(File file, String fileName) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final storageRef = _storage.ref().child('pengajuan/$timestamp-$fileName');
      final uploadTask = await storageRef.putFile(file);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Gagal upload file: $e');
    }
  }

  Future<void> _savePengajuanToFirestore({
    required String jenis,
    required String keterangan,
    required String fileName,
    required int fileSize,
    required String fileUrl,
  }) async {
    try {
      await _firestore.collection('pengajuan').add({
        'jenis': jenis,
        'keterangan': keterangan,
        'fileName': fileName,
        'fileSize': fileSize,
        'fileUrl': fileUrl,
        'tanggal': FieldValue.serverTimestamp(),
        'status': 'Pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Gagal menyimpan data: $e');
    }
  }

  void _showUploadDialog() {
    String? selectedJenis;
    File? selectedFile;
    final TextEditingController keteranganController = TextEditingController();
    bool isUploading = false;
    double uploadProgress = 0.0;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.upload_file_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Upload Pengajuan',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Jenis Pengajuan',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: selectedJenis,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.textTertiary),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.textTertiary),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: AppColors.background,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      hint: const Text('Pilih jenis pengajuan'),
                      items: _jenisPengajuan.map((String jenis) {
                        return DropdownMenuItem<String>(
                          value: jenis,
                          child: Text(
                            jenis,
                            style: const TextStyle(fontSize: 14),
                          ),
                        );
                      }).toList(),
                      onChanged: isUploading
                          ? null
                          : (String? newValue) {
                              setDialogState(() {
                                selectedJenis = newValue;
                              });
                            },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Keterangan',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: keteranganController,
                      enabled: !isUploading,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.textTertiary),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.textTertiary),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                            width: 2,
                          ),
                        ),
                        hintText: 'Masukkan keterangan',
                        filled: true,
                        fillColor: AppColors.background,
                        contentPadding: const EdgeInsets.all(16),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Upload File',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: isUploading
                                ? null
                                : () async {
                                    final result = await FilePicker.platform
                                        .pickFiles(
                                          type: FileType.custom,
                                          allowedExtensions: [
                                            'pdf',
                                            'doc',
                                            'docx',
                                            'jpg',
                                            'jpeg',
                                            'png',
                                          ],
                                        );

                                    if (result != null) {
                                      final file = File(
                                        result.files.single.path!,
                                      );
                                      final fileSize = await file.length();

                                      if (fileSize > 10 * 1024 * 1024) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: const Row(
                                                children: [
                                                  Icon(
                                                    Icons.warning,
                                                    color: Colors.white,
                                                  ),
                                                  SizedBox(width: 12),
                                                  Text(
                                                    'Ukuran file maksimal 10 MB',
                                                  ),
                                                ],
                                              ),
                                              backgroundColor:
                                                  AppColors.warning,
                                              behavior:
                                                  SnackBarBehavior.floating,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              margin: const EdgeInsets.all(16),
                                            ),
                                          );
                                        }
                                      } else {
                                        setDialogState(() {
                                          selectedFile = file;
                                        });
                                      }
                                    }
                                  },
                            icon: const Icon(
                              Icons.folder_open_rounded,
                              size: 18,
                            ),
                            label: const Text(
                              'Pilih File',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: isUploading
                                ? null
                                : () async {
                                    final ImagePicker picker = ImagePicker();
                                    final XFile? photo = await picker.pickImage(
                                      source: ImageSource.camera,
                                      maxWidth: 1920,
                                      maxHeight: 1920,
                                      imageQuality: 85,
                                    );

                                    if (photo != null) {
                                      final file = File(photo.path);
                                      final fileSize = await file.length();

                                      if (fileSize > 10 * 1024 * 1024) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: const Row(
                                                children: [
                                                  Icon(
                                                    Icons.warning,
                                                    color: Colors.white,
                                                  ),
                                                  SizedBox(width: 12),
                                                  Text(
                                                    'Ukuran foto maksimal 10 MB',
                                                  ),
                                                ],
                                              ),
                                              backgroundColor:
                                                  AppColors.warning,
                                              behavior:
                                                  SnackBarBehavior.floating,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              margin: const EdgeInsets.all(16),
                                            ),
                                          );
                                        }
                                      } else {
                                        setDialogState(() {
                                          selectedFile = file;
                                        });
                                      }
                                    }
                                  },
                            icon: const Icon(
                              Icons.camera_alt_rounded,
                              size: 18,
                            ),
                            label: const Text(
                              'Kamera',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.secondary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (selectedFile != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.success.withOpacity(0.1),
                              AppColors.successLight.withOpacity(0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.success.withOpacity(0.3),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.success.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.check_circle_rounded,
                                color: AppColors.success,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                selectedFile!.path.split('/').last,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (!isUploading)
                              IconButton(
                                icon: const Icon(
                                  Icons.close_rounded,
                                  size: 20,
                                  color: AppColors.error,
                                ),
                                onPressed: () {
                                  setDialogState(() {
                                    selectedFile = null;
                                  });
                                },
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                          ],
                        ),
                      ),
                    ],
                    if (isUploading) ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            SizedBox(
                              width: 40,
                              height: 40,
                              child: CircularProgressIndicator(
                                value: uploadProgress,
                                strokeWidth: 4,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  AppColors.primary,
                                ),
                                backgroundColor: AppColors.primary.withOpacity(
                                  0.2,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Mengupload... ${(uploadProgress * 100).toStringAsFixed(0)}%',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                if (!isUploading)
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: const Text(
                      'Batal',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ElevatedButton(
                  onPressed: isUploading
                      ? null
                      : () async {
                          if (selectedJenis == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Row(
                                  children: [
                                    Icon(Icons.warning, color: Colors.white),
                                    SizedBox(width: 12),
                                    Text(
                                      'Pilih jenis pengajuan terlebih dahulu',
                                    ),
                                  ],
                                ),
                                backgroundColor: AppColors.warning,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                margin: const EdgeInsets.all(16),
                              ),
                            );
                            return;
                          }

                          if (selectedFile == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Row(
                                  children: [
                                    Icon(Icons.warning, color: Colors.white),
                                    SizedBox(width: 12),
                                    Text('Pilih file terlebih dahulu'),
                                  ],
                                ),
                                backgroundColor: AppColors.warning,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                margin: const EdgeInsets.all(16),
                              ),
                            );
                            return;
                          }

                          setDialogState(() {
                            isUploading = true;
                            uploadProgress = 0.0;
                          });

                          try {
                            final fileSize = await selectedFile!.length();
                            final fileName = selectedFile!.path.split('/').last;

                            final timestamp =
                                DateTime.now().millisecondsSinceEpoch;
                            final storageRef = _storage.ref().child(
                              'pengajuan/$timestamp-$fileName',
                            );

                            final uploadTask = storageRef.putFile(
                              selectedFile!,
                            );

                            uploadTask.snapshotEvents.listen((
                              TaskSnapshot snapshot,
                            ) {
                              setDialogState(() {
                                uploadProgress =
                                    snapshot.bytesTransferred /
                                    snapshot.totalBytes;
                              });
                            });

                            final taskSnapshot = await uploadTask;
                            final downloadUrl = await taskSnapshot.ref
                                .getDownloadURL();

                            await _savePengajuanToFirestore(
                              jenis: selectedJenis!,
                              keterangan: keteranganController.text,
                              fileName: fileName,
                              fileSize: fileSize,
                              fileUrl: downloadUrl,
                            );

                            if (context.mounted) {
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Row(
                                    children: [
                                      Icon(
                                        Icons.check_circle,
                                        color: Colors.white,
                                      ),
                                      SizedBox(width: 12),
                                      Text('Pengajuan berhasil disimpan'),
                                    ],
                                  ),
                                  backgroundColor: AppColors.success,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  margin: const EdgeInsets.all(16),
                                ),
                              );
                            }
                          } catch (e) {
                            setDialogState(() {
                              isUploading = false;
                              uploadProgress = 0.0;
                            });
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      const Icon(
                                        Icons.error_outline,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text('Error: ${e.toString()}'),
                                      ),
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
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Upload',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

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

  void _showFilePreview(BuildContext context, Map<String, dynamic> data) async {
    final fileName = data['fileName'] as String;
    final fileUrl = data['fileUrl'] as String?;
    final fileSize = data['fileSize'] as int;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
                        'Detail File',
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
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow(
                        Icons.insert_drive_file_rounded,
                        'Nama File',
                        fileName,
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        Icons.storage_rounded,
                        'Ukuran',
                        _formatFileSize(fileSize),
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        Icons.link_rounded,
                        'Status',
                        fileUrl != null
                            ? 'File tersedia'
                            : 'File tidak tersedia',
                      ),
                      if (fileUrl != null) ...[
                        const SizedBox(height: 20),
                        const Divider(),
                        const SizedBox(height: 20),
                        if (fileName.toLowerCase().endsWith('.jpg') ||
                            fileName.toLowerCase().endsWith('.jpeg') ||
                            fileName.toLowerCase().endsWith('.png')) ...[
                          const Text(
                            'Preview',
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
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Container(
                                      height: 200,
                                      alignment: Alignment.center,
                                      child: CircularProgressIndicator(
                                        value:
                                            loadingProgress
                                                    .expectedTotalBytes !=
                                                null
                                            ? loadingProgress
                                                      .cumulativeBytesLoaded /
                                                  loadingProgress
                                                      .expectedTotalBytes!
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
                                        'Gagal memuat gambar',
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
                    ],
                  ),
                ),
              ),
              if (fileUrl != null)
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
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      color: Colors.white,
                                    ),
                                    SizedBox(width: 12),
                                    Text('Implementasi download/buka file'),
                                  ],
                                ),
                                backgroundColor: AppColors.primary,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                margin: const EdgeInsets.all(16),
                              ),
                            );
                          },
                          icon: const Icon(Icons.open_in_new_rounded, size: 20),
                          label: const Text(
                            'Buka File',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Header Section dengan gradient modern
          Container(
            padding: const EdgeInsets.only(top: 40, bottom: 24),
            decoration: const BoxDecoration(
              gradient: AppColors.headerGradient,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 20),
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
                      Icons.description_rounded,
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
                    'Halaman Pengajuan',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withOpacity(0.9),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Statistics Cards
                  StreamBuilder<QuerySnapshot>(
                    stream: _firestore.collection('pengajuan').snapshots(),
                    builder: (context, snapshot) {
                      int pendingCount = 0;
                      int approvedCount = 0;
                      int rejectedCount = 0;

                      if (snapshot.hasData) {
                        for (var doc in snapshot.data!.docs) {
                          final status = doc['status'] as String;
                          if (status == 'Pending') pendingCount++;
                          if (status == 'Approved') approvedCount++;
                          if (status == 'Rejected') rejectedCount++;
                        }
                      }

                      return Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              Icons.pending_rounded,
                              '$pendingCount',
                              'Pending',
                              AppColors.warning,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              Icons.check_circle_rounded,
                              '$approvedCount',
                              'Approved',
                              AppColors.success,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              Icons.cancel_rounded,
                              '$rejectedCount',
                              'Rejected',
                              AppColors.error,
                            ),
                          ),
                        ],
                      );
                    },
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
                          'Belum Ada Pengajuan',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap tombol + untuk membuat pengajuan baru',
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
                    final fileName = data['fileName'] as String;
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
                            const SizedBox(height: 12),
                            Divider(
                              color: AppColors.textTertiary.withOpacity(0.3),
                            ),
                            const SizedBox(height: 12),
                            // File Info
                            Row(
                              children: [
                                Icon(
                                  Icons.attach_file_rounded,
                                  size: 16,
                                  color: AppColors.textTertiary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    fileName,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            if (tanggal != null) ...[
                              const SizedBox(height: 8),
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
                                ],
                              ),
                            ],
                            const SizedBox(height: 12),
                            // View Button
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () =>
                                    _showFilePreview(context, data),
                                icon: const Icon(
                                  Icons.visibility_rounded,
                                  size: 18,
                                ),
                                label: const Text(
                                  'Lihat Detail',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.primary,
                                  side: BorderSide(
                                    color: AppColors.primary.withOpacity(0.5),
                                    width: 1.5,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showUploadDialog,
        backgroundColor: AppColors.primary,
        elevation: 4,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Buat Pengajuan',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    IconData icon,
    String count,
    String label,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 6),
          Text(
            count,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withOpacity(0.9),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
