import 'package:flutter/foundation.dart';

/// Simple in-memory UI settings used at runtime. Kept intentionally lightweight
/// (no persistence) because ranking mode is a view-model driven behavior.
class UISettings extends ChangeNotifier {
  bool _useScaledRanking = true;

  bool get useScaledRanking => _useScaledRanking;

  void setUseScaledRanking(bool v) {
    if (_useScaledRanking == v) return;
    _useScaledRanking = v;
    notifyListeners();
  }

  void toggleScaledRanking() => setUseScaledRanking(!_useScaledRanking);
}
