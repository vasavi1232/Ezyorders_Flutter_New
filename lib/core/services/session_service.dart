import 'dart:async';

class SessionService {
  final _sessionExpiredController = StreamController<void>.broadcast();

  Stream<void> get sessionExpiredStream => _sessionExpiredController.stream;

  void notifySessionExpired() {
    _sessionExpiredController.add(null);
  }

  void dispose() {
    _sessionExpiredController.close();
  }
}
