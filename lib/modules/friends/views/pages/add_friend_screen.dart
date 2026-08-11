import 'package:badminton_ai/core/data/models/user_model.dart';
import 'package:badminton_ai/modules/auth/viewmodels/auth_provider.dart';
import 'package:badminton_ai/modules/friends/viewmodels/friend_provider.dart';
import 'package:badminton_ai/core/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:badminton_ai/core/design_system/components/ui/app_toast.dart';
import 'package:easy_localization/easy_localization.dart';

class AddFriendScreen extends StatefulWidget {
  const AddFriendScreen({super.key});

  @override
  State<AddFriendScreen> createState() => _AddFriendScreenState();
}

class _AddFriendScreenState extends State<AddFriendScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  bool _isActing = false;
  UserModel? _searchedUser;
  String? _errorMessage;

  /// Trạng thái quan hệ: 'none' | 'pending_sent' | 'pending_received' | 'accepted'
  String _relationship = 'none';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final phone = _searchController.text.trim();
    if (phone.isEmpty) return;

    setState(() {
      _isSearching = true;
      _errorMessage = null;
      _searchedUser = null;
      _relationship = 'none';
    });

    final friendProvider = context.read<FriendProvider>();
    final myId = context.read<AppAuthProvider>().userModel?.id;
    final user = await friendProvider.searchUserByPhone(phone);

    if (!mounted) return;

    if (user == null) {
      setState(() {
        _isSearching = false;
        _errorMessage = 'screens.noUsersWereFoundWithThis'.tr();
      });
      return;
    }

    if (user.id == myId) {
      setState(() {
        _isSearching = false;
        _errorMessage = 'screens.thisIsYourPhoneNumber'.tr();
      });
      return;
    }

    // Kiểm tra trạng thái quan hệ
    final relationship = myId != null
        ? await friendProvider.checkRelationship(myId, user.id)
        : 'none';

    if (!mounted) return;
    setState(() {
      _isSearching = false;
      _searchedUser = user;
      _relationship = relationship;
    });
  }

  Future<void> _sendRequest() async {
    if (_searchedUser == null || _isActing) return;

    final myId = context.read<AppAuthProvider>().userModel?.id;
    if (myId == null) return;

    setState(() => _isActing = true);

    try {
      await context.read<FriendProvider>().sendFriendRequest(
        myId,
        _searchedUser!.id,
      );

      if (!mounted) return;
      AppToast.show(
        context,
        'screens.friendRequestSent'.tr(),
        type: ToastType.success,
      );
      setState(() {
        _relationship = 'pending_sent';
        _isActing = false;
      });
    } on Exception catch (e) {
      if (!mounted) return;
      setState(() => _isActing = false);

      final msg = e.toString();
      if (msg.contains('already_friends')) {
        setState(() => _relationship = 'accepted');
      } else if (msg.contains('already_pending')) {
        setState(() => _relationship = 'pending_sent');
        AppToast.show(
          context,
          'Đã gửi lời mời kết bạn trước đó.',
          type: ToastType.error,
        );
      } else {
        AppToast.show(
          context,
          'Không thể gửi lời mời: $msg',
          type: ToastType.error,
        );
      }
    }
  }

  // ─── Trailing button theo trạng thái ────────────────────────────────────────

  Widget _buildTrailingButton() {
    switch (_relationship) {
      case 'accepted':
        return Chip(
          label: Text(
            'screens.friend'.tr(),
            style: const TextStyle(color: VColors.brandPrimary),
          ),
          backgroundColor: VColors.brandPrimarySubdued,
          side: const BorderSide(color: VColors.brandPrimary),
          avatar: const Icon(
            Icons.check_circle,
            color: VColors.brandPrimary,
            size: 16,
          ),
        );

      case 'pending_sent':
        return Chip(
          label: Text(
            'Đã gửi lời mời',
            style: const TextStyle(color: VColors.textSecondary),
          ),
          backgroundColor: Colors.grey.shade100,
        );

      case 'pending_received':
        return ElevatedButton(
          onPressed: _isActing ? null : _acceptRequest,
          style: ElevatedButton.styleFrom(backgroundColor: VColors.statusSuccess),
          child: _isActing
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text('screens.accept'.tr()),
        );

      default: // 'none'
        return ElevatedButton(
          onPressed: _isActing ? null : _sendRequest,
          style: ElevatedButton.styleFrom(backgroundColor: VColors.brandPrimary),
          child: _isActing
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text('screens.makeFriend'.tr()),
        );
    }
  }

  Future<void> _acceptRequest() async {
    if (_searchedUser == null || _isActing) return;
    final myId = context.read<AppAuthProvider>().userModel?.id;
    if (myId == null) return;

    setState(() => _isActing = true);
    try {
      await context.read<FriendProvider>().acceptFriendRequest(
        myId,
        _searchedUser!.id,
      );
      if (!mounted) return;
      setState(() {
        _relationship = 'accepted';
        _isActing = false;
      });
      AppToast.show(
        context,
        'screens.acceptSuccess'.tr(),
        type: ToastType.success,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isActing = false);
      AppToast.show(context, 'Lỗi: $e', type: ToastType.error);
    }
  }

  // ─── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VColors.background,
      appBar: AppBar(
        title: Text('screens.addFriends'.tr()),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // ── Search bar ──────────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      hintText: 'screens.enterPhoneNumber1'.tr(),
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    onSubmitted: (_) => _search(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isSearching ? null : _search,
                  child: _isSearching
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text('screens.find'.tr()),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ── Error message ───────────────────────────────────────────────
            if (_errorMessage != null)
              Text(
                _errorMessage!,
                style: const TextStyle(color: VColors.statusCritical),
              ),

            // ── Result ─────────────────────────────────────────────────────
            if (_searchedUser != null)
              Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: VColors.borderDefault),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: CircleAvatar(
                    backgroundImage: _searchedUser!.photoUrl != null
                        ? NetworkImage(_searchedUser!.photoUrl!)
                        : null,
                    backgroundColor: VColors.brandPrimarySubdued,
                    child: _searchedUser!.photoUrl == null
                        ? const Icon(Icons.person, color: VColors.brandPrimary)
                        : null,
                  ),
                  title: Text(
                    _searchedUser!.displayName ?? 'screens.anonymousUser'.tr(),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(_searchedUser!.phoneNumber ?? ''),
                  trailing: _buildTrailingButton(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
