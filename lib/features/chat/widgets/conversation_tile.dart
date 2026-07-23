import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../models/user_profile_model.dart';
import '../../../services/user_service.dart';

/// A single row in the chat list.
///
/// Presence (the online dot) is fetched internally via [UserService], scoped
/// to just the avatar, so a presence update only rebuilds the small avatar
/// subtree rather than the whole tile or the whole list.
class ConversationTile extends StatefulWidget {
  final String partnerId;
  final String partnerName;
  final String partnerPhoto;
  final String lastMessage;
  final String time;
  final int unreadCount;
  final VoidCallback onTap;

  const ConversationTile({
    super.key,
    required this.partnerId,
    required this.partnerName,
    required this.partnerPhoto,
    required this.lastMessage,
    required this.time,
    required this.unreadCount,
    required this.onTap,
  });

  @override
  State<ConversationTile> createState() => _ConversationTileState();
}

class _ConversationTileState extends State<ConversationTile> {
  final UserService _userService = UserService();

  @override
  Widget build(BuildContext context) {
    final hasUnread = widget.unreadCount > 0;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 8),
            child: child,
          ),
        );
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: widget.onTap,
          child: Container(
            margin: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 6,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.border,
              ),
            ),
            child: Row(
              children: [
                _Avatar(
                  partnerId: widget.partnerId,
                  partnerName: widget.partnerName,
                  partnerPhoto: widget.partnerPhoto,
                  userService: _userService,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.partnerName,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.lastMessage.isEmpty
                            ? 'Say hello 👋'
                            : widget.lastMessage,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13.5,
                          color: hasUnread
                              ? AppColors.textPrimary.withValues(alpha: 0.9)
                              : AppColors.textSecondary,
                          fontWeight:
                              hasUnread ? FontWeight.w500 : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      widget.time,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: hasUnread
                            ? AppColors.primary
                            : AppColors.textSecondary,
                        fontWeight:
                            hasUnread ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 8),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      transitionBuilder: (child, animation) => ScaleTransition(
                        scale: animation,
                        child: child,
                      ),
                      child: hasUnread
                          ? Container(
                              key: ValueKey(widget.unreadCount),
                              constraints: const BoxConstraints(
                                minWidth: 20,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 3,
                              ),
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.primary,
                                    AppColors.secondary,
                                  ],
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                widget.unreadCount > 99
                                    ? '99+'
                                    : widget.unreadCount.toString(),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          : const SizedBox(
                              key: ValueKey('no-unread'),
                              height: 20,
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Avatar with a small online-presence dot. Isolated in its own widget so a
/// presence update rebuilds only this small subtree, not the whole tile.
class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.partnerId,
    required this.partnerName,
    required this.partnerPhoto,
    required this.userService,
  });

  final String partnerId;
  final String partnerName;
  final String partnerPhoto;
  final UserService userService;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UserProfileModel?>(
      stream: userService.userStream(partnerId),
      builder: (context, snapshot) {
        final isOnline = snapshot.data?.online ?? false;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isOnline
                      ? AppColors.success
                      : AppColors.border,
                  width: isOnline ? 2 : 1,
                ),
              ),
              padding: const EdgeInsets.all(2),
              child: CircleAvatar(
                backgroundColor: AppColors.surfaceLight,
                backgroundImage: partnerPhoto.isNotEmpty
                    ? NetworkImage(partnerPhoto)
                    : null,
                child: partnerPhoto.isEmpty
                    ? Text(
                        partnerName.isNotEmpty
                            ? partnerName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      )
                    : null,
              ),
            ),
            if (isOnline)
              Positioned(
                right: 1,
                bottom: 1,
                child: Container(
                  width: 13,
                  height: 13,
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.surface,
                      width: 2,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}