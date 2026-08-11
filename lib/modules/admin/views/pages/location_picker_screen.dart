import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:badminton_ai/core/design_system/components/ui/custom_gradient_app_bar.dart';
import 'package:easy_localization/easy_localization.dart';

class LocationPickerScreen extends StatefulWidget {
  final LatLng? initialLocation;
  final String? initialAddress;

  const LocationPickerScreen({
    super.key,
    this.initialLocation,
    this.initialAddress,
  });

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  GoogleMapController? _mapController;
  LatLng _selectedLocation = const LatLng(21.0285, 105.8542); // Hà Nội mặc định
  String _selectedAddress = '';
  bool _isLoadingAddress = false;
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    if (widget.initialLocation != null) {
      _selectedLocation = widget.initialLocation!;
      _selectedAddress = widget.initialAddress ?? '';
      _updateMarker();
    } else {
      _getCurrentLocation();
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showMessage('screens.pleaseEnableLocationService'.tr());
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showMessage('screens.locationAccessDenied'.tr());
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showMessage('screens.locationAccessIsPermanently'.tr());
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      setState(() {
        _selectedLocation = LatLng(position.latitude, position.longitude);
      });

      _updateMarker();
      _getAddressFromLocation(_selectedLocation);
      
      if (_mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(_selectedLocation, 15.0),
        );
      }
    } catch (e) {
      debugPrint("Lỗi lấy vị trí: $e");
      _showMessage('screens.unableToGetCurrentLocation'.tr());
    }
  }

  void _updateMarker() {
    setState(() {
      _markers = {
        Marker(
          markerId: MarkerId('selected_location'),
          position: _selectedLocation,
          draggable: true,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          onDragEnd: (LatLng newPosition) {
            setState(() {
              _selectedLocation = newPosition;
            });
            _getAddressFromLocation(newPosition);
          },
        ),
      };
    });
  }

  Future<void> _getAddressFromLocation(LatLng location) async {
    setState(() {
      _isLoadingAddress = true;
    });

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final address = [
          place.street,
          place.subLocality,
          place.locality,
          place.administrativeArea,
          place.country,
        ].where((part) => part != null && part.isNotEmpty).join(', ');

        setState(() {
          _selectedAddress = address.isNotEmpty ? address : 'screens.noAddressAvailable'.tr();
          _isLoadingAddress = false;
        });
      } else {
        setState(() {
          _selectedAddress = 'screens.addressNotFound'.tr();
          _isLoadingAddress = false;
        });
      }
    } catch (e) {
      debugPrint("Lỗi lấy địa chỉ: $e");
      setState(() {
        _selectedAddress = 'screens.unableToGetAddress'.tr();
        _isLoadingAddress = false;
      });
    }
  }

  void _onMapTap(LatLng location) {
    setState(() {
      _selectedLocation = location;
    });
    _updateMarker();
    _getAddressFromLocation(location);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: CustomGradientAppBar(
        title: Text('screens.selectLocationOnTheMap'.tr()),
      ),
      body: Stack(
        children: [
          // Google Map
          GoogleMap(
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
            },
            initialCameraPosition: CameraPosition(
              target: _selectedLocation,
              zoom: 15.0,
            ),
            markers: _markers,
            onTap: _onMapTap,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapType: MapType.normal,
          ),

          // Thông tin vị trí đã chọn
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Card(
              elevation: 4,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.location_on, color: colors.primary),
                        SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('screens.selectedLocation'.tr(),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              SizedBox(height: 4),
                              _isLoadingAddress
                                  ? SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      _selectedAddress,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Tọa độ: ${_selectedLocation.latitude.toStringAsFixed(6)}, ${_selectedLocation.longitude.toStringAsFixed(6)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Nút quay về vị trí hiện tại
          Positioned(
            right: 16,
            bottom: 100,
            child: FloatingActionButton(
              mini: true,
              onPressed: _getCurrentLocation,
              child: Icon(Icons.my_location, color: colors.primary),
            ),
          ),

          // Nút xác nhận
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text('screens.cancel1'.tr()),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context, {
                          'location': _selectedLocation,
                          'address': _selectedAddress,
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text('screens.confirm'.tr(),
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}


