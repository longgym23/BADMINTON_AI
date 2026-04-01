import 'package:badminton_ai/data/models/user_model.dart';
import 'package:badminton_ai/providers/auth_provider.dart';
import 'package:badminton_ai/providers/friend_provider.dart';
import 'package:badminton_ai/screens/user/friends/add_friend_screen.dart';
import 'package:badminton_ai/screens/user/chat/chat_rooms_list_screen.dart';
import 'package:badminton_ai/screens/user/chat/create_group_screen.dart';
import 'package:badminton_ai/screens/user/chat/direct_chat_screen.dart';
import 'package:badminton_ai/data/repositories/chat_room_repository.dart';
import 'package:badminton_ai/utils/app_colors.dart';
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
      length: 3,
      child: _TabIndexListener(
        onTabChanged: (index) {}, // only used for FAB, handled inside
        builder: (context, currentTab) => Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text("Cộng đồng & Bạn bè"),
            backgroundColor: Colors.white,
            actions: [
              IconButton(
                icon: const Icon(Icons.person_add),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddFriendScreen()),
                ),
              ),
            ],
            bottom: const TabBar(
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textGrey,
              indicatorColor: AppColors.primary,
              tabs: [
                Tab(text: "Tin nhắn"),
                Tab(text: "Bạn bè"),
                Tab(text: "Lời mời"),
              ],
            ),
          ),
          floatingActionButton: currentTab == 0
              ? Padding(
                  padding: const EdgeInsets.only(bottom: 100.0),
                  child: FloatingActionButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CreateGroupScreen()),
                    ),
                    backgroundColor: AppColors.primary,
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.edit_square, color: Colors.white),
                  ),
                )
              : null,
          body: const TabBarView(
            children: [
              ChatRoomsListScreen(isEmbedded: true),
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

  const _TabIndexListener({
    required this.builder,
    required this.onTabChanged,
  });

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
  Widget build(BuildContext context) =>
      widget.builder(context, _currentTab);
}

// ─────────────────────────────────────────────
class _FriendsListTab extends StatelessWidget {
  const _FriendsListTab();
  @override
  Widget build(BuildContext context) {
    return Consumer<FriendProvider>(
      builder: (context, provider, child) {
        final friends = provider.friends;

        if (friends.isEmpty) {
          return const Center(
            child: Text("Bạn chưa có người bạn nào. Hãy thêm bạn bè nhé!"),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          itemCount: friends.length,
          itemBuilder: (context, index) {
            final friend = friends[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.9),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.5),
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(25),
                            child: friend.photoUrl != null
                                ? Image.network(
                                    friend.photoUrl!,
                                    fit: BoxFit.cover,
                                  )
                                : Icon(
                                    Icons.person,
                                    color: AppColors.primary.withOpacity(0.7),
                                  ),
                          ),
                        ),
                        title: Text(
                          friend.displayName ?? 'Người dùng không tên',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textBlack,
                          ),
                        ),
                        subtitle: Text(
                          friend.phoneNumber ?? '',
                          style: TextStyle(
                            color: AppColors.textGrey.withOpacity(0.9),
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.message,
                            color: AppColors.primary,
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
                                  friend.displayName ?? 'Người dùng';
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
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Lỗi tạo phòng: $e')),
                                );
                              }
                            }
                          },
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

class _PendingRequestsTab extends StatelessWidget {
  const _PendingRequestsTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<FriendProvider>(
      builder: (context, provider, child) {
        final requests = provider.pendingRequests;

        if (requests.isEmpty) {
          return const Center(child: Text("Không có lời mời kết bạn nào."));
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final request = requests[index];
            final UserModel sender = request['user'];

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.9),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.5),
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(25),
                            child: sender.photoUrl != null
                                ? Image.network(
                                    sender.photoUrl!,
                                    fit: BoxFit.cover,
                                  )
                                : Icon(
                                    Icons.person,
                                    color: AppColors.primary.withOpacity(0.7),
                                  ),
                          ),
                        ),
                        title: Text(
                          sender.displayName ?? 'Người dùng không tên',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textBlack,
                          ),
                        ),
                        subtitle: Text(
                          sender.phoneNumber ?? '',
                          style: TextStyle(
                            color: AppColors.textGrey.withOpacity(0.9),
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.check_circle,
                                color: AppColors.success,
                                size: 28,
                              ),
                              onPressed: () {
                                provider.acceptFriendRequest(
                                  request['user_id1'],
                                  request['user_id2'],
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.cancel,
                                color: AppColors.error,
                                size: 28,
                              ),
                              onPressed: () {
                                provider.rejectOrRemoveFriend(
                                  request['user_id1'],
                                  request['user_id2'],
                                );
                              },
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
