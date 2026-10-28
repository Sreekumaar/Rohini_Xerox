import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

/// An isolated, non-production workflow preview. Nothing is uploaded or charged.
class DemoOrder {
  DemoOrder(this.id, this.file, this.pages, this.copies, this.color,
      this.delivery, this.address, this.total);
  final String id, file, address;
  final int pages, copies;
  final bool color, delivery;
  final double total;
  String status = 'Received';
  String payment = 'Not paid — demo';
}

class DemoStoreScreen extends StatefulWidget {
  const DemoStoreScreen({super.key});
  @override
  State<DemoStoreScreen> createState() => _DemoStoreScreenState();
}

class _DemoStoreScreenState extends State<DemoStoreScreen> {
  int tab = 0;
  final orders = <DemoOrder>[];
  final name = TextEditingController();
  final phone = TextEditingController();
  final address = TextEditingController();
  final pages = TextEditingController(text: '1');
  int copies = 1;
  bool color = false, delivery = false;
  String? file;
  final statuses = ['Received', 'Printing', 'Ready for pickup', 'Out for delivery', 'Delivered', 'Completed', 'Cancelled'];
  double get total => ((int.tryParse(pages.text) ?? 0) * copies * (color ? 10 : 2) + (delivery ? 60 : 0)).toDouble();

  @override
  void dispose() {
    for (final c in [name, phone, address, pages]) { c.dispose(); }
    super.dispose();
  }

  void notice(String message) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));

  Future<void> pickPdf() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    if (result != null && result.files.isNotEmpty) setState(() => file = result.files.single.name);
  }

  void placeOrder() {
    final count = int.tryParse(pages.text);
    if (file == null || name.text.trim().isEmpty || phone.text.trim().length < 10 || count == null || count < 1 || count > 2000 || (delivery && address.text.trim().isEmpty)) {
      notice('Select a PDF and enter valid customer, page and delivery details.');
      return;
    }
    setState(() {
      orders.insert(0, DemoOrder('RX-${(DateTime.now().microsecondsSinceEpoch % 100000000).toString().padLeft(8, '0')}', file!, count, copies, color, delivery, address.text.trim(), total));
      tab = 1;
    });
    notice('Demo order created. No upload or payment occurred.');
  }

  Widget field(String label, TextEditingController controller, {TextInputType? keyboard, int lines = 1}) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextField(controller: controller, keyboardType: keyboard, maxLines: lines,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder())),
  );

  Widget orderCard(DemoOrder o, {bool admin = false}) => Card(
    child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(o.id, style: const TextStyle(fontWeight: FontWeight.bold)),
      const SizedBox(height: 6),
      Text(o.file, maxLines: 2, overflow: TextOverflow.ellipsis),
      Text('${o.pages} pages × ${o.copies} copies • ${o.color ? 'Colour' : 'B&W'}'),
      Text(o.delivery ? 'Home delivery: ${o.address}' : 'Shop pickup'),
      Text('₹${o.total.toStringAsFixed(2)} • ${o.payment}'),
      const SizedBox(height: 8),
      admin ? DropdownButtonFormField<String>(initialValue: o.status,
        decoration: const InputDecoration(labelText: 'Order status', border: OutlineInputBorder()),
        items: statuses.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
        onChanged: (s) { if (s != null) setState(() => o.status = s); })
        : Chip(label: Text(o.status)),
    ])),
  );

  Widget customer() => ListView(padding: const EdgeInsets.all(16), children: [
    const Text('Create a print order', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
    const SizedBox(height: 8),
    const Text('Preview mode: documents stay on your device; prices are illustrative.'),
    const SizedBox(height: 20),
    field('Customer name', name),
    field('Mobile number', phone, keyboard: TextInputType.phone),
    OutlinedButton.icon(onPressed: pickPdf, icon: const Icon(Icons.picture_as_pdf), label: Text(file ?? 'Choose PDF')),
    const SizedBox(height: 12),
    field('Number of PDF pages', pages, keyboard: TextInputType.number),
    Row(children: [const Expanded(child: Text('Copies')), IconButton(onPressed: copies > 1 ? () => setState(() => copies--) : null, icon: const Icon(Icons.remove_circle_outline)), Text('$copies'), IconButton(onPressed: copies < 100 ? () => setState(() => copies++) : null, icon: const Icon(Icons.add_circle_outline))]),
    SwitchListTile(title: const Text('Colour printing'), subtitle: const Text('B&W ₹2/page • Colour ₹10/page (demo)'), value: color, onChanged: (v) => setState(() => color = v)),
    SwitchListTile(title: const Text('Home delivery'), subtitle: const Text('Illustrative delivery charge ₹60'), value: delivery, onChanged: (v) => setState(() => delivery = v)),
    if (delivery) field('Full delivery address', address, lines: 3),
    const Divider(),
    Text('Estimated total: ₹${total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
    const SizedBox(height: 10),
    FilledButton.icon(onPressed: placeOrder, icon: const Icon(Icons.shopping_bag_outlined), label: const Text('Place demo order')),
    const SizedBox(height: 12),
    const Text('Online payment is disabled until the live backend and Razorpay verification are connected.', style: TextStyle(color: Colors.deepOrange)),
  ]);

  Widget listOrders({bool admin = false}) => orders.isEmpty
    ? const Center(child: Text('No demo orders yet. Create an order first.'))
    : ListView(padding: const EdgeInsets.all(12), children: [
        if (admin) Padding(padding: const EdgeInsets.all(8), child: Text('Orders: ${orders.length} • Value: ₹${orders.fold<double>(0, (sum, o) => sum + o.total).toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
        ...orders.map((o) => orderCard(o, admin: admin)),
      ]);

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('ROHINI XEROX'), backgroundColor: const Color(0xFF142A4D), foregroundColor: Colors.white,
      actions: const [Center(child: Padding(padding: EdgeInsets.only(right: 16), child: Text('DEMO', style: TextStyle(fontWeight: FontWeight.bold))))]),
    body: IndexedStack(index: tab, children: [customer(), listOrders(), listOrders(admin: true)]),
    bottomNavigationBar: NavigationBar(selectedIndex: tab, onDestinationSelected: (v) => setState(() => tab = v), destinations: const [
      NavigationDestination(icon: Icon(Icons.upload_file), label: 'Print'),
      NavigationDestination(icon: Icon(Icons.receipt_long), label: 'My orders'),
      NavigationDestination(icon: Icon(Icons.admin_panel_settings), label: 'Admin preview'),
    ]),
  );
}
