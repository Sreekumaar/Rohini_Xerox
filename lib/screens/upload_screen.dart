import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/pdf_service.dart';
import '../widgets/logo_widget.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  final PDFService _pdfService = PDFService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String? _selectedFileName;
  int? _selectedFileSize;
  PlatformFile? _selectedFile;
  bool _homeDelivery = false;
  final _addressController = TextEditingController();

  // Print options
  int _copies = 1;
  bool _isColorPrint = false;
  bool _isDoubleSided = false;
  String? _selectedPaperSize = 'A4';
  final TextEditingController _notesController = TextEditingController();

  final List<String> _paperSizes = ['A4', 'A3', 'Letter', 'Legal'];

  @override
  void dispose() {
    _notesController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
      );

      if (result != null) {
        setState(() {
          _selectedFile = result.files.single;
          _selectedFileName = result.files.single.name;
          _selectedFileSize = result.files.single.size;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('File selected: ${result.files.single.name}'),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking file: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _uploadFile() async {
    if (_selectedFileName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a PDF file first'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
      _selectedFile = null;
      _homeDelivery = false;
      _addressController.clear();
    });

    try {
      if (_homeDelivery && _addressController.text.trim().isEmpty) {
        throw StateError('Enter a delivery address.');
      }
      final selectedFile = _selectedFile;
      if (selectedFile == null) throw StateError('Select a PDF first.');
      {
        final user = _auth.currentUser;

        await _pdfService.uploadAndNotify(
          selectedFile,
          copies: _copies,
          isColorPrint: _isColorPrint,
          isDoubleSided: _isDoubleSided,
          paperSize: _selectedPaperSize,
          notes: _notesController.text,
          customerName: user?.displayName,
          customerEmail: user?.email,
          customerId: user?.uid,
          deliveryAddress: _homeDelivery ? _addressController.text.trim() : null,
        );

        // Show success dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 30),
                SizedBox(width: 10),
                Text('Success!'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('File: $_selectedFileName'),
                const SizedBox(height: 10),
                Text('Size: ${_formatFileSize(_selectedFileSize!)}'),
                const SizedBox(height: 10),
                Text('Copies: $_copies'),
                Text('Print Type: ${_isColorPrint ? "Color" : "B&W"}'),
                Text('Paper Size: $_selectedPaperSize'),
                Text('Double Sided: ${_isDoubleSided ? "Yes" : "No"}'),
                if (_notesController.text.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text('Notes: ${_notesController.text}'),
                ],
                const SizedBox(height: 20),
                const Text(
                  'Your order has been sent to Rohini Xero.\nYou will be notified when it\'s ready.',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _resetForm();
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 10),
                Expanded(child: Text('File uploaded successfully!')),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error uploading file: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  void _resetForm() {
    setState(() {
      _selectedFileName = null;
      _selectedFileSize = null;
      _copies = 1;
      _isColorPrint = false;
      _isDoubleSided = false;
      _selectedPaperSize = 'A4';
      _notesController.clear();
      _uploadProgress = 0.0;
      _selectedFile = null;
      _homeDelivery = false;
      _addressController.clear();
    });
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Scaffold(
      appBar: AppBar(title: const LogoWidget(), elevation: 0),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [const Color(0xFF0D47A1), Colors.blue.shade800],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.cloud_upload, color: Colors.white, size: 30),
                      SizedBox(width: 10),
                      Text(
                        'Upload Document',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    user != null
                        ? 'Welcome, ${user.displayName ?? "Customer"}'
                        : 'Please login to upload',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Main Upload Card
            Padding(
              padding: const EdgeInsets.all(20),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // File Selection Area
                      InkWell(
                        onTap: _isUploading ? null : _pickFile,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 30),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.blue.shade200,
                              width: 2,
                              style: BorderStyle.solid,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.picture_as_pdf,
                                size: 60,
                                color: _selectedFileName == null
                                    ? Colors.blue.shade400
                                    : Colors.green,
                              ),
                              const SizedBox(height: 12),
                              if (_selectedFileName == null) ...[
                                const Text(
                                  'Tap to select PDF file',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF0D47A1),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Maximum file size: 50MB',
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                              ] else ...[
                                Text(
                                  _selectedFileName!,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.green,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatFileSize(_selectedFileSize!),
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text(
                                    '✓ File Selected',
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      const Text('Fulfilment', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Home delivery'),
                        subtitle: const Text('Delivery charges are confirmed by the shop.'),
                        value: _homeDelivery,
                        onChanged: _isUploading ? null : (v) => setState(() => _homeDelivery = v),
                      ),
                      if (_homeDelivery)
                        TextField(
                          controller: _addressController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Full delivery address',
                            hintText: 'House number, street, area, city, PIN code',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      const SizedBox(height: 20),
                      // Print Options
                      const Text(
                        'Print Options',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Copies
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.content_copy,
                              color: Color(0xFF0D47A1),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Number of Copies:',
                              style: TextStyle(fontSize: 16),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed: _copies > 1
                                  ? () => setState(() => _copies--)
                                  : null,
                            ),
                            Container(
                              width: 40,
                              alignment: Alignment.center,
                              child: Text(
                                '$_copies',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline),
                              onPressed: () => setState(() => _copies++),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Color/B&W Selection
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.color_lens,
                              color: Color(0xFF0D47A1),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Print Type:',
                              style: TextStyle(fontSize: 16),
                            ),
                            const Spacer(),
                            ChoiceChip(
                              label: const Text('B&W'),
                              selected: !_isColorPrint,
                              onSelected: (_) =>
                                  setState(() => _isColorPrint = false),
                              selectedColor: Colors.blue.shade100,
                              backgroundColor: Colors.grey.shade200,
                            ),
                            const SizedBox(width: 8),
                            ChoiceChip(
                              label: const Text('Color'),
                              selected: _isColorPrint,
                              onSelected: (_) =>
                                  setState(() => _isColorPrint = true),
                              selectedColor: Colors.blue.shade100,
                              backgroundColor: Colors.grey.shade200,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Double Sided
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.sync_alt,
                              color: Color(0xFF0D47A1),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Double Sided:',
                              style: TextStyle(fontSize: 16),
                            ),
                            const Spacer(),
                            Switch(
                              value: _isDoubleSided,
                              onChanged: (value) =>
                                  setState(() => _isDoubleSided = value),
                              activeThumbColor: const Color(0xFF0D47A1),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Paper Size
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.screenshot,
                              color: Color(0xFF0D47A1),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Paper Size:',
                              style: TextStyle(fontSize: 16),
                            ),
                            const Spacer(),
                            DropdownButton<String>(
                              value: _selectedPaperSize,
                              items: _paperSizes.map((String size) {
                                return DropdownMenuItem<String>(
                                  value: size,
                                  child: Text(size),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                setState(() {
                                  _selectedPaperSize = newValue;
                                });
                              },
                              underline: Container(),
                              icon: const Icon(Icons.arrow_drop_down),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Notes
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.note, color: Color(0xFF0D47A1)),
                                SizedBox(width: 12),
                                Text(
                                  'Additional Notes:',
                                  style: TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _notesController,
                              decoration: InputDecoration(
                                hintText: 'Enter any special instructions...',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.all(12),
                              ),
                              maxLines: 3,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Price Estimate
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Estimated Price:',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '₹${_calculatePrice()}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0D47A1),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Upload Progress
                      if (_isUploading) ...[
                        LinearProgressIndicator(
                          value: _uploadProgress,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF0D47A1),
                          ),
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Uploading: ${(_uploadProgress * 100).toStringAsFixed(0)}%',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Upload Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isUploading ? null : _uploadFile,
                          icon: _isUploading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Icon(Icons.cloud_upload),
                          label: Text(
                            _isUploading
                                ? 'UPLOADING...'
                                : 'UPLOAD & SEND TO XEROX',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0D47A1),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),

                      if (_selectedFileName != null) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: TextButton.icon(
                            onPressed: _isUploading ? null : _resetForm,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Clear Selection'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            // Instructions Card
            Padding(
              padding: const EdgeInsets.all(20),
              child: Card(
                color: Colors.blue.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.info, color: Color(0xFF0D47A1)),
                          SizedBox(width: 8),
                          Text(
                            'Instructions',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0D47A1),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildInstructionItem(
                        icon: Icons.check_circle,
                        text: 'Maximum file size: 50MB',
                      ),
                      _buildInstructionItem(
                        icon: Icons.check_circle,
                        text: 'Supported format: PDF only',
                      ),
                      _buildInstructionItem(
                        icon: Icons.check_circle,
                        text:
                            'You will receive notification when order is ready',
                      ),
                      _buildInstructionItem(
                        icon: Icons.check_circle,
                        text: 'Collect your print at Rohini Xero shop',
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: const Text(
                          'Note: Please ensure your PDF is properly formatted before uploading.',
                          style: TextStyle(color: Colors.orange, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionItem({required IconData icon, required String text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.green),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  String _calculatePrice() {
    // Assuming 100 pages for estimation
    const estimatedPages = 100;
    final ratePerPage = _isColorPrint ? 3.0 : 1.0;
    final total = estimatedPages * ratePerPage * _copies;
    return total.toStringAsFixed(0);
  }
}
