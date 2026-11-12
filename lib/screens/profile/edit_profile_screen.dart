import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/writtle_avatar.dart';
import '../../models/user_profile_model.dart';
import '../../providers/auth_provider.dart';

/// Full-fledged Edit Profile Screen with Avatar customization,
/// Pen Name & Bio management, and Password change capabilities.
class EditProfileScreen extends ConsumerStatefulWidget {
  final UserProfileModel? initialProfile;

  const EditProfileScreen({
    super.key,
    required this.initialProfile,
  });

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late TextEditingController _penNameController;
  late TextEditingController _bioController;
  String? _avatarUrl;
  bool _isSaving = false;
  bool _isUploadingAvatar = false;

  @override
  void initState() {
    super.initState();
    _penNameController = TextEditingController(text: widget.initialProfile?.penName ?? '');
    _bioController = TextEditingController(text: widget.initialProfile?.bio ?? '');
    _avatarUrl = widget.initialProfile?.avatarUrl;
  }

  @override
  void dispose() {
    _penNameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadAvatarFromGallery() async {
    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      // 1. INSTANT LOCAL PREVIEW (0 ms lag)
      setState(() {
        _avatarUrl = pickedFile.path;
        _isUploadingAvatar = true;
      });

      // 2. Background Upload to Supabase Storage
      final authRepo = ref.read(authRepositoryProvider);
      final uploadedUrl = await authRepo.uploadAvatarImage(pickedFile);

      if (mounted) {
        setState(() {
          _avatarUrl = uploadedUrl;
          _isUploadingAvatar = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile photo uploaded successfully from gallery!')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingAvatar = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            content: Text('Failed to pick profile photo: $e'),
          ),
        );
      }
    }
  }

  void _showAvatarPickerModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (modalCtx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                height: 4,
                width: 36,
                decoration: BoxDecoration(
                  color: AppColors.borderLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Text('Profile Portrait', style: AppTypography.uiHeadline),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: AppColors.accentPrimary),
                title: const Text('Choose Photo from Local Gallery'),
                onTap: () {
                  Navigator.of(modalCtx).pop();
                  _pickAndUploadAvatarFromGallery();
                },
              ),
              if (_avatarUrl != null && _avatarUrl!.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: AppColors.error),
                  title: const Text('Remove Profile Photo', style: TextStyle(color: AppColors.error)),
                  onTap: () {
                    Navigator.of(modalCtx).pop();
                    setState(() => _avatarUrl = null);
                  },
                ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  void _showChangePasswordModal() {
    final newPassCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();
    bool obscureNew = true;
    bool obscureConfirm = true;
    bool isUpdating = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomCtx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                24,
                16,
                24,
                MediaQuery.of(bottomCtx).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        height: 4,
                        width: 36,
                        decoration: BoxDecoration(
                          color: AppColors.borderLight,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Renew Sanctuary Key',
                      style: AppTypography.storyHeading.copyWith(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Set a new, secure password for entering your account.',
                      style: AppTypography.uiBody.copyWith(color: AppColors.textSecondary, fontSize: 13),
                    ),
                    const SizedBox(height: 20),

                    // New Password field
                    TextField(
                      controller: newPassCtrl,
                      obscureText: obscureNew,
                      decoration: InputDecoration(
                        labelText: 'New Password',
                        hintText: 'At least 8 characters',
                        prefixIcon: const Icon(Icons.lock_outline, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(obscureNew ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                          onPressed: () => setModalState(() => obscureNew = !obscureNew),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Confirm Password field
                    TextField(
                      controller: confirmPassCtrl,
                      obscureText: obscureConfirm,
                      decoration: InputDecoration(
                        labelText: 'Confirm New Password',
                        hintText: 'Repeat new password',
                        prefixIcon: const Icon(Icons.lock_reset, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                          onPressed: () => setModalState(() => obscureConfirm = !obscureConfirm),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),

                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentPrimary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: isUpdating
                          ? null
                          : () async {
                              final newPass = newPassCtrl.text.trim();
                              final confirmPass = confirmPassCtrl.text.trim();

                              if (newPass.length < 8) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Password must be at least 8 characters long.')),
                                );
                                return;
                              }
                              if (newPass != confirmPass) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Passwords do not match.')),
                                );
                                return;
                              }

                              setModalState(() => isUpdating = true);
                              try {
                                final authRepo = ref.read(authRepositoryProvider);
                                await authRepo.updatePassword(newPassword: newPass);
                                if (ctx.mounted) Navigator.of(ctx).pop();
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Sanctuary key renewed successfully!')),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Could not renew key: $e')),
                                  );
                                }
                              } finally {
                                setModalState(() => isUpdating = false);
                              }
                            },
                      child: isUpdating
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text('Update Password', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      newPassCtrl.dispose();
      confirmPassCtrl.dispose();
    });
  }

  Future<void> _handleSave() async {
    final penName = _penNameController.text.trim();
    final bio = _bioController.text.trim();

    if (penName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide a pen name or moniker.')),
      );
      return;
    }

    if (penName.length > 32) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pen name cannot exceed 32 characters.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final authRepo = ref.read(authRepositoryProvider);
      final clearAvatar = _avatarUrl == null && widget.initialProfile?.avatarUrl != null;

      await authRepo.updateProfile(
        penName: penName,
        bio: bio,
        avatarUrl: _avatarUrl,
        clearAvatar: clearAvatar,
      );

      ref.invalidate(currentUserProfileProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sanctuary identity updated beautifully!')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save identity: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentPenName = _penNameController.text.trim();
    final authRepo = ref.watch(authRepositoryProvider);
    final userEmail = authRepo.currentUser?.email ?? 'Unknown';

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Edit Sanctuary Identity', style: AppTypography.pageHeader),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: TextButton(
              onPressed: _isSaving ? null : _handleSave,
              child: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.accentPrimary,
                      ),
                    )
                  : Text(
                      'Save',
                      style: AppTypography.buttonText.copyWith(
                        color: AppColors.accentPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar Hero Section
            Center(
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      GestureDetector(
                        onTap: _pickAndUploadAvatarFromGallery,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.accentPrimary, width: 2),
                          ),
                          child: WrittleAvatar(
                            avatarUrl: _avatarUrl,
                            radius: 46,
                            fallbackInitial: currentPenName.isNotEmpty ? currentPenName[0] : 'W',
                          ),
                        ),
                      ),
                      if (_isUploadingAvatar)
                        const Positioned.fill(
                          child: CircleAvatar(
                            backgroundColor: Colors.black45,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          ),
                        ),
                      Positioned(
                        right: 2,
                        bottom: 2,
                        child: InkWell(
                          onTap: _showAvatarPickerModal,
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: AppColors.accentPrimary,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.surfaceLight, width: 2),
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              size: 15,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextButton.icon(
                    onPressed: _pickAndUploadAvatarFromGallery,
                    icon: const Icon(Icons.photo_library_outlined, size: 16, color: AppColors.accentPrimary),
                    label: Text(
                      'Choose Photo from Gallery',
                      style: AppTypography.captionMeta.copyWith(
                        color: AppColors.accentPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Pen Name Section
            Text(
              'Pen Name / Alias',
              style: AppTypography.uiBodyMedium.copyWith(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 6),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _penNameController,
              builder: (context, value, _) {
                final trimmed = value.text.trim();
                final preview = trimmed.isNotEmpty
                    ? trimmed.toLowerCase().replaceAll(RegExp(r'\s+'), '')
                    : 'author';
                return TextField(
                  controller: _penNameController,
                  maxLength: 32,
                  decoration: InputDecoration(
                    hintText: 'Enter your moniker...',
                    prefixIcon: const Icon(Icons.edit_note, size: 20),
                    helperText: 'Your voice in the sanctuary: @$preview',
                    helperStyle: AppTypography.captionMeta.copyWith(color: AppColors.textSecondary),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            // Bio Section
            Text(
              'About Your Soul (Bio)',
              style: AppTypography.uiBodyMedium.copyWith(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _bioController,
              maxLines: 4,
              maxLength: 200,
              decoration: const InputDecoration(
                hintText: 'Share a glimpse of your thoughts, inspirations, or inner world...',
                prefixIcon: Padding(
                  padding: EdgeInsets.only(bottom: 50.0),
                  child: Icon(Icons.format_quote_outlined, size: 20),
                ),
                helperText: 'Max 200 characters to keep thoughts concise and poetic.',
              ),
            ),
            const SizedBox(height: 24),

            // Account & Security Card
            Text(
              'Account & Security',
              style: AppTypography.uiHeadline.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 10),

            Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Column(
                children: [
                  // Email Row
                  ListTile(
                    leading: const Icon(Icons.mail_outline, color: AppColors.textSecondary),
                    title: const Text('Registered Email', style: TextStyle(fontSize: 14)),
                    subtitle: Text(userEmail, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceWarm,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle, size: 12, color: AppColors.success),
                          SizedBox(width: 4),
                          Text('Active', style: TextStyle(fontSize: 11, color: AppColors.success, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  const Divider(height: 1),

                  // Change Password Row
                  ListTile(
                    leading: const Icon(Icons.lock_outline, color: AppColors.accentPrimary),
                    title: const Text('Change Sanctuary Key', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: const Text('Update your password securely', style: TextStyle(fontSize: 12)),
                    trailing: const Icon(Icons.chevron_right, size: 20, color: AppColors.textTertiary),
                    onTap: _showChangePasswordModal,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 36),
          ],
        ),
      ),
    );
  }
}
