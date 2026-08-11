import 'package:easy_localization/easy_localization.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:badminton_ai/core/design_system/components/ui/custom_gradient_app_bar.dart';
import 'package:badminton_ai/core/data/models/court_location_model.dart';
import 'package:image_picker/image_picker.dart';
import 'package:badminton_ai/modules/auth/viewmodels/auth_provider.dart';
import 'package:badminton_ai/core/data/repositories/supabase_repository.dart';
import 'package:badminton_ai/modules/admin/views/pages/location_picker_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:badminton_ai/core/utils/dialog_utils.dart';

class ManageCourtsScreen extends StatefulWidget {
  const ManageCourtsScreen({super.key});

  @override
  State<ManageCourtsScreen> createState() => _ManageCourtsScreenState();
}

class _ManageCourtsScreenState extends State<ManageCourtsScreen> {
  // Biến state cho Dialog/Form
  void _showCourtFormDialog(BuildContext context, {CourtLocationModel? court}) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: court?.name);
    final addressController = TextEditingController(text: court?.address);
    final priceController = TextEditingController(
      text: court?.pricePerHour.toString(),
    );
    final totalCourtsController = TextEditingController(
      text: court?.totalCourts.toString(),
    );
    final linkController = TextEditingController();

    LatLng? selectedLocation = court != null
        ? LatLng(court.latitude, court.longitude)
        : null;
    String selectedAddress = court?.address ?? '';
    String selectedSportType = court?.sportType ?? 'badminton';

    File? imageFile;
    String? currentImageUrl = court?.imageUrl;
    final imagePicker = ImagePicker();
    bool isUploading = false;
    bool isScanningLink = false;

    Future<void> scanLocationFromLink(
      String link,
      StateSetter setDialogState,
    ) async {
      if (link.isEmpty) return;
      setDialogState(() => isScanningLink = true);

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
          selectedLocation = LatLng(lat, lng);
          selectedAddress = 'screens.coordinatesTakenFromLinkP'.tr();
          addressController.text = selectedAddress;

          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('screens.coordinatesSuccessfullyFound'.tr()),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          throw Exception('screens.noCoordinatesFoundInTheLi'.tr());
        }
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: Không thể lấy tọa độ từ link này. $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setDialogState(() => isScanningLink = false);
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
                                  ? 'screens.stationAddsNewYard'.tr()
                                  : 'screens.editCourseInformation'.tr(),
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
                            key: formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Ảnh minh họa
                                GestureDetector(
                                  onTap: () async {
                                    final pickedFile = await imagePicker
                                        .pickImage(source: ImageSource.gallery);
                                    if (pickedFile != null) {
                                      setDialogState(() {
                                        imageFile = File(pickedFile.path);
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
                                      image: imageFile != null
                                          ? DecorationImage(
                                              image: FileImage(imageFile!),
                                              fit: BoxFit.cover,
                                            )
                                          : (currentImageUrl != null
                                                ? DecorationImage(
                                                    image: NetworkImage(
                                                      currentImageUrl,
                                                    ),
                                                    fit: BoxFit.cover,
                                                  )
                                                : null),
                                    ),
                                    child:
                                        imageFile == null &&
                                            currentImageUrl == null
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
                                                'screens.uploadACoverPhoto'
                                                    .tr(),
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
                                  controller: nameController,
                                  decoration: inputDecoration.copyWith(
                                    labelText: 'screens.nameOfTheYardFacility'
                                        .tr(),
                                  ),
                                  validator: (value) => value!.isEmpty
                                      ? 'screens.cannotBeLeftBlank'.tr()
                                      : null,
                                ),
                                const SizedBox(height: 16),

                                // Link & Tính năng get Tọa độ
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: linkController,
                                        decoration: inputDecoration.copyWith(
                                          labelText:
                                              'screens.pasteTheGoogleMapsLink'
                                                  .tr(),
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
                                        onPressed: isScanningLink
                                            ? null
                                            : () => scanLocationFromLink(
                                                linkController.text.trim(),
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
                                        child: isScanningLink
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
                                                      selectedLocation,
                                                  initialAddress:
                                                      selectedAddress,
                                                ),
                                          ),
                                        );

                                    if (result != null) {
                                      selectedLocation =
                                          result['location'] as LatLng;
                                      selectedAddress =
                                          result['address'] as String;
                                      addressController.text =
                                          selectedAddress;
                                      setDialogState(() {});
                                    }
                                  },
                                  icon: const Icon(Icons.map_outlined),
                                  label: Text(
                                    selectedLocation != null
                                        ? 'screens.fixedLocationOnMap'.tr()
                                        : 'screens.selectLocationManually'.tr(),
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

                                if (selectedLocation != null) ...[
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
                                            Text(
                                              'screens.coordinatesIdentified'
                                                  .tr(),
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          selectedAddress,
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 16),

                                TextFormField(
                                  controller: addressController,
                                  decoration: inputDecoration.copyWith(
                                    labelText:
                                        'screens.specificAddressCanBeEdite'
                                            .tr(),
                                    suffixIcon: const Icon(
                                      Icons.edit_location_alt,
                                      size: 20,
                                    ),
                                  ),
                                  validator: (value) => value!.isEmpty
                                      ? 'screens.changeOfAddress'.tr()
                                      : null,
                                ),
                                const SizedBox(height: 16),

                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: priceController,
                                        decoration: inputDecoration.copyWith(
                                          labelText: 'screens.rentalPriceHour'
                                              .tr(),
                                          suffixText: 'screens.vND'.tr(),
                                        ),
                                        keyboardType: TextInputType.number,
                                        validator: (value) => value!.isEmpty
                                            ? 'screens.enterPrice'.tr()
                                            : null,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: TextFormField(
                                        controller: totalCourtsController,
                                        decoration: inputDecoration.copyWith(
                                          labelText: 'screens.subyardNumber'
                                              .tr(),
                                        ),
                                        keyboardType: TextInputType.number,
                                        validator: (value) => value!.isEmpty
                                            ? 'screens.enterNumber'.tr()
                                            : null,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                DropdownButtonFormField<String>(
                                  initialValue: selectedSportType,
                                  decoration: inputDecoration.copyWith(
                                    labelText: 'screens.typeOfBusiness'.tr(),
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
                                          Text('screens.badminton'.tr()),
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
                                    DropdownMenuItem(
                                      value: 'football',
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.sports_soccer,
                                            color: Colors.orange,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Text('screens.football'.tr()),
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
                                      selectedSportType = value;
                                    }
                                  },
                                ),
                                const SizedBox(height: 32),

                                ElevatedButton(
                                  onPressed: isUploading
                                      ? null
                                      : () async {
                                          if (formKey.currentState!
                                              .validate()) {
                                            if (selectedLocation == null) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    'screens.pleaseSelectLocationOnThe'
                                                        .tr(),
                                                  ),
                                                  backgroundColor:
                                                      Colors.orange,
                                                ),
                                              );
                                              return;
                                            }

                                            setDialogState(
                                              () => isUploading = true,
                                            );
                                            final repo = context
                                                .read<SupabaseRepository>();
                                            String? imageUrlToSave =
                                                currentImageUrl;

                                            try {
                                              if (imageFile != null) {
                                                imageUrlToSave = await repo
                                                    .uploadImage(
                                                      imageFile!.path,
                                                      'court_images',
                                                    );
                                              }
                                            } catch (e) {
                                              if (!context.mounted) return;
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
                                                () => isUploading = false,
                                              );
                                              return;
                                            }

                                            if (!context.mounted) return;
                                            final authProvider = context
                                                .read<AppAuthProvider>();
                                            final user = authProvider.userModel;
                                            final isOwner =
                                                user?.role == 'court_owner';
                                            final newCourt = CourtLocationModel(
                                              id: court?.id ?? '',
                                              name: nameController.text,
                                              address:
                                                  addressController.text
                                                      .trim()
                                                      .isNotEmpty
                                                  ? addressController.text
                                                        .trim()
                                                  : selectedAddress,
                                              latitude:
                                                  selectedLocation!.latitude,
                                              longitude:
                                                  selectedLocation!.longitude,
                                              pricePerHour:
                                                  double.tryParse(
                                                    priceController.text,
                                                  ) ??
                                                  0.0,
                                              totalCourts:
                                                  int.tryParse(
                                                    totalCourtsController.text,
                                                  ) ??
                                                  0,
                                              sportType: selectedSportType,
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
                                              if (!context.mounted) return;
                                              Navigator.of(context).pop();
                                            } catch (e) {
                                              if (!context.mounted) return;
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
                                                () => isUploading = false,
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
                                  child: isUploading
                                      ? const SizedBox(
                                          height: 24,
                                          width: 24,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : Text(
                                          'screens.completeSave'.tr(),
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
    String label = 'screens.badminton'.tr();
    Color color = Colors.blue;
    if (type == 'pickleball') {
      label = 'Pickleball';
      color = Colors.green;
    } else if (type == 'football') {
      label = 'screens.football'.tr();
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
        title: Text(
          isOwner
              ? 'screens.myYard'.tr()
              : 'screens.stadiumRentalManagement'.tr(),
        ),
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
                    'screens.thereAreNoYardServicesYet'.tr(),
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
                      color: Colors.black.withValues(alpha: 0.04),
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
                                label: Text('screens.edit'.tr()),
                                onPressed: () =>
                                    _showCourtFormDialog(context, court: court),
                              ),
                              const SizedBox(width: 8),
                              TextButton.icon(
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.red,
                                ),
                                icon: const Icon(
                                  Icons.delete_forever,
                                  size: 18,
                                ),
                                label: Text('screens.erase'.tr()),
                                onPressed: () {
                                  DialogUtils.showConfirmDialog(
                                    context,
                                    title: 'screens.deleteThisFacility'.tr(),
                                    content:
                                        'Bạn có chắc chắn muốn xóa sân "${court.name}"? Tác vụ này không thể hoàn tác.',
                                    confirmText: 'screens.deleteNow'.tr(),
                                    cancelText: 'screens.cancelShell'.tr(),
                                    isDestructive: true,
                                    onConfirm: () async {
                                      try {
                                        await firestoreRepo.deleteCourtLocation(
                                          court.id,
                                        );
                                        if (!context.mounted) return;
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'screens.facilityDeletedSuccessfully'
                                                  .tr(),
                                            ),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                      } catch (e) {
                                        if (!context.mounted) return;
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
        label: Text(
          'screens.addNewYard'.tr(),
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
