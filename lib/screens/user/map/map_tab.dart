import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:badminton_ai/data/models/court_location_model.dart';
import 'package:badminton_ai/data/repositories/supabase_repository.dart';
import 'package:badminton_ai/screens/user/map/court_detail_sheet.dart';
import 'package:badminton_ai/screens/user/map/map_view_model.dart';
import 'package:badminton_ai/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:badminton_ai/utils/app_colors.dart';

// Tab 2: Bản đồ
enum SportType { pickleball, badminton, football, tennis }

class MapTab extends StatelessWidget {
  const MapTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MapViewModel(context.read<SupabaseRepository>()),
      child: const _MapTabContent(),
    );
  }
}

class _MapTabContent extends StatefulWidget {
  const _MapTabContent({Key? key}) : super(key: key);

  @override
  _MapTabContentState createState() => _MapTabContentState();
}

class _MapTabContentState extends State<_MapTabContent> {
  GoogleMapController? _mapController;
  final TextEditingController _searchController = TextEditingController();

  // Custom Markers
  final Map<String, BitmapDescriptor> _customIcons = {};
  bool _iconsLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadCustomMarkers();
  }

  // --- Cấu hình Icons ---
  Future<void> _loadCustomMarkers() async {
    try {
      _customIcons['badminton'] = await _createCustomMarkerBitmapFromAsset('assets/images/caulong.png', AppColors.primary);
      _customIcons['pickleball'] = await _createCustomMarkerBitmapFromAsset('assets/images/pickleball.png', AppColors.primaryLight);
      _customIcons['football'] = await _createCustomMarkerBitmap(Icons.sports_soccer, AppColors.primary);
      _customIcons['tennis'] = await _createCustomMarkerBitmap(Icons.sports_tennis, AppColors.primaryDark);

      if (mounted) {
        setState(() {
          _iconsLoaded = true;
        });
      }
    } catch (e) {
      debugPrint('Error creating custom markers: $e');
    }
  }

  Future<BitmapDescriptor> _createCustomMarkerBitmapFromAsset(String assetPath, Color color) async {
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    final size = const Size(120, 120);
    final radius = size.width / 2;

    final paint = Paint()..color = color;
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

    canvas.drawCircle(Offset(radius, radius + 5), radius - 5, shadowPaint);
    canvas.drawCircle(Offset(radius, radius), radius - 10, paint);
    canvas.drawCircle(Offset(radius, radius), radius - 10, borderPaint);

    try {
      final ByteData data = await rootBundle.load(assetPath);
      final ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(), targetWidth: 60);
      final ui.FrameInfo fi = await codec.getNextFrame();
      final ui.Image image = fi.image;
      final Offset imageOffset = Offset(radius - (image.width / 2), radius - (image.height / 2));
      canvas.drawImage(image, imageOffset, Paint());
    } catch (e) {}

    final recordedImage = await pictureRecorder.endRecording().toImage(size.width.toInt(), size.height.toInt());
    final byteData = await recordedImage.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
  }

  Future<BitmapDescriptor> _createCustomMarkerBitmap(IconData iconData, Color color) async {
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    final size = const Size(120, 120); 
    final radius = size.width / 2;

    final paint = Paint()..color = color;
    final borderPaint = Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 4;
    final shadowPaint = Paint()..color = Colors.black.withOpacity(0.3)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

    canvas.drawCircle(Offset(radius, radius + 5), radius - 5, shadowPaint);
    canvas.drawCircle(Offset(radius, radius), radius - 10, paint);
    canvas.drawCircle(Offset(radius, radius), radius - 10, borderPaint);

    final textPainter = TextPainter(textDirection: ui.TextDirection.ltr);
    textPainter.text = TextSpan(
      text: String.fromCharCode(iconData.codePoint),
      style: TextStyle(fontSize: 60, fontFamily: iconData.fontFamily, package: iconData.fontPackage, color: Colors.white),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(radius - textPainter.width / 2, radius - textPainter.height / 2));

    final image = await pictureRecorder.endRecording().toImage(size.width.toInt(), size.height.toInt());
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(data!.buffer.asUint8List());
  }

  BitmapDescriptor _getMarkerIcon(CourtLocationModel court) {
    if (!_iconsLoaded) return BitmapDescriptor.defaultMarker;
    String? sportType = court.sportType?.toLowerCase();
    if (sportType == null) {
      final nameLower = court.name.toLowerCase();
      if (nameLower.contains('pickle')) sportType = 'pickleball';
      else if (nameLower.contains('bóng đá') || nameLower.contains('football')) sportType = 'football';
      else if (nameLower.contains('tennis')) sportType = 'tennis';
      else sportType = 'badminton';
    }
    if (sportType == 'pickleball') return _customIcons['pickleball'] ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
    if (sportType == 'football') return _customIcons['football'] ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
    if (sportType == 'tennis') return _customIcons['tennis'] ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet);
    return _customIcons['badminton'] ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    final vm = context.read<MapViewModel>();
    if (!vm.isLoadingLocation) {
      controller.animateCamera(CameraUpdate.newLatLngZoom(vm.currentPosition, 14.0));
    }
  }

  Set<Marker> _buildMarkers(MapViewModel vm) {
    final Set<Marker> markers = {};
    for (final court in vm.filteredCourts.take(50)) {
      markers.add(
        Marker(
          markerId: MarkerId(court.id),
          position: LatLng(court.latitude, court.longitude),
          icon: _getMarkerIcon(court),
          infoWindow: InfoWindow(
            title: court.name,
            snippet: court.address,
          ),
          onTap: () {
            vm.selectCourt(court);
            _mapController?.animateCamera(
              CameraUpdate.newLatLngZoom(LatLng(court.latitude, court.longitude), 16.0),
            );
          },
        ),
      );
    }
    return markers;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MapViewModel>(
      builder: (context, vm, child) {
        
        final hasSmallCard = vm.selectedCourt != null;
        final hasListCard = vm.showNearbyList;

        // Khai báo chiều cao xấp xỉ của thanh Navigation Bar phía dưới để tránh bị đè UI
        const double navBarOffset = 100.0;

        int durationMs = 300;
        double bottomOffset = navBarOffset + 16.0; // Vị trí cơ bản sát trên Navigation Bar
        if (hasListCard) {
          bottomOffset = navBarOffset + MediaQuery.of(context).size.height * 0.4 + 20; // Float trên danh sách
        } else if (hasSmallCard) {
          bottomOffset = MediaQuery.of(context).size.height * vm.sheetExtent + 16.0; // Đi theo khung
          if ((vm.sheetExtent - 0.55).abs() > 0.01) {
             durationMs = 0; // Trượt trực tiếp theo vị trí ngón tay
          }
        }

        return Scaffold(
          body: Stack(
            children: [
              GoogleMap(
                onMapCreated: _onMapCreated,
                initialCameraPosition: CameraPosition(target: vm.currentPosition, zoom: 14.0),
                markers: _buildMarkers(vm),
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                onTap: (_) => vm.closeBottomCard(),
              ),

              // Search & Filter
              Positioned(
                top: 0, left: 0, right: 0,
                child: SafeArea(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextField(
                                controller: _searchController,
                                decoration: InputDecoration(
                                  hintText: "Tìm kiếm sân quanh đây...",
                                  prefixIcon: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Image.asset('assets/images/logo1.png', width: 24, height: 24),
                                  ),
                                  suffixIcon: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (_searchController.text.isNotEmpty)
                                        IconButton(
                                          icon: const Icon(Icons.close),
                                          onPressed: () {
                                            _searchController.clear();
                                            vm.setSearchQuery('');
                                            vm.closeBottomCard();
                                            FocusScope.of(context).unfocus();
                                          },
                                        ),
                                      const Padding(
                                        padding: EdgeInsets.only(right: 16.0),
                                        child: Icon(Icons.search, color: Colors.black87),
                                      ),
                                    ],
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                ),
                                onChanged: vm.setSearchQuery,
                              ),
                              if (vm.searchResults.isNotEmpty)
                                Container(
                                  constraints: const BoxConstraints(maxHeight: 200),
                                  child: ListView.separated(
                                    shrinkWrap: true,
                                    padding: EdgeInsets.zero,
                                    itemCount: vm.searchResults.length,
                                    separatorBuilder: (_, __) => const Divider(height: 1),
                                    itemBuilder: (context, index) {
                                      final court = vm.searchResults[index];
                                      return ListTile(
                                        leading: const Icon(Icons.location_on, color: Colors.red),
                                        title: Text(court.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                                        subtitle: Text(court.address, maxLines: 1, overflow: TextOverflow.ellipsis),
                                        onTap: () {
                                          _searchController.clear();
                                          vm.setSearchQuery('');
                                          vm.selectCourt(court);
                                          _mapController?.animateCamera(
                                            CameraUpdate.newLatLngZoom(LatLng(court.latitude, court.longitude), 16.0),
                                          );
                                          FocusScope.of(context).unfocus();
                                        },
                                      );
                                    },
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          children: [
                            _buildFilterChip(vm, 'Cầu lông', SportType.badminton, Colors.green),
                            const SizedBox(width: 8),
                            _buildFilterChip(vm, 'Pickleball', SportType.pickleball, Colors.blue),
                            const SizedBox(width: 8),
                            _buildFilterChip(vm, 'Bóng đá', SportType.football, Colors.orange),
                            const SizedBox(width: 8),
                            _buildFilterChip(vm, 'Tennis', SportType.tennis, Colors.purple),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Animated Bottom Card for Nearby List
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutQuart,
                left: 16,
                right: 16,
                bottom: hasListCard ? navBarOffset + 8.0 : -400, // Trượt lên trên navbar
                child: _buildNearbyListCard(vm),
              ),

              // Court Details Sheet (Draggable Frame)
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                switchInCurve: Curves.easeOutQuart,
                switchOutCurve: Curves.easeOutQuart,
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 1),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  );
                },
                child: vm.selectedCourt != null
                    ? NotificationListener<DraggableScrollableNotification>(
                        onNotification: (notification) {
                          vm.setSheetExtent(notification.extent);
                          
                          if (notification.extent <= 0.02) {
                            // Người dùng kéo xuống thấp nhất (đóng)
                            Future.microtask(() => vm.closeBottomCard());
                          }

                          if (notification.extent > 0.6) {
                            vm.setHideFabs(true);
                          } else {
                            vm.setHideFabs(false);
                          }
                          return false; // let the notification bubble up
                        },
                        child: CourtDetailSheet(
                          key: ValueKey(vm.selectedCourt!.id),
                          court: vm.selectedCourt!,
                          onClose: () => vm.closeBottomCard(),
                        ),
                      )
                    : const SizedBox.shrink(key: ValueKey('empty_sheet')),
              ),

              // Animated Floating Buttons
              AnimatedPositioned(
                duration: Duration(milliseconds: durationMs),
                curve: Curves.easeOutQuart,
                right: 16,
                bottom: bottomOffset,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: vm.hideFabs ? 0.0 : 1.0,
                  child: IgnorePointer(
                    ignoring: vm.hideFabs,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FloatingActionButton(
                          mini: false,
                          heroTag: 'nearby',
                          backgroundColor:AppColors.primary,
                          onPressed: vm.toggleNearbyList,
                          shape: const CircleBorder(),
                          child: const Icon(Icons.arrow_downward, color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        FloatingActionButton(
                          mini: false,
                          heroTag: 'loc',
                          backgroundColor: AppColors.primary,
                          onPressed: () async {
                            await vm.requestLocationUpdate();
                            _mapController?.animateCamera(CameraUpdate.newLatLngZoom(vm.currentPosition, 14.0));
                          },
                          shape: const CircleBorder(),
                          child: const Icon(Icons.my_location, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterChip(MapViewModel vm, String label, SportType type, Color color) {
    final isSelected = vm.selectedSport == type;
    return ChoiceChip(
      label: Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.black87)),
      selected: isSelected,
      showCheckmark: false,
      selectedColor: color.withOpacity(0.8),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
        side: BorderSide(color: isSelected ? Colors.transparent : Colors.grey.shade300),
      ),
      elevation: 2,
      onSelected: (selected) {
        if (selected) vm.selectSport(type);
      },
      avatar: _getAvatarForSport(type, isSelected, color),
    );
  }

  Widget _getAvatarForSport(SportType type, bool isSelected, Color color) {
    if (type == SportType.badminton) {
      return Image.asset('assets/images/caulong.png', width: 16, height: 16, color: isSelected ? null : const ui.Color.fromARGB(255, 55, 240, 104));
    } else if (type == SportType.pickleball) {
      return Image.asset('assets/images/pickleball.png', width: 16, height: 16, color: isSelected ? null : const ui.Color.fromARGB(255, 212, 234, 15));
    } else if (type == SportType.football) {
      return Icon(Icons.sports_soccer, size: 16, color: isSelected ? color : const ui.Color.fromARGB(255, 24, 164, 229));
    } else {
      return Icon(Icons.sports_tennis, size: 16, color: isSelected ? color : const ui.Color.fromARGB(255, 225, 50, 50));
    }
  }

  // Removed _buildBottomCard and _buildSmallCourtCard as they are now replaced by CourtDetailSheet inline

  Widget _buildNearbyListCard(MapViewModel vm) {
    final courts = vm.courtsSortedByDistance.take(15).toList();
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 8,
      color: Colors.white,
      margin: EdgeInsets.zero,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.4,
        padding: const EdgeInsets.only(top: 12),
        child: Column(
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
            ),
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('Sân gần đây & Đã tìm kiếm', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: ListView.separated(
                itemCount: courts.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final court = courts[index];
                  String distanceStr = '';
                  if (vm.currentPosition.latitude != 21.028511) {
                    final dist = Geolocator.distanceBetween(
                      vm.currentPosition.latitude, vm.currentPosition.longitude, court.latitude, court.longitude);
                    distanceStr = '${(dist / 1000).toStringAsFixed(1)}km';
                  }
                  
                  return ListTile(
                    leading: const Icon(Icons.history, color: Colors.grey),
                    title: Text(court.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                    subtitle: Text(
                      distanceStr.isNotEmpty ? '($distanceStr) ${court.address}' : court.address,
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    ),
                    trailing: const Icon(Icons.turn_right, color: Colors.grey),
                    onTap: () {
                      vm.selectCourt(court);
                      _mapController?.animateCamera(
                        CameraUpdate.newLatLngZoom(LatLng(court.latitude, court.longitude), 16.0),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
