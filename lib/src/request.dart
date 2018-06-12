import 'dart:async';
import 'package:rxdart/rxdart.dart';
import 'package:meta/meta.dart';
import 'bloc.dart';

abstract class RequestBloc<Request, Response> implements Bloc {
  final _requestPublisher = new PublishSubject<Request>();

  final _responsePublisher = new PublishSubject<Response>();

  final _loadingBehavior = new BehaviorSubject<bool>(seedValue: false);

  RequestBloc() {
    _requestPublisher.stream.listen(_handleRequest);
  }

  Future<void> _handleRequest(Request input) async {
    if (_loadingBehavior.value) return;

    _loadingBehavior.add(true);

    try {
      _responsePublisher.add(await request(input));
    } catch (e, s) {
      _responsePublisher.addError(e, s);
    } finally {
      _loadingBehavior.add(false);
    }
  }

  @mustCallSuper
  void dispose() {
    _requestPublisher.close();
    _responsePublisher.close();
    _loadingBehavior.close();
  }

  Sink<Request> get requestSink => _requestPublisher.sink;

  Stream<bool> get onLoading => _loadingBehavior.stream;

  Stream<Response> get onResponse => _responsePublisher.stream;

  Future<Response> request(Request input);
}

abstract class CachedRequestBloc<Request, Response>
    extends RequestBloc<Request, Response> {
  final _cachedResponseBehavior = new BehaviorSubject<Response>();
  final _cachedRequestBehavior = new BehaviorSubject<Request>();
  final _invalidatePublisher = new PublishSubject<void>();

  CachedRequestBloc() : super() {
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
    _cachedRequestBehavior.close();
    _cachedResponseBehavior.close();
    _invalidatePublisher.close();
    super.dispose();
  }

  Stream<Response> get cachedResponse => _cachedResponseBehavior.stream;

  Stream<Request> get cachedRequest => _cachedRequestBehavior.stream;

  Sink<void> get invalidateCacheSink => _invalidatePublisher.sink;
}
