import 'package:badminton_ai/data/repositories/chat_room_repository.dart';
import 'package:badminton_ai/providers/auth_provider.dart';
import 'package:badminton_ai/screens/user/chat/direct_chat_screen.dart';
import 'package:badminton_ai/screens/user/chat/create_group_screen.dart';
import 'package:badminton_ai/utils/app_colors.dart';
import 'package:badminton_ai/blocs/chat_rooms/chat_rooms_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;

class ChatRoomsListScreen extends StatelessWidget {
  final bool isEmbedded;

  const ChatRoomsListScreen({super.key, this.isEmbedded = false});

  @override
  Widget build(BuildContext context) {
    final userId = context.read<AppAuthProvider>().userModel?.id;
    if (userId == null) {
      return const Scaffold(body: Center(child: Text('Vui lòng đăng nhập')));
    }

    return BlocProvider(
      create: (context) =>
          ChatRoomsBloc(chatRoomRepository: context.read<ChatRoomRepository>())
            ..add(ChatRoomsLoadStarted(userId: userId)),
      child: _ChatRoomsListContent(isEmbedded: isEmbedded),
    );
  }
}

class _ChatRoomsListContent extends StatelessWidget {
  final bool isEmbedded;

  const _ChatRoomsListContent({required this.isEmbedded});

  @override
  Widget build(BuildContext context) {
    // Thêm ngôn ngữ tiếng việt cho timeago
    timeago.setLocaleMessages('vi', timeago.ViMessages());

    final bodyContent = BlocBuilder<ChatRoomsBloc, ChatRoomsState>(
      builder: (context, state) {
        if (state is ChatRoomsLoading || state is ChatRoomsInitial) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        if (state is ChatRoomsError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: AppColors.error,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text('Đã xảy ra lỗi: ${state.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    final userId = context
                        .read<AppAuthProvider>()
                        .userModel
                        ?.id;
                    if (userId != null) {
                      context.read<ChatRoomsBloc>().add(
                        ChatRoomsLoadStarted(userId: userId),
                      );
                    }
                  },
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          );
        }

        if (state is ChatRoomsLoaded) {
          final rooms = state.rooms;

          if (rooms.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 80,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Theo dõi cuộc hội thoại",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textBlack,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Bạn chưa có đoạn hội thoại nào.\nHãy bắt đầu nhắn tin với bạn bè nhé!",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textGrey),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CreateGroupScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.group_add),
                    label: const Text('Tạo nhóm mới'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: rooms.length,
            separatorBuilder: (context, index) =>
                const Divider(height: 1, indent: 76, endIndent: 16),
            itemBuilder: (context, index) {
              final room = rooms[index];
              final timeAgoStr = timeago.format(
                room.createdAt,
                locale: 'vi',
                allowFromNow: true,
              );

              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DirectChatScreen(room: room),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      // Avatar
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey.shade200,
                          border: Border.all(
                            color: Colors.grey.shade300,
                            width: 0.5,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(28),
                          child: room.displayAvatar != null
                              ? CachedNetworkImage(
                                  imageUrl: room.displayAvatar!,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => const Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  errorWidget: (context, url, error) => Icon(
                                    room.isGroup ? Icons.group : Icons.person,
                                    color: Colors.grey,
                                    size: 32,
                                  ),
                                )
                              : Icon(
                                  room.isGroup ? Icons.group : Icons.person,
                                  color: Colors.grey,
                                  size: 32,
                                ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              room.displayTitle ?? 'Không tên',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: AppColors.textBlack,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              "Chạm để xem tin nhắn...",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: AppColors.textGrey,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Time
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            timeAgoStr,
                            style: const TextStyle(
                              color: AppColors.textGrey,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Placeholder for unread badge if needed in the future
                          // Container(...)
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        }

        return const SizedBox.shrink();
      },
    );

    if (isEmbedded) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: bodyContent,
        floatingActionButton: _buildFAB(context),
      );
    } else {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text(
            'Tin nhắn',
            style: TextStyle(
              color: AppColors.textBlack,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 2,
        ),
        body: bodyContent,
        floatingActionButton: _buildFAB(context),
      );
    }
  }

  Widget _buildFAB(BuildContext context) {
    return BlocBuilder<ChatRoomsBloc, ChatRoomsState>(
      builder: (context, state) {
        // Hide FAB if list is empty because empty state has a big button
        if (state is ChatRoomsLoaded && state.rooms.isEmpty) {
          return const SizedBox.shrink();
        }
        return FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CreateGroupScreen(),
              ),
            );
          },
          backgroundColor: AppColors.primary,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.edit_square, color: Colors.white),
        );
      },
    );
  }
}
