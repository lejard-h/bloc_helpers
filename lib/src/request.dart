import 'dart:async';
import 'package:rxdart/rxdart.dart';
import 'package:meta/meta.dart';
import 'bloc.dart';

typedef Future<Response> RequestHandler<Request, Response>(Request input);

class RequestBloc<Request, Response> implements Bloc {
  var _markerKey = new Object();
  final RequestHandler _request;

  final _requestPublisher = new PublishSubject<Request>();

  final _responsePublisher = new PublishSubject<Response>();

  final _loadingBehavior = new BehaviorSubject<bool>(seedValue: false);

  RequestBloc(this._request) {
    _requestPublisher.stream.listen(_handleRequest);
  }

  Future<void> _handleRequest(Request input) async {
    _loadingBehavior.add(true);

    try {
      final key = _markerKey = new Object();
      final res = await _request(input);

      if (key != _markerKey) return;

      _responsePublisher.add(res);
    } catch (e, s) {
      _responsePublisher.addError(e, s);
    }
    _loadingBehavior.add(false);
  }

  @mustCallSuper
  void dispose() {
    _requestPublisher.close();
  }

  Sink<Request> get requestSink => _requestPublisher.sink;

  Stream<bool> get onLoading => _loadingBehavior.stream;

  Stream<Response> get onResponse => _responsePublisher.stream;
}

class CachedRequestBloc<Request, Response>
    extends RequestBloc<Request, Response> {
  final _cachedResponseBehavior = new BehaviorSubject<Response>();
  final _cachedRequestBehavior = new BehaviorSubject<Request>();
  final _invalidatePublisher = new PublishSubject<void>();

  CachedRequestBloc(RequestHandler request) : super(request) {
    _responsePublisher.stream.listen(_onResponse, onError: _onError);
    _invalidatePublisher.stream.listen((_) {
      _cachedRequestBehavior.add(null);
      _cachedResponseBehavior.add(null);
    });
  }

  @override
  Future<void> _handleRequest(Request input) async {
    if (_cachedRequestBehavior.value == input &&
        _cachedResponseBehavior.value != null) {
      _responsePublisher.add(_cachedResponseBehavior.value);
      return;
    }
    _cachedRequestBehavior.add(input);
    super._handleRequest(input);
  }

  void _onError(_) => _cachedResponseBehavior.add(null);

  void _onResponse(Response response) => _cachedResponseBehavior.add(response);

  @override
  @mustCallSuper
  void dispose() {
    _invalidatePublisher.close();
    super.dispose();
  }

  Stream<Response> get cachedResponse => _cachedResponseBehavior.stream;

  Stream<Request> get cachedRequest => _cachedRequestBehavior.stream;

  Sink<void> get invalidateCacheSink => _invalidatePublisher.sink;
}
