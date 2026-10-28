// lib/screens/admin_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/pdf_service.dart';
import 'package:url_launcher/url_launcher.dart';

// Brand colors (same as home_screen)
class _B {
  static const Color pink = Color(0xFFE91E8C);
  static const Color cyan = Color(0xFF00BCD4);
  static const Color bg = Color(0xFF1A2530);
  static const Color nav = Color(0xFF111D27);
  static const Color card = Color(0xFF243040);
  static const Color border = Color(0x14FFFFFF);
  static const Color faint = Color(0x0DFFFFFF);
}

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final PDFService _pdfService = PDFService();
  int _selectedTab = 0;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  late Future<List<Map<String, dynamic>>> _ordersFuture;

  @override
  void initState() {
    super.initState();
    _ordersFuture = _pdfService.getAllOrders();
  }
  void _refreshOrders() {
    setState(() {
      _ordersFuture = _pdfService.getAllOrders();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _B.bg,
      appBar: AppBar(
        backgroundColor: _B.nav,
        elevation: 0,
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: _refreshOrders,
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white70),
            onPressed: () => _logout(context),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(height: 0.5, color: _B.border),
        ),
      ),
      body: Column(
        children: [
          _buildStatsRow(),
          _buildSearchBar(),
          _buildStatusTabs(),
          Expanded(child: _buildOrdersList()),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Container(
      padding: const EdgeInsets.all(12),
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _ordersFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.hasError) {
            return _buildStatsSkeleton();
          }

          final orders = snapshot.data!;

          int total = orders.length;
          int pending = orders
              .where((doc) => doc['status'] == 'pending')
              .length;
          int processing = orders
              .where((doc) => doc['status'] == 'processing')
              .length;
          int completed = orders
              .where((doc) => doc['status'] == 'completed')
              .length;
          int cancelled = orders
              .where((doc) => doc['status'] == 'cancelled')
              .length;
          int courier = orders
              .where(
                (doc) =>
                    doc['is_courier_required'] == 1 ||
                    doc['is_courier_required'] == true,
              )
              .length;

          double revenue = orders
              .where((doc) => doc['status'] == 'completed')
              .fold<double>(0, (sum, doc) {
                final value = doc['total_amount'] ?? 0;
                return sum + (value is num ? value.toDouble() : 0.0);
              });

          // Use SingleChildScrollView for horizontal scrolling on small screens
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _statCard(
                  'Total',
                  total.toString(),
                  Icons.receipt_long,
                  _B.cyan,
                ),
                _statCard(
                  'Pending',
                  pending.toString(),
                  Icons.schedule,
                  Colors.orange,
                ),
                _statCard(
                  'Processing',
                  processing.toString(),
                  Icons.hourglass_top,
                  Colors.blue,
                ),
                _statCard(
                  'Completed',
                  completed.toString(),
                  Icons.check_circle,
                  Colors.green,
                ),
                _statCard(
                  'Courier',
                  courier.toString(),
                  Icons.local_shipping,
                  _B.pink,
                ),
                _statCard(
                  'Revenue',
                  '₹${revenue.toStringAsFixed(0)}',
                  Icons.currency_rupee,
                  _B.cyan,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      width: 100,
      margin: const EdgeInsets.all(4),
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: _B.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _B.border),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 9),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSkeleton() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(
          6,
          (_) => Container(
            width: 100,
            margin: const EdgeInsets.all(4),
            height: 60,
            decoration: BoxDecoration(
              color: _B.card,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: _B.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _B.border),
        ),
        child: TextField(
          controller: _searchController,
          style: const TextStyle(color: Colors.white),
          onChanged: (value) =>
              setState(() => _searchQuery = value.toLowerCase()),
          decoration: InputDecoration(
            hintText: 'Search by Order ID, Customer, or File...',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
            prefixIcon: Icon(
              Icons.search,
              color: Colors.white.withOpacity(0.5),
            ),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      Icons.clear,
                      color: Colors.white.withOpacity(0.5),
                    ),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusTabs() {
    final tabs = [
      'All',
      'Pending',
      'Processing',
      'Courier',
      'Completed',
      'Cancelled',
    ];

    return Container(
      height: 45,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: tabs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final isSelected = _selectedTab == i;
          return GestureDetector(
            onTap: () => setState(() => _selectedTab = i),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isSelected ? _B.pink : _B.card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isSelected ? _B.pink : _B.border),
              ),
              child: Center(
                child: Text(
                  tabs[i],
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white70,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOrdersList() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _ordersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: _B.cyan));
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 12),
                Text(
                  'Error loading orders: ${snapshot.error}',
                  style: TextStyle(color: Colors.white.withOpacity(0.6)),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        var docs = snapshot.data ?? [];

        // Apply Status Filter
        if (_selectedTab == 1) {
          docs = docs.where((doc) => doc['status'] == 'pending').toList();
        } else if (_selectedTab == 2) {
          docs = docs.where((doc) => doc['status'] == 'processing').toList();
        } else if (_selectedTab == 4) {
          docs = docs.where((doc) => doc['status'] == 'completed').toList();
        } else if (_selectedTab == 5) {
          docs = docs.where((doc) => doc['status'] == 'cancelled').toList();
        }

        // Filter by courier if needed
        if (_selectedTab == 3) {
          docs = docs
              .where(
                (doc) =>
                    doc['is_courier_required'] == 1 ||
                    doc['is_courier_required'] == true,
              )
              .toList();
        }

        // Apply search filter
        if (_searchQuery.isNotEmpty) {
          docs = docs.where((doc) {
            final orderId = (doc['order_id'] ?? '').toLowerCase();
            final customerName = (doc['customer_name'] ?? '').toLowerCase();
            final fileName = (doc['file_name'] ?? '').toLowerCase();
            return orderId.contains(_searchQuery) ||
                customerName.contains(_searchQuery) ||
                fileName.contains(_searchQuery);
          }).toList();
        }

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inbox_outlined,
                  color: Colors.white.withOpacity(0.2),
                  size: 64,
                ),
                const SizedBox(height: 12),
                Text(
                  'No orders found',
                  style: TextStyle(color: Colors.white.withOpacity(0.4)),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            return _OrderCard(
              orderId: doc['order_id']?.toString() ?? 'Unknown',
              fileName: doc['file_name']?.toString() ?? 'Unknown',
              customerName: doc['customer_name']?.toString() ?? 'Guest',
              customerEmail: doc['customer_email']?.toString() ?? '',
              copies: doc['copies'] as int? ?? 1,
              isColor: doc['is_color'] == 1 || doc['is_color'] == true,
              paperSize: doc['paper_size']?.toString() ?? 'A4',
              pageCount: doc['page_count'] as int?,
              price: (doc['total_amount'] as num?)?.toDouble() ?? 0.0,
              status: doc['status']?.toString() ?? 'pending',
              timestamp: doc['created_at'] != null
                  ? DateTime.tryParse(doc['created_at'].toString())
                  : null,
              downloadUrl: doc['download_url']?.toString() ?? '',
              notes: doc['notes']?.toString(),
              isDoubleSided:
                  doc['is_double_sided'] == 1 || doc['is_double_sided'] == true,
              bindingType: doc['binding_type']?.toString(),
              isCourierRequired:
                  doc['is_courier_required'] == 1 ||
                  doc['is_courier_required'] == true,
              deliveryAddress: doc['delivery_address']?.toString(),
              deliveryStatus: doc['delivery_status']?.toString(),
              courierCharge: (doc['courier_charge'] as num?)?.toDouble(),
              onStatusChanged: _refreshOrders,
            );
          },
        );
      },
    );
  }

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      Navigator.pushReplacementNamed(context, '/auth');
    }
  }
}

// Order Card Widget
class _OrderCard extends StatefulWidget {
  final String orderId;
  final String fileName;
  final String customerName;
  final String customerEmail;
  final int copies;
  final bool isColor;
  final String paperSize;
  final int? pageCount;
  final double price;
  final String status;
  final DateTime? timestamp;
  final String downloadUrl;
  final String? notes;
  final bool isDoubleSided;
  final String? bindingType;
  final bool isCourierRequired;
  final String? deliveryAddress;
  final String? deliveryStatus;
  final double? courierCharge;
  final VoidCallback onStatusChanged;

  const _OrderCard({
    required this.orderId,
    required this.fileName,
    required this.customerName,
    required this.customerEmail,
    required this.copies,
    required this.isColor,
    required this.paperSize,
    required this.pageCount,
    required this.price,
    required this.status,
    required this.timestamp,
    required this.downloadUrl,
    this.notes,
    required this.isDoubleSided,
    this.bindingType,
    required this.isCourierRequired,
    this.deliveryAddress,
    this.deliveryStatus,
    this.courierCharge,
    required this.onStatusChanged,
  });

  @override
  State<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<_OrderCard> {
  final PDFService _pdfService = PDFService();
  bool _isExpanded = false;

  final Map<String, String> _statusLabels = {
    'pending': 'Pending',
    'processing': 'Processing',
    'completed': 'Completed',
    'cancelled': 'Cancelled',
    'delivered': 'Delivered',
  };

  final Map<String, Color> _statusColors = {
    'pending': Colors.orange,
    'processing': Colors.blue,
    'completed': Colors.green,
    'cancelled': Colors.red,
    'delivered': Colors.purple,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _B.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _B.border),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: widget.isColor
                              ? _B.pink.withOpacity(0.1)
                              : _B.cyan.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.picture_as_pdf,
                          color: widget.isColor ? _B.pink : _B.cyan,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  widget.orderId,
                                  style: const TextStyle(
                                    color: _B.cyan,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _statusColors[widget.status]
                                        ?.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    _statusLabels[widget.status] ??
                                        widget.status,
                                    style: TextStyle(
                                      color: _statusColors[widget.status],
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.fileName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.person_outline,
                                  size: 12,
                                  color: Colors.white.withOpacity(0.4),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    widget.customerName,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.6),
                                      fontSize: 11,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Icon(
                                  Icons.copy,
                                  size: 12,
                                  color: Colors.white.withOpacity(0.4),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${widget.copies} cop${widget.copies == 1 ? "y" : "ies"}',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.6),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '₹${widget.price.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Icon(
                            _isExpanded ? Icons.expand_less : Icons.expand_more,
                            color: Colors.white.withOpacity(0.4),
                            size: 20,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        if (widget.status == 'pending')
                          _actionButton(
                            icon: Icons.play_arrow,
                            label: 'Process',
                            color: Colors.blue,
                            onTap: () => _updateStatus('processing'),
                          ),
                        if (widget.status == 'processing')
                          _actionButton(
                            icon: Icons.check_circle,
                            label: 'Complete',
                            color: Colors.green,
                            onTap: () => _updateStatus('completed'),
                          ),
                        if (widget.isCourierRequired &&
                            widget.status == 'completed' &&
                            widget.deliveryStatus != 'delivered')
                          _actionButton(
                            icon: Icons.local_shipping,
                            label: widget.deliveryStatus == 'out_for_delivery'
                                ? 'Mark Delivered'
                                : 'Out for Delivery',
                            color: Colors.purple,
                            onTap: () => _updateDeliveryStatus(),
                          ),
                        _actionButton(
                          icon: Icons.visibility,
                          label: 'View',
                          color: _B.cyan,
                          onTap: _viewPdf,
                        ),
                        if (widget.status == 'pending')
                          _actionButton(
                            icon: Icons.cancel,
                            label: 'Cancel',
                            color: Colors.red,
                            onTap: () => _confirmCancel(),
                          ),
                        _actionButton(
                          icon: Icons.delete,
                          label: 'Delete',
                          color: Colors.red,
                          onTap: () => _confirmDelete(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _detailRow('Customer Email', widget.customerEmail),
                  _detailRow('Paper Size', widget.paperSize),
                  _detailRow('Print Mode', widget.isColor ? 'Color' : 'B&W'),
                  _detailRow(
                    'Double-sided',
                    widget.isDoubleSided ? 'Yes' : 'No',
                  ),
                  if (widget.bindingType != null &&
                      widget.bindingType != 'none')
                    _detailRow(
                      'Binding',
                      widget.bindingType == 'spiral'
                          ? 'Spiral (₹25)'
                          : 'Tape (₹15)',
                    ),
                  if (widget.isCourierRequired) ...[
                    _detailRow(
                      'Courier Charge',
                      '₹${widget.courierCharge?.toStringAsFixed(2) ?? "0"}',
                    ),
                    _detailRow(
                      'Delivery Status',
                      widget.deliveryStatus?.toUpperCase() ?? 'Pending',
                    ),
                    _detailRow(
                      'Delivery Address',
                      widget.deliveryAddress ?? 'N/A',
                    ),
                  ],
                  if (widget.notes != null && widget.notes!.isNotEmpty)
                    _detailRow('Notes', widget.notes!),
                  _detailRow('Order Time', _formatDate(widget.timestamp)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateStatus(String newStatus) async {
    try {
      await _pdfService.updateOrderStatus(widget.orderId, newStatus);
      widget.onStatusChanged();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order ${widget.orderId} marked as $newStatus'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
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

  Future<void> _updateDeliveryStatus() async {
    String newStatus;
    if (widget.deliveryStatus == 'out_for_delivery') {
      newStatus = 'delivered';
    } else {
      newStatus = 'out_for_delivery';
    }

    try {
      await _pdfService.updateDeliveryStatus(widget.orderId, newStatus);

      if (newStatus == 'delivered') {
        await _pdfService.updateOrderStatus(widget.orderId, 'delivered');
      }

      widget.onStatusChanged();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Delivery status updated to $newStatus'),
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
Future<void> _viewPdf() async {
  if (widget.downloadUrl.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('No download URL available'),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  final uri = Uri.parse(widget.downloadUrl);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } else {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open PDF'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
  void _confirmCancel() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _B.card,
        title: const Text(
          'Cancel Order',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to cancel order ${widget.orderId}?',
          style: TextStyle(color: Colors.white.withOpacity(0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('No', style: TextStyle(color: _B.cyan)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _updateStatus('cancelled');
            },
            child: const Text(
              'Yes, Cancel',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _B.card,
        title: const Text(
          'Delete Order',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Permanently delete order ${widget.orderId}? This action cannot be undone.',
          style: TextStyle(color: Colors.white.withOpacity(0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: _B.cyan)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _pdfService.deleteOrder(widget.orderId);
                widget.onStatusChanged();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Order deleted'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown';
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
