import 'package:badminton_ai/data/models/court_location_model.dart';
import 'package:badminton_ai/data/repositories/firestore_repository.dart';
import 'package:badminton_ai/screens/admin/location_picker_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

class ManageCourtsScreen extends StatefulWidget {
  const ManageCourtsScreen({super.key});

  @override
  State<ManageCourtsScreen> createState() => _ManageCourtsScreenState();
}

class _ManageCourtsScreenState extends State<ManageCourtsScreen> {
  // Hàm để hiển thị Dialog/Form thêm/sửa sân
  void _showCourtFormDialog(BuildContext context, {CourtLocationModel? court}) {
    final _formKey = GlobalKey<FormState>();
    // Dùng controller để lấy text, gán giá trị ban đầu nếu là "sửa"
    final _nameController = TextEditingController(text: court?.name);
    final _addressController = TextEditingController(text: court?.address);
    final _priceController =
        TextEditingController(text: court?.pricePerHour.toString());
    final _totalCourtsController =
        TextEditingController(text: court?.totalCourts.toString());
    
    // State cho location
    LatLng? _selectedLocation = court != null
        ? LatLng(court.latitude, court.longitude)
        : null;
    String _selectedAddress = court?.address ?? '';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              // Đổi theme cho dialog để dễ đọc trên nền tối
              backgroundColor: Colors.grey[200], // Nền sáng
              title: Text(
                court == null ? 'Thêm Sân Mới' : 'Sửa Thông Tin Sân',
                style: TextStyle(color: Theme.of(context).primaryColorDark),
              ),
              content: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                            labelText: 'Tên sân', filled: true, fillColor: Colors.white),
                        validator: (value) =>
                            value!.isEmpty ? 'Không được bỏ trống' : null,
                      ),
                      SizedBox(height: 8),
                      // Nút chọn vị trí từ Google Maps
                      ElevatedButton.icon(
                        onPressed: () async {
                          final result = await Navigator.push<Map<String, dynamic>>(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LocationPickerScreen(
                                initialLocation: _selectedLocation,
                                initialAddress: _selectedAddress,
                              ),
                            ),
                          );
                          
                          if (result != null) {
                            _selectedLocation = result['location'] as LatLng;
                            _selectedAddress = result['address'] as String;
                            _addressController.text = _selectedAddress;
                            // Trigger rebuild để hiển thị thông tin mới
                            setDialogState(() {});
                          }
                        },
                        icon: const Icon(Icons.map),
                        label: Text(_selectedLocation != null
                            ? 'Đã chọn vị trí'
                            : 'Chọn vị trí trên bản đồ'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                          backgroundColor: Theme.of(context).colorScheme.secondary,
                          foregroundColor: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      if (_selectedLocation != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue[200]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.location_on,
                                      size: 16, color: Colors.blue[700]),
                                  const SizedBox(width: 4),
                                  const Text(
                                    'Địa chỉ:',
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
                                style: TextStyle(fontSize: 12),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Tọa độ: ${_selectedLocation!.latitude.toStringAsFixed(6)}, ${_selectedLocation!.longitude.toStringAsFixed(6)}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      SizedBox(height: 8),
                      TextFormField(
                        controller: _addressController,
                        decoration: InputDecoration(
                          labelText: 'Địa chỉ (có thể chỉnh sửa)',
                          filled: true,
                          fillColor: Colors.white,
                          suffixIcon: Icon(Icons.edit, size: 18),
                        ),
                        validator: (value) =>
                            value!.isEmpty ? 'Không được bỏ trống' : null,
                      ),
                      SizedBox(height: 8),
                      TextFormField(
                        controller: _priceController,
                        decoration: InputDecoration(
                            labelText: 'Giá / giờ (VND)',
                            filled: true,
                            fillColor: Colors.white),
                        keyboardType: TextInputType.number,
                        validator: (value) =>
                            value!.isEmpty ? 'Không được bỏ trống' : null,
                      ),
                      SizedBox(height: 8),
                      TextFormField(
                        controller: _totalCourtsController,
                        decoration: InputDecoration(
                            labelText: 'Tổng số sân con (ví dụ: 4)',
                            filled: true,
                            fillColor: Colors.white),
                        keyboardType: TextInputType.number,
                        validator: (value) =>
                            value!.isEmpty ? 'Không được bỏ trống' : null,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text('Hủy'),
                ),
                ElevatedButton(
                  onPressed: () async { // Thêm async
                    if (_formKey.currentState!.validate()) {
                      // Kiểm tra đã chọn vị trí chưa
                      if (_selectedLocation == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Vui lòng chọn vị trí trên bản đồ'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                        return;
                      }

                      final newCourt = CourtLocationModel(
                        // Lấy ID cũ nếu là "sửa", rỗng nếu là "thêm mới"
                        // FirestoreRepository sẽ bỏ qua ID khi tạo mới
                        id: court?.id ?? '',
                        name: _nameController.text,
                        address: _addressController.text.trim().isNotEmpty
                            ? _addressController.text.trim()
                            : _selectedAddress,
                        latitude: _selectedLocation!.latitude,
                        longitude: _selectedLocation!.longitude,
                        pricePerHour: double.tryParse(_priceController.text) ?? 0.0,
                        totalCourts: int.tryParse(_totalCourtsController.text) ?? 0,
                      );

                      final repo = context.read<FirestoreRepository>();
                      
                      try {
                        if (court == null) {
                          // Thêm mới
                          await repo.addCourtLocation(newCourt);
                        } else {
                          // Cập nhật
                          await repo.updateCourtLocation(newCourt);
                        }
                        Navigator.of(ctx).pop();
                      } catch (e) {
                        // Hiển thị lỗi (nếu có)
                        print("Lỗi khi lưu sân: $e");
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Lỗi khi lưu sân: $e'), backgroundColor: Colors.red)
                        );
                      }
                    }
                  },
                  child: Text('Lưu'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Dùng context.watch để lắng nghe thay đổi
    final firestoreRepo = context.watch<FirestoreRepository>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Quản Lý Các Sân'),
      ),
      // Dùng StreamBuilder để tự động cập nhật khi có sân mới
      body: StreamBuilder<List<CourtLocationModel>>(
        stream: firestoreRepo.getCourtLocationsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
                child: Text('Lỗi: ${snapshot.error}',
                    style: TextStyle(color: Colors.white)));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
                child: Text('Chưa có sân nào. Hãy thêm sân mới.',
                    style: TextStyle(color: Colors.white)));
          }

          final courts = snapshot.data!;
          return ListView.builder(
            itemCount: courts.length,
            itemBuilder: (context, index) {
              final court = courts[index];
              return Card(
                color: Colors.white, // Nền card màu trắng
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(court.name,
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.black)),
                  subtitle: Text(
                      "${court.address}\n${court.pricePerHour} VND/giờ - ${court.totalCourts} sân con",
                      style: TextStyle(color: Colors.black87)),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit,
                            color: Theme.of(context).colorScheme.secondary),
                        onPressed: () =>
                            _showCourtFormDialog(context, court: court),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          // Thêm dialog xác nhận xóa
                          showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                    title: Text('Xác nhận xóa'),
                                    content: Text(
                                        'Bạn có chắc muốn xóa sân "${court.name}" không?'),
                                    actions: [
                                      TextButton(
                                          onPressed: () =>
                                              Navigator.of(ctx).pop(),
                                          child: Text('Hủy')),
                                      TextButton(
                                          onPressed: () async { // Thêm async
                                            try {
                                              await firestoreRepo
                                                .deleteCourtLocation(court.id);
                                              Navigator.of(ctx).pop();
                                            } catch (e) {
                                               print("Lỗi khi xóa sân: $e");
                                               Navigator.of(ctx).pop();
                                               ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(content: Text('Lỗi khi xóa sân: $e'), backgroundColor: Colors.red)
                                                );
                                            }
                                          },
                                          child: Text('Xóa',
                                              style: TextStyle(
                                                  color: Colors.red))),
                                    ],
                                  ));
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCourtFormDialog(context),
        child: Icon(Icons.add),
        tooltip: 'Thêm Sân Mới',
      ),
    );
  }
}

