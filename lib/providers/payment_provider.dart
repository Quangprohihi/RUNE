import 'package:flutter/foundation.dart';

import '../core/errors/friendly_error.dart';
import '../data/repositories/payment_repository.dart';

class PaymentProvider extends ChangeNotifier {
  PaymentProvider(this._repository);

  final PaymentRepository _repository;
  PaymentCheckout? _checkout;
  PaymentStatus? _status;
  bool _isLoading = false;
  String? _error;

  PaymentCheckout? get checkout => _checkout;
  PaymentStatus? get status => _status;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Drops any in-flight checkout state from the previous account.
  void resetForAccountSwitch() {
    _checkout = null;
    _status = null;
    _error = null;
    notifyListeners();
  }

  Future<PaymentCheckout> createVnpayPayment(String productCode) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final checkout = await _repository.createVnpayPayment(productCode);
      _checkout = checkout;
      _status = null;
      return checkout;
    } catch (error) {
      _error = friendlyError(error);
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<PaymentStatus> loadStatus(String orderId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final status = await _repository.getPaymentStatus(orderId);
      _status = status;
      return status;
    } catch (error) {
      _error = friendlyError(error);
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
