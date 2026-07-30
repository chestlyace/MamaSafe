import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  bool _isConnected = true;
  final StreamController<bool> _controller = StreamController<bool>.broadcast();

  ConnectivityService() {
    _connectivity.onConnectivityChanged.listen((results) {
      _isConnected = results.any((r) => r != ConnectivityResult.none);
      _controller.add(_isConnected);
    });
  }

  Stream<bool> get isConnected => _controller.stream;
  bool get currentValue => _isConnected;

  void dispose() => _controller.close();
}

final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  return ConnectivityService();
});
