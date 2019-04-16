import 'dart:async';

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

class MyResponse {}

class MyRequest {}

main() {
  final bloc = MyRequestBloc();

  bloc.running.listen((loading) => print('loading $loading'));

  bloc.onResult.listen(
    (response) => print(response),
    onError: (error) => print(error),
  );

  bloc.callSink.add(MyRequest());
}
