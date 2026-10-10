import 'package:flutter/foundation.dart';

/// Central reactive event bus notifying screens to re-fetch their data immediately
class AppDataNotifier extends ChangeNotifier {
  static final AppDataNotifier instance = AppDataNotifier._internal();
  AppDataNotifier._internal();

  /// Notify all subscribed screens (Dashboard, Subscriptions, Ledger, Analytics)
  void notifyDataChanged() {
    notifyListeners();
  }
}
