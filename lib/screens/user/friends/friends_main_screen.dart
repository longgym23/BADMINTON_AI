import 'package:badminton_ai/data/models/user_model.dart';
import 'package:badminton_ai/providers/auth_provider.dart';
import 'package:badminton_ai/providers/friend_provider.dart';
import 'package:badminton_ai/screens/user/friends/add_friend_screen.dart';
import 'package:badminton_ai/screens/user/chat/chat_rooms_list_screen.dart';
import 'package:badminton_ai/screens/user/chat/direct_chat_screen.dart';
import 'package:badminton_ai/data/repositories/chat_room_repository.dart';
import 'package:badminton_ai/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text("Cộng đồng & Bạn bè"),
          backgroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.person_add),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddFriendScreen(),
                  ),
                );
              },
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
        body: const TabBarView(
          children: [
            ChatRoomsListScreen(isEmbedded: true),
            _FriendsListTab(),
            _PendingRequestsTab(),
          ],
        ),
      ),
    );
  }
}

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
          itemCount: friends.length,
          itemBuilder: (context, index) {
            final friend = friends[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundImage: friend.photoUrl != null
                    ? NetworkImage(friend.photoUrl!)
                    : null,
                child: friend.photoUrl == null
                    ? const Icon(Icons.person)
                    : null,
              ),
              title: Text(friend.displayName ?? 'Người dùng không tên'),
              subtitle: Text(friend.phoneNumber ?? ''),
              trailing: IconButton(
                icon: const Icon(Icons.message, color: AppColors.primary),
                onPressed: () async {
                  final myId = context.read<AppAuthProvider>().userModel?.id;
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
                    room.displayTitle = friend.displayName ?? 'Người dùng';
                    room.displayAvatar = friend.photoUrl;

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DirectChatScreen(room: room),
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
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final request = requests[index];
            final UserModel sender = request['user'];

            return ListTile(
              leading: CircleAvatar(
                backgroundImage: sender.photoUrl != null
                    ? NetworkImage(sender.photoUrl!)
                    : null,
                child: sender.photoUrl == null
                    ? const Icon(Icons.person)
                    : null,
              ),
              title: Text(sender.displayName ?? 'Người dùng không tên'),
              subtitle: Text(sender.phoneNumber ?? ''),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.check_circle,
                      color: AppColors.success,
                    ),
                    onPressed: () {
                      provider.acceptFriendRequest(
                        request['user_id1'],
                        request['user_id2'],
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.cancel, color: AppColors.error),
                    onPressed: () {
                      provider.rejectOrRemoveFriend(
                        request['user_id1'],
                        request['user_id2'],
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
