import 'package:flutter/widgets.dart';
import '../../services/presence_service.dart';

class AppLifecycleManager extends WidgetsBindingObserver {
  AppLifecycleManager({
    required this.uid,
    PresenceService? presenceService,
  }) : _presenceService = presenceService ?? PresenceService();

  final String uid;
  final PresenceService _presenceService;

  void start() {
    WidgetsBinding.instance.addObserver(this);
    _presenceService.setOnline(uid);
  }

  void stop() {
    WidgetsBinding.instance.removeObserver(this);
    _presenceService.setOffline(uid);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _presenceService.setOnline(uid);
        break;

      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _presenceService.setOffline(uid);
        break;
    }
  }
}