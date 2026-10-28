import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'notification_service.dart';

class PDFService {
  // 🔧 Use this for local testing with `npx wrangler dev` (replace with your PC's local IP)
  // final String _apiUrl = 'http://192.168.X.X:8787';

  // 🚀 Use this for production
  final String _apiUrl = 'https://rohini-api.rohinixerox.workers.dev';

  // ─────────────────────────────────────────────────────────────────────────
  // ORDER ID GENERATOR
  // Format:  RX-YYYYMMDD-XXXX   e.g.  RX-20250615-0042
  // RX = Rohini Xerox prefix
  // YYYYMMDD = date
  // XXXX = daily auto-incrementing 4-digit counter (resets each day)
  // ─────────────────────────────────────────────────────────────────────────
  Future<String> _generateOrderId() async {
    final now = DateTime.now();
    final dateStr =
        '${now.year}'
        '${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}';
    // Generate random sequence to avoid counter DB locks for now
    final seqStr = (now.millisecondsSinceEpoch % 10000).toString().padLeft(
      4,
      '0',
    );
    return 'RX-$dateStr-$seqStr';
  }

  // ─────────────────────────────────────────────────────────────────────────
  // UPLOAD & NOTIFY
  // ─────────────────────────────────────────────────────────────────────────
  Future<String> uploadAndNotify(
    PlatformFile file, {
    int? copies,
    bool? isColorPrint,
    bool? isDoubleSided,
    String? paperSize,
    String? notes,
    String? customerName,
    String? customerEmail,
    String? customerId,
    double? price,
    int? pageCount,
    void Function(double progress)? onProgress,
    // NEW PARAMETERS FOR BINDING AND DELIVERY
    String? bindingType,
    String? deliveryAddress,
    double? courierCharge,
  }) async {
    try {
      debugPrint('▶ Starting upload: ${file.name}');

      // 1. Generate human-readable order ID
      final orderId = await _generateOrderId();
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final fileName = '${orderId}_$timestamp.pdf';
      final storagePath = 'pdf_uploads/$fileName';

      debugPrint('📋 Order ID: $orderId');

      // Simulate start progress
      onProgress?.call(0.1);

      // 2. Upload to Cloudflare Worker R2 Proxy
      var request = http.MultipartRequest('POST', Uri.parse('$_apiUrl/upload'));
      request.fields['fileName'] = fileName;

      if (file.bytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            file.bytes!,
            filename: file.name,
          ),
        );
      } else if (file.path != null) {
        request.files.add(
          await http.MultipartFile.fromPath('file', file.path!),
        );
      } else {
        throw Exception('No file data available');
      }

      onProgress?.call(0.4);
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode != 200) {
        throw Exception(
          'Upload failed: ${response.statusCode} ${response.body}',
        );
      }

      onProgress?.call(0.8);

      String downloadURL;
      try {
        final resData = jsonDecode(response.body);
        downloadURL = resData['downloadURL'];
      } catch (e) {
        throw Exception(
          'Server returned invalid response. Did you deploy the Cloudflare Worker? Response: ${response.body}',
        );
      }

      debugPrint('✅ Upload complete. URL: $downloadURL');

      // 4. Save order to Cloudflare D1 via API
      final orderData = {
        // Identifiers
        'orderId': orderId,
        'customerName': customerName,
        'customerEmail': customerEmail,

        // File info
        'fileName': file.name,
        'downloadURL': downloadURL,
        'pageCount': pageCount,

        // Print options
        'copies': copies ?? 1,
        'isColorPrint': isColorPrint ?? false,
        'isDoubleSided': isDoubleSided ?? false,
        'paperSize': paperSize ?? 'A4',
        'notes': notes,

        // Binding options (NEW)
        'bindingType': bindingType,

        // Delivery options (NEW)
        'deliveryAddress': deliveryAddress,
        'isCourierRequired': deliveryAddress != null,
        'courierCharge': courierCharge ?? 0,
        'deliveryStatus': deliveryAddress != null ? 'pending_delivery' : null,

        // Pricing
        'totalAmount': price,

        // Status & timestamps
        'status':
            'pending', // pending → processing → completed → delivered (if courier)
      };

      final saveResponse = await http.post(
        Uri.parse('$_apiUrl/orders'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(orderData),
      );

      if (saveResponse.statusCode < 200 || saveResponse.statusCode >= 300) {
        throw Exception('Document uploaded but order creation failed: ${saveResponse.statusCode}. Contact support with order ID $orderId.');
      }
      debugPrint('💾 Order saved: $orderId');

      onProgress?.call(1.0);

      // 5. Build notification message with additional details
      String notificationBody =
          '${file.name}  •  ${copies ?? 1} cop${(copies ?? 1) == 1 ? "y" : "ies"}  •  ${isColorPrint == true ? "Color" : "B&W"}  •  ${paperSize ?? "A4"}';

      if (pageCount != null) {
        notificationBody += '  •  $pageCount pages';
      }

      if (bindingType != null && bindingType != 'none') {
        notificationBody +=
            '  •  ${bindingType == 'spiral' ? "Spiral Binding" : "Tape Binding"}';
      }

      if (deliveryAddress != null) {
        notificationBody += '  •  🚚 Courier Required';
      }

      // 6. Notify admin
      await NotificationService().sendNotificationToAdmin({
        'title': '📄 New Order: $orderId',
        'body': notificationBody,
        'fileName': file.name,
        'downloadURL': downloadURL,
        'orderId': orderId,
        'price': price?.toStringAsFixed(2),
        'pageCount': pageCount?.toString(),
        'bindingType': bindingType,
        'deliveryAddress': deliveryAddress,
        'courierCharge': courierCharge?.toStringAsFixed(2),
      });

      return orderId;
    } catch (e, st) {
      debugPrint('❌ Upload error: $e\n$st');
      rethrow;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // UPDATE ORDER STATUS (Extended with delivery status)
  // Valid statuses: pending | processing | completed | cancelled | delivered
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> updateOrderStatus(String orderId, String status) async {
    try {
      await http.put(
        Uri.parse('$_apiUrl/orders/$orderId/status'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'status': status}),
      );
      debugPrint('✏ Order $orderId → $status');
    } catch (e) {
      debugPrint('❌ updateOrderStatus: $e');
      rethrow;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // UPDATE DELIVERY STATUS (for courier orders)
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> updateDeliveryStatus(
    String orderId,
    String deliveryStatus,
  ) async {
    try {
      await http.put(
        Uri.parse('$_apiUrl/orders/$orderId/status'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'deliveryStatus': deliveryStatus}),
      );
      debugPrint('🚚 Order $orderId delivery status → $deliveryStatus');
    } catch (e) {
      debugPrint('❌ updateDeliveryStatus: $e');
      rethrow;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ADD ADMIN NOTES
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> addAdminNotes(String orderId, String notes) async {
    try {
      // TODO: Update Cloudflare D1 schema and Worker API to support 'adminNotes'
      // await http.put(Uri.parse('$_apiUrl/orders/$orderId/notes'), ...);
      debugPrint(
        '📝 Admin notes added to $orderId (Not saved to Cloudflare yet)',
      );
    } catch (e) {
      debugPrint('❌ addAdminNotes: $e');
      rethrow;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ASSIGN PRINTER
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> assignPrinter(String orderId, String printedBy) async {
    try {
      // TODO: Update Cloudflare D1 schema and Worker API to support 'printedBy'
      // await http.put(Uri.parse('$_apiUrl/orders/$orderId/printer'), ...);
      debugPrint(
        '📝 Printer $printedBy assigned to $orderId (Not saved to Cloudflare yet)',
      );
    } catch (e) {
      debugPrint('❌ assignPrinter: $e');
      rethrow;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // DELETE ORDER
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> deleteOrder(String orderId, {bool deleteFile = true}) async {
    try {
      await http.delete(Uri.parse('$_apiUrl/orders/$orderId'));
      debugPrint('🗑 Order $orderId deleted');
    } catch (e) {
      debugPrint('❌ deleteOrder: $e');
      rethrow;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // STREAMS
  // ─────────────────────────────────────────────────────────────────────────

  // Fetch all orders from Cloudflare Worker
Future<List<Map<String, dynamic>>> getAllOrders() async {
  try {
    final res = await http.get(Uri.parse('$_apiUrl/orders'));
    debugPrint('📦 Status: ${res.statusCode}');
    debugPrint('📦 Body: ${res.body}');
    if (res.statusCode == 200) {
      final List<dynamic> data = jsonDecode(res.body);
      debugPrint('📦 Orders count: ${data.length}');
      return List<Map<String, dynamic>>.from(data);
    }
  } catch (e) {
    debugPrint('❌ getAllOrders: $e');
  }
  return [];
}
  // ─────────────────────────────────────────────────────────────────────────
  // STATS  (used by admin dashboard)
  // ─────────────────────────────────────────────────────────────────────────

  Future<int> getTodayOrdersCount() async {
    final orders = await getAllOrders();
    return orders.where((o) => _isToday(o['created_at'].toString())).length;
  }

  Future<int> getPendingOrdersCount() async {
    final orders = await getAllOrders();
    return orders.where((o) => o['status'] == 'pending').length;
  }

  Future<int> getPendingDeliveriesCount() async {
    final orders = await getAllOrders();
    return orders
        .where(
          (o) =>
              (o['is_courier_required'] == 1 ||
                  o['is_courier_required'] == true) &&
              o['delivery_status'] == 'pending_delivery',
        )
        .length;
  }

  Future<double> getTodayRevenue() async {
    final orders = await getAllOrders();
    return orders
        .where(
          (o) =>
              o['status'] == 'completed' &&
              _isToday(o['created_at'].toString()),
        )
        .fold<double>(
          0.0,
          (sum, o) => sum + ((o['total_amount'] as num?)?.toDouble() ?? 0.0),
        );
  }

  Future<int> getTotalOrdersCount() async {
    final orders = await getAllOrders();
    return orders.length;
  }

  /// Returns a map of { 'pending': n, 'processing': n, 'completed': n, 'cancelled': n, 'delivered': n }
  Future<Map<String, int>> getOrderStatusCounts() async {
    final orders = await getAllOrders();
    final statuses = [
      'pending',
      'processing',
      'completed',
      'cancelled',
      'delivered',
    ];
    final Map<String, int> result = {};
    for (final s in statuses) {
      result[s] = orders.where((o) => o['status'] == s).length;
    }
    return result;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────────────────────────────────

  bool _isToday(String? dateStr) {
    if (dateStr == null) return false;
    final d = DateTime.tryParse(dateStr);
    if (d == null) return false;
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  String _fmtSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
