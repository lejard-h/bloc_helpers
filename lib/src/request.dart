import 'dart:async';
import 'package:rxdart/rxdart.dart';
import 'package:meta/meta.dart';
import 'bloc.dart';

typedef Future<Response> RequestHandler<Request, Response>(Request input);

/// Helper class to implement asynchronous call to a server
/// Need to implement the [request] method
abstract class RequestBloc<Request, Response> extends Bloc {
  var _markerKey = new Object();

  final _requestPublisher = new PublishSubject<Request>();

  // ignore: close_sinks
  final _responsePublisher = new PublishSubject<Response>();

  // ignore: close_sinks
  final _loadingBehavior = new BehaviorSubject<bool>(seedValue: false);

  RequestBloc() {
    onRequest.listen(_handleRequest);
  }

  Future<void> _handleRequest(Request input) async {
    _loadingBehavior.add(true);

    try {
      final key = _markerKey = new Object();
      final res = await request(input);

      if (key != _markerKey) return;

      _responsePublisher.add(res);
    } catch (e, s) {
      _responsePublisher.addError(e, s);
    }
    _loadingBehavior.add(false);
  }

  @mustCallSuper
  @override
  void dispose() {
    _requestPublisher.close();

    super.dispose();
  }

  /// Sink to trigger the request
  /// the response and errors are push in the [onResponse] stream
  Sink<Request> get requestSink => _requestPublisher.sink;

  /// Stream representing the current state of the bloc
  /// true if a request is ongoing
  Stream<bool> get onLoading => _loadingBehavior.stream;

  /// Request stream
  Stream<Request> get onRequest => _requestPublisher.stream;

  /// Response stream
  Stream<Response> get onResponse => _responsePublisher.stream;

  /// Create a Request Bloc by passing the request function
  ///
  /// ```dart
  /// final requestBloc = new RequestBloc<String,int>.func(myRequest);
  ///
  /// Future<int> myRequest(String input) async {
  ///   ...
  /// }
  /// ```
  factory RequestBloc.func(RequestHandler<Request, Response> handler) =>
      new _RequestBloc<Request, Response>(handler);

  @protected
  Future<Response> request(Request input);
}

/// Helper class to implement asynchronous call to a server
/// Need to implement the [request] method
/// The response is cached to avoid multiple request to a server for exemple
///
/// ```dart
/// cachedRequestBloc.requestSink.add('foo'); /// will call [request]
/// cachedRequestBloc.onResponse.first; /// response 'a'
///
/// cachedRequestBloc.requestSink.add('foo'); /// same input, won't call [request]
/// cachedRequestBloc.onResponse.first; /// response 'a'
/// ```
///
/// If the request input change it will invalidate the cache and call [request]
abstract class CachedRequestBloc<Request, Response>
    extends RequestBloc<Request, Response> {
  var _cached = false;

  // ignore: close_sinks
  final BehaviorSubject<Response> _cachedResponseBehavior;

  // ignore: close_sinks
  final _cachedRequestBehavior = new BehaviorSubject<Request>();
  final _invalidatePublisher = new PublishSubject<Response>();

  /// [seedValue] will init the value of the [cachedResponse]
  CachedRequestBloc({Response seedValue})
      : _cachedResponseBehavior =
            new BehaviorSubject<Response>(seedValue: seedValue),
        super() {
    onResponse.listen(_onResponse, onError: _onError);
    _invalidatePublisher.stream.listen((value) {
      _cached = false;
      _cachedRequestBehavior.add(null);

      if (disposed) return;
      _cachedResponseBehavior.add(value ?? seedValue);
    });
  }

  @override
  Future<void> _handleRequest(Request input) async {
    if (_cachedRequestBehavior.value == input && _cached) {
      _responsePublisher.add(_cachedResponseBehavior.value);
      return;
    }
    _cachedRequestBehavior.add(input);
    super._handleRequest(input);
  }

  void _onError(e, s) => _cachedResponseBehavior.addError(e, s);

  void _onResponse(Response response) {
    _cached = true;
    if (disposed) return;
    _cachedResponseBehavior.add(response);
  }

  @override
  @mustCallSuper
  void dispose() {
    _invalidatePublisher.close();
    _cachedResponseBehavior.close();
    super.dispose();
  }

  /// Create a Cached Request Bloc by passing the request function
  ///
  /// ```dart
  /// final requestBloc = new RequestBloc<String,int>.func(myRequest);
  ///
  /// Future<int> myRequest(String input) async {
  ///   ...
  /// }
  /// ```
  factory CachedRequestBloc.func(RequestHandler<Request, Response> handler) =>
      new _CachedRequestBloc<Request, Response>(handler);

  /// cached response stream
  /// Use a Behavior subject so will emit the last value at each `listen`
  Stream<Response> get cachedResponse => _cachedResponseBehavior.stream;

  /// Sink to invalidate the cache
  /// Can take a value if you want to put back the seedValue of the cachedResponse
  Sink<Response> get invalidateCacheSink => _invalidatePublisher.sink;

  /// Sink to manualy update the cachedResponse
  Sink<Response> get updateCachedResponseSink => _cachedResponseBehavior.sink;
}

class _CachedRequestBloc<Request, Response>
    extends CachedRequestBloc<Request, Response> {
  final RequestHandler<Request, Response> _request;

  _CachedRequestBloc(this._request) : super();

  @override
  Future<Response> request(Request input) => _request(input);
}

class _RequestBloc<Request, Response> extends RequestBloc<Request, Response> {
  final RequestHandler<Request, Response> _request;

  _RequestBloc(this._request) : super();

  @override
  Future<Response> request(Request input) => _request(input);
}
