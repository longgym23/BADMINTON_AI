import 'package:badminton_ai/data/models/user_model.dart';
import 'package:badminton_ai/providers/auth_provider.dart';
import 'package:badminton_ai/providers/friend_provider.dart';
import 'package:badminton_ai/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:badminton_ai/widgets/app_toast.dart';
class AddFriendScreen extends StatefulWidget {
  const AddFriendScreen({super.key});

  @override
  State<AddFriendScreen> createState() => _AddFriendScreenState();
}

class _AddFriendScreenState extends State<AddFriendScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;
  UserModel? _searchedUser;
  String? _errorMessage;

  Future<void> _search() async {
    final phone = _searchController.text.trim();
    if (phone.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _searchedUser = null;
    });

    final friendProvider = context.read<FriendProvider>();
    final user = await friendProvider.searchUserByPhone(phone);

    setState(() {
      _isLoading = false;
      if (user != null) {
        // Không cho phép tự kết bạn với chính mình
        final myId = context.read<AppAuthProvider>().userModel?.id;
        if (user.id == myId) {
          _errorMessage = "Đây là số điện thoại của bạn.";
        } else {
          _searchedUser = user;
        }
      } else {
        _errorMessage = "Không tìm thấy người dùng với số điện thoại này.";
      }
    });
  }

  Future<void> _sendRequest() async {
    if (_searchedUser == null) return;

    final myId = context.read<AppAuthProvider>().userModel?.id;
    if (myId == null) return;

    try {
      await context.read<FriendProvider>().sendFriendRequest(
        myId,
        _searchedUser!.id,
      );

      if (!mounted) return;
      AppToast.show(context, 'Đã gửi lời mời kết bạn!', type: ToastType.success);
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Chưa gửi được: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Thêm bạn bè"),
        backgroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      hintText: "Nhập số điện thoại...",
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onSubmitted: (_) => _search(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(onPressed: _search, child: const Text("Tìm")),
              ],
            ),
            const SizedBox(height: 24),
            if (_isLoading) const CircularProgressIndicator(),
            if (_errorMessage != null)
              Text(
                _errorMessage!,
                style: const TextStyle(color: AppColors.error),
              ),
            if (_searchedUser != null)
              ListTile(
                leading: CircleAvatar(
                  backgroundImage: _searchedUser!.photoUrl != null
                      ? NetworkImage(_searchedUser!.photoUrl!)
                      : null,
                  child: _searchedUser!.photoUrl == null
                      ? const Icon(Icons.person)
                      : null,
                ),
                title: Text(
                  _searchedUser!.displayName ?? 'Người dùng không tên',
                ),
                subtitle: Text(_searchedUser!.phoneNumber ?? ''),
                trailing: ElevatedButton(
                  onPressed: _sendRequest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  child: const Text("Kết bạn"),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
