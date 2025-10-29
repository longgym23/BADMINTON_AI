import 'package:badminton_ai/data/models/court_location_model.dart';
import 'package:badminton_ai/data/repositories/firestore_repository.dart';
import 'package:flutter/material.dart';
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
    final _latController =
        TextEditingController(text: court?.latitude.toString());
    final _lngController =
        TextEditingController(text: court?.longitude.toString());
    final _priceController =
        TextEditingController(text: court?.pricePerHour.toString());
    final _totalCourtsController =
        TextEditingController(text: court?.totalCourts.toString());

    showDialog(
      context: context,
      builder: (ctx) {
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
                  TextFormField(
                    controller: _addressController,
                    decoration: InputDecoration(
                        labelText: 'Địa chỉ', filled: true, fillColor: Colors.white),
                    validator: (value) =>
                        value!.isEmpty ? 'Không được bỏ trống' : null,
                  ),
                  SizedBox(height: 8),
                  TextFormField(
                    controller: _latController,
                    decoration: InputDecoration(
                        labelText: 'Vĩ độ (Latitude)',
                        filled: true,
                        fillColor: Colors.white),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    validator: (value) =>
                        value!.isEmpty ? 'Không được bỏ trống' : null,
                  ),
                  SizedBox(height: 8),
                  TextFormField(
                    controller: _lngController,
                    decoration: InputDecoration(
                        labelText: 'Kinh độ (Longitude)',
                        filled: true,
                        fillColor: Colors.white),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
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
                  final newCourt = CourtLocationModel(
                    // Lấy ID cũ nếu là "sửa", rỗng nếu là "thêm mới"
                    // FirestoreRepository sẽ bỏ qua ID khi tạo mới
                    id: court?.id ?? '',
                    name: _nameController.text,
                    address: _addressController.text,
                    latitude: double.tryParse(_latController.text) ?? 0.0,
                    longitude: double.tryParse(_lngController.text) ?? 0.0,
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

