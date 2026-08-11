import 'package:easy_localization/easy_localization.dart';
import 'dart:io';
import 'package:badminton_ai/core/data/repositories/chat_room_repository.dart';
import 'package:badminton_ai/modules/auth/viewmodels/auth_provider.dart';
import 'package:badminton_ai/core/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:badminton_ai/modules/chat/viewmodels/unread_count_provider.dart';
import 'package:badminton_ai/core/utils/snackbar_utils.dart';
import 'package:badminton_ai/core/utils/dialog_utils.dart';
import 'package:timeago/timeago.dart' as timeago;

class DirectChatScreen extends StatefulWidget {
  final ChatRoom room;

  const DirectChatScreen({super.key, required this.room});

  @override
  State<DirectChatScreen> createState() => _DirectChatScreenState();
}

class _DirectChatScreenState extends State<DirectChatScreen> {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();
  XFile? _previewImage;
  bool _isUploading = false;
  late Stream<List<Message>> _messagesStream;

  @override
  void initState() {
    super.initState();
    _messagesStream = context.read<ChatRoomRepository>().getMessagesStream(widget.room.id);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // Báo provider: phòng này đang mở → bỏ đếm badge ngay
        context.read<UnreadCountProvider>().enterRoom(widget.room.id);
        // Ghi DB last_read_at
        context.read<UnreadCountProvider>().markRoomAsRead(widget.room.id);
      }
    });
  }

  @override
  void dispose() {
    // Báo provider: đã thoát phòng → tính lại badge
    context.read<UnreadCountProvider>().leaveRoom();
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _msgController.text.trim();
    if (text.isEmpty && _previewImage == null) return;

    final userId = context.read<AppAuthProvider>().userModel?.id;
    if (userId == null) return;

    // Cache local references
    final currentText = text;
    final pickedImage = _previewImage;

    setState(() {
      _isUploading = true;
      _msgController.clear();
      _previewImage = null; // clear preview instantly
    });

    try {
      String? uploadedUrl;
      if (pickedImage != null) {
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_${pickedImage.name}';
        uploadedUrl = await context.read<ChatRoomRepository>().uploadImage(
          pickedImage.path,
          fileName,
        );
        if (uploadedUrl == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('screens.errorUploadingPhoto'.tr())));
          }
        }
      }

      if (!mounted) return;
      await context.read<ChatRoomRepository>().sendMessage(
        widget.room.id,
        userId,
        currentText.isEmpty && uploadedUrl != null ? 'screens.Image'.tr() : currentText,
        imagePath: uploadedUrl,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 70,
      );
      if (image == null) return;

      setState(() {
        _previewImage = image;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Không thể chọn ảnh: $e')));
      }
    }
  }

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: Center(
            child: Hero(
              tag: imageUrl,
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = context.read<AppAuthProvider>().userModel?.id;

    return Scaffold(
      backgroundColor: VColors.background,
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.grey.shade200,
              backgroundImage: widget.room.displayAvatar != null
                  ? NetworkImage(widget.room.displayAvatar!)
                  : null,
              child: widget.room.displayAvatar == null
                  ? Icon(
                      widget.room.isGroup ? Icons.group : Icons.person,
                      color: Colors.grey,
                    )
                  : null,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.room.displayTitle ?? 'screens.nameless'.tr(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Builder(
                    builder: (context) {
                      if (widget.room.isGroup) {
                        return Text(
                          "${widget.room.members.length} thành viên",
                          style: TextStyle(fontSize: 12, color: VColors.brandPrimary),
                        );
                      }
                      
                      if (widget.room.members.isEmpty) {
                        return SizedBox.shrink();
                      }
                      final otherUser = widget.room.members.firstWhere(
                        (m) => m.id != userId,
                        orElse: () => widget.room.members.first,
                      );
                      
                      final isOnline = otherUser.status == 'online';
                      String text = 'screens.offline'.tr();
                      Color color = Colors.grey;
                      
                      if (isOnline) {
                        text = 'screens.active'.tr();
                        color = VColors.statusSuccess;
                      } else if (otherUser.lastActiveAt != null) {
                        timeago.setLocaleMessages('vi', timeago.ViMessages());
                        text = "Hoạt động ${timeago.format(otherUser.lastActiveAt!, locale: 'vi')}";
                      }
                      
                      return Text(
                        text,
                        style: TextStyle(
                          fontSize: 12,
                          color: color,
                          fontWeight: FontWeight.normal,
                        ),
                      );
                    }
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: widget.room.isGroup
            ? [
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: VColors.textPrimary),
                  onSelected: (value) async {
                    if (value == 'leave') {
                      DialogUtils.showConfirmDialog(
                        context,
                        title: 'screens.leaveTheGroup'.tr(),
                        content: 'screens.areYouSureYouWantToLeave'.tr(),
                        confirmText: 'screens.leave'.tr(),
                        isDestructive: true,
                        onConfirm: () async {
                          if (userId == null) return;
                          try {
                            await context.read<ChatRoomRepository>().leaveGroup(widget.room.id, userId);
                            if (!context.mounted) return;
                            Navigator.pop(context); // Trở về màn hình trước
                            SnackbarUtils.showSuccess(context, 'screens.leftTheGroup'.tr());
                          } catch (e) {
                            if (!context.mounted) return;
                            SnackbarUtils.showError(context, 'Lỗi: $e');
                          }
                        },
                      );
                    } else if (value == 'dissolve') {
                      DialogUtils.showConfirmDialog(
                        context,
                        title: 'screens.disbandTheGroup'.tr(),
                        content: 'screens.thisActionWillPermanentlyD'.tr(),
                        confirmText: 'screens.dissolve'.tr(),
                        isDestructive: true,
                        onConfirm: () async {
                          try {
                            await context.read<ChatRoomRepository>().dissolveGroup(widget.room.id);
                            if (!context.mounted) return;
                            Navigator.pop(context); // Trở về
                            SnackbarUtils.showSuccess(context, 'screens.theGroupHasBeenDisbanded'.tr());
                          } catch (e) {
                            if (!context.mounted) return;
                            SnackbarUtils.showError(context, 'Lỗi: $e');
                          }
                        },
                      );
                    }
                  },
                  itemBuilder: (BuildContext context) {
                    final isLeader = widget.room.adminId == null || widget.room.adminId == userId;
                    return [
                      if (isLeader)
                        PopupMenuItem(
                          value: 'dissolve',
                          child: Text('screens.disbandTheGroup'.tr(), style: TextStyle(color: VColors.statusCritical)),
                        ),
                      PopupMenuItem(
                        value: 'leave',
                        child: Text('screens.leaveTheGroup'.tr()),
                      ),
                    ];
                  },
                )
              ]
            : null,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Message>>(
              stream: _messagesStream,
              builder: (context, snapshot) {
                // Đánh dấu đã đọc bất cứ khi nào có tin nhắn mới stream về
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    context.read<UnreadCountProvider>().markRoomAsRead(widget.room.id);
                  }
                });
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Lỗi: ${snapshot.error}'));
                }

                final messages = snapshot.data ?? [];

                // Auto-scroll xuống tin mới nhất
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollController.animateTo(
                      _scrollController.position.maxScrollExtent,
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                    );
                  }
                });

                return ListView.builder(
                  controller: _scrollController,
                  reverse: false,
                  padding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 16,
                  ),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg.senderId == userId;

                    // Show small time above message
                    final timeStr = DateFormat('HH:mm').format(msg.createdAt);

                    return Align(
                      alignment: isMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: EdgeInsets.only(bottom: 12),
                        child: Column(
                          crossAxisAlignment: isMe
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          children: [
                            if (!isMe && widget.room.isGroup) ...[
                              Padding(
                                padding: EdgeInsets.only(
                                  left: 8,
                                  bottom: 4,
                                ),
                                child: Text(
                                  msg.sender?.displayName ?? 'screens.user'.tr(),
                                  style: TextStyle(
                                    color: VColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                            Container(
                              constraints: BoxConstraints(
                                maxWidth:
                                    MediaQuery.of(context).size.width * 0.75,
                              ),
                              decoration: BoxDecoration(
                                color: isMe ? VColors.brandPrimary : Colors.white,
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(20),
                                  topRight: const Radius.circular(20),
                                  bottomLeft: Radius.circular(isMe ? 20 : 4),
                                  bottomRight: Radius.circular(isMe ? 4 : 20),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 5,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // ── Ảnh (chỉ render khi có imagePath) ──
                                    if (msg.imagePath != null)
                                      GestureDetector(
                                        onTap: () => _showFullScreenImage(context, msg.imagePath!),
                                        child: Hero(
                                          tag: msg.imagePath!,
                                          child: ConstrainedBox(
                                            constraints: const BoxConstraints(
                                              maxHeight: 220,
                                            ),
                                            child: CachedNetworkImage(
                                              imageUrl: msg.imagePath!,
                                              fit: BoxFit.cover,
                                              width: double.infinity,
                                              placeholder: (context, url) =>
                                                  Container(
                                                    height: 200,
                                                    color: Colors.grey.shade200,
                                                    child: Center(
                                                      child:
                                                          CircularProgressIndicator(),
                                                    ),
                                                  ),
                                              errorWidget: (context, url, error) =>
                                                  Container(
                                                    height: 150,
                                                    color: Colors.grey.shade200,
                                                    child: Icon(
                                                      Icons.broken_image,
                                                      color: Colors.grey,
                                                      size: 40,
                                                    ),
                                                  ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    // ── Nội dung text ──
                                    if (msg.content.isNotEmpty &&
                                        msg.content != 'screens.Image'.tr())
                                      Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 12,
                                        ),
                                        child: Text(
                                          msg.content,
                                          style: TextStyle(
                                            color: isMe
                                                ? Colors.white
                                                : VColors.textPrimary,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ),
                                    // Nếu chỉ có ảnh (không có text), thêm padding nhỏ
                                    if (msg.imagePath != null &&
                                        (msg.content.isEmpty || msg.content == 'screens.Image'.tr()))
                                      SizedBox(height: 4),
                                  ],
                                ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.only(
                                top: 4,
                                left: 4,
                                right: 4,
                              ),
                              child: Text(
                                timeStr,
                                style: TextStyle(
                                  color: VColors.textSubdued,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          if (_isUploading)
            Padding(
              padding: EdgeInsets.all(8.0),
              child: LinearProgressIndicator(),
            ),

          // Message Input Field
          SafeArea(
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 8.0,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    offset: const Offset(0, -2),
                    blurRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_previewImage != null)
                    Padding(
                      padding: EdgeInsets.only(bottom: 8, left: 8, top: 4),
                      child: SizedBox(
                        width: 88,
                        height: 88,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: VColors.borderDefault),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(
                                  File(_previewImage!.path),
                                  fit: BoxFit.cover,
                                  width: 80,
                                  height: 80,
                                ),
                              ),
                            ),
                            Positioned(
                              top: -8,
                              right: -8,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _previewImage = null;
                                  });
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 1.5),
                                  ),
                                  padding: EdgeInsets.all(3),
                                  child: Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 13,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.camera_alt_outlined,
                          color: VColors.brandPrimary,
                          size: 26,
                        ),
                        onPressed: _isUploading ? null : () => _pickImage(ImageSource.camera),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.image_outlined,
                          color: VColors.brandPrimary,
                          size: 26,
                        ),
                        onPressed: _isUploading ? null : () => _pickImage(ImageSource.gallery),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _msgController,
                          minLines: 1,
                          maxLines: 4,
                          decoration: InputDecoration(
                            hintText: 'screens.texting'.tr(),
                            hintStyle: TextStyle(color: VColors.textSubdued),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.grey[100],
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                          ),
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                      SizedBox(width: 4),
                      CircleAvatar(
                        backgroundColor: VColors.brandPrimary,
                        child: IconButton(
                          icon: Icon(
                            Icons.send_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          onPressed: _sendMessage,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
