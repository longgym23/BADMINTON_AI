import 'package:badminton_ai/core/data/repositories/chat_room_repository.dart';
import 'package:badminton_ai/modules/auth/viewmodels/auth_provider.dart';
import 'package:badminton_ai/modules/friends/viewmodels/friend_provider.dart';
import 'package:badminton_ai/core/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:badminton_ai/modules/chat/views/pages/direct_chat_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:easy_localization/easy_localization.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final TextEditingController _nameController = TextEditingController();
  final Set<String> _selectedFriendIds = {};
  bool _isLoading = false;
  XFile? _groupImage;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image != null) {
      setState(() {
        _groupImage = image;
      });
    }
  }

  Future<void> _createGroup() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('screens.pleaseEnterAGroupName'.tr())));
      return;
    }

    if (_selectedFriendIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('screens.pleaseSelectAtLeast1Membe'.tr())),
      );
      return;
    }

    final myId = context.read<AppAuthProvider>().userModel?.id;
    if (myId == null) return;

    setState(() => _isLoading = true);

    try {
      String? avatarUrl;
      if (_groupImage != null) {
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_group.jpg';
        avatarUrl = await context.read<ChatRoomRepository>().uploadImage(
          _groupImage!.path,
          fileName,
        );
      }

      if (!mounted) return;
      final memberIds = [myId, ..._selectedFriendIds];
      final roomId = await context.read<ChatRoomRepository>().createGroupRoom(
        name,
        memberIds,
        avatarUrl: avatarUrl,
      );

      if (!mounted) return;

      final room = ChatRoom(
        id: roomId,
        isGroup: true,
        name: name,
        createdAt: DateTime.now(),
      );
      room.displayTitle = name;
      room.displayAvatar = avatarUrl;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => DirectChatScreen(room: room)),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi tạo nhóm: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final friends = context.watch<FriendProvider>().friends;

    return Scaffold(
      backgroundColor: VColors.background,
      appBar: AppBar(
        title: Text('screens.createAChatGroup'.tr()),
        backgroundColor: Colors.white,
        actions: [
          if (_isLoading)
            Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _createGroup,
              child: Text('screens.create'.tr(),
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(24),
            color: Colors.white,
            child: Column(
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: VColors.brandPrimary,
                        ),
                        child: ClipOval(
                          child: _groupImage != null
                              ? Image.file(
                                  File(_groupImage!.path),
                                  fit: BoxFit.cover,
                                  width: 80,
                                  height: 80,
                                )
                              : Center(
                                  child: Icon(
                                    Icons.group,
                                    size: 40,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: VColors.brandPrimary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Icon(
                          Icons.camera_alt,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24),
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    hintText: 'screens.groupName'.tr(),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 8),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'screens.cHOOSEFRIENDS'.tr(),
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Expanded(
            child: friends.isEmpty
                ? Center(
                    child: Text('screens.youDonTHaveAnyFriendsTo'.tr()),
                  )
                : ListView.builder(
                    itemCount: friends.length,
                    itemBuilder: (context, index) {
                      final friend = friends[index];
                      final isSelected = _selectedFriendIds.contains(friend.id);

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: friend.photoUrl != null
                              ? NetworkImage(friend.photoUrl!)
                              : null,
                          child: friend.photoUrl == null
                              ? Icon(Icons.person)
                              : null,
                        ),
                        title: Text(friend.displayName ?? 'screens.user'.tr()),
                        trailing: Icon(
                          isSelected
                              ? Icons.check_box
                              : Icons.check_box_outline_blank,
                          color: isSelected ? VColors.brandPrimary : Colors.grey,
                        ),
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedFriendIds.remove(friend.id);
                            } else {
                              _selectedFriendIds.add(friend.id);
                            }
                          });
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
