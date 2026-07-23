import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/date_formatter.dart';
import '../../models/connection_model.dart';
import '../../models/status_model.dart';
import '../../models/user_profile_model.dart';
import '../../services/auth_service.dart';
import '../../services/connection_service.dart';
import '../../services/status_service.dart';
import '../../services/user_service.dart';
import 'status_viewer_screen.dart';
import 'widgets/status_avatar.dart';

/// The Status tab: "My Status" at the top, followed by active status
/// updates from connected/friend users. Mirrors WhatsApp's Status screen.
class StatusScreen extends StatefulWidget {
  const StatusScreen({super.key});

  @override
  State<StatusScreen> createState() => _StatusScreenState();
}

class _StatusScreenState extends State<StatusScreen> {
  final _authService = AuthService();
  final _connectionService = ConnectionService();
  final _userService = UserService();
  final _statusService = StatusService();
  final _picker = ImagePicker();

  bool _uploading = false;
  double _uploadProgress = 0;

  @override
  void initState() {
    super.initState();

    final uid = _authService.currentUser?.uid;
    if (uid != null) {
      // Best-effort cleanup of this user's own expired statuses.
      _statusService.deleteExpiredForUser(uid);
    }
  }

  Future<void> _addStatus() async {
    final uid = _authService.currentUser?.uid;
    if (uid == null) return;

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(
                Icons.camera_alt_outlined,
                color: AppColors.icon,
              ),
              title: const Text(
                'Camera',
                style: TextStyle(color: AppColors.textPrimary),
              ),
              onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library_outlined,
                color: AppColors.icon,
              ),
              title: const Text(
                'Gallery',
                style: TextStyle(color: AppColors.textPrimary),
              ),
              onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );

    if (source == null) return;

    final picked = await _picker.pickImage(source: source, imageQuality: 85);
    if (picked == null) return;

    setState(() {
      _uploading = true;
      _uploadProgress = 0;
    });

    try {
      await _statusService.uploadStatus(
        uid: uid,
        file: File(picked.path),
        onProgress: (progress) {
          if (mounted) {
            setState(() => _uploadProgress = progress);
          }
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload status: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _uploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = _authService.currentUser?.uid;

    if (uid == null) {
      return const Center(
        child: Text(
          'User not logged in',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return SafeArea(
      top: false,
      child: Column(
        children: [
          if (_uploading)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: 8,
              ),
              child: Column(
                children: [
                  LinearProgressIndicator(
                    value: _uploadProgress > 0 ? _uploadProgress : null,
                    backgroundColor: AppColors.surfaceLight,
                    valueColor:
                        const AlwaysStoppedAnimation(AppColors.primary),
                  ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Uploading status... '
                      '${(_uploadProgress * 100).clamp(0, 100).toStringAsFixed(0)}%',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          _MyStatusTile(
            uid: uid,
            userService: _userService,
            statusService: _statusService,
            onAdd: _addStatus,
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              4,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Recent updates',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<ConnectionModel>>(
              stream: _connectionService.getConnections(uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final connections = snapshot.data ?? [];

                if (connections.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(AppSpacing.lg),
                      child: Text(
                        'Connect with someone to see their status '
                        'updates here.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 100),
                  itemCount: connections.length,
                  itemBuilder: (context, index) {
                    final friendId = connections[index].users.firstWhere(
                          (id) => id != uid,
                          orElse: () => '',
                        );

                    if (friendId.isEmpty) return const SizedBox.shrink();

                    return _FriendStatusTile(
                      friendId: friendId,
                      userService: _userService,
                      statusService: _statusService,
                    );
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

/// "My Status" row: shows the current user's own active statuses (if any)
/// with a tappable avatar, and an add button to upload a new one.
class _MyStatusTile extends StatelessWidget {
  final String uid;
  final UserService userService;
  final StatusService statusService;
  final VoidCallback onAdd;

  const _MyStatusTile({
    required this.uid,
    required this.userService,
    required this.statusService,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UserProfileModel?>(
      stream: userService.userStream(uid),
      builder: (context, userSnap) {
        final profile = userSnap.data;

        return StreamBuilder<List<StatusModel>>(
          stream: statusService.statusesForUser(uid),
          builder: (context, statusSnap) {
            final statuses = statusSnap.data ?? [];
            final hasStatus = statuses.isNotEmpty;

            return ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: 4,
              ),
              leading: GestureDetector(
                onTap: hasStatus
                    ? () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => StatusViewerScreen(
                              userId: uid,
                              userName: profile?.fullName ?? 'You',
                              userPhoto: profile?.photoUrl ?? '',
                              statuses: statuses,
                              isOwn: true,
                            ),
                          ),
                        )
                    : onAdd,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    StatusAvatar(
                      imageUrl: profile?.photoUrl ?? '',
                      label: profile?.fullName ?? 'You',
                      hasStatus: hasStatus,
                    ),
                    if (!hasStatus)
                      Positioned(
                        right: -2,
                        bottom: -2,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: AppColors.background,
                            shape: BoxShape.circle,
                          ),
                          child: const CircleAvatar(
                            radius: 10,
                            backgroundColor: AppColors.primary,
                            child: Icon(
                              Icons.add,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              title: const Text(
                'My Status',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                hasStatus
                    ? 'Tap to view - '
                        '${DateFormatter.formatChatTime(statuses.last.createdAt)}'
                    : 'Tap to add a status update',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12.5,
                ),
              ),
              trailing: IconButton(
                icon: const Icon(
                  Icons.camera_alt_outlined,
                  color: AppColors.icon,
                ),
                onPressed: onAdd,
              ),
            );
          },
        );
      },
    );
  }
}

/// A single connected friend's row, showing their latest active status
/// with a ring avatar. Hidden entirely if the friend has no active status.
class _FriendStatusTile extends StatelessWidget {
  final String friendId;
  final UserService userService;
  final StatusService statusService;

  const _FriendStatusTile({
    required this.friendId,
    required this.userService,
    required this.statusService,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UserProfileModel?>(
      stream: userService.userStream(friendId),
      builder: (context, userSnap) {
        final profile = userSnap.data;

        return StreamBuilder<List<StatusModel>>(
          stream: statusService.statusesForUser(friendId),
          builder: (context, statusSnap) {
            final statuses = statusSnap.data ?? [];

            if (statuses.isEmpty) {
              return const SizedBox.shrink();
            }

            return ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: 4,
              ),
              leading: StatusAvatar(
                imageUrl: profile?.photoUrl ?? '',
                label: profile?.fullName ?? '?',
                hasStatus: true,
              ),
              title: Text(
                profile?.fullName ?? 'Unknown',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                DateFormatter.formatChatTime(statuses.last.createdAt),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12.5,
                ),
              ),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => StatusViewerScreen(
                    userId: friendId,
                    userName: profile?.fullName ?? 'Unknown',
                    userPhoto: profile?.photoUrl ?? '',
                    statuses: statuses,
                    isOwn: false,
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
