import 'package:badminton_ai/widgets/custom_gradient_app_bar.dart';
import 'package:badminton_ai/data/models/user_model.dart';
import 'package:badminton_ai/data/repositories/supabase_repository.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:badminton_ai/providers/auth_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:badminton_ai/viewmodels/manage_users_viewmodel.dart';
import 'package:badminton_ai/utils/app_colors.dart';
import 'package:badminton_ai/widgets/app_toast.dart';
import 'package:badminton_ai/utils/dialog_utils.dart';
import 'package:flutter/cupertino.dart';

class ManageUsersScreen extends StatelessWidget {
  const ManageUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ManageUsersViewModel(),
      child: const _ManageUsersView(),
    );
  }
}

class _ManageUsersView extends StatefulWidget {
  const _ManageUsersView();

  @override
  State<_ManageUsersView> createState() => _ManageUsersViewState();
}

class _ManageUsersViewState extends State<_ManageUsersView> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showUserEditDialog(BuildContext context, UserModel user) {
    final _formKey = GlobalKey<FormState>();
    final _nameController = TextEditingController(text: user.displayName);
    final _emailController = TextEditingController(text: user.email);
    final _phoneController = TextEditingController(text: user.phoneNumber);
    String _selectedRole = user.role;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Cập nhật người dùng', style: TextStyle(fontWeight: FontWeight.bold)),
              content: Material(
                color: Colors.transparent,
                child: Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Form(
                    key: _formKey,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(labelText: 'Tên hiển thị', filled: true, fillColor: Colors.white),
                            validator: (value) => value!.isEmpty ? 'Không được bỏ trống' : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _emailController,
                            decoration: const InputDecoration(labelText: 'Email', filled: true, fillColor: Colors.white),
                            enabled: false,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _phoneController,
                            decoration: const InputDecoration(labelText: 'Số điện thoại', filled: true, fillColor: Colors.white),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: _selectedRole,
                            decoration: const InputDecoration(labelText: 'Vai trò', filled: true, fillColor: Colors.white),
                            items: const [
                              DropdownMenuItem(value: 'user', child: Text('Người dùng')),
                              DropdownMenuItem(value: 'court_owner', child: Text('Chủ sân')),
                              DropdownMenuItem(value: 'admin', child: Text('Quản trị viên')),
                            ],
                            onChanged: (value) {
                              if (value != null) setDialogState(() => _selectedRole = value);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Hủy', style: TextStyle(color: Colors.blue))),
                TextButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      try {
                        final repo = ctx.read<SupabaseRepository>();
                        final updatedUser = user.copyWith(
                          displayName: _nameController.text.trim(),
                          phoneNumber: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
                          role: _selectedRole,
                        );
                        await repo.updateUser(updatedUser);
                        if (!ctx.mounted) return;
                        Navigator.of(ctx).pop();
                        AppToast.show(context, 'Cập nhật thành công!', type: ToastType.success);
                        setState(() {});
                      } catch (e) {
                        AppToast.show(context, 'Lỗi: \$e', type: ToastType.error);
                      }
                    }
                  },
                  child: const Text('Lưu', style: TextStyle(color: Colors.blue)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, UserModel user) {
    DialogUtils.showConfirmDialog(
      context,
      title: 'Xác nhận xóa',
      content: 'Bạn có chắc muốn xóa người dùng "${user.displayName ?? user.email}" không?',
      confirmText: 'Xóa',
      isDestructive: true,
      onConfirm: () async {
        try {
          await context.read<SupabaseRepository>().deleteUser(user.id);
          if (!context.mounted) return;
          AppToast.show(context, 'Đã xóa người dùng.', type: ToastType.success);
          setState(() {});
        } catch (e) {
          AppToast.show(context, 'Lỗi: $e', type: ToastType.error);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ManageUsersViewModel>();
    final repo = context.watch<SupabaseRepository>();
    final auth = context.watch<AppAuthProvider>();

    if (auth.userModel?.role != 'admin') {
      return const Scaffold(body: Center(child: Text('Chỉ Admin mới có quyền truy cập trang này.')));
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomGradientAppBar(title: const Text('Quản lý Người dùng')),
      body: Column(
        children: [
          // Search & Filter Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm tên, email, sđt...',
                    prefixIcon: const Icon(Icons.search, color: AppColors.brandOrange),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(icon: const Icon(Icons.clear), onPressed: () {
                            setState(() => _searchController.clear());
                            vm.setSearchQuery('');
                          })
                        : null,
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                  onChanged: (value) => vm.setSearchQuery(value),
                ),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(label: 'Tất cả', isSelected: vm.selectedRole == 'all', onTap: () => vm.setSelectedRole('all')),
                      const SizedBox(width: 8),
                      _FilterChip(label: 'Admin', isSelected: vm.selectedRole == 'admin', onTap: () => vm.setSelectedRole('admin')),
                      const SizedBox(width: 8),
                      _FilterChip(label: 'Chủ sân', isSelected: vm.selectedRole == 'court_owner', onTap: () => vm.setSelectedRole('court_owner')),
                      const SizedBox(width: 8),
                      _FilterChip(label: 'User', isSelected: vm.selectedRole == 'user', onTap: () => vm.setSelectedRole('user')),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // User List
          Expanded(
            child: StreamBuilder<List<UserModel>>(
              stream: repo.getAllUsersStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (snapshot.hasError) return Center(child: Text('Lỗi: ${snapshot.error}'));

                final allUsers = snapshot.data ?? [];
                final filtered = vm.applyFilters(allUsers);

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_search, size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text('Không tìm thấy người dùng nào.', style: TextStyle(color: Colors.grey[500])),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final user = filtered[index];
                    return _UserCard(
                      user: user,
                      onEdit: () => _showUserEditDialog(context, user),
                      onDelete: () => _showDeleteConfirmDialog(context, user),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.brandOrange : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppColors.brandOrange : Colors.transparent),
        ),
        child: Text(
          label,
          style: TextStyle(color: isSelected ? Colors.white : Colors.grey[600], fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, fontSize: 13),
        ),
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final UserModel user;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _UserCard({required this.user, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    Color roleColor;
    String roleName;
    switch (user.role) {
      case 'admin':
        roleColor = Colors.red;
        roleName = 'Admin';
        break;
      case 'court_owner':
        roleColor = Colors.orange;
        roleName = 'Chủ sân';
        break;
      default:
        roleColor = AppColors.primary;
        roleName = 'User';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey[200]!)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: roleColor.withValues(alpha: 0.1),
              child: user.photoUrl != null && user.photoUrl!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: CachedNetworkImage(
                        imageUrl: user.photoUrl!,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const CircularProgressIndicator(strokeWidth: 2),
                        errorWidget: (context, url, error) => Text(
                          (user.displayName ?? user.email ?? 'U').substring(0, 1).toUpperCase(),
                          style: TextStyle(color: roleColor, fontWeight: FontWeight.bold),
                        ),
                      ),
                    )
                  : Text(
                      (user.displayName ?? user.email ?? 'U').substring(0, 1).toUpperCase(),
                      style: TextStyle(color: roleColor, fontWeight: FontWeight.bold),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.displayName ?? 'Chưa có tên', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.email, size: 12, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Expanded(child: Text(user.email ?? '', style: TextStyle(color: Colors.grey[600], fontSize: 12), overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: roleColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                    child: Text(roleName, style: TextStyle(color: roleColor, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(icon: Icon(Icons.edit_outlined, color: Colors.blue[700], size: 20), onPressed: onEdit),
                IconButton(icon: Icon(Icons.delete_outline, color: Colors.red[700], size: 20), onPressed: onDelete),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

