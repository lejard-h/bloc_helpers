import 'dart:async';

import 'package:bloc_helpers/bloc_helpers.dart';
import 'package:meta/meta.dart';
import 'package:rxdart/rxdart.dart';

part 'request.dart';

typedef FutureOr<Result> TaskHandler<Parameter, Result>(Parameter parameter);

mixin _AsyncMixin<Parameter, Result> {
  final _callPublisher = PublishSubject<Parameter>();

  // ignore: close_sinks
  final _resultPublisher = PublishSubject<Result>();

  // ignore: close_sinks
  final _runningBehavior = BehaviorSubject<bool>.seeded(false);

  /// Sink to start the task
  /// the result and errors are push in the [onResult] stream
  Sink<Parameter> get callSink => _callPublisher.sink;

  /// Stream representing the current state of the bloc
  /// true if task is ongoing
  ValueObservable<bool> get running => _runningBehavior.stream;

  /// Task will start stream
  Observable<Parameter> get onCall => _callPublisher.stream;

  /// Result stream
  Observable<Result> get onResult => _resultPublisher.stream;

  Future<void> _disposeAsyncMixin() async {
    await _callPublisher.close();
  }
}

mixin _CachedAsyncMixin<Parameter, Result> {
  var _cached = false;

  BehaviorSubject<Result> get _cachedResultBehavior;
  PublishSubject<Result> get _resultPublisher;
  bool get disposed;

  // ignore: close_sinks
  final _cachedParameterBehavior = BehaviorSubject<Parameter>();
  final _invalidatePublisher = PublishSubject<Result>();

  // return true if hit cache
  bool _handleCache(Parameter input) {
    if (_cachedParameterBehavior.value == input && _cached) {
      _resultPublisher.add(_cachedResultBehavior.value);
      return true;
    }
    _cachedParameterBehavior.add(input);
    return false;
  }

  void _onError(e, s) {
    if (disposed) return;
    _cachedResultBehavior.addError(e, s);
  }

  void _onResult(Result response) {
    _cached = true;
    if (disposed) return;
    _cachedResultBehavior.add(response);
  }

  Future<void> _disposeCachedAsyncMixin() async {
    await _invalidatePublisher.close();
    await _cachedResultBehavior.close();
  }

  /// cached result stream
  /// Use a Behavior subject so will emit the last value at each `listen`
  ValueObservable<Result> get cachedResult => _cachedResultBehavior.stream;

  /// Sink to invalidate the cache
  /// Can take a value if you want to put back the seedValue of the [cachedResult]
  Sink<Result> get invalidateCacheSink => _invalidatePublisher.sink;

  /// Sink to manualy update the [cachedResult]
  Sink<Result> get updateCachedResultSink => _cachedResultBehavior.sink;
}

/// Helper class to implement asynchronous task
/// Need to implement the [run] method
abstract class AsyncTaskBloc<Parameter, Result> extends Bloc
    with _AsyncMixin<Parameter, Result> {
  AsyncTaskBloc() {
    onCall.listen(_handleTask);
  }

  Future<void> _handleTask(Parameter input) async {
    _runningBehavior.add(true);
    try {
      final res = await run(input);
      _resultPublisher.add(res);
    } catch (e, s) {
      _resultPublisher.addError(e, s);
    } finally {
      _runningBehavior.add(false);
    }
  }

  @mustCallSuper
  @override
  Future<void> dispose() async {
    await _disposeAsyncMixin();

    await super.dispose();
  }

  /// Create a Task Bloc by passing the function
  ///
  /// ```dart
  /// final taskBloc = new TaskBloc<String,int>.func(myRequest);
  ///
  /// Future<int> myRequest(String param) async {
  ///   ...
  /// }
  /// ```
  factory AsyncTaskBloc.func(TaskHandler<Parameter, Result> handler) =>
      _AsyncBloc<Parameter, Result>(handler);

  @protected
  FutureOr<Result> run(Parameter parameter);
}

class _AsyncBloc<Parameter, Result> extends AsyncTaskBloc<Parameter, Result> {
  final TaskHandler<Parameter, Result> _request;

  _AsyncBloc(this._request) : super();

  @override
  FutureOr<Result> run(Parameter parameter) => _request(parameter);
}

/// Helper class to implement asynchronous task
/// Need to implement the [run] method
/// The result is cached to avoid multiple request to a server for exemple
///
/// ```dart
/// cachedTaskBloc.callSink.add('foo'); /// will call [run]
/// cachedTaskBloc.onResult.first; /// response 'a'
///
/// cachedTaskBloc.callSink.add('foo'); /// same input, won't call [run]
/// cachedTaskBloc.onResult.first; /// response 'a'
/// ```
///
/// If the input change it will invalidate the cache and call [run]
abstract class AsyncCachedTaskBloc<Parameter, Result>
    extends AsyncTaskBloc<Parameter, Result>
    with _CachedAsyncMixin<Parameter, Result> {
  AsyncCachedTaskBloc()
      : _cachedResultBehavior = BehaviorSubject<Result>(),
        super() {
    _init(null);
  }

  /// [seedValue] will init the value of the [cachedResult]
  AsyncCachedTaskBloc.seeded(Result seedValue)
      : _cachedResultBehavior = BehaviorSubject<Result>.seeded(seedValue),
        super() {
    _init(seedValue);
  }

  void _init(Result seedValue) {
    onResult.listen(_onResult, onError: _onError);
    _invalidatePublisher.stream.listen((value) {
      _cached = false;
      _cachedParameterBehavior.add(null);

      if (disposed) return;
      _cachedResultBehavior.add(value ?? seedValue);
    });
  }

  @override
  final BehaviorSubject<Result> _cachedResultBehavior;

  @override
  Future<void> _handleTask(Parameter input) async {
    final hitCache = _handleCache(input);

    if (hitCache) return;

    super._handleTask(input);
  }

  @override
  @mustCallSuper
  Future<void> dispose() async {
    await _disposeCachedAsyncMixin();
    await super.dispose();
  }

  /// Create a Cached Task Bloc by passing the task function
  ///
  /// ```dart
  /// final requestBloc = new AsyncCachedTaskBloc<String,int>.func(myRequest);
  ///
  /// Future<int> myRequest(String input) async {
  ///   ...
  /// }
  /// ```
  factory AsyncCachedTaskBloc.func(TaskHandler<Parameter, Result> handler) =>
      _AsyncCachedTaskBloc<Parameter, Result>(handler);
}

class _AsyncCachedTaskBloc<Request, Response>
    extends AsyncCachedTaskBloc<Request, Response> {
  final TaskHandler<Request, Response> _request;

  _AsyncCachedTaskBloc(this._request) : super();

  @override
  FutureOr<Response> run(Request input) => _request(input);
}
