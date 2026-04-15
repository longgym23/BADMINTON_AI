import 'package:flutter/foundation.dart';

abstract class ViewModel extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;
  bool _isDisposed = false;

  void setLoading(bool value) {
    if (_isLoading == value) return;
    _isLoading = value;
    safeNotifyListeners();
  }

  void setError(String? message) {
    if (_errorMessage == message) return;
    _errorMessage = message;
    safeNotifyListeners();
  }

  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    safeNotifyListeners();
  }

  @protected
  void safeNotifyListeners() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _errorMessage = null;
    super.dispose();
  }
}
