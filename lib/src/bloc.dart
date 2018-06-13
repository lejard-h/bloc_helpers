import 'package:meta/meta.dart';

abstract class Bloc {
  bool _disposed = false;

  bool get disposed => _disposed;

  @mustCallSuper
  void dispose() {
    _disposed = true;
  }
}
