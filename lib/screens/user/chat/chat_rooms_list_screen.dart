import 'package:badminton_ai/data/repositories/chat_room_repository.dart';
import 'package:badminton_ai/providers/auth_provider.dart';
import 'package:badminton_ai/screens/user/chat/direct_chat_screen.dart';
import 'package:badminton_ai/screens/user/chat/create_group_screen.dart';
import 'package:badminton_ai/utils/app_colors.dart';
import 'package:badminton_ai/blocs/chat_rooms/chat_rooms_bloc.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;

// ─────────────────────────────────────────────
// Entry point
// ─────────────────────────────────────────────
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

// ─────────────────────────────────────────────
// Main content
// ─────────────────────────────────────────────
class _ChatRoomsListContent extends StatelessWidget {
  final bool isEmbedded;

  const _ChatRoomsListContent({required this.isEmbedded});

  @override
  Widget build(BuildContext context) {
    timeago.setLocaleMessages('vi', timeago.ViMessages());

    final body = BlocBuilder<ChatRoomsBloc, ChatRoomsState>(
      builder: (context, state) {
        if (state is ChatRoomsLoading || state is ChatRoomsInitial) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }
        if (state is ChatRoomsError) return _ErrorView(error: state.error);
        if (state is ChatRoomsLoaded) {
          return state.rooms.isEmpty
              ? const _EmptyView()
              : _RoomsList(rooms: state.rooms, isEmbedded: isEmbedded);
        }
        return const SizedBox.shrink();
      },
    );

    if (isEmbedded) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: body,
        // FAB được quản lý bởi FriendsMainScreen để tránh
        // bị chèn lên navigation bar của Scaffold cha.
      );
    }

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
        
      ),
      body: body,
      floatingActionButton: _CreateGroupFAB(),
    );
  }
}

// ─────────────────────────────────────────────
// Rooms list
// ─────────────────────────────────────────────
class _RoomsList extends StatelessWidget {
  final List rooms;
  final bool isEmbedded;

  const _RoomsList({required this.rooms, required this.isEmbedded});

  @override
  Widget build(BuildContext context) {
    final bottomPadding =
        12 + MediaQuery.of(context).padding.bottom + (isEmbedded ? 120 : 0);

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(16, 12, 16, bottomPadding),
      itemCount: rooms.length,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _RoomCard(room: rooms[index]),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Room card
// ─────────────────────────────────────────────
class _RoomCard extends StatelessWidget {
  final dynamic room;

  const _RoomCard({required this.room});

  @override
  Widget build(BuildContext context) {
    final timeAgoStr = timeago.format(
      room.createdAt,
      locale: 'vi',
      allowFromNow: true,
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
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
            child: InkWell(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DirectChatScreen(room: room),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    _RoomAvatar(room: room),
                    const SizedBox(width: 16),
                    Expanded(child: _RoomInfo(room: room)),
                    const SizedBox(width: 8),
                    _TimeChip(label: timeAgoStr),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Room avatar
// ─────────────────────────────────────────────
class _RoomAvatar extends StatelessWidget {
  final dynamic room;

  const _RoomAvatar({required this.room});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.5),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipOval(
        child: room.displayAvatar != null
            ? CachedNetworkImage(
                imageUrl: room.displayAvatar!,
                fit: BoxFit.cover,
                placeholder: (_, __) => const Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                ),
                errorWidget: (_, __, ___) => _fallbackIcon(room.isGroup),
              )
            : _fallbackIcon(room.isGroup),
      ),
    );
  }

  Widget _fallbackIcon(bool isGroup) => Icon(
        isGroup ? Icons.group : Icons.person,
        color: AppColors.primary.withOpacity(0.7),
        size: 28,
      );
}

// ─────────────────────────────────────────────
// Room name & preview
// ─────────────────────────────────────────────
class _RoomInfo extends StatelessWidget {
  final dynamic room;

  const _RoomInfo({required this.room});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          room.displayTitle ?? 'Không tên',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: AppColors.textBlack,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Chạm để xem tin nhắn...',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: AppColors.textGrey.withOpacity(0.9),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Time chip
// ─────────────────────────────────────────────
class _TimeChip extends StatelessWidget {
  final String label;

  const _TimeChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.8)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: AppColors.textGrey,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Empty state
// ─────────────────────────────────────────────
class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text(
            'Theo dõi cuộc hội thoại',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textBlack,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Bạn chưa có đoạn hội thoại nào.\nHãy bắt đầu nhắn tin với bạn bè nhé!',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textGrey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CreateGroupScreen()),
            ),
            icon: const Icon(Icons.group_add),
            label: const Text('Tạo nhóm mới'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Error state
// ─────────────────────────────────────────────
class _ErrorView extends StatelessWidget {
  final String error;

  const _ErrorView({required this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 48),
          const SizedBox(height: 16),
          Text('Đã xảy ra lỗi: $error'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              final userId =
                  context.read<AppAuthProvider>().userModel?.id;
              if (userId != null) {
                context
                    .read<ChatRoomsBloc>()
                    .add(ChatRoomsLoadStarted(userId: userId));
              }
            },
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Floating action button
// ─────────────────────────────────────────────
class _CreateGroupFAB extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChatRoomsBloc, ChatRoomsState>(
      builder: (context, state) {
        if (state is ChatRoomsLoaded && state.rooms.isEmpty) {
          return const SizedBox.shrink();
        }
        return FloatingActionButton(
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
        );
      },
    );
  }
}
