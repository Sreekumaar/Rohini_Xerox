import 'package:flutter/material.dart';

class OrderModel {
  final String id;
  final String fileName;
  final int fileSize;
  final String downloadURL;
  final DateTime timestamp;
  String status;
  final String? customerName;
  final int? pageCount;
  final double? price;
  final String? customerPhone;
  final String? customerEmail;
  final int? copies;
  final bool? isColorPrint;
  final String? notes;
  final String? storagePath;

  // NEW fields added to support your Cloudflare SQL schema
  final bool? isDoubleSided;
  final String? paperSize;
  final String? bindingType;
  final String? deliveryAddress;
  final bool? isCourierRequired;
  final double? courierCharge;
  final String? deliveryStatus;

  OrderModel({
    required this.id,
    required this.fileName,
    required this.fileSize,
    required this.downloadURL,
    required this.timestamp,
    required this.status,
    this.customerName,
    this.pageCount,
    this.price,
    this.customerPhone,
    this.customerEmail,
    this.copies,
    this.isColorPrint,
    this.notes,
    this.storagePath,
    this.isDoubleSided,
    this.paperSize,
    this.bindingType,
    this.deliveryAddress,
    this.isCourierRequired,
    this.courierCharge,
    this.deliveryStatus,
  });

  // Replaced fromFirestore with standard fromJson
  factory OrderModel.fromJson(Map<String, dynamic> json) {
    // Cloudflare D1/SQLite sometimes returns booleans as 1 or 0 instead of true/false
    bool parseBool(dynamic value) {
      if (value == null) return false;
      if (value is bool) return value;
      if (value is int) return value == 1;
      return false;
    }

    return OrderModel(
      // Checking both snake_case (Cloudflare) and camelCase (Flutter) just to be safe
      id: json['order_id'] ?? json['id'] ?? json['orderId'] ?? '',
      fileName: json['file_name'] ?? json['fileName'] ?? 'Unknown.pdf',
      fileSize: json['file_size'] ?? json['fileSize'] ?? 0,
      downloadURL: json['download_url'] ?? json['downloadURL'] ?? '',

      // Convert standard SQL string timestamp to Dart DateTime
      timestamp: json['created_at'] != null || json['createdAt'] != null
          ? DateTime.parse(
              (json['created_at'] ?? json['createdAt']).toString(),
            ).toLocal()
          : DateTime.now(),

      status: json['status'] ?? 'pending',
      customerName: json['customer_name'] ?? json['customerName'],
      pageCount: json['page_count'] ?? json['pageCount'],
      price: (json['total_amount'] ?? json['price'])?.toDouble(),
      customerPhone: json['customer_phone'] ?? json['customerPhone'],
      customerEmail: json['customer_email'] ?? json['customerEmail'],
      copies: json['copies'],
      isColorPrint: parseBool(json['is_color_print'] ?? json['isColorPrint']),
      notes: json['notes'],
      storagePath: json['storage_path'] ?? json['storagePath'],

      isDoubleSided: parseBool(
        json['is_double_sided'] ?? json['isDoubleSided'],
      ),
      paperSize: json['paper_size'] ?? json['paperSize'],
      bindingType: json['binding_type'] ?? json['bindingType'],
      deliveryAddress: json['delivery_address'] ?? json['deliveryAddress'],
      isCourierRequired: parseBool(
        json['is_courier_required'] ?? json['isCourierRequired'],
      ),
      courierCharge: (json['courier_charge'] ?? json['courierCharge'])
          ?.toDouble(),
      deliveryStatus: json['delivery_status'] ?? json['deliveryStatus'],
    );
  }

  // Replaced toFirestore with standard toJson
  Map<String, dynamic> toJson() {
    return {
      'order_id': id,
      'file_name': fileName,
      'file_size': fileSize,
      'download_url': downloadURL,
      'created_at': timestamp.toIso8601String(),
      'status': status,
      'customer_name': customerName,
      'page_count': pageCount,
      'total_amount': price,
      'customer_phone': customerPhone,
      'customer_email': customerEmail,
      'copies': copies,
      'is_color_print': isColorPrint,
      'notes': notes,
      'storage_path': storagePath,
      'is_double_sided': isDoubleSided,
      'paper_size': paperSize,
      'binding_type': bindingType,
      'delivery_address': deliveryAddress,
      'is_courier_required': isCourierRequired,
      'courier_charge': courierCharge,
      'delivery_status': deliveryStatus,
    };
  }

  String get formattedFileSize {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Color getStatusColor() {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'processing':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'delivered':
        return Colors.teal; // Added delivered status
      default:
        return Colors.grey;
    }
  }

  IconData getStatusIcon() {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.pending;
      case 'processing':
        return Icons.print;
      case 'completed':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      case 'delivered':
        return Icons.local_shipping; // Added delivered status
      default:
        return Icons.description;
    }
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
