import 'dart:async';

import 'package:meta/meta.dart';

/// Base of a Bloc pattern class
/// Help implement the dispose method
/// Store the state of the Bloc if disposed or not (see [disposed])
abstract class Bloc {
  bool _disposed = false;

  bool get disposed => _disposed;

  @mustCallSuper
  FutureOr<void> dispose() async {
    _disposed = true;
  }
}
