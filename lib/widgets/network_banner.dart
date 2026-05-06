import 'package:easy_localization/easy_localization.dart';
// import 'dart:async';
// import 'package:connectivity_plus/connectivity_plus.dart';
// import 'package:flutter/material.dart';

// /// A widget that monitors actual internet connectivity (not just network
// /// connection type) and shows an animated banner above the nav bar when offline.
// class NetworkBanner extends StatefulWidget {
//   const NetworkBanner({Key? key}) : super(key: key);

//   @override
//   State<NetworkBanner> createState() => _NetworkBannerState();
// }

// class _NetworkBannerState extends State<NetworkBanner>
//     with SingleTickerProviderStateMixin {
//   late StreamSubscription<List<ConnectivityResult>> _subscription;
//   bool _isOffline = false;
//   late AnimationController _controller;
//   late Animation<Offset> _slide;

//   @override
//   void initState() {
//     super.initState();

//     _controller = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 350),
//     );
//     _slide = Tween<Offset>(
//       begin: const Offset(0, 1.5),
//       end: Offset.zero,
//     ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

//     _subscription = Connectivity().onConnectivityChanged.listen(
//       _updateConnectionState,
//     );

//     // Check immediately on startup
//     Connectivity().checkConnectivity().then(_updateConnectionState);
//   }

//   void _updateConnectionState(List<ConnectivityResult> results) {
//     if (!mounted) return;
    
//     // Consider offline only if 'none' is the reported result.
//     // If the device has any active connection, this will normally not contain 'none'.
//     final bool offline = results.isEmpty || (results.length == 1 && results.contains(ConnectivityResult.none));

//     if (offline == _isOffline) return;

//     setState(() {
//       _isOffline = offline;
//     });

//     if (offline) {
//       _controller.forward();
//     } else {
//       _controller.reverse();
//     }
//   }

//   @override
//   void dispose() {
//     _subscription.cancel();
//     _controller.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Positioned(
//       // sits just above the GlassBottomNavBar (which is at bottom: 24 + 68h)
//       bottom: 102,
//       left: 16,
//       right: 16,
//       child: SlideTransition(
//         position: _slide,
//         child: Material(
//           color: Colors.transparent,
//           child: Container(
//             padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
//             decoration: BoxDecoration(
//               color: const Color(0xFFB71C1C),
//               borderRadius: BorderRadius.circular(40),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.red.withValues(alpha: 0.35),
//                   blurRadius: 12,
//                   offset: const Offset(0, 4),
//                 ),
//               ],
//             ),
//             child: const Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Icon(
//                   Icons.wifi_off_rounded,
//                   color: Colors.white,
//                   size: 18,
//                 ),
//                 SizedBox(width: 8),
//                 Text(
//                   'Mất kết nối internet',
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontSize: 13,
//                     fontWeight: FontWeight.w600,
//                     fontFamily: 'Inter',
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
