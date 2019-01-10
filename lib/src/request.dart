part of 'async.dart';

mixin _RequestMixin<Request, Response> on AsyncTaskBloc<Request, Response> {
  var _markerKey = Object();

  Future<void> _doRequest(Request input) async {
    _runningBehavior.add(true);
    try {
      final key = _markerKey = Object();

      final res = await run(input);

      if (key != _markerKey) return;

      _resultPublisher.add(res);
    } catch (e, s) {
      _resultPublisher.addError(e, s);
    } finally {
      _runningBehavior.add(false);
    }
  }

  /// Sink to trigger the request
  /// the response and errors are push in the [onResult] stream
  @Deprecated('Use callSink')
  Sink<Request> get requestSink => callSink;

  /// Stream representing the current state of the bloc
  /// true if a request is ongoing
  @Deprecated('Use onRunning')
  ValueObservable<bool> get onLoading => onRunning;

  /// Request stream
  @Deprecated('Use onCall')
  Observable<Request> get onRequest => onCall;

  /// Response stream
  @Deprecated('Use onResult')
  Observable<Response> get onResponse => onResult;
}

/// Helper class to implement asynchronous call to a server
/// Need to implement the [request] method
///
/// The difference with an AsyncTaskBloc
/// Is that the taskHandler is using a key to mark the request
/// if you trigger 2 request at the same time of at a small interval
/// ```dart
/// callSink.add(request);
/// callSink.add(request);
/// ```
/// The result of the first one will be ignored
abstract class RequestBloc<Request, Response>
    extends AsyncTaskBloc<Request, Response>
    with _RequestMixin<Request, Response> {
  RequestBloc();

  /// Create a Request Bloc by passing the request function
  ///
  /// ```dart
  /// final requestBloc = new RequestBloc<String,int>.func(myRequest);
  ///
  /// Future<int> myRequest(String input) async {
  ///   ...
  /// }
  /// ```
  factory RequestBloc.func(TaskHandler<Request, Response> handler) =>
      new _RequestBloc<Request, Response>(handler);

  @protected
  FutureOr<Response> request(Request input);

  @protected
  FutureOr<Response> run(Request input) => request(input);

  @override
  Future<void> _handleTask(Request input) => _doRequest(input);
}

/// Helper class to implement asynchronous call to a server
/// Need to implement the [request] method
/// The response is cached to avoid multiple request to a server for exemple
///
/// ```dart
/// cachedRequestBloc.requestSink.add('foo'); /// will call [request]
/// cachedRequestBloc.onResult.first; /// response 'a'
///
/// cachedRequestBloc.requestSink.add('foo'); /// same input, won't call [request]
/// cachedRequestBloc.onResult.first; /// response 'a'
/// ```
///
/// If the request input change it will invalidate the cache and call [request]
abstract class CachedRequestBloc<Request, Response>
    extends AsyncCachedTaskBloc<Request, Response>
    with _RequestMixin<Request, Response> {
  /// [seedValue] will init the value of the [cachedResult]
  CachedRequestBloc({Response seedValue}) : super(seedValue: seedValue);

  /// Create a Cached Request Bloc by passing the request function
  ///
  /// ```dart
  /// final requestBloc = new RequestBloc<String,int>.func(myRequest);
  ///
  /// Future<int> myRequest(String input) async {
  ///   ...
  /// }
  /// ```
  factory CachedRequestBloc.func(TaskHandler<Request, Response> handler) =>
      new _CachedRequestBloc<Request, Response>(handler);

  /// cached response stream
  /// Use a Behavior subject so will emit the last value at each `listen`
  @Deprecated('Use cachedResult')
  ValueObservable<Response> get cachedResponse => cachedResult;

  /// Sink to manualy update the cachedResponse
  @Deprecated('Use updateCachedResultSink')
  Sink<Response> get updateCachedResponseSink => updateCachedResultSink;

  @protected
  FutureOr<Response> request(Request input);

  @protected
  FutureOr<Response> run(Request input) => request(input);

  @override
  Future<void> _handleTask(Request input) async {
    final hitCache = _handleCache(input);

    if (hitCache) return;

    await _doRequest(input);
  }
}

class _CachedRequestBloc<Request, Response>
    extends CachedRequestBloc<Request, Response> {
  final TaskHandler<Request, Response> _request;

  _CachedRequestBloc(this._request) : super();

  @override
  FutureOr<Response> request(Request input) => _request(input);
}

class _RequestBloc<Request, Response> extends RequestBloc<Request, Response> {
  final TaskHandler<Request, Response> _request;

  _RequestBloc(this._request) : super();

  @override
  FutureOr<Response> request(Request input) => _request(input);
}
