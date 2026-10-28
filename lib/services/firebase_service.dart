// // lib/screens/home_screen.dart
// //
// // Brand colors from Rohini Xerox logo:
// //   Pink   #E91E8C  — ROHINI text, active states, CTA button
// //   Cyan   #00BCD4  — XEROX text, upload zone, color mode
// //   Dark   #1A2530  — background
// //   Navy   #111D27  — appbar / bottom nav
// //   Card   #243040  — card surfaces

// import 'package:flutter/material.dart';
// import '../services/payment_service.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:file_picker/file_picker.dart';
// import '../services/pdf_service.dart';
// import '../services/notification_service.dart';
// import 'admin_screen.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:pdfx/pdfx.dart';
// import 'auth_screen.dart';

// // ─────────────────────────────────────────────────────────────────────────────
// // BRAND TOKENS
// // ─────────────────────────────────────────────────────────────────────────────
// class _B {
//   static const Color pink = Color(0xFFE91E8C);
//   static const Color cyan = Color(0xFF00BCD4);
//   static const Color bg = Color(0xFF1A2530);
//   static const Color nav = Color(0xFF111D27);
//   static const Color card = Color(0xFF243040);
//   static const Color border = Color(0x14FFFFFF); // 8% white
//   static const Color faint = Color(0x0DFFFFFF); // 5% white
// }

// // ─────────────────────────────────────────────────────────────────────────────
// // PRICING  (edit values freely)
// // ─────────────────────────────────────────────────────────────────────────────
// class _P {
//   static const double bwA4 = 2.0;
//   static const double bwA3 = 4.0;
//   static const double colA4 = 10.0;
//   static const double colA3 = 20.0;
//   static const double dsDisc = 0.15; // 15% double-sided discount
//   static const double minAmt = 10.0;

//   static double calc({
//     required int pages,
//     required bool color,
//     required String paper,
//     required int copies,
//     required bool ds,
//   }) {
//     double ppp = color
//         ? (paper == 'A3' ? colA3 : colA4)
//         : (paper == 'A3' ? bwA3 : bwA4);
//     int ep = ds ? (pages / 2).ceil() : pages;
//     double t = ppp * ep * copies;
//     if (ds) t *= (1 - dsDisc);
//     return t < minAmt ? minAmt : t;
//   }

//   static String breakdown({
//     required int pages,
//     required bool color,
//     required String paper,
//     required int copies,
//     required bool ds,
//   }) {
//     double ppp = color
//         ? (paper == 'A3' ? colA3 : colA4)
//         : (paper == 'A3' ? bwA3 : bwA4);
//     int ep = ds ? (pages / 2).ceil() : pages;
//     return '${color ? "Color" : "B&W"} $paper  •  '
//         '${ds ? "$ep sheets" : "$pages pages"}  ×  '
//         '₹${ppp.toStringAsFixed(0)}  ×  '
//         '$copies cop${copies == 1 ? "y" : "ies"}';
//   }
// }

// // ─────────────────────────────────────────────────────────────────────────────
// // HOME SCREEN
// // ─────────────────────────────────────────────────────────────────────────────
// class HomeScreen extends StatefulWidget {
//   const HomeScreen({super.key});
//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen> {
//   int _tab = 0;
//   final _ns = NotificationService();
//   final List<Widget> _screens = const [CustomerScreen(), AdminScreen()];

//   @override
//   void initState() {
//     super.initState();
//     _ns.initialize();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: _B.bg,
//       appBar: AppBar(
//         backgroundColor: _B.nav,
//         elevation: 0,
//         title: _BrandLogo(),
//         actions: [
//           IconButton(
//             icon: const Icon(
//               Icons.notifications_outlined,
//               color: Colors.white70,
//             ),
//             onPressed: () => _notifDialog(context),
//           ),
//           IconButton(
//             icon: const Icon(Icons.person_outline, color: Colors.white70),
//             onPressed: () => _profileDialog(context),
//           ),
//         ],
//         bottom: PreferredSize(
//           preferredSize: const Size.fromHeight(0.5),
//           child: Container(height: 0.5, color: _B.border),
//         ),
//       ),
//       body: _screens[_tab],
//       bottomNavigationBar: Container(
//         decoration: BoxDecoration(
//           color: _B.nav,
//           border: Border(top: BorderSide(color: _B.border, width: 0.5)),
//         ),
//         child: BottomNavigationBar(
//           currentIndex: _tab,
//           onTap: (i) => setState(() => _tab = i),
//           backgroundColor: Colors.transparent,
//           elevation: 0,
//           selectedItemColor: _B.pink,
//           unselectedItemColor: Colors.white38,
//           selectedLabelStyle: const TextStyle(
//             fontSize: 11,
//             fontWeight: FontWeight.w600,
//           ),
//           unselectedLabelStyle: const TextStyle(fontSize: 11),
//           type: BottomNavigationBarType.fixed,
//           items: [
//             BottomNavigationBarItem(
//               label: 'Upload',
//               icon: const Icon(Icons.upload_file_outlined),
//               activeIcon: _activeNavIcon(Icons.upload_file),
//             ),
//             BottomNavigationBarItem(
//               label: 'Admin',
//               icon: const Icon(Icons.admin_panel_settings_outlined),
//               activeIcon: _activeNavIcon(Icons.admin_panel_settings),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _activeNavIcon(IconData icon) => Column(
//     mainAxisSize: MainAxisSize.min,
//     children: [
//       Container(
//         width: 4,
//         height: 4,
//         margin: const EdgeInsets.only(bottom: 4),
//         decoration: const BoxDecoration(color: _B.pink, shape: BoxShape.circle),
//       ),
//       Icon(icon, color: _B.pink),
//     ],
//   );

//   // ── Notification dialog ────────────────────────────────────────────────────
//   void _notifDialog(BuildContext ctx) {
//     showDialog(
//       context: ctx,
//       builder: (_) => _Dialog(
//         title: 'Notifications',
//         icon: Icons.notifications,
//         child: ListView.builder(
//           shrinkWrap: true,
//           itemCount: 3,
//           itemBuilder: (_, i) => Container(
//             margin: const EdgeInsets.only(bottom: 8),
//             decoration: BoxDecoration(
//               color: _B.faint,
//               borderRadius: BorderRadius.circular(10),
//             ),
//             child: ListTile(
//               leading: CircleAvatar(
//                 backgroundColor: _B.cyan.withOpacity(0.15),
//                 child: const Icon(
//                   Icons.picture_as_pdf,
//                   color: _B.cyan,
//                   size: 18,
//                 ),
//               ),
//               title: Text(
//                 'Order #${1000 + i}',
//                 style: const TextStyle(color: Colors.white, fontSize: 13),
//               ),
//               subtitle: Text(
//                 'Your PDF is ready for pickup',
//                 style: TextStyle(
//                   color: Colors.white.withOpacity(0.5),
//                   fontSize: 12,
//                 ),
//               ),
//               trailing: Text(
//                 '${i + 1}h ago',
//                 style: const TextStyle(color: Colors.white38, fontSize: 11),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   // ── Profile dialog ─────────────────────────────────────────────────────────
//   // ── Profile dialog ─────────────────────────────────────────────────────────
//   void _profileDialog(BuildContext ctx) {
//     final user = FirebaseAuth.instance.currentUser;
//     final email = user?.email ?? 'No email linked';
//     final phone = user?.phoneNumber?.isNotEmpty == true
//         ? user!.phoneNumber!
//         : (user?.displayName?.isNotEmpty == true
//               ? user!.displayName!
//               : 'Not provided');

//     showDialog(
//       context: ctx,
//       builder: (_) => _Dialog(
//         title: 'Profile',
//         icon: Icons.person,
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             // ── Avatar ──────────────────────────────────────────────
//             Container(
//               width: 72,
//               height: 72,
//               decoration: BoxDecoration(
//                 shape: BoxShape.circle,
//                 border: Border.all(color: _B.pink, width: 2),
//                 color: _B.pink.withOpacity(0.1),
//               ),
//               child: const Icon(Icons.person, size: 40, color: _B.pink),
//             ),
//             const SizedBox(height: 14),
//             const Text(
//               'Welcome to Rohini Xerox',
//               style: TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.white,
//               ),
//             ),
//             const SizedBox(height: 4),
//             const Text(
//               'KING OF XEROX · SINCE 2002',
//               style: TextStyle(
//                 fontSize: 11,
//                 color: _B.cyan,
//                 letterSpacing: 1.5,
//               ),
//             ),
//             const SizedBox(height: 16),
//             Divider(color: _B.border),
//             const SizedBox(height: 4),

//             // ── Real user data ───────────────────────────────────────
//             _profileRow(Icons.email_outlined, email),
//             _profileRow(Icons.phone_outlined, phone),

//             const SizedBox(height: 16),
//             Divider(color: _B.border),
//             const SizedBox(height: 8),

//             // ── Logout button ────────────────────────────────────────
//             SizedBox(
//               width: double.infinity,
//               child: ElevatedButton.icon(
//                 onPressed: () async {
//                   Navigator.pop(ctx); // close dialog first
//                   await FirebaseAuth.instance.signOut();
//                   if (mounted) {
//                     Navigator.pushAndRemoveUntil(
//                       context,
//                       MaterialPageRoute(builder: (_) => const AuthScreen()),
//                       (route) => false, // clear entire nav stack
//                     );
//                   }
//                 },
//                 icon: const Icon(Icons.logout_rounded, size: 17),
//                 label: const Text(
//                   'Logout',
//                   style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
//                 ),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.red[800],
//                   foregroundColor: Colors.white,
//                   padding: const EdgeInsets.symmetric(vertical: 13),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   elevation: 0,
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// Widget _profileRow(IconData icon, String text) => Padding(
//   padding: const EdgeInsets.symmetric(vertical: 6),
//   child: Row(
//     children: [
//       Icon(icon, color: _B.cyan, size: 18),
//       const SizedBox(width: 12),
//       Expanded(
//         child: Text(
//           text,
//           style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13),
//           overflow: TextOverflow.ellipsis,
//         ),
//       ),
//     ],
//   ),
// );

// // ─────────────────────────────────────────────────────────────────────────────
// // CUSTOMER SCREEN
// // ─────────────────────────────────────────────────────────────────────────────
// class CustomerScreen extends StatefulWidget {
//   const CustomerScreen({super.key});
//   @override
//   State<CustomerScreen> createState() => _CustomerScreenState();
// }

// class _CustomerScreenState extends State<CustomerScreen> {
//   // State
//   // PlatformFile? _file;
//   // int? _pages;
//   // String _paper = 'A4';
//   // bool _isColor = false;
//   // bool _doubleSide = false;
//   // int _copies = 1;
//   // final _notesCtrl = TextEditingController();
//   // bool _uploading = false;
//   // double _uploadProg = 0;

//   // @override
//   // void dispose() {
//   //   _notesCtrl.dispose();
//   //   super.dispose();
//   PlatformFile? _file;
//   int? _pages;
//   String _paper = 'A4';
//   bool _isColor = false;
//   bool _doubleSide = false;
//   int _copies = 1;
//   final _notesCtrl = TextEditingController();
//   bool _uploading = false;
//   double _uploadProg = 0;

//   // Add this line - Payment service
//   late PaymentService _paymentService;

//   @override
//   void initState() {
//     super.initState();
//     // Add this line - Initialize payment service
//     _paymentService = PaymentService();
//   }

//   @override
//   void dispose() {
//     _notesCtrl.dispose();
//     // Add this line - Dispose payment service
//     _paymentService.dispose();
//     super.dispose();
//   }

//   double? get _price => _pages == null
//       ? null
//       : _P.calc(
//           pages: _pages!,
//           color: _isColor,
//           paper: _paper,
//           copies: _copies,
//           ds: _doubleSide,
//         );

//   // ── Actions ────────────────────────────────────────────────────────────────
//   Future<void> _pickFile() async {
//     final r = await FilePicker.platform.pickFiles(
//       type: FileType.custom,
//       allowedExtensions: ['pdf'],
//       withData: true,
//     );

//     if (r != null && r.files.isNotEmpty) {
//       final f = r.files.first;
//       int pageCount = 1;

//       try {
//         // Android/iOS: openFile via path is more reliable than openData
//         // Web: falls back to bytes since there is no file path
//         final PdfDocument doc;
//         if (f.path != null) {
//           doc = await PdfDocument.openFile(f.path!);
//         } else {
//           doc = await PdfDocument.openData(f.bytes!);
//         }
//         debugPrint('✅ pdfx page count: ${doc.pagesCount}');
//         pageCount = doc.pagesCount;
//         await doc.close();
//       } catch (e) {
//         debugPrint('❌ pdfx failed, using size estimate: $e');
//         pageCount = (f.size / 75000).ceil().clamp(1, 9999);
//       }

//       setState(() {
//         _file = f;
//         _pages = pageCount;
//       });
//     }
//   }

//   // ── FIX: clear file and reset page count ──────────────────────────────────
//   void _clearFile() => setState(() {
//     _file = null;
//     _pages = null;
//   });

//   Future<void> _upload() async {
//     if (_file == null) return;
//     setState(() {
//       _uploading = true;
//       _uploadProg = 0;
//     });
//     try {
//       final orderId = await PDFService().uploadAndNotify(
//         _file!,
//         copies: _copies,
//         isColorPrint: _isColor,
//         isDoubleSided: _doubleSide,
//         paperSize: _paper,
//         notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
//         price: _price, // ← estimated price
//         pageCount: _pages, // ← actual page count from pdfx
//         onProgress: (p) => setState(() => _uploadProg = p),
//       );
//       setState(() => _uploading = false);
//       _showSuccess(orderId);
//     } catch (e) {
//       setState(() => _uploading = false);
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(
//             'Upload failed: $e',
//             style: const TextStyle(color: Colors.white),
//           ),
//           backgroundColor: Colors.red[900],
//           behavior: SnackBarBehavior.floating,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(10),
//           ),
//         ),
//       );
//     }
//   }

//   void _showSuccess(String orderId) {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (_) => Dialog(
//         backgroundColor: _B.card,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//         child: Padding(
//           padding: const EdgeInsets.all(24),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Container(
//                 width: 68,
//                 height: 68,
//                 decoration: BoxDecoration(
//                   shape: BoxShape.circle,
//                   color: Colors.green.withOpacity(0.12),
//                   border: Border.all(
//                     color: Colors.green.withOpacity(0.4),
//                     width: 1.5,
//                   ),
//                 ),
//                 child: const Icon(
//                   Icons.check_circle,
//                   color: Colors.green,
//                   size: 38,
//                 ),
//               ),
//               const SizedBox(height: 16),
//               const Text(
//                 'Order Placed!',
//                 style: TextStyle(
//                   fontSize: 20,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.white,
//                 ),
//               ),
//               const SizedBox(height: 8),
//               // ── Show the real order ID ─────────────────────────────────
//               Container(
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 14,
//                   vertical: 8,
//                 ),
//                 decoration: BoxDecoration(
//                   color: _B.cyan.withOpacity(0.08),
//                   borderRadius: BorderRadius.circular(10),
//                   border: Border.all(color: _B.cyan.withOpacity(0.25)),
//                 ),
//                 child: Row(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     const Icon(
//                       Icons.confirmation_number_outlined,
//                       color: _B.cyan,
//                       size: 15,
//                     ),
//                     const SizedBox(width: 6),
//                     Text(
//                       orderId,
//                       style: const TextStyle(
//                         color: _B.cyan,
//                         fontSize: 13,
//                         fontWeight: FontWeight.w700,
//                         letterSpacing: 0.5,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               const SizedBox(height: 10),
//               Text(
//                 'Your print job has been received.\nWe\'ll notify you when it\'s ready.',
//                 textAlign: TextAlign.center,
//                 style: TextStyle(
//                   color: Colors.white.withOpacity(0.55),
//                   fontSize: 13,
//                   height: 1.6,
//                 ),
//               ),
//               const SizedBox(height: 22),
//               SizedBox(
//                 width: double.infinity,
//                 child: ElevatedButton(
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: _B.pink,
//                     foregroundColor: Colors.white,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     padding: const EdgeInsets.symmetric(vertical: 14),
//                   ),
//                   onPressed: () {
//                     Navigator.pop(context);
//                     setState(() {
//                       _file = null;
//                       _pages = null;
//                       _copies = 1;
//                       _isColor = false;
//                       _doubleSide = false;
//                       _paper = 'A4';
//                     });
//                     _notesCtrl.clear();
//                   },
//                   child: const Text(
//                     'Done',
//                     style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   // ── Build ──────────────────────────────────────────────────────────────────
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       color: _B.bg,
//       child: SingleChildScrollView(
//         padding: const EdgeInsets.only(bottom: 36),
//         child: Column(
//           children: [
//             _hero(),
//             const SizedBox(height: 20),
//             _pad(_fileCard()),
//             const SizedBox(height: 10),
//             _pad(_optionsCard()),
//             const SizedBox(height: 10),
//             _pad(_notesCard()),
//             const SizedBox(height: 10),
//             if (_price != null) ...[_priceBanner(), const SizedBox(height: 10)],
//             _ctaBtn(),
//             const SizedBox(height: 20),
//             _pad(_recentCard()),
//             const SizedBox(height: 24),
//             _footer(),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _pad(Widget w) =>
//       Padding(padding: const EdgeInsets.symmetric(horizontal: 14), child: w);

//   // ── Hero ───────────────────────────────────────────────────────────────────
//   Widget _hero() {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
//       decoration: BoxDecoration(
//         color: _B.nav,
//         borderRadius: const BorderRadius.only(
//           bottomLeft: Radius.circular(28),
//           bottomRight: Radius.circular(28),
//         ),
//         border: Border(bottom: BorderSide(color: _B.border, width: 0.5)),
//       ),
//       child: Column(
//         children: [
//           // Logo ring
//           Container(
//             width: 88,
//             height: 88,
//             decoration: BoxDecoration(
//               shape: BoxShape.circle,
//               border: Border.all(color: _B.pink.withOpacity(0.4), width: 2),
//               color: _B.pink.withOpacity(0.07),
//             ),
//             child: Stack(
//               alignment: Alignment.center,
//               children: [
//                 Container(
//                   width: 72,
//                   height: 72,
//                   decoration: BoxDecoration(
//                     shape: BoxShape.circle,
//                     border: Border.all(
//                       color: _B.cyan.withOpacity(0.3),
//                       width: 1,
//                     ),
//                   ),
//                 ),
//                 Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Text(
//                       'ROHINI',
//                       style: TextStyle(
//                         color: _B.pink.withOpacity(0.95),
//                         fontSize: 11,
//                         fontWeight: FontWeight.w800,
//                         letterSpacing: 1,
//                       ),
//                     ),
//                     const Text(
//                       'XERO',
//                       style: TextStyle(
//                         color: _B.cyan,
//                         fontSize: 17,
//                         fontWeight: FontWeight.w800,
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//           const SizedBox(height: 14),
//           RichText(
//             text: TextSpan(
//               children: [
//                 TextSpan(
//                   text: 'ROHINI ',
//                   style: TextStyle(
//                     color: _B.pink,
//                     fontSize: 24,
//                     fontWeight: FontWeight.w800,
//                     letterSpacing: 0.5,
//                   ),
//                 ),
//                 const TextSpan(
//                   text: 'XEROX',
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontSize: 24,
//                     fontWeight: FontWeight.w800,
//                     letterSpacing: 0.5,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           const SizedBox(height: 5),
//           const Text(
//             'KING OF XEROX · SINCE 2002',
//             style: TextStyle(fontSize: 11, color: _B.cyan, letterSpacing: 2.0),
//           ),
//           const SizedBox(height: 20),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               _badge(Icons.security_outlined, 'Secure', _B.cyan),
//               const SizedBox(width: 10),
//               _badge(Icons.bolt_outlined, 'Fast', _B.pink),
//               const SizedBox(width: 10),
//               _badge(
//                 Icons.support_agent_outlined,
//                 'Support',
//                 const Color(0xFF9C27B0),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _badge(IconData icon, String label, Color c) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
//       decoration: BoxDecoration(
//         color: c.withOpacity(0.10),
//         borderRadius: BorderRadius.circular(20),
//         border: Border.all(color: c.withOpacity(0.25), width: 0.5),
//       ),
//       child: Row(
//         children: [
//           Container(
//             width: 6,
//             height: 6,
//             decoration: BoxDecoration(color: c, shape: BoxShape.circle),
//           ),
//           const SizedBox(width: 6),
//           Text(
//             label,
//             style: TextStyle(
//               color: c,
//               fontSize: 12,
//               fontWeight: FontWeight.w600,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // ── File card ──────────────────────────────────────────────────────────────
//   Widget _fileCard() {
//     return _Card(
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           _ctitle(Icons.upload_file_outlined, 'PDF File', _B.cyan),
//           const SizedBox(height: 12),
//           _file == null ? _dropZone() : _filePreview(),
//         ],
//       ),
//     );
//   }

//   Widget _dropZone() {
//     return GestureDetector(
//       onTap: _pickFile,
//       child: Container(
//         width: double.infinity,
//         padding: const EdgeInsets.symmetric(vertical: 26),
//         decoration: BoxDecoration(
//           color: _B.cyan.withOpacity(0.04),
//           borderRadius: BorderRadius.circular(12),
//           border: Border.all(color: _B.cyan.withOpacity(0.35), width: 1.5),
//         ),
//         child: Column(
//           children: [
//             Icon(
//               Icons.cloud_upload_outlined,
//               size: 40,
//               color: _B.cyan.withOpacity(0.85),
//             ),
//             const SizedBox(height: 10),
//             const Text(
//               'Tap to select PDF',
//               style: TextStyle(
//                 color: _B.cyan,
//                 fontSize: 15,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//             const SizedBox(height: 6),
//             Container(
//               padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
//               decoration: BoxDecoration(
//                 color: Colors.amber.withOpacity(0.12),
//                 borderRadius: BorderRadius.circular(20),
//               ),
//               child: const Text(
//                 'Maximum file size: 50 MB',
//                 style: TextStyle(
//                   color: Colors.amber,
//                   fontSize: 11,
//                   fontWeight: FontWeight.w500,
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _filePreview() {
//     return Container(
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: _B.pink.withOpacity(0.07),
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: _B.pink.withOpacity(0.3)),
//       ),
//       child: Row(
//         children: [
//           Container(
//             width: 44,
//             height: 44,
//             decoration: BoxDecoration(
//               color: Colors.red.withOpacity(0.14),
//               borderRadius: BorderRadius.circular(10),
//             ),
//             child: const Icon(
//               Icons.picture_as_pdf,
//               color: Colors.redAccent,
//               size: 26,
//             ),
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   _file!.name,
//                   maxLines: 1,
//                   overflow: TextOverflow.ellipsis,
//                   style: const TextStyle(
//                     color: Colors.white,
//                     fontWeight: FontWeight.w600,
//                     fontSize: 13,
//                   ),
//                 ),
//                 const SizedBox(height: 3),
//                 Text(
//                   '${_fmt(_file!.size)}${_pages != null ? "  •  $_pages pages" : ""}',
//                   style: TextStyle(
//                     color: Colors.white.withOpacity(0.45),
//                     fontSize: 12,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           IconButton(
//             icon: Icon(
//               Icons.close,
//               color: Colors.white.withOpacity(0.4),
//               size: 18,
//             ),
//             onPressed: _clearFile,
//           ),
//         ],
//       ),
//     );
//   }

//   // ── Options card ───────────────────────────────────────────────────────────
//   Widget _optionsCard() {
//     return _Card(
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           _ctitle(Icons.tune_outlined, 'Print Options', _B.pink),
//           const SizedBox(height: 16),

//           _olabel('Paper Size'),
//           const SizedBox(height: 8),
//           Row(
//             children: ['A4', 'A3'].map((s) {
//               return Expanded(
//                 child: Padding(
//                   padding: const EdgeInsets.only(right: 8),
//                   child: _Chip(
//                     label: s,
//                     selected: _paper == s,
//                     activeColor: _B.pink,
//                     onTap: () => setState(() => _paper = s),
//                   ),
//                 ),
//               );
//             }).toList(),
//           ),
//           const SizedBox(height: 16),

//           _olabel('Print Mode'),
//           const SizedBox(height: 8),
//           Row(
//             children: [
//               Expanded(
//                 child: _Chip(
//                   label: 'B & W',
//                   icon: Icons.contrast,
//                   selected: !_isColor,
//                   activeColor: _B.pink,
//                   onTap: () => setState(() => _isColor = false),
//                 ),
//               ),
//               const SizedBox(width: 8),
//               Expanded(
//                 child: _Chip(
//                   label: 'Color',
//                   icon: Icons.color_lens_outlined,
//                   selected: _isColor,
//                   activeColor: _B.cyan,
//                   onTap: () => setState(() => _isColor = true),
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 16),

//           _SwRow(
//             label: 'Double-sided',
//             subtitle: 'Save 15% on printing',
//             value: _doubleSide,
//             activeColor: _B.pink,
//             onChanged: (v) => setState(() => _doubleSide = v),
//           ),
//           Divider(color: _B.border, height: 28),

//           _olabel('Number of Copies'),
//           const SizedBox(height: 12),
//           Row(
//             children: [
//               _CBtn(
//                 icon: Icons.remove,
//                 on: _copies > 1,
//                 tap: () => setState(() => _copies--),
//               ),
//               Expanded(
//                 child: Center(
//                   child: Text(
//                     '$_copies',
//                     style: const TextStyle(
//                       fontSize: 26,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.white,
//                     ),
//                   ),
//                 ),
//               ),
//               _CBtn(
//                 icon: Icons.add,
//                 on: _copies < 99,
//                 tap: () => setState(() => _copies++),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   // ── Notes card ─────────────────────────────────────────────────────────────
//   Widget _notesCard() {
//     return _Card(
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           _ctitle(Icons.notes_outlined, 'Special Instructions', Colors.white54),
//           const SizedBox(height: 12),
//           TextField(
//             controller: _notesCtrl,
//             maxLines: 3,
//             style: const TextStyle(color: Colors.white, fontSize: 13),
//             decoration: InputDecoration(
//               hintText: 'E.g. staple, binding, urgent, print from page 3…',
//               hintStyle: TextStyle(
//                 color: Colors.white.withOpacity(0.28),
//                 fontSize: 13,
//               ),
//               filled: true,
//               fillColor: Colors.white.withOpacity(0.05),
//               contentPadding: const EdgeInsets.all(14),
//               border: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(12),
//                 borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
//               ),
//               enabledBorder: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(12),
//                 borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
//               ),
//               focusedBorder: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(12),
//                 borderSide: BorderSide(color: _B.cyan.withOpacity(0.5)),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // ── Price banner ───────────────────────────────────────────────────────────
//   Widget _priceBanner() {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 14),
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             colors: [_B.pink.withOpacity(0.22), _B.cyan.withOpacity(0.16)],
//           ),
//           borderRadius: BorderRadius.circular(16),
//           border: Border.all(color: _B.pink.withOpacity(0.35)),
//         ),
//         child: Row(
//           children: [
//             Icon(
//               Icons.receipt_long_outlined,
//               color: Colors.white.withOpacity(0.55),
//               size: 20,
//             ),
//             const SizedBox(width: 12),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     _P.breakdown(
//                       pages: _pages!,
//                       color: _isColor,
//                       paper: _paper,
//                       copies: _copies,
//                       ds: _doubleSide,
//                     ),
//                     style: TextStyle(
//                       color: Colors.white.withOpacity(0.6),
//                       fontSize: 11,
//                     ),
//                   ),
//                   const SizedBox(height: 2),
//                   Text(
//                     'Estimated Total',
//                     style: TextStyle(
//                       color: Colors.white.withOpacity(0.4),
//                       fontSize: 11,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             RichText(
//               text: TextSpan(
//                 children: [
//                   TextSpan(
//                     text: '₹',
//                     style: TextStyle(
//                       color: Colors.white.withOpacity(0.65),
//                       fontSize: 14,
//                     ),
//                   ),
//                   TextSpan(
//                     text: _price!.toStringAsFixed(2),
//                     style: const TextStyle(
//                       color: Colors.white,
//                       fontSize: 24,
//                       fontWeight: FontWeight.w800,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   // ── CTA button ─────────────────────────────────────────────────────────────
//   Widget _ctaBtn() {
//     final ready = _file != null && !_uploading;
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 14),
//       child: Column(
//         children: [
//           if (_uploading) ...[
//             ClipRRect(
//               borderRadius: BorderRadius.circular(6),
//               child: LinearProgressIndicator(
//                 value: _uploadProg > 0 ? _uploadProg : null,
//                 backgroundColor: Colors.white10,
//                 valueColor: const AlwaysStoppedAnimation(_B.pink),
//                 minHeight: 5,
//               ),
//             ),
//             const SizedBox(height: 8),
//             Text(
//               _uploadProg > 0
//                   ? 'Uploading… ${(_uploadProg * 100).toStringAsFixed(0)}%'
//                   : 'Uploading…',
//               style: TextStyle(
//                 color: Colors.white.withOpacity(0.45),
//                 fontSize: 12,
//               ),
//             ),
//             const SizedBox(height: 12),
//           ],
//           SizedBox(
//             width: double.infinity,
//             height: 54,
//             child: ElevatedButton(
//               onPressed: ready ? _upload : null,
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: _B.pink,
//                 disabledBackgroundColor: Colors.white10,
//                 foregroundColor: Colors.white,
//                 disabledForegroundColor: Colors.white30,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(14),
//                 ),
//                 elevation: ready ? 6 : 0,
//                 shadowColor: _B.pink.withOpacity(0.4),
//               ),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Icon(_uploading ? Icons.hourglass_top : Icons.send, size: 18),
//                   const SizedBox(width: 8),
//                   Text(
//                     _uploading
//                         ? 'Uploading…'
//                         : _file == null
//                         ? 'Select a PDF to continue'
//                         : _price != null
//                         ? 'Place Order  ·  ₹${_price!.toStringAsFixed(2)}'
//                         : 'Place Order',
//                     style: const TextStyle(
//                       fontSize: 15,
//                       fontWeight: FontWeight.w700,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//           if (ready && _price != null) ...[
//             const SizedBox(height: 7),
//             Text(
//               'Razorpay payment coming soon',
//               style: TextStyle(
//                 color: Colors.white.withOpacity(0.28),
//                 fontSize: 11,
//               ),
//             ),
//           ],
//         ],
//       ),
//     );
//   }

//   // ── Recent uploads card ────────────────────────────────────────────────────
//   // ── Recent uploads card ────────────────────────────────────────────────────
//   Widget _recentCard() {
//     final user = FirebaseAuth.instance.currentUser;

//     return _Card(
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           _ctitle(Icons.history, 'Recent Uploads', Colors.white54),
//           const SizedBox(height: 10),
//           StreamBuilder<QuerySnapshot>(
//             stream: FirebaseFirestore.instance
//                 .collection('orders') // ← was 'print_jobs'
//                 .where('customerId', isEqualTo: user?.uid) // ← was 'userId'
//                 .orderBy('createdAt', descending: true)
//                 .limit(5)
//                 .snapshots(),
//             builder: (context, snapshot) {
//               // ── Loading ──────────────────────────────────────────
//               if (snapshot.connectionState == ConnectionState.waiting) {
//                 return const Padding(
//                   padding: EdgeInsets.symmetric(vertical: 24),
//                   child: Center(
//                     child: CircularProgressIndicator(
//                       color: _B.cyan,
//                       strokeWidth: 2,
//                     ),
//                   ),
//                 );
//               }

//               // ── Error ────────────────────────────────────────────
//               if (snapshot.hasError) {
//                 return Padding(
//                   padding: const EdgeInsets.symmetric(vertical: 16),
//                   child: Center(
//                     child: Text(
//                       'Failed to load orders',
//                       style: TextStyle(
//                         color: Colors.white.withOpacity(0.38),
//                         fontSize: 13,
//                       ),
//                     ),
//                   ),
//                 );
//               }

//               final docs = snapshot.data?.docs ?? [];

//               // ── Empty state ──────────────────────────────────────
//               if (docs.isEmpty) {
//                 return Padding(
//                   padding: const EdgeInsets.symmetric(vertical: 24),
//                   child: Center(
//                     child: Column(
//                       children: [
//                         Icon(
//                           Icons.inbox_outlined,
//                           color: Colors.white.withOpacity(0.2),
//                           size: 40,
//                         ),
//                         const SizedBox(height: 10),
//                         Text(
//                           'No uploads yet',
//                           style: TextStyle(
//                             color: Colors.white.withOpacity(0.35),
//                             fontSize: 13,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 );
//               }

//               // ── List ─────────────────────────────────────────────
//               return ListView.separated(
//                 shrinkWrap: true,
//                 physics: const NeverScrollableScrollPhysics(),
//                 itemCount: docs.length,
//                 separatorBuilder: (_, __) =>
//                     Divider(color: _B.border, height: 14),
//                 itemBuilder: (_, i) {
//                   final data = docs[i].data() as Map<String, dynamic>;
//                   final fileName =
//                       data['fileName'] ?? data['fileUrl'] ?? 'Unknown file';
//                   final status = data['status'] ?? 'pending';
//                   final pages = data['pageCount'];
//                   final copies = data['copies'] ?? 1;
//                   final price = data['price'] ?? data['totalAmount'];
//                   final Timestamp? ts = data['createdAt'];
//                   final timeAgo = ts != null ? _timeAgo(ts.toDate()) : '';

//                   return Row(
//                     children: [
//                       // ── PDF icon ───────────────────────────────
//                       Container(
//                         width: 42,
//                         height: 42,
//                         decoration: BoxDecoration(
//                           color: Colors.red.withOpacity(0.13),
//                           borderRadius: BorderRadius.circular(10),
//                         ),
//                         child: const Icon(
//                           Icons.picture_as_pdf,
//                           color: Colors.redAccent,
//                           size: 22,
//                         ),
//                       ),
//                       const SizedBox(width: 10),

//                       // ── File info ──────────────────────────────
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               fileName,
//                               maxLines: 1,
//                               overflow: TextOverflow.ellipsis,
//                               style: const TextStyle(
//                                 color: Colors.white,
//                                 fontWeight: FontWeight.w500,
//                                 fontSize: 13,
//                               ),
//                             ),
//                             const SizedBox(height: 3),
//                             Text(
//                               [
//                                 if (pages != null) '$pages pages',
//                                 '$copies cop${copies == 1 ? "y" : "ies"}',
//                                 if (price != null)
//                                   '₹${(price as num).toStringAsFixed(2)}',
//                                 timeAgo,
//                               ].join('  •  '),
//                               style: TextStyle(
//                                 color: Colors.white.withOpacity(0.38),
//                                 fontSize: 11,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                       const SizedBox(width: 8),

//                       // ── Status badge ───────────────────────────
//                       _statusBadge(status),
//                     ],
//                   );
//                 },
//               );
//             },
//           ),
//         ],
//       ),
//     );
//   }

//   // ── Status badge ─────────────────────────────────────────────────────────────
//   Widget _statusBadge(String status) {
//     final map = {
//       'ready': (Colors.green, Icons.check_circle_outline, 'Ready'),
//       'processing': (Colors.orange, Icons.hourglass_top_outlined, 'Processing'),
//       'pending': (Colors.blue, Icons.schedule_outlined, 'Pending'),
//       'cancelled': (Colors.red, Icons.cancel_outlined, 'Cancelled'),
//     };
//     final (color, icon, label) =
//         map[status.toLowerCase()] ??
//         (Colors.white38, Icons.help_outline, status);

//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//       decoration: BoxDecoration(
//         color: color.withOpacity(0.13),
//         borderRadius: BorderRadius.circular(20),
//         border: Border.all(color: color.withOpacity(0.3), width: 0.5),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(icon, color: color, size: 11),
//           const SizedBox(width: 4),
//           Text(
//             label,
//             style: TextStyle(
//               color: color,
//               fontSize: 11,
//               fontWeight: FontWeight.w600,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // ── Time ago helper ───────────────────────────────────────────────────────────
//   String _timeAgo(DateTime dt) {
//     final diff = DateTime.now().difference(dt);
//     if (diff.inSeconds < 60) return 'just now';
//     if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
//     if (diff.inHours < 24) return '${diff.inHours}h ago';
//     if (diff.inDays < 7) return '${diff.inDays}d ago';
//     return '${(diff.inDays / 7).floor()}w ago';
//   }

//   // ── Footer ─────────────────────────────────────────────────────────────────
//   Widget _footer() {
//     return Center(
//       child: Column(
//         children: [
//           Text(
//             'ROHINI XEROX',
//             style: TextStyle(
//               color: Colors.white.withOpacity(0.18),
//               fontSize: 15,
//               fontWeight: FontWeight.w800,
//               letterSpacing: 1,
//             ),
//           ),
//           const SizedBox(height: 4),
//           Text(
//             'KING OF XEROX · SINCE 2002',
//             style: TextStyle(
//               color: Colors.white.withOpacity(0.1),
//               fontSize: 10,
//               letterSpacing: 2,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // ── Micro helpers ──────────────────────────────────────────────────────────
//   Widget _ctitle(IconData icon, String label, Color c) => Row(
//     children: [
//       Icon(icon, color: c, size: 17),
//       const SizedBox(width: 8),
//       Text(
//         label,
//         style: const TextStyle(
//           color: Colors.white,
//           fontSize: 14,
//           fontWeight: FontWeight.bold,
//         ),
//       ),
//     ],
//   );

//   Widget _olabel(String t) => Text(
//     t,
//     style: TextStyle(
//       color: Colors.white.withOpacity(0.42),
//       fontSize: 11,
//       letterSpacing: 0.5,
//     ),
//   );

//   String _fmt(int b) {
//     if (b < 1024) return '$b B';
//     if (b < 1024 * 1024) return '${(b / 1024).toStringAsFixed(1)} KB';
//     return '${(b / (1024 * 1024)).toStringAsFixed(1)} MB';
//   }
// }

// // ─────────────────────────────────────────────────────────────────────────────
// // SMALL REUSABLE WIDGETS
// // ─────────────────────────────────────────────────────────────────────────────

// class _Card extends StatelessWidget {
//   final Widget child;
//   const _Card({required this.child});
//   @override
//   Widget build(BuildContext ctx) => Container(
//     width: double.infinity,
//     padding: const EdgeInsets.all(18),
//     decoration: BoxDecoration(
//       color: _B.card,
//       borderRadius: BorderRadius.circular(16),
//       border: Border.all(color: _B.border, width: 0.5),
//     ),
//     child: child,
//   );
// }

// class _Chip extends StatelessWidget {
//   final String label;
//   final bool selected;
//   final Color activeColor;
//   final VoidCallback onTap;
//   final IconData? icon;
//   const _Chip({
//     required this.label,
//     required this.selected,
//     required this.activeColor,
//     required this.onTap,
//     this.icon,
//   });
//   @override
//   Widget build(BuildContext ctx) => GestureDetector(
//     onTap: onTap,
//     child: AnimatedContainer(
//       duration: const Duration(milliseconds: 200),
//       padding: const EdgeInsets.symmetric(vertical: 11),
//       decoration: BoxDecoration(
//         color: selected
//             ? activeColor.withOpacity(0.15)
//             : Colors.white.withOpacity(0.05),
//         borderRadius: BorderRadius.circular(10),
//         border: Border.all(
//           color: selected
//               ? activeColor.withOpacity(0.6)
//               : Colors.white.withOpacity(0.12),
//           width: selected ? 1.5 : 0.5,
//         ),
//       ),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           if (icon != null) ...[
//             Icon(
//               icon,
//               size: 14,
//               color: selected ? activeColor : Colors.white38,
//             ),
//             const SizedBox(width: 5),
//           ],
//           Text(
//             label,
//             style: TextStyle(
//               fontSize: 13,
//               fontWeight: FontWeight.w600,
//               color: selected ? activeColor : Colors.white54,
//             ),
//           ),
//         ],
//       ),
//     ),
//   );
// }

// class _SwRow extends StatelessWidget {
//   final String label, subtitle;
//   final bool value;
//   final Color activeColor;
//   final ValueChanged<bool> onChanged;
//   const _SwRow({
//     required this.label,
//     required this.subtitle,
//     required this.value,
//     required this.activeColor,
//     required this.onChanged,
//   });
//   @override
//   Widget build(BuildContext ctx) => Row(
//     children: [
//       Expanded(
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               label,
//               style: const TextStyle(
//                 color: Colors.white,
//                 fontSize: 14,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//             Text(
//               subtitle,
//               style: TextStyle(
//                 color: Colors.white.withOpacity(0.38),
//                 fontSize: 12,
//               ),
//             ),
//           ],
//         ),
//       ),
//       Switch.adaptive(
//         value: value,
//         onChanged: onChanged,
//         activeColor: activeColor,
//         activeTrackColor: activeColor.withOpacity(0.3),
//         inactiveThumbColor: Colors.white38,
//         inactiveTrackColor: Colors.white10,
//       ),
//     ],
//   );
// }

// class _CBtn extends StatelessWidget {
//   final IconData icon;
//   final bool on;
//   final VoidCallback tap;
//   const _CBtn({required this.icon, required this.on, required this.tap});
//   @override
//   Widget build(BuildContext ctx) => GestureDetector(
//     onTap: on ? tap : null,
//     child: AnimatedContainer(
//       duration: const Duration(milliseconds: 150),
//       width: 42,
//       height: 42,
//       decoration: BoxDecoration(
//         color: on ? _B.pink.withOpacity(0.12) : Colors.transparent,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(
//           color: on ? _B.pink.withOpacity(0.4) : Colors.white.withOpacity(0.08),
//           width: 0.5,
//         ),
//       ),
//       child: Icon(icon, color: on ? _B.pink : Colors.white, size: 20),
//     ),
//   );
// }

// class _BrandLogo extends StatelessWidget {
//   @override
//   Widget build(BuildContext ctx) => Column(
//     crossAxisAlignment: CrossAxisAlignment.start,
//     mainAxisSize: MainAxisSize.min,
//     children: const [
//       Text(
//         'ROHINI',
//         style: TextStyle(
//           color: _B.pink,
//           fontSize: 14,
//           fontWeight: FontWeight.w800,
//           letterSpacing: 1.5,
//           height: 1,
//         ),
//       ),
//       Text(
//         'XEROX',
//         style: TextStyle(
//           color: _B.cyan,
//           fontSize: 10,
//           fontWeight: FontWeight.w600,
//           letterSpacing: 3,
//           height: 1.3,
//         ),
//       ),
//     ],
//   );
// }

// class _Dialog extends StatelessWidget {
//   final String title;
//   final IconData icon;
//   final Widget child;
//   const _Dialog({required this.title, required this.icon, required this.child});
//   @override
//   Widget build(BuildContext ctx) => Dialog(
//     backgroundColor: _B.card,
//     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//     child: Padding(
//       padding: const EdgeInsets.all(20),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Icon(icon, color: _B.cyan, size: 20),
//               const SizedBox(width: 10),
//               Text(
//                 title,
//                 style: const TextStyle(
//                   color: Colors.white,
//                   fontSize: 16,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 16),
//           child,
//           const SizedBox(height: 10),
//           Align(
//             alignment: Alignment.centerRight,
//             child: TextButton(
//               onPressed: () => Navigator.pop(ctx),
//               style: TextButton.styleFrom(foregroundColor: _B.cyan),
//               child: const Text('Close'),
//             ),
//           ),
//         ],
//       ),
//     ),
//   );
// }
