# Dart Bloc Pattern helper

## What is Bloc pattern ?

- [Flutter / AngularDart – Code sharing, better together (DartConf 2018)](https://youtu.be/PLHln7wHgPE)
- [Build reactive mobile apps in Flutter](https://youtu.be/RS36gBEp8OI)
- [Build reactive mobile apps in Flutter - companion article](https://medium.com/flutter-io/build-reactive-mobile-apps-in-flutter-companion-article-13950959e381)

## bloc_helpers

This package contain helper class and common Bloc Pattern

- Bloc (base to implement Bloc pattern)
- RequestBloc
- CachedRequestBloc
- SelectorBloc

### `Bloc` class

The bloc class is a simple class that provide dispose function and a disposed boolean

```dart
abstract class Bloc {
  bool _disposed = false;

  bool get disposed => _disposed;

  @mustCallSuper
  void dispose() {
    _disposed = true;
  }
}
```

### Request bloc 

RequestBloc help to implement async call, it provides following stream ans sink.

`Sink<Request> requestSink`

`Stream<bool> onLoading`

`Stream<Request> onRequest`

`Stream<Response> onResponse`

CachedRequestBloc add the ability to cache response, to avoid multiple call when request does not change, it provides following stream and sink.

`Stream<Response> cachedResponse`

`Sink<Response> invalidateCacheSink`

`Sink<Response> updateCachedResponseSink`

#### Usage

```dart
import 'package:bloc_helpers/bloc_helpers.dart';
import 'package:meta/meta.dart';

class MyRequestBloc extends RequestBloc<MyRequest, MyResponse> {
  @override
  @protected
  Future<MyResponse> request(MyRequest input) async {
    // TODO: implement request
    return MyResponse();
  }
}

bloc.requestSink.add(MyRequest());
```

See [example](https://github.com/lejard-h/bloc_helpers/tree/master/example/request.dart)

### Selector bloc

Selector bloc help implementing a simple selection behavior

```dart
final selector = SelectorBloc<String>();

  selector.selected.listen((selected) => print(selected));

  selector.selectSink.add('foo');
  selector.unselectSink.add('foo');

  selector.selectAllSink.add(['foo', 'bar']);
```

## Contributions

This repository is open to Pull Request and new idea :)
