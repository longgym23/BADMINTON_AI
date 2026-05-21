import 'package:easy_localization/easy_localization.dart';
import 'package:badminton_ai/data/models/user_model.dart';

import 'package:badminton_ai/providers/auth_provider.dart';
import 'package:badminton_ai/providers/friend_provider.dart';
import 'package:badminton_ai/screens/user/friends/add_friend_screen.dart';
import 'package:badminton_ai/screens/user/chat/chat_rooms_list_screen.dart';
import 'package:badminton_ai/screens/user/chat/create_group_screen.dart';
import 'package:badminton_ai/screens/user/chat/direct_chat_screen.dart';
import 'package:badminton_ai/data/repositories/chat_room_repository.dart';
import 'package:badminton_ai/utils/app_colors.dart';
import 'package:badminton_ai/utils/snackbar_utils.dart';
import 'package:badminton_ai/utils/dialog_utils.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';

class FriendsMainScreen extends StatefulWidget {
  const FriendsMainScreen({super.key});

  @override
  State<FriendsMainScreen> createState() => _FriendsMainScreenState();
}

class _FriendsMainScreenState extends State<FriendsMainScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AppAuthProvider>().userModel?.id;
      if (userId != null) {
        context.read<FriendProvider>().startListening(userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: _TabIndexListener(
        onTabChanged: (int index) {},
        builder: (context, currentTab) => Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            centerTitle: false,
            title: Text(
              'screens.community'.tr(),
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppColors.textBlack,
                letterSpacing: -0.5,
              ),
            ),
            backgroundColor: Colors.white.withValues(alpha: 0.8),
            elevation: 0,
            actions: [
              IconButton(
                icon: Container(
                  padding: EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person_add,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddFriendScreen()),
                ),
              ),
              SizedBox(width: 8),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: TabBar(
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.textGrey,
                  indicatorColor: AppColors.primary,
                  indicatorWeight: 4,
                  indicatorSize: TabBarIndicatorSize.label,
                  labelPadding: EdgeInsets.symmetric(horizontal: 16),
                  labelStyle: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    letterSpacing: -0.4,
                  ),
                  unselectedLabelStyle: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    letterSpacing: -0.4,
                  ),
                  dividerColor: Colors.transparent,
                  tabs: [
                    Tab(text: 'screens.individual'.tr()),
                    Tab(text: 'screens.group'.tr()),
                    Tab(text: 'screens.friend'.tr()),
                    Tab(text: 'screens.invitation'.tr()),
                  ],
                ),
              ),
            ),
          ),
          floatingActionButton: currentTab == 0
              ? Padding(
                  padding: EdgeInsets.only(bottom: 100.0),
                  child: FloatingActionButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CreateGroupScreen(),
                      ),
                    ),
                    backgroundColor: AppColors.primary,
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(Icons.edit_square, color: Colors.white),
                  ),
                )
              : null,
          body: const TabBarView(
            children: [
              ChatRoomsListScreen(isEmbedded: true, roomType: 'direct'),
              ChatRoomsListScreen(isEmbedded: true, roomType: 'group'),
              _FriendsListTab(),
              _PendingRequestsTab(),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Tab index listener để track tab hiện tại cho FAB
// ─────────────────────────────────────────────
class _TabIndexListener extends StatefulWidget {
  final Widget Function(BuildContext context, int currentTab) builder;
  final void Function(int index) onTabChanged;

  const _TabIndexListener({required this.builder, required this.onTabChanged});

  @override
  State<_TabIndexListener> createState() => _TabIndexListenerState();
}

class _TabIndexListenerState extends State<_TabIndexListener> {
  TabController? _controller;
  int _currentTab = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newController = DefaultTabController.of(context);
    if (newController != _controller) {
      _controller?.removeListener(_handleTabChange);
      _controller = newController;
      _controller?.addListener(_handleTabChange);
    }
  }

  void _handleTabChange() {
    final index = _controller?.index ?? 0;
    if (index != _currentTab) {
      setState(() => _currentTab = index);
      widget.onTabChanged(index);
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_handleTabChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _currentTab);
}

// ─────────────────────────────────────────────
class _FriendsListTab extends StatefulWidget {
  const _FriendsListTab();
  @override
  State<_FriendsListTab> createState() => _FriendsListTabState();
}

class _FriendsListTabState extends State<_FriendsListTab> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSearchField(),
        Expanded(
          child: Consumer<FriendProvider>(
            builder: (context, provider, child) {
              var friends = provider.friends;

              if (_searchQuery.isNotEmpty) {
                final q = _searchQuery.toLowerCase();
                friends = friends
                    .where(
                      (f) =>
                          (f.displayName ?? '').toLowerCase().contains(q) ||
                          (f.phoneNumber ?? '').toLowerCase().contains(q),
                    )
                    .toList();
              }

              if (friends.isEmpty) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.group, size: 60, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('screens.noFriendsFound'.tr()),
                  ],
                );
              }

              return ListView.builder(
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                itemCount: friends.length,
                itemBuilder: (context, index) {
                  final friend = friends[index];
                  return Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: _FriendCard(friend: friend),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: Colors.grey[200]!.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Builder(
          builder: (context) {
            return TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'home_screen.searchNameOrPhone'.tr(),
                hintStyle: TextStyle(color: Colors.grey[500], fontSize: 13),
                prefixIcon: Icon(
                  Icons.search,
                  color: Colors.grey[500],
                  size: 20,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 10),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _FriendCard extends StatelessWidget {
  final UserModel friend;
  const _FriendCard({required this.friend});

  @override
  Widget build(BuildContext context) {
    final bool isOnline = friend.status == 'online';

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.9),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: ListTile(
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: Stack(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.5),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(27),
                      child: friend.photoUrl != null
                          ? Image.network(friend.photoUrl!, fit: BoxFit.cover)
                          : Icon(
                              Icons.person,
                              color: AppColors.primary.withValues(alpha: 0.7),
                            ),
                    ),
                  ),
                  if (isOnline)
                    Positioned(
                      right: 0,
                      bottom: 2,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2.5),
                        ),
                      ),
                    )
                  else
                    Positioned(
                      right: 0,
                      bottom: 2,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.grey[400],
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2.5),
                        ),
                      ),
                    ),
                ],
              ),
              title: Text(
                friend.displayName ?? 'screens.anonymousUser'.tr(),
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textBlack,
                ),
              ),
              subtitle: Text(
                friend.phoneNumber ?? '',
                style: TextStyle(
                  color: AppColors.textGrey.withValues(alpha: 0.9),
                  fontSize: 12,
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.message_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      onPressed: () async {
                        final myId = context
                            .read<AppAuthProvider>()
                            .userModel
                            ?.id;
                        if (myId == null) return;

                        try {
                          final roomId = await context
                              .read<ChatRoomRepository>()
                              .createDirectRoom(myId, friend.id);
                          if (!context.mounted) return;
                          final room = ChatRoom(
                            id: roomId,
                            isGroup: false,
                            createdAt: DateTime.now(),
                          );
                          room.displayTitle =
                              friend.displayName ?? 'screens.user'.tr();
                          room.displayAvatar = friend.photoUrl;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  DirectChatScreen(room: room),
                            ),
                          );
                        } catch (e) {
                          if (context.mounted) {
                            SnackbarUtils.showError(
                              context,
                              'Lỗi tạo phòng: $e',
                            );
                          }
                        }
                      },
                    ),
                  ),
                  SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.person_remove,
                        color: AppColors.error,
                        size: 20,
                      ),
                      onPressed: () {
                        DialogUtils.showConfirmDialog(
                          context,
                          title: 'screens.deleteFriends'.tr(),
                          content:
                              'Bạn có chắc chắn muốn xóa ${friend.displayName ?? "người này"} khỏi danh sách bạn bè?',
                          confirmText: 'screens.erase'.tr(),
                          isDestructive: true,
                          onConfirm: () async {
                            final myId = context
                                .read<AppAuthProvider>()
                                .userModel
                                ?.id;
                            if (myId == null) return;
                            try {
                              await context
                                  .read<FriendProvider>()
                                  .rejectOrRemoveFriend(myId, friend.id);
                              if (context.mounted) {
                                SnackbarUtils.showSuccess(
                                  context,
                                  'screens.deletedFriends'.tr(),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                SnackbarUtils.showError(context, "Lỗi: $e");
                              }
                            }
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PendingRequestsTab extends StatelessWidget {
  const _PendingRequestsTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<FriendProvider>(
      builder: (context, provider, child) {
        final requests = provider.pendingRequests;

        if (requests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person_add, size: 60, color: Colors.grey),
                SizedBox(height: 16),
                Text('screens.thereAreNoFriendRequests'.tr()),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final request = requests[index];
            final UserModel sender = request['user'];

            return Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.9),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: ListTile(
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.5),
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(27),
                            child: sender.photoUrl != null
                                ? Image.network(
                                    sender.photoUrl!,
                                    fit: BoxFit.cover,
                                  )
                                : Icon(
                                    Icons.person,
                                    color: AppColors.primary.withValues(
                                      alpha: 0.7,
                                    ),
                                  ),
                          ),
                        ),
                        title: Text(
                          sender.displayName ?? 'screens.anonymousUser'.tr(),
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textBlack,
                          ),
                        ),
                        subtitle: Text(
                          'screens.wantToMakeFriendsWithYou'.tr(),
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textGrey,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextButton(
                              onPressed: () async {
                                try {
                                  await provider.acceptFriendRequest(
                                    request['user_id1'],
                                    request['user_id2'],
                                  );
                                  if (context.mounted) {
                                    SnackbarUtils.showSuccess(
                                      context,
                                      'screens.acceptSuccess'.tr(),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    SnackbarUtils.showError(context, "Lỗi: $e");
                                  }
                                }
                              },
                              style: TextButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: EdgeInsets.symmetric(horizontal: 16),
                              ),
                              child: Text(
                                'screens.accept'.tr(),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            SizedBox(width: 8),
                            IconButton(
                              icon: Icon(
                                Icons.close,
                                color: AppColors.textGrey,
                                size: 20,
                              ),
                              onPressed: () => provider.rejectOrRemoveFriend(
                                request['user_id1'],
                                request['user_id2'],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
