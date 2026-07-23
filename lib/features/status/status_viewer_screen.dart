import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/date_formatter.dart';
import '../../models/status_model.dart';
import '../../services/status_service.dart';

/// Fullscreen viewer for a single user's chronological status updates.
///
/// Behaves like a WhatsApp/Instagram story: a thin progress bar per status
/// at the top, tap-left/tap-right to move between statuses, and auto-advance
/// once each status's timer completes. If [isOwn] is true, the owner can
/// delete the currently visible status.
class StatusViewerScreen extends StatefulWidget {
  final String userId;
  final String userName;
  final String userPhoto;
  final List<StatusModel> statuses;
  final bool isOwn;

  const StatusViewerScreen({
    super.key,
    required this.userId,
    required this.userName,
    required this.userPhoto,
    required this.statuses,
    required this.isOwn,
  });

  @override
  State<StatusViewerScreen> createState() => _StatusViewerScreenState();
}

class _StatusViewerScreenState extends State<StatusViewerScreen>
    with SingleTickerProviderStateMixin {
  static const _statusDuration = Duration(seconds: 5);

  final _statusService = StatusService();
  late final List<StatusModel> _statuses;
  late final PageController _pageController;
  late final AnimationController _progressController;

  int _currentIndex = 0;
  bool _deleting = false;

  @override
  void initState() {
    super.initState();
    _statuses = List<StatusModel>.from(widget.statuses);
    _pageController = PageController();
    _progressController = AnimationController(
      vsync: this,
      duration: _statusDuration,
    )..addStatusListener(_onProgressStatusChanged);

    if (_statuses.isNotEmpty) {
      _progressController.forward();
    }
  }

  void _onProgressStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _goToNext();
    }
  }

  void _restartProgress() {
    _progressController
      ..reset()
      ..forward();
  }

  void _goToNext() {
    if (_currentIndex >= _statuses.length - 1) {
      Navigator.of(context).pop();
      return;
    }

    setState(() => _currentIndex++);
    _pageController.jumpToPage(_currentIndex);
    _restartProgress();
  }

  void _goToPrevious() {
    if (_currentIndex == 0) {
      _restartProgress();
      return;
    }

    setState(() => _currentIndex--);
    _pageController.jumpToPage(_currentIndex);
    _restartProgress();
  }

  Future<void> _deleteCurrent() async {
    if (_deleting) return;

    setState(() => _deleting = true);
    _progressController.stop();

    final status = _statuses[_currentIndex];

    try {
      await _statusService.deleteStatus(status);
      if (!mounted) return;

      if (_statuses.length == 1) {
        Navigator.of(context).pop();
        return;
      }

      setState(() {
        _statuses.removeAt(_currentIndex);
        if (_currentIndex >= _statuses.length) {
          _currentIndex = _statuses.length - 1;
        }
        _deleting = false;
      });

      _pageController.jumpToPage(_currentIndex);
      _restartProgress();
    } catch (e) {
      if (!mounted) return;
      setState(() => _deleting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not delete status: $e')),
      );
      _progressController.forward();
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_statuses.isEmpty) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            'No status updates',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    final current = _statuses[_currentIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _statuses.length,
              itemBuilder: (context, index) {
                final status = _statuses[index];

                return Center(
                  child: Image.network(
                    status.imageUrl,
                    fit: BoxFit.contain,
                    width: double.infinity,
                    height: double.infinity,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      );
                    },
                    errorBuilder: (context, error, stack) => const Center(
                      child: Icon(
                        Icons.broken_image,
                        color: Colors.white54,
                        size: 48,
                      ),
                    ),
                  ),
                );
              },
            ),

            // Tap zones: left third goes back, right two-thirds goes next.
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: _goToPrevious,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: _goToNext,
                  ),
                ),
              ],
            ),

            // Progress bars.
            Positioned(
              top: 8,
              left: 8,
              right: 8,
              child: Row(
                children: List.generate(_statuses.length, (index) {
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: AnimatedBuilder(
                        animation: _progressController,
                        builder: (context, _) {
                          double value;
                          if (index < _currentIndex) {
                            value = 1;
                          } else if (index == _currentIndex) {
                            value = _progressController.value;
                          } else {
                            value = 0;
                          }

                          return ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: value,
                              minHeight: 3,
                              backgroundColor: Colors.white24,
                              valueColor:
                                  const AlwaysStoppedAnimation(Colors.white),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                }),
              ),
            ),

            // Header: avatar, name, time, delete/close.
            Positioned(
              top: 20,
              left: 8,
              right: 8,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.surfaceLight,
                    backgroundImage: widget.userPhoto.isNotEmpty
                        ? NetworkImage(widget.userPhoto)
                        : null,
                    child: widget.userPhoto.isEmpty
                        ? Text(
                            widget.userName.isNotEmpty
                                ? widget.userName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(color: Colors.white),
                          )
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.isOwn ? 'My Status' : widget.userName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          DateFormatter.formatChatTime(current.createdAt),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (widget.isOwn)
                    IconButton(
                      icon: _deleting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.delete_outline,
                              color: Colors.white),
                      onPressed: _deleting ? null : _deleteCurrent,
                    ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
