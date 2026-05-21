import 'package:easy_localization/easy_localization.dart';
import 'package:badminton_ai/data/repositories/chat_room_repository.dart';
import 'package:badminton_ai/domain/usecases/chat_rooms/watch_user_chat_rooms_usecase.dart';

import 'package:badminton_ai/providers/auth_provider.dart';
import 'package:badminton_ai/screens/user/chat/direct_chat_screen.dart';
import 'package:badminton_ai/screens/user/chat/create_group_screen.dart';
import 'package:badminton_ai/utils/app_colors.dart';
import 'package:badminton_ai/blocs/chat_rooms/chat_rooms_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:badminton_ai/providers/friend_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;

// ─────────────────────────────────────────────
// Entry point
// ─────────────────────────────────────────────
class ChatRoomsListScreen extends StatefulWidget {
  final bool isEmbedded;
  final String roomType; // 'all', 'direct', 'group'

  const ChatRoomsListScreen({
    super.key,
    this.isEmbedded = false,
    this.roomType = 'all',
  });

  @override
  State<ChatRoomsListScreen> createState() => _ChatRoomsListScreenState();
}

class _ChatRoomsListScreenState extends State<ChatRoomsListScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    final userId = context.read<AppAuthProvider>().userModel?.id;
    if (userId == null) {
      return Scaffold(body: Center(child: Text('screens.pleaseLogIn'.tr())));
    }

    return BlocProvider(
      create: (context) => ChatRoomsBloc(
        watchUserChatRoomsUseCase: context.read<WatchUserChatRoomsUseCase>(),
      )..add(ChatRoomsLoadStarted(userId: userId)),
      child: Column(
        children: [
          _buildSearchField(),
          Expanded(
            child: _ChatRoomsListContent(
              isEmbedded: widget.isEmbedded,
              roomType: widget.roomType,
              searchQuery: _searchQuery,
            ),
          ),
        ],
      ),
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
                hintText: 'home_screen.searchUsersOrGroups'.tr(),
                hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
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

// ─────────────────────────────────────────────
// Main content
// ─────────────────────────────────────────────
class _ChatRoomsListContent extends StatelessWidget {
  final bool isEmbedded;
  final String roomType;
  final String searchQuery;

  const _ChatRoomsListContent({
    required this.isEmbedded,
    required this.roomType,
    required this.searchQuery,
  });

  @override
  Widget build(BuildContext context) {
    timeago.setLocaleMessages('vi', timeago.ViMessages());

    final body = BlocBuilder<ChatRoomsBloc, ChatRoomsState>(
      builder: (context, state) {
        if (state is ChatRoomsLoading || state is ChatRoomsInitial) {
          return Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }
        if (state is ChatRoomsError) return _ErrorView(error: state.error);
        if (state is ChatRoomsLoaded) {
          var filteredRooms = state.rooms;

          // Lọc theo loại phòng
          if (roomType == 'direct') {
            filteredRooms = filteredRooms.where((r) => !r.isGroup).toList();
          } else if (roomType == 'group') {
            filteredRooms = filteredRooms.where((r) => r.isGroup).toList();
          }

          // Lọc theo tìm kiếm
          if (searchQuery.isNotEmpty) {
            final q = searchQuery.toLowerCase();
            filteredRooms = filteredRooms
                .where(
                  (r) =>
                      (r.displayTitle ?? '').toLowerCase().contains(q) ||
                      (r.lastMessage ?? '').toLowerCase().contains(q),
                )
                .toList();
          }

          return filteredRooms.isEmpty
              ? const _EmptyView()
              : _RoomsList(
                  rooms: filteredRooms,
                  isEmbedded: isEmbedded,
                  roomType: roomType,
                );
        }
        return SizedBox.shrink();
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
        title: Text('screens.message'.tr(),
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
  final String roomType;

  const _RoomsList({
    required this.rooms,
    required this.isEmbedded,
    required this.roomType,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding =
        12 + MediaQuery.of(context).padding.bottom + (isEmbedded ? 120 : 0);

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(16, 12, 16, bottomPadding),
      itemCount: rooms.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: _RoomCard(room: rooms[index]),
        );
      },
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
    final timeRef = (room.lastMessageTime ?? room.createdAt) as DateTime;
    final timeAgoStr = timeago.format(
      timeRef,
      locale: 'vi',
      allowFromNow: true,
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
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
                color: AppColors.primary.withValues(alpha: 0.15),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => DirectChatScreen(room: room)),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    _RoomAvatar(room: room),
                    SizedBox(width: 14),
                    Expanded(child: _RoomInfo(room: room)),
                    if (room.unreadCount > 0) ...[
                      SizedBox(width: 8),
                      Container(
                        padding: EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          room.unreadCount > 9
                              ? '9+'
                              : room.unreadCount.toString(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
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
    // Tìm otherUser để lấy trạng thái online nế là chat 1-1
    dynamic otherUser;
    if (!room.isGroup && room.members != null) {
      final myId = context.read<AppAuthProvider>().userModel?.id;
      try {
        otherUser = (room.members as List).firstWhere((m) => m.id != myId);
      } catch (_) {
        otherUser = null;
      }
    }

    final bool isOnline = otherUser?.status == 'online';

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.5),
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
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
                    placeholder: (_, __) => Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    ),
                    errorWidget: (_, __, ___) => _fallbackIcon(room.isGroup),
                  )
                : _fallbackIcon(room.isGroup),
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
                color: AppColors.success, // Màu xanh lá khi online
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2.5),
              ),
            ),
          )
        else if (otherUser != null)
          Positioned(
            right: 0,
            bottom: 2,
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: Colors.grey[400], // Màu xám khi offline
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2.5),
              ),
            ),
          ),
      ],
    );
  }

  Widget _fallbackIcon(bool isGroup) => Icon(
    isGroup ? Icons.group : Icons.person,
    color: AppColors.primary.withValues(alpha: 0.7),
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
    dynamic otherUser;
    if (!room.isGroup && room.members != null) {
      final myId = context.read<AppAuthProvider>().userModel?.id;
      try {
        otherUser = (room.members as List).firstWhere((m) => m.id != myId);
      } catch (_) {
        otherUser = null;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                room.displayTitle ?? 'screens.nameless'.tr(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: AppColors.textBlack,
                  letterSpacing: -0.3,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 4),
        Text(
          room.lastMessage ?? 'screens.tapToText'.tr(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: (room.unreadCount > 0)
                ? AppColors.textBlack
                : AppColors.textGrey.withValues(alpha: 0.9),
            fontSize: 13.5,
            fontWeight: (room.unreadCount > 0)
                ? FontWeight.bold
                : FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Active friends horizontal row
// ─────────────────────────────────────────────
class _ActiveFriendsRow extends StatelessWidget {
  const _ActiveFriendsRow();

  @override
  Widget build(BuildContext context) {
    return Consumer<FriendProvider>(
      builder: (context, provider, child) {
        // Lọc những người bạn đang online (hoặc hiện tất cả nhưng ưu tiên online)
        final friends = provider.friends;
        if (friends.isEmpty) return SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(left: 4, bottom: 12),
              child: Text(
                'screens.active'.tr(),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textGrey,
                ),
              ),
            ),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: friends.length,
                itemBuilder: (context, index) {
                  final friend = friends[index];
                  final bool isOnline = friend.status == 'online';

                  return GestureDetector(
                    onTap: () async {
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
                        room.displayTitle = friend.displayName ?? 'screens.user'.tr();
                        room.displayAvatar = friend.photoUrl;
                        room.members = [friend]; // Mock members for navigation

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DirectChatScreen(room: room),
                          ),
                        );
                      } catch (e) {
                        print("Lỗi mở chat từ ActiveRow: $e");
                      }
                    },
                    child: Padding(
                      padding: EdgeInsets.only(right: 20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Stack(
                            children: [
                              Container(
                                width: 62,
                                height: 62,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: isOnline
                                      ? LinearGradient(
                                          colors: [
                                            AppColors.primary,
                                            AppColors.primary.withValues(
                                              alpha: 0.5,
                                            ),
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        )
                                      : null,
                                  color: !isOnline ? Colors.grey[300] : null,
                                ),
                                padding: EdgeInsets.all(2.5),
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                  child: CircleAvatar(
                                    backgroundImage: friend.photoUrl != null
                                        ? NetworkImage(friend.photoUrl!)
                                        : null,
                                    backgroundColor: Colors.grey[200],
                                    child: friend.photoUrl == null
                                        ? Icon(
                                            Icons.person,
                                            color: Colors.grey,
                                          )
                                        : null,
                                  ),
                                ),
                              ),
                              if (isOnline)
                                Positioned(
                                  right: 2,
                                  bottom: 2,
                                  child: Container(
                                    width: 15,
                                    height: 15,
                                    decoration: BoxDecoration(
                                      color: AppColors.success,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2.5,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          SizedBox(height: 8),
                          SizedBox(
                            width: 65,
                            child: Text(
                              friend.displayName ?? "User",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: isOnline
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: isOnline
                                    ? AppColors.textBlack
                                    : AppColors.textGrey,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
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
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.15),
          width: 1.5,
        ),
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
          Icon(
            Icons.chat_bubble_outline,
            size: 80,
            color: Colors.grey.shade300,
          ),
          SizedBox(height: 16),
          Text('screens.followTheConversation'.tr(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textBlack,
            ),
          ),
          SizedBox(height: 8),
          Text('screens.youDonTHaveAnyConversatio'.tr(),
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textGrey),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CreateGroupScreen()),
            ),
            icon: Icon(Icons.group_add),
            label: Text('screens.createANewGroup'.tr()),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
    bool isTimeout =
        error.contains('RealtimeSubscribeStatus.timedOut') ||
        error.toLowerCase().contains('timeout');
    String displayMessage = isTimeout
        ? 'screens.lossOfRealTimeConnection'.tr()
        : 'Đã xảy ra lỗi: $error';

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isTimeout ? Icons.wifi_off_outlined : Icons.error_outline,
            color: isTimeout ? Colors.orange : AppColors.error,
            size: 48,
          ),
          SizedBox(height: 16),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              displayMessage,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textGrey, height: 1.5),
            ),
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              final userId = context.read<AppAuthProvider>().userModel?.id;
              if (userId != null) {
                context.read<ChatRoomsBloc>().add(
                  ChatRoomsLoadStarted(userId: userId),
                );
              }
            },
            child: Text('screens.retry'.tr()),
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
          return SizedBox.shrink();
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
          child: Icon(Icons.edit_square, color: Colors.white),
        );
      },
    );
  }
}

