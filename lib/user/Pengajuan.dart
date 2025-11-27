import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'dart:convert';

class PengajuanPage extends StatefulWidget {
  const PengajuanPage({super.key});

  @override
  State<PengajuanPage> createState() => _PengajuanPageState();
}

class _PengajuanPageState extends State<PengajuanPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final List<String> _jenisPengajuan = [
    'Request budget / petty cash',
    'Surat jalan',
    'Laporan panen / laporan harian',
    'FP, CS, plantation, planning',
  ];

  Future<String?> _convertFileToBase64(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final fileSize = bytes.length;

      // Hanya convert ke base64 jika ukuran file < 1MB
      // Firestore memiliki limit 1MB per document
      if (fileSize < 1024 * 1024) {
        return base64Encode(bytes);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> _savePengajuanToFirestore({
    required String jenis,
    required String keterangan,
    required String filePath,
    required String fileName,
    required int fileSize,
    String? fileBase64,
  }) async {
    try {
      await _firestore.collection('pengajuan').add({
        'jenis': jenis,
        'keterangan': keterangan,
        'filePath': filePath,
        'fileName': fileName,
        'fileSize': fileSize,
        'fileBase64': fileBase64,
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

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Upload Pengajuan'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Jenis Pengajuan',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: selectedJenis,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
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
                    const Text(
                      'Keterangan',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: keteranganController,
                      enabled: !isUploading,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Masukkan keterangan',
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Upload File',
                      style: TextStyle(fontWeight: FontWeight.bold),
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
                                            const SnackBar(
                                              content: Text(
                                                'Ukuran file maksimal 10 MB',
                                              ),
                                              backgroundColor: Colors.red,
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
                            icon: const Icon(Icons.folder_open, size: 18),
                            label: const Text(
                              'Pilih File',
                              style: TextStyle(fontSize: 12),
                            ),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 8),
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
                                            const SnackBar(
                                              content: Text(
                                                'Ukuran foto maksimal 10 MB',
                                              ),
                                              backgroundColor: Colors.red,
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
                            icon: const Icon(Icons.camera_alt, size: 18),
                            label: const Text(
                              'Kamera',
                              style: TextStyle(fontSize: 12),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (selectedFile != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                selectedFile!.path.split('/').last,
                                style: const TextStyle(fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (!isUploading)
                              IconButton(
                                icon: const Icon(Icons.close, size: 18),
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
                      const SizedBox(height: 16),
                      const Center(
                        child: Column(
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 8),
                            Text(
                              'Menyimpan...',
                              style: TextStyle(fontSize: 12),
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
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('Batal'),
                  ),
                ElevatedButton(
                  onPressed: isUploading
                      ? null
                      : () async {
                          if (selectedJenis == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Pilih jenis pengajuan terlebih dahulu',
                                ),
                                backgroundColor: Colors.orange,
                              ),
                            );
                            return;
                          }

                          if (selectedFile == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Pilih file terlebih dahulu'),
                                backgroundColor: Colors.orange,
                              ),
                            );
                            return;
                          }

                          setDialogState(() {
                            isUploading = true;
                          });

                          try {
                            final fileSize = await selectedFile!.length();
                            String? fileBase64;

                            // Convert ke base64 jika file kecil (< 1MB)
                            if (fileSize < 1024 * 1024) {
                              fileBase64 = await _convertFileToBase64(
                                selectedFile!,
                              );
                            }

                            // Simpan data ke Firestore
                            await _savePengajuanToFirestore(
                              jenis: selectedJenis!,
                              keterangan: keteranganController.text,
                              filePath: selectedFile!.path,
                              fileName: selectedFile!.path.split('/').last,
                              fileSize: fileSize,
                              fileBase64: fileBase64,
                            );

                            if (context.mounted) {
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Pengajuan berhasil disimpan'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            setDialogState(() {
                              isUploading = false;
                            });
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error: ${e.toString()}'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  child: const Text('Upload'),
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
        return Colors.orange;
      case 'Approved':
        return Colors.green;
      case 'Rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Pending':
        return Icons.pending_actions;
      case 'Approved':
        return Icons.check_circle;
      case 'Rejected':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  void _showFilePreview(BuildContext context, Map<String, dynamic> data) {
    final filePath = data['filePath'] as String?;
    final fileName = data['fileName'] as String;
    final fileBase64 = data['fileBase64'] as String?;
    final fileSize = data['fileSize'] as int;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Detail File'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nama: $fileName'),
            const SizedBox(height: 8),
            Text('Ukuran: ${_formatFileSize(fileSize)}'),
            const SizedBox(height: 8),
            if (filePath != null && File(filePath).existsSync()) ...[
              const Text('Status: File tersedia'),
              const SizedBox(height: 8),
              if (fileName.toLowerCase().endsWith('.jpg') ||
                  fileName.toLowerCase().endsWith('.jpeg') ||
                  fileName.toLowerCase().endsWith('.png'))
                Image.file(File(filePath), height: 200, fit: BoxFit.contain),
            ] else if (fileBase64 != null) ...[
              const Text('Status: File dalam database'),
              const SizedBox(height: 8),
              if (fileName.toLowerCase().endsWith('.jpg') ||
                  fileName.toLowerCase().endsWith('.jpeg') ||
                  fileName.toLowerCase().endsWith('.png'))
                Image.memory(
                  base64Decode(fileBase64),
                  height: 200,
                  fit: BoxFit.contain,
                ),
            ] else
              const Text(
                'File tidak tersedia',
                style: TextStyle(color: Colors.red),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              border: Border(bottom: BorderSide(color: Colors.green.shade200)),
            ),
            child: Column(
              children: [
                const Icon(Icons.description, size: 60, color: Colors.green),
                const SizedBox(height: 12),
                const Text(
                  'Halaman Pengajuan',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                StreamBuilder<QuerySnapshot>(
                  stream: _firestore.collection('pengajuan').snapshots(),
                  builder: (context, snapshot) {
                    int pendingCount = 0;
                    int approvedCount = 0;

                    if (snapshot.hasData) {
                      for (var doc in snapshot.data!.docs) {
                        final status = doc['status'] as String;
                        if (status == 'Pending') pendingCount++;
                        if (status == 'Approved') approvedCount++;
                      }
                    }

                    return Row(
                      children: [
                        Expanded(
                          child: Card(
                            elevation: 2,
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                children: [
                                  const Icon(
                                    Icons.pending_actions,
                                    color: Colors.orange,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$pendingCount',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Text(
                                    'Pending',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Card(
                            elevation: 2,
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                children: [
                                  const Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$approvedCount',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Text(
                                    'Approved',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
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

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.folder_open,
                          size: 80,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Belum ada pengajuan',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap tombol + untuk membuat pengajuan baru',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
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

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        leading: CircleAvatar(
                          backgroundColor: _getStatusColor(
                            status,
                          ).withOpacity(0.2),
                          child: Icon(
                            _getStatusIcon(status),
                            color: _getStatusColor(status),
                          ),
                        ),
                        title: Text(
                          jenis,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (keterangan.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(keterangan),
                            ],
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.attach_file,
                                  size: 14,
                                  color: Colors.grey.shade600,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    fileName,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            if (tanggal != null) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    size: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${tanggal.day}/${tanggal.month}/${tanggal.year} ${tanggal.hour}:${tanggal.minute.toString().padLeft(2, '0')}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.visibility, size: 20),
                              onPressed: () => _showFilePreview(context, data),
                              color: Colors.blue,
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(status).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                status,
                                style: TextStyle(
                                  color: _getStatusColor(status),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
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
      floatingActionButton: FloatingActionButton(
        onPressed: _showUploadDialog,
        backgroundColor: Colors.green,
        child: const Icon(Icons.add),
      ),
    );
  }
}
