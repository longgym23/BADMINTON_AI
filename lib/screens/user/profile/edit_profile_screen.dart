import 'dart:io';
import 'package:badminton_ai/providers/auth_provider.dart';
import 'package:badminton_ai/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:badminton_ai/widgets/custom_gradient_app_bar.dart';
import 'package:badminton_ai/widgets/app_toast.dart';
import 'package:easy_localization/easy_localization.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;

  DateTime? _selectedDate;
  String? _selectedGender;

  // ─── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    final user = context.read<AppAuthProvider>().userModel;
    _nameController = TextEditingController(text: user?.displayName ?? '');
    _phoneController = TextEditingController(text: user?.phoneNumber ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _selectedDate = user?.dateOfBirth;
    _selectedGender = user?.gender;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  // ─── Actions ─────────────────────────────────────────────────────────────────

  Future<void> _pickAndUploadImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile == null || !mounted) return;

    final authProvider = context.read<AppAuthProvider>();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('screens.uploadingPhotos'.tr())));

    final success = await authProvider.updateUserAvatar(File(pickedFile.path));

    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    // ScaffoldMessenger.of(context).showSnackBar(
    //   SnackBar(
    //     content: Text(
    //       success
    //           ? 'screens.updatedProfilePictureSucces'.tr()
    //           : 'screens.failedToUpdateProfilePictu'.tr(),
    //     ),
    //   ),
    // );
    AppToast.show(
      context,
      success
          ? 'screens.updatedProfilePictureSucces'.tr()
          : 'screens.failedToUpdateProfilePictu'.tr(),
      type: success ? ToastType.success : ToastType.error,
    );
  }

  Future<void> _deleteAvatar() async {
    if (!mounted) return;
    final authProvider = context.read<AppAuthProvider>();
    final success = await authProvider.deleteUserAvatar();
    if (!mounted) return;
    AppToast.show(
      context,
      success ? 'screens.deletedPhotosSuccessfully'.tr() : 'screens.photoDeletionFailed'.tr(),
      type: success ? ToastType.success : ToastType.error,
    );
  }

  Future<void> _selectDate() async {
    DateTime temp = _selectedDate ?? DateTime.now();
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => Container(
        height: 300,
        padding: EdgeInsets.only(top: 6.0),
        margin: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        color: CupertinoColors.systemBackground.resolveFrom(ctx),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CupertinoButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text('screens.cancel1'.tr(),
                    style: TextStyle(color: AppColors.textGrey),
                  ),
                ),
                CupertinoButton(
                  onPressed: () {
                    setState(() => _selectedDate = temp);
                    Navigator.of(ctx).pop();
                  },
                  child: Text(
                    'Xong',
                    style: TextStyle(color: AppColors.brandOrange),
                  ),
                ),
              ],
            ),
            Expanded(
              child: CupertinoDatePicker(
                initialDateTime: _selectedDate ?? DateTime.now(),
                mode: CupertinoDatePickerMode.date,
                minimumYear: 1900,
                maximumDate: DateTime.now(),
                onDateTimeChanged: (dt) => temp = dt,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveChanges() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final success = await context.read<AppAuthProvider>().updateUserProfile(
      displayName: _nameController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      dob: _selectedDate,
      gender: _selectedGender,
    );

    if (!mounted) return;
    AppToast.show(context, 'screens.updatedSuccessfully'.tr(), type: ToastType.success);
    if (success) Navigator.pop(context);
  }

  // ─── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AppAuthProvider>();
    final user = authProvider.userModel;

    return Scaffold(
      appBar: CustomGradientAppBar(
        title: Text('screens.editPersonalInformation'.tr(),
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.chevron_left, size: 30, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      bottomNavigationBar: _buildBottomBar(authProvider),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('screens.accountInformation'.tr(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              SizedBox(height: 16),

              Text('screens.avatar'.tr(),
                style: TextStyle(
                  color: AppColors.textBlack,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 8),
              _buildAvatarCard(user, authProvider),
              SizedBox(height: 16),

              _buildLabel('screens.fullName1'.tr(), isRequired: true),
              SizedBox(height: 8),
              _buildTextField(
                controller: _nameController,
                hintText: 'screens.enterFullName'.tr(),
                validator: (val) =>
                    (val == null || val.isEmpty) ? 'screens.pleaseEnterAName'.tr() : null,
              ),
              SizedBox(height: 16),

              _buildLabel('screens.phoneNumber1'.tr(), isRequired: true),
              SizedBox(height: 8),
              _buildPhoneField(),
              SizedBox(height: 16),

              _buildLabel('Email', isRequired: false),
              SizedBox(height: 8),
              _buildTextField(
                controller: _emailController,
                hintText: 'screens.enterEmail'.tr(),
                enabled: false,
              ),
              SizedBox(height: 16),

              _buildDateAndGenderRow(),
              SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Widget Helpers ───────────────────────────────────────────────────────────

  Widget _buildBottomBar(AppAuthProvider authProvider) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text('screens.cancel'.tr(),
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: authProvider.isUpdatingProfile ? null : _saveChanges,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
                child: authProvider.isUpdatingProfile
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text('screens.save'.tr(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarCard(user, AppAuthProvider authProvider) {
    final initials =
        (user?.displayName != null && user!.displayName!.isNotEmpty)
        ? user.displayName!.substring(0, 2).toUpperCase()
        : 'U';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.borderColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(12),
              image: user?.photoUrl != null
                  ? DecorationImage(
                      image: NetworkImage(user!.photoUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: user?.photoUrl == null
                ? Center(
                    child: Text(
                      initials,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                : null,
          ),
          if (authProvider.isUpdatingProfile)
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
            ),
          Positioned(
            top: -24,
            right: -16,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.camera_alt_sharp,
                    color: AppColors.primary,
                  ),
                  tooltip: 'screens.changeAvatar'.tr(),
                  onPressed: _pickAndUploadImage,
                ),
                IconButton(
                  icon: Icon(
                    Icons.delete_forever,
                    color: Colors.redAccent,
                  ),
                  tooltip: 'screens.deletePhotos'.tr(),
                  onPressed: () => _confirmDeleteAvatar(user),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAvatar(user) {
    if (user?.photoUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('screens.youDonTHaveAProfilePictu'.tr())),
      );
      return;
    }
    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text('screens.deleteAvatar'.tr()),
        message: Text('screens.areYouSureYouWantToDelet3'.tr()),
        actions: [
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(ctx);
              _deleteAvatar();
            },
            child: Text('screens.deletePhotos1'.tr()),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.pop(ctx),
          child: Text('screens.cancel1'.tr()),
        ),
      ),
    );
  }

  Widget _buildPhoneField() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.borderColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            child: Row(
              children: [
                Image.asset('assets/images/vietnam.png', width: 24, height: 24),
                SizedBox(width: 8),
                Text(
                  '+ 84',
                  style: TextStyle(color: AppColors.textGrey, fontSize: 14),
                ),
              ],
            ),
          ),
          Expanded(
            child: TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                hintText: 'screens.enterPhoneNumber'.tr(),
                hintStyle: TextStyle(color: AppColors.textLight, fontSize: 14),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateAndGenderRow() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel('screens.dateOfBirth'.tr(), isRequired: true),
              SizedBox(height: 8),
              InkWell(
                onTap: _selectDate,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.borderColor),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedDate != null
                            ? DateFormat('dd/MM/yyyy').format(_selectedDate!)
                            : 'dd/MM/yyyy',
                        style: TextStyle(
                          color: _selectedDate != null
                              ? AppColors.textBlack
                              : AppColors.textLight,
                          fontSize: 14,
                        ),
                      ),
                      Icon(
                        Icons.calendar_month_rounded,
                        size: 18,
                        color: AppColors.textGrey,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel('screens.sex'.tr(), isRequired: true),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.borderColor),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _selectedGender,
                    hint: Text('screens.chooseGender'.tr(),
                      style: TextStyle(color: AppColors.textGrey, fontSize: 14),
                    ),
                    icon: Icon(
                      Icons.keyboard_arrow_down,
                      color: AppColors.textGrey,
                    ),
                    style: TextStyle(
                      color: AppColors.textGrey,
                      fontSize: 14,
                    ),
                    items: ['Nam', 'screens.female'.tr(), 'screens.other'.tr()]
                        .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedGender = v),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String text, {required bool isRequired}) {
    return Row(
      children: [
        Text(
          text,
          style: TextStyle(
            color: AppColors.textBlack,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (isRequired) ...[
          SizedBox(width: 4),
          Text('*', style: TextStyle(color: AppColors.primaryDark)),
        ],
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    bool enabled = true,
    String? Function(String?)? validator,
  }) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: AppColors.borderColor),
    );
    return TextFormField(
      controller: controller,
      enabled: enabled,
      style: TextStyle(
        color: enabled ? AppColors.textBlack : AppColors.textGrey,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: AppColors.textLight, fontSize: 14),
        fillColor: enabled ? Colors.white : AppColors.background,
        filled: true,
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: border,
        enabledBorder: border,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary),
        ),
      ),
      validator: validator,
    );
  }
}
