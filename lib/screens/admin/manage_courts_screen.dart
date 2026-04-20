import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:badminton_ai/widgets/custom_gradient_app_bar.dart';
import 'package:badminton_ai/data/models/court_location_model.dart';
import 'package:image_picker/image_picker.dart';
import 'package:badminton_ai/providers/auth_provider.dart';
import 'package:badminton_ai/data/repositories/supabase_repository.dart';
import 'package:badminton_ai/screens/admin/location_picker_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:badminton_ai/utils/dialog_utils.dart';
import 'package:intl/intl.dart';

class ManageCourtsScreen extends StatefulWidget {
  const ManageCourtsScreen({super.key});

  @override
  State<ManageCourtsScreen> createState() => _ManageCourtsScreenState();
}

class _ManageCourtsScreenState extends State<ManageCourtsScreen> {
  // Biến state cho Dialog/Form
  void _showCourtFormDialog(BuildContext context, {CourtLocationModel? court}) {
    final _formKey = GlobalKey<FormState>();
    final _nameController = TextEditingController(text: court?.name);
    final _addressController = TextEditingController(text: court?.address);
    final _priceController = TextEditingController(
      text: court?.pricePerHour.toString(),
    );
    final _totalCourtsController = TextEditingController(
      text: court?.totalCourts.toString(),
    );
    final _linkController = TextEditingController();

    LatLng? _selectedLocation = court != null
        ? LatLng(court.latitude, court.longitude)
        : null;
    String _selectedAddress = court?.address ?? '';
    String _selectedSportType = court?.sportType ?? 'badminton';

    File? _imageFile;
    String? _currentImageUrl = court?.imageUrl;
    final _imagePicker = ImagePicker();
    bool _isUploading = false;
    bool _isScanningLink = false;

    Future<void> _scanLocationFromLink(
      String link,
      StateSetter setDialogState,
    ) async {
      if (link.isEmpty) return;
      setDialogState(() => _isScanningLink = true);

      try {
        String finalUrl = link;
        if (link.contains('goo.gl') || link.contains('g.co')) {
          final client = http.Client();
          final request = http.Request('GET', Uri.parse(link))
            ..followRedirects = false;
          final response = await client.send(request);
          if (response.headers.containsKey('location')) {
            finalUrl = response.headers['location']!;
          }
        }

        final regexAt = RegExp(r'@(-?\d+\.\d+),(-?\d+\.\d+)');
        final matchAt = regexAt.firstMatch(finalUrl);

        double? lat, lng;

        if (matchAt != null) {
          lat = double.parse(matchAt.group(1)!);
          lng = double.parse(matchAt.group(2)!);
        } else {
          final regexQ = RegExp(r'q=(-?\d+\.\d+),(-?\d+\.\d+)');
          final matchQ = regexQ.firstMatch(finalUrl);
          if (matchQ != null) {
            lat = double.parse(matchQ.group(1)!);
            lng = double.parse(matchQ.group(2)!);
          }
        }

        if (lat != null && lng != null) {
          _selectedLocation = LatLng(lat, lng);
          _selectedAddress = "Đã lấy tọa độ từ link (Vui lòng kiểm tra lại)";
          _addressController.text = _selectedAddress;

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã tìm thấy tọa độ thành công!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          throw Exception("Không tìm thấy tọa độ trong link");
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: Không thể lấy tọa độ từ link này. $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setDialogState(() => _isScanningLink = false);
      }
    }

    final inputDecoration = InputDecoration(
      filled: true,
      fillColor: Colors.grey.shade100,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
      ),
    );

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black54,
      pageBuilder: (context, anim1, anim2) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 24,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  color: Colors.white,
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.85,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 8,
                          right: 8,
                          top: 8,
                          bottom: 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                            Text(
                              court == null
                                  ? 'Trạm Thêm Mới Sân'
                                  : 'Sửa Thông Tin Sân',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(
                              width: 48,
                            ), // To balance the close button
                          ],
                        ),
                      ),
                      Flexible(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Ảnh minh họa
                                GestureDetector(
                                  onTap: () async {
                                    final pickedFile = await _imagePicker
                                        .pickImage(source: ImageSource.gallery);
                                    if (pickedFile != null) {
                                      setDialogState(() {
                                        _imageFile = File(pickedFile.path);
                                      });
                                    }
                                  },
                                  child: Container(
                                    height: 180,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade50,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: Colors.grey.shade300,
                                        width: 1.5,
                                        strokeAlign:
                                            BorderSide.strokeAlignOutside,
                                      ),
                                      image: _imageFile != null
                                          ? DecorationImage(
                                              image: FileImage(_imageFile!),
                                              fit: BoxFit.cover,
                                            )
                                          : (_currentImageUrl != null
                                                ? DecorationImage(
                                                    image: NetworkImage(
                                                      _currentImageUrl,
                                                    ),
                                                    fit: BoxFit.cover,
                                                  )
                                                : null),
                                    ),
                                    child:
                                        _imageFile == null &&
                                            _currentImageUrl == null
                                        ? Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons
                                                    .add_photo_alternate_outlined,
                                                size: 48,
                                                color: Colors.blue.shade300,
                                              ),
                                              const SizedBox(height: 12),
                                              Text(
                                                'Tải ảnh bìa lên',
                                                style: TextStyle(
                                                  color: Colors.grey.shade600,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          )
                                        : null,
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // Tên sân
                                TextFormField(
                                  controller: _nameController,
                                  decoration: inputDecoration.copyWith(
                                    labelText: 'Tên cơ sở sân',
                                  ),
                                  validator: (value) => value!.isEmpty
                                      ? 'Không được bỏ trống'
                                      : null,
                                ),
                                const SizedBox(height: 16),

                                // Link & Tính năng get Tọa độ
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: _linkController,
                                        decoration: inputDecoration.copyWith(
                                          labelText: 'Dán Link Google Maps',
                                          hintText:
                                              'https://maps.app.goo.gl/...',
                                          prefixIcon: const Icon(Icons.link),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    SizedBox(
                                      height: 55,
                                      width: 55,
                                      child: ElevatedButton(
                                        onPressed: _isScanningLink
                                            ? null
                                            : () => _scanLocationFromLink(
                                                _linkController.text.trim(),
                                                setDialogState,
                                              ),
                                        style: ElevatedButton.styleFrom(
                                          padding: EdgeInsets.zero,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          backgroundColor: Theme.of(
                                            context,
                                          ).primaryColor,
                                        ),
                                        child: _isScanningLink
                                            ? const Padding(
                                                padding: EdgeInsets.all(16.0),
                                                child:
                                                    CircularProgressIndicator(
                                                      color: Colors.white,
                                                      strokeWidth: 2.5,
                                                    ),
                                              )
                                            : const Icon(
                                                Icons.search,
                                                color: Colors.white,
                                              ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // Nút bản đồ thủ công
                                OutlinedButton.icon(
                                  onPressed: () async {
                                    final result =
                                        await Navigator.push<
                                          Map<String, dynamic>
                                        >(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                LocationPickerScreen(
                                                  initialLocation:
                                                      _selectedLocation,
                                                  initialAddress:
                                                      _selectedAddress,
                                                ),
                                          ),
                                        );

                                    if (result != null) {
                                      _selectedLocation =
                                          result['location'] as LatLng;
                                      _selectedAddress =
                                          result['address'] as String;
                                      _addressController.text =
                                          _selectedAddress;
                                      setDialogState(() {});
                                    }
                                  },
                                  icon: const Icon(Icons.map_outlined),
                                  label: Text(
                                    _selectedLocation != null
                                        ? 'Đã chốt vị trí trên bản đồ'
                                        : 'Chọn vị trí thủ công',
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    side: BorderSide(
                                      color: Theme.of(context).primaryColor,
                                    ),
                                  ),
                                ),

                                if (_selectedLocation != null) ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.location_on,
                                              size: 16,
                                              color: Colors.blue.shade700,
                                            ),
                                            const SizedBox(width: 4),
                                            const Text(
                                              'Đã nhận diện tọa độ',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _selectedAddress,
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 16),

                                TextFormField(
                                  controller: _addressController,
                                  decoration: inputDecoration.copyWith(
                                    labelText: 'Địa chỉ cụ thể (có thể sửa)',
                                    suffixIcon: const Icon(
                                      Icons.edit_location_alt,
                                      size: 20,
                                    ),
                                  ),
                                  validator: (value) => value!.isEmpty
                                      ? 'Thay đổi địa chỉ'
                                      : null,
                                ),
                                const SizedBox(height: 16),

                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: _priceController,
                                        decoration: inputDecoration.copyWith(
                                          labelText: 'Giá thuê / giờ',
                                          suffixText: 'VNĐ',
                                        ),
                                        keyboardType: TextInputType.number,
                                        validator: (value) =>
                                            value!.isEmpty ? 'Nhập giá' : null,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: TextFormField(
                                        controller: _totalCourtsController,
                                        decoration: inputDecoration.copyWith(
                                          labelText: 'Số sân con',
                                        ),
                                        keyboardType: TextInputType.number,
                                        validator: (value) =>
                                            value!.isEmpty ? 'Nhập số' : null,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                DropdownButtonFormField<String>(
                                  value: _selectedSportType,
                                  decoration: inputDecoration.copyWith(
                                    labelText: 'Loại hình kinh doanh',
                                  ),
                                  items: [
                                    DropdownMenuItem(
                                      value: 'badminton',
                                      child: Row(
                                        children: [
                                          Image.asset(
                                            'assets/images/caulong.png',
                                            width: 20,
                                            height: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          const Text('Cầu lông'),
                                        ],
                                      ),
                                    ),
                                    DropdownMenuItem(
                                      value: 'pickleball',
                                      child: Row(
                                        children: [
                                          Image.asset(
                                            'assets/images/pickleball.png',
                                            width: 20,
                                            height: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          const Text('Pickleball'),
                                        ],
                                      ),
                                    ),
                                    const DropdownMenuItem(
                                      value: 'football',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.sports_soccer,
                                            color: Colors.orange,
                                            size: 20,
                                          ),
                                          SizedBox(width: 8),
                                          Text('Bóng đá'),
                                        ],
                                      ),
                                    ),
                                    const DropdownMenuItem(
                                      value: 'tennis',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.sports_tennis,
                                            color: Colors.green,
                                            size: 20,
                                          ),
                                          SizedBox(width: 8),
                                          Text('Tennis'),
                                        ],
                                      ),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    if (value != null) {
                                      _selectedSportType = value;
                                    }
                                  },
                                ),
                                const SizedBox(height: 32),

                                ElevatedButton(
                                  onPressed: _isUploading
                                      ? null
                                      : () async {
                                          if (_formKey.currentState!
                                              .validate()) {
                                            if (_selectedLocation == null) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Vui lòng chọn vị trí trên bản đồ',
                                                  ),
                                                  backgroundColor:
                                                      Colors.orange,
                                                ),
                                              );
                                              return;
                                            }

                                            setDialogState(
                                              () => _isUploading = true,
                                            );
                                            final repo = context
                                                .read<SupabaseRepository>();
                                            String? imageUrlToSave =
                                                _currentImageUrl;

                                            try {
                                              if (_imageFile != null) {
                                                imageUrlToSave = await repo
                                                    .uploadImage(
                                                      _imageFile!.path,
                                                      'court_images',
                                                    );
                                              }
                                            } catch (e) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    'Lỗi upload ảnh: $e',
                                                  ),
                                                ),
                                              );
                                              setDialogState(
                                                () => _isUploading = false,
                                              );
                                              return;
                                            }

                                            final authProvider = context
                                                .read<AppAuthProvider>();
                                            final user = authProvider.userModel;
                                            final isOwner =
                                                user?.role == 'court_owner';
                                            final newCourt = CourtLocationModel(
                                              id: court?.id ?? '',
                                              name: _nameController.text,
                                              address:
                                                  _addressController.text
                                                      .trim()
                                                      .isNotEmpty
                                                  ? _addressController.text
                                                        .trim()
                                                  : _selectedAddress,
                                              latitude:
                                                  _selectedLocation!.latitude,
                                              longitude:
                                                  _selectedLocation!.longitude,
                                              pricePerHour:
                                                  double.tryParse(
                                                    _priceController.text,
                                                  ) ??
                                                  0.0,
                                              totalCourts:
                                                  int.tryParse(
                                                    _totalCourtsController.text,
                                                  ) ??
                                                  0,
                                              sportType: _selectedSportType,
                                              imageUrl: imageUrlToSave,
                                              ownerId: isOwner
                                                  ? user?.id
                                                  : court?.ownerId,
                                            );

                                            try {
                                              if (court == null) {
                                                await repo.addCourtLocation(
                                                  newCourt,
                                                );
                                              } else {
                                                await repo.updateCourtLocation(
                                                  newCourt,
                                                );
                                              }
                                              Navigator.of(context).pop();
                                            } catch (e) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    'Lỗi khi lưu sân: $e',
                                                  ),
                                                  backgroundColor: Colors.red,
                                                ),
                                              );
                                              setDialogState(
                                                () => _isUploading = false,
                                              );
                                            }
                                          }
                                        },
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    backgroundColor: Theme.of(
                                      context,
                                    ).primaryColor,
                                    foregroundColor: Colors.white,
                                    elevation: 2,
                                  ),
                                  child: _isUploading
                                      ? const SizedBox(
                                          height: 24,
                                          width: 24,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Text(
                                          'Hoàn Tất & Lưu',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
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
              ),
            );
          },
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.1),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic)),
          child: FadeTransition(opacity: anim1, child: child),
        );
      },
    );
  }

  Widget _buildSportTypeChip(String? type) {
    String label = 'Cầu lông';
    Color color = Colors.blue;
    if (type == 'pickleball') {
      label = 'Pickleball';
      color = Colors.green;
    } else if (type == 'football') {
      label = 'Bóng đá';
      color = Colors.orange;
    } else if (type == 'tennis') {
      label = 'Tennis';
      color = Colors.purple;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color.darken(0.2),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final firestoreRepo = context.watch<SupabaseRepository>();
    final user = context.watch<AppAuthProvider>().userModel;
    final isOwner = user?.role == 'court_owner';
    final ownerId = isOwner ? user?.id : null;

    final formatCurrency = NumberFormat.simpleCurrency(
      locale: 'vi_VN',
      decimalDigits: 0,
    );

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: CustomGradientAppBar(
        title: Text(isOwner ? 'Sân Của Tôi' : 'Quản Lý Thuê Sân'),
      ),
      body: StreamBuilder<List<CourtLocationModel>>(
        stream: firestoreRepo.getCourtLocationsStream(ownerId: ownerId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Lỗi: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/logo1.png',
                    width: 180,
                    height: 180,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Chưa có dịch vụ sân nào.\nBấm + để thêm cơ sở đầu tiên.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          final courts = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.only(
              top: 16,
              bottom: 100,
              left: 16,
              right: 16,
            ),
            itemCount: courts.length,
            itemBuilder: (context, index) {
              final court = courts[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header Image
                    if (court.imageUrl != null)
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                        child: Image.network(
                          court.imageUrl!,
                          height: 160,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            height: 160,
                            color: Colors.grey.shade200,
                            child: const Icon(
                              Icons.broken_image,
                              color: Colors.grey,
                              size: 40,
                            ),
                          ),
                        ),
                      )
                    else
                      Container(
                        height: 160,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                        ),
                        child: const Icon(
                          Icons.image_not_supported,
                          color: Colors.grey,
                          size: 40,
                        ),
                      ),

                    // Content
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  court.name,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              _buildSportTypeChip(court.sportType),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 16,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  court.address,
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 13,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade50,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.monetization_on_outlined,
                                      size: 16,
                                      color: Colors.amber,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${formatCurrency.format(court.pricePerHour)}/giờ',
                                      style: TextStyle(
                                        color: Colors.amber.shade900,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.sports_tennis,
                                      size: 16,
                                      color: Colors.grey.shade700,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${court.totalCourts} sân',
                                      style: TextStyle(
                                        color: Colors.grey.shade800,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Divider(height: 1),
                          ),
                          // Actions
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton.icon(
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.blue,
                                ),
                                icon: const Icon(Icons.edit_outlined, size: 18),
                                label: const Text('Chỉnh Sửa'),
                                onPressed: () =>
                                    _showCourtFormDialog(context, court: court),
                              ),
                              const SizedBox(width: 8),
                              TextButton.icon(
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.red,
                                ),
                                icon: const Icon(
                                  Icons.delete_outline,
                                  size: 18,
                                ),
                                label: const Text('Xóa'),
                                onPressed: () {
                                  DialogUtils.showConfirmDialog(
                                    context,
                                    title: 'Xóa Cơ Sở Này?',
                                    content:
                                        'Bạn có chắc chắn muốn xóa sân "${court.name}"? Tác vụ này không thể hoàn tác.',
                                    confirmText: 'Xóa Ngay',
                                    cancelText: 'Hủy Vỏ',
                                    isDestructive: true,
                                    onConfirm: () async {
                                      try {
                                        await firestoreRepo.deleteCourtLocation(
                                          court.id,
                                        );
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Đã xóa cơ sở thành công!',
                                            ),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                      } catch (e) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Lỗi khi xóa sân: $e',
                                            ),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    },
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCourtFormDialog(context),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add_business_rounded),
        label: const Text(
          'Thêm Sân Mới',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

extension ColorExtension on Color {
  Color darken([double amount = .1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }
}
