import 'package:easy_localization/easy_localization.dart';
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
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _loadCustomMarkers();
    _searchFocusNode.addListener(() {
      if (mounted) setState(() {});
    });
  }

  // --- Cấu hình Icons ---
  Future<void> _loadCustomMarkers() async {
    try {
      _customIcons['badminton'] = await _createCustomMarkerBitmapFromAsset(
        'assets/images/caulong.png',
        AppColors.primary,
      );
      _customIcons['pickleball'] = await _createCustomMarkerBitmapFromAsset(
        'assets/images/pickleball.png',
        AppColors.primaryLight,
      );
      _customIcons['football'] = await _createCustomMarkerBitmap(
        Icons.sports_soccer,
        AppColors.primary,
      );
      _customIcons['tennis'] = await _createCustomMarkerBitmap(
        Icons.sports_tennis,
        AppColors.primaryDark,
      );

      if (mounted) {
        setState(() {
          _iconsLoaded = true;
        });
      }
    } catch (e) {
      debugPrint('Error creating custom markers: $e');
    }
  }

  Future<BitmapDescriptor> _createCustomMarkerBitmapFromAsset(
    String assetPath,
    Color color,
  ) async {
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
      ..color = Colors.black.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

    canvas.drawCircle(Offset(radius, radius + 5), radius - 5, shadowPaint);
    canvas.drawCircle(Offset(radius, radius), radius - 10, paint);
    canvas.drawCircle(Offset(radius, radius), radius - 10, borderPaint);

    try {
      final ByteData data = await rootBundle.load(assetPath);
      final ui.Codec codec = await ui.instantiateImageCodec(
        data.buffer.asUint8List(),
        targetWidth: 60,
      );
      final ui.FrameInfo fi = await codec.getNextFrame();
      final ui.Image image = fi.image;
      final Offset imageOffset = Offset(
        radius - (image.width / 2),
        radius - (image.height / 2),
      );
      canvas.drawImage(image, imageOffset, Paint());
    } catch (e) {}

    final recordedImage = await pictureRecorder.endRecording().toImage(
      size.width.toInt(),
      size.height.toInt(),
    );
    final byteData = await recordedImage.toByteData(
      format: ui.ImageByteFormat.png,
    );
    return BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
  }

  Future<BitmapDescriptor> _createCustomMarkerBitmap(
    IconData iconData,
    Color color,
  ) async {
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
      ..color = Colors.black.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

    canvas.drawCircle(Offset(radius, radius + 5), radius - 5, shadowPaint);
    canvas.drawCircle(Offset(radius, radius), radius - 10, paint);
    canvas.drawCircle(Offset(radius, radius), radius - 10, borderPaint);

    final textPainter = TextPainter(textDirection: ui.TextDirection.ltr);
    textPainter.text = TextSpan(
      text: String.fromCharCode(iconData.codePoint),
      style: TextStyle(
        fontSize: 60,
        fontFamily: iconData.fontFamily,
        package: iconData.fontPackage,
        color: Colors.white,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(radius - textPainter.width / 2, radius - textPainter.height / 2),
    );

    final image = await pictureRecorder.endRecording().toImage(
      size.width.toInt(),
      size.height.toInt(),
    );
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(data!.buffer.asUint8List());
  }

  BitmapDescriptor _getMarkerIcon(CourtLocationModel court) {
    if (!_iconsLoaded) return BitmapDescriptor.defaultMarker;
    // Dùng _inferSportType để đảm bảo nhất quán với list và filter
    final sType = _inferSportType(court);
    switch (sType) {
      case SportType.pickleball:
        return _customIcons['pickleball'] ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
      case SportType.football:
        return _customIcons['football'] ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
      case SportType.tennis:
        return _customIcons['tennis'] ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet);
      case SportType.badminton:
      default:
        return _customIcons['badminton'] ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
    }
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    _searchController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    final vm = context.read<MapViewModel>();
    if (!vm.isLoadingLocation) {
      controller.animateCamera(
        CameraUpdate.newLatLngZoom(vm.currentPosition, 14.0),
      );
    }
  }

  Set<Marker> _buildMarkers(MapViewModel vm) {
    final Set<Marker> markers = {};
    // Lấy icon theo sport đang được lọc — đảm bảo TẤT CẢ marker hiển thị
    // cùng icon với nút filter đang chọn, không phụ thuộc tên sân
    final BitmapDescriptor activeIcon = _getIconForSportType(vm.selectedSport);

    for (final court in vm.filteredCourts.take(50)) {
      markers.add(
        Marker(
          markerId: MarkerId(court.id),
          position: LatLng(court.latitude, court.longitude),
          icon: activeIcon,
          infoWindow: InfoWindow(title: court.name, snippet: court.address),
          onTap: () {
            vm.selectCourt(court);
            _mapController?.animateCamera(
              CameraUpdate.newLatLngZoom(
                LatLng(court.latitude, court.longitude),
                16.0,
              ),
            );
          },
        ),
      );
    }
    return markers;
  }

  /// Trả về icon marker theo loại sport đang lọc
  BitmapDescriptor _getIconForSportType(SportType type) {
    if (!_iconsLoaded) return BitmapDescriptor.defaultMarker;
    switch (type) {
      case SportType.pickleball:
        return _customIcons['pickleball'] ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
      case SportType.football:
        return _customIcons['football'] ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
      case SportType.tennis:
        return _customIcons['tennis'] ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet);
      case SportType.badminton:
      default:
        return _customIcons['badminton'] ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MapViewModel>(
      builder: (context, vm, child) {
        final hasSmallCard = vm.selectedCourt != null;
        final hasListCard = vm.showNearbyList;

        // Khai báo chiều cao xấp xỉ của thanh Navigation Bar phía dưới để tránh bị đè UI
        const double navBarOffset = 100.0;

        return Scaffold(
          resizeToAvoidBottomInset:
              false, // Bàn phím sẽ trượt đè lên thay vì đẩy các thành phần bottom (BottomSheet, Fab, Map) lên giữa màn hình
          body: Stack(
            children: [
              GoogleMap(
                onMapCreated: _onMapCreated,
                initialCameraPosition: CameraPosition(
                  target: vm.currentPosition,
                  zoom: 14.0,
                ),
                markers: _buildMarkers(vm),
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                onTap: (_) {
                  FocusScope.of(context).unfocus();
                  vm.closeBottomCard();
                },
              ),

              // Filter Chips (Render trước, đặt cố định phía dưới Search Bar)
              SafeArea(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: EdgeInsets.only(
                      top: 76.0,
                    ), // Canh tương đối dưới Search Bar
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        children: [
                          _buildFilterChip(
                            vm,
                            'screens.badminton'.tr(),
                            SportType.badminton,
                            Colors.green,
                          ),
                          SizedBox(width: 8),
                          _buildFilterChip(
                            vm,
                            'Pickleball',
                            SportType.pickleball,
                            Colors.blue,
                          ),
                          SizedBox(width: 8),
                          _buildFilterChip(
                            vm,
                            'screens.football'.tr(),
                            SportType.football,
                            Colors.orange,
                          ),
                          SizedBox(width: 8),
                          _buildFilterChip(
                            vm,
                            'Tennis',
                            SportType.tennis,
                            Colors.purple,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Search Bar & Dropdown Results (Render sau, đè lên Filter Chips)
              SafeArea(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Column(
                    mainAxisSize: MainAxisSize
                        .min, // Rất quan trọng để Map bên dưới không bị block touch
                    children: [
                      Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Builder(
                            builder: (context) {
                              
                              return TextField(
                                controller: _searchController,
                                focusNode: _searchFocusNode,
                                decoration: InputDecoration(
                                  hintText: 'home_screen.searchCourtsAroundYou'.tr(),
                                  prefixIcon: Padding(
                                    padding: EdgeInsets.all(12.0),
                                    child: Image.asset(
                                      'assets/images/logo1.png',
                                      width: 24,
                                      height: 24,
                                    ),
                                  ),
                                  suffixIcon: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (_searchController.text.isNotEmpty)
                                        IconButton(
                                          icon: Icon(Icons.close),
                                          onPressed: () {
                                            _searchController.clear();
                                            vm.setSearchQuery('');
                                            vm.closeBottomCard();
                                            _searchFocusNode.unfocus();
                                            FocusScope.of(context).unfocus();
                                          },
                                        ),
                                      Padding(
                                        padding: EdgeInsets.only(right: 16.0),
                                        child: Icon(
                                          Icons.search,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                ),
                                onChanged: vm.setSearchQuery,
                                onTap: () {
                                  if (vm.searchQuery.isEmpty) {
                                    vm.setSearchQuery('');
                                  }
                                },
                              );
                            },
                          ),
                        ),
                      ),
                      if (_searchFocusNode.hasFocus &&
                          vm.searchResults.isNotEmpty)
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12.0),
                          child: Container(
                            constraints: const BoxConstraints(maxHeight: 300),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.12),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: ListView.builder(
                                shrinkWrap: true,
                                padding: EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                itemCount: vm.searchResults.length,
                                itemBuilder: (context, index) {
                                  final court = vm.searchResults[index];
                                  final isHistory = vm.searchQuery
                                      .trim()
                                      .isEmpty;

                                  String? inferredSport = court.sportType
                                      ?.toLowerCase();
                                  if (inferredSport == null ||
                                      inferredSport.isEmpty) {
                                    final nameLower = court.name.toLowerCase();
                                    if (nameLower.contains('pickle'))
                                      inferredSport = 'pickleball';
                                    else if (nameLower.contains('screens.football1'.tr()) ||
                                        nameLower.contains('football'))
                                      inferredSport = 'football';
                                    else if (nameLower.contains('tennis'))
                                      inferredSport = 'tennis';
                                    else
                                      inferredSport = 'badminton';
                                  }
                                  SportType sType = SportType.badminton;
                                  if (inferredSport.contains('pickle'))
                                    sType = SportType.pickleball;
                                  else if (inferredSport.contains('foot') ||
                                      inferredSport.contains('screens.ball'.tr()))
                                    sType = SportType.football;
                                  else if (inferredSport.contains('tennis'))
                                    sType = SportType.tennis;

                                  final sportColor = _getSportColor(sType);
                                  final sportLabel = _getSportLabel(sType);

                                  return InkWell(
                                    onTap: () {
                                      _searchController.text = court.name;
                                      vm.setSearchQuery(court.name);
                                      vm.selectCourt(court);
                                      _mapController?.animateCamera(
                                        CameraUpdate.newLatLngZoom(
                                          LatLng(
                                            court.latitude,
                                            court.longitude,
                                          ),
                                          16.0,
                                        ),
                                      );
                                      _searchFocusNode.unfocus();
                                      FocusScope.of(context).unfocus();
                                    },
                                    borderRadius: BorderRadius.circular(12),
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 10,
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 40,
                                            height: 40,
                                            decoration: BoxDecoration(
                                              color: isHistory
                                                  ? Colors.grey.shade100
                                                  : sportColor.withValues(alpha: 
                                                      0.12,
                                                    ),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Icon(
                                              isHistory
                                                  ? Icons.history_rounded
                                                  : Icons.place_rounded,
                                              color: isHistory
                                                  ? Colors.grey.shade500
                                                  : sportColor,
                                              size: 20,
                                            ),
                                          ),
                                          SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  court.name,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 14,
                                                    color: Color(0xFF1A1A2E),
                                                  ),
                                                ),
                                                SizedBox(height: 2),
                                                Text(
                                                  court.address,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey.shade500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          SizedBox(width: 8),
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 3,
                                            ),
                                            decoration: BoxDecoration(
                                              color: sportColor.withValues(alpha: 
                                                0.1,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              border: Border.all(
                                                color: sportColor.withValues(alpha: 
                                                  0.3,
                                                ),
                                              ),
                                            ),
                                            child: Text(
                                              sportLabel,
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                                color: sportColor,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
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
                bottom: hasListCard
                    ? navBarOffset + 8.0
                    : -400, // Trượt lên trên navbar
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
                          vm.sheetExtentNotifier.value = notification.extent;

                          if (notification.extent <= 0.02) {
                            // Người dùng kéo xuống thấp nhất (đóng)
                            Future.microtask(() => vm.closeBottomCard());
                          }
                          return false; // let the notification bubble up
                        },
                        child: CourtDetailSheet(
                          key: ValueKey(vm.selectedCourt!.id),
                          court: vm.selectedCourt!,
                          onClose: () => vm.closeBottomCard(),
                        ),
                      )
                    : SizedBox.shrink(key: ValueKey('empty_sheet')),
              ),

              // Animated Floating Buttons
              ValueListenableBuilder<double>(
                valueListenable: vm.sheetExtentNotifier,
                builder: (context, extent, child) {
                  int durationMs = 300;
                  double bottomOffset = navBarOffset + 16.0;

                  if (hasListCard) {
                    bottomOffset = navBarOffset +
                        MediaQuery.of(context).size.height * 0.4 +
                        20;
                  } else if (hasSmallCard) {
                    bottomOffset =
                        MediaQuery.of(context).size.height * extent + 16.0;
                    if ((extent - 0.55).abs() > 0.01) {
                      durationMs = 0;
                    }
                  }

                  bool hideFabs = extent > 0.6;

                  return AnimatedPositioned(
                    duration: Duration(milliseconds: durationMs),
                    curve: Curves.easeOutQuart,
                    right: 16,
                    bottom: bottomOffset,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: hideFabs ? 0.0 : 1.0,
                      child: IgnorePointer(
                        ignoring: hideFabs,
                        child: child,
                      ),
                    ),
                  );
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FloatingActionButton(
                      mini: false,
                      heroTag: 'nearby',
                      backgroundColor: AppColors.primary,
                      onPressed: vm.toggleNearbyList,
                      shape: const CircleBorder(),
                      child: Icon(
                        Icons.arrow_downward,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 12),
                    FloatingActionButton(
                      mini: false,
                      heroTag: 'loc',
                      backgroundColor: AppColors.primary,
                      onPressed: () async {
                        await vm.requestLocationUpdate();
                        _mapController?.animateCamera(
                          CameraUpdate.newLatLngZoom(
                            vm.currentPosition,
                            14.0,
                          ),
                        );
                      },
                      shape: const CircleBorder(),
                      child: Icon(
                        Icons.my_location,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterChip(
    MapViewModel vm,
    String label,
    SportType type,
    Color color,
  ) {
    final isSelected = vm.selectedSport == type;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(color: isSelected ? Colors.white : Colors.black87),
      ),
      selected: isSelected,
      showCheckmark: false,
      selectedColor: color.withValues(alpha: 0.8),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
        side: BorderSide(
          color: isSelected ? Colors.transparent : Colors.grey.shade300,
        ),
      ),
      elevation: 2,
      onSelected: (selected) {
        if (selected) vm.selectSport(type);
      },
      avatar: _getAvatarForSport(type, isSelected, color),
    );
  }

  Widget _getAvatarForSport(SportType type, bool isSelected, Color color) {
    // Màu icon khi chưa chọn — khớp với màu của từng môn trong _getSportColor()
    Color badmintonColor = Color(0xFF22C55E); // xanh lá
    Color pickleballColor = Color(0xFF3B82F6); // xanh dương
    Color footballColor = Color(0xFFF97316); // cam
    Color tennisColor = Color(0xFF8B5CF6); // tím

    if (type == SportType.badminton) {
      return Image.asset(
        'assets/images/caulong.png',
        width: 16,
        height: 16,
        color: isSelected ? Colors.white : badmintonColor,
      );
    } else if (type == SportType.pickleball) {
      return Image.asset(
        'assets/images/pickleball.png',
        width: 16,
        height: 16,
        color: isSelected ? Colors.white : pickleballColor,
      );
    } else if (type == SportType.football) {
      return Icon(
        Icons.sports_soccer,
        size: 16,
        color: isSelected ? Colors.white : footballColor,
      );
    } else {
      return Icon(
        Icons.sports_tennis,
        size: 16,
        color: isSelected ? Colors.white : tennisColor,
      );
    }
  }

  // Removed _buildBottomCard and _buildSmallCourtCard as they are now replaced by CourtDetailSheet inline

  Color _getSportColor(SportType type) {
    switch (type) {
      case SportType.pickleball:
        return Color(0xFF3B82F6);
      case SportType.football:
        return Color(0xFFF97316);
      case SportType.tennis:
        return Color(0xFF8B5CF6);
      default:
        return AppColors.primary;
    }
  }

  String _getSportLabel(SportType type) {
    switch (type) {
      case SportType.pickleball:
        return 'Pickleball';
      case SportType.football:
        return 'screens.football'.tr();
      case SportType.tennis:
        return 'Tennis';
      default:
        return 'screens.badminton'.tr();
    }
  }

  SportType _inferSportType(CourtLocationModel court) {
    String? s = court.sportType?.toLowerCase();
    if (s == null || s.isEmpty) {
      final n = court.name.toLowerCase();
      if (n.contains('pickle'))
        s = 'pickleball';
      else if (n.contains('screens.football1'.tr()) || n.contains('football'))
        s = 'football';
      else if (n.contains('tennis'))
        s = 'tennis';
      else
        s = 'badminton';
    }
    if (s.contains('pickle')) return SportType.pickleball;
    if (s.contains('foot') || s.contains('screens.ball'.tr())) return SportType.football;
    if (s.contains('tennis')) return SportType.tennis;
    return SportType.badminton;
  }

  Widget _buildNearbyListCard(MapViewModel vm) {
    final courts = vm.courtsSortedByDistance.take(15).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.42,
      decoration: BoxDecoration(
        color: Color(0xFFF8F9FE),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 30,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Handle bar ──
          Padding(
            padding: EdgeInsets.only(top: 10, bottom: 4),
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // ── Header title ──
          Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              children: [
                Icon(Icons.place_rounded, color: AppColors.primary, size: 18),
                SizedBox(width: 8),
                Text('screens.recentYardsSearched'.tr(),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
              ],
            ),
          ),

          // ── List ──
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 16),
              itemCount: courts.length,
              itemBuilder: (context, index) {
                final court = courts[index];
                final sType = _inferSportType(court);
                final sportColor = _getSportColor(sType);
                final sportLabel = _getSportLabel(sType);

                String distanceStr = '';
                if (vm.currentPosition.latitude != 21.028511) {
                  final dist = Geolocator.distanceBetween(
                    vm.currentPosition.latitude,
                    vm.currentPosition.longitude,
                    court.latitude,
                    court.longitude,
                  );
                  distanceStr = '${(dist / 1000).toStringAsFixed(1)}km';
                }

                return Padding(
                  padding: EdgeInsets.only(bottom: 10),
                  child: Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    elevation: 0,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        vm.selectCourt(court);
                        _mapController?.animateCamera(
                          CameraUpdate.newLatLngZoom(
                            LatLng(court.latitude, court.longitude),
                            16.0,
                          ),
                        );
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade100),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // Sport icon
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: sportColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Center(
                                child: _getAvatarForSport(
                                  sType,
                                  false,
                                  sportColor,
                                ),
                              ),
                            ),
                            SizedBox(width: 12),
                            // Name & address
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    court.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: Color(0xFF1A1A2E),
                                    ),
                                  ),
                                  SizedBox(height: 3),
                                  Text(
                                    court.address,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 8),
                            // Right side: distance + sport badge
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                if (distanceStr.isNotEmpty)
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          AppColors.primary,
                                          AppColors.primary.withValues(alpha: 0.75),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      distanceStr,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                SizedBox(height: 4),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: sportColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    sportLabel,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: sportColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

