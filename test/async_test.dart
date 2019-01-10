import 'dart:async';

import 'package:bloc_helpers/bloc_helpers.dart';
import 'package:rxdart/rxdart.dart';
import 'package:test/test.dart';

class CachedMockRequest extends CachedRequestBloc<String, int> {
  final hitRequest = PublishSubject<void>();

  @override
  Future<int> request(String input) async {
    hitRequest.add(null);
    return int.parse(input);
  }

  @override
  FutureOr<void> dispose() {
    hitRequest.close();
    return super.dispose();
  }
}

void main() {
  group('request bloc', () {
    RequestBloc<String, int> _initBloc() => RequestBloc<String, int>.func(
          (req) async => int.parse(req),
        );

    test('response', () async {
      final bloc = _initBloc();

      scheduleMicrotask(() {
        bloc.callSink.add('10');
        bloc.callSink.add('5');
        bloc.dispose();
      });

      await expectLater(
          bloc.onResult,
          emitsInOrder(<dynamic>[
            10,
            5,
          ]));
    });

    test('1 response for same request', () async {
      final bloc = _initBloc();

      scheduleMicrotask(() {
        bloc.callSink.add('10');
        bloc.callSink.add('10');
        bloc.dispose();
      });

      await expectLater(
          bloc.onResult,
          emitsInOrder(<dynamic>[
            10,
          ]));
    });

    test('loading', () async {
      final bloc = _initBloc();

      scheduleMicrotask(() {
        bloc.callSink.add('10');
        bloc.dispose();
      });

      await expectLater(
          bloc.onRunning,
          emitsInOrder(<dynamic>[
            false,
            true,
            false,
          ]));
    });

    test('loading on error', () async {
      final bloc = _initBloc();

      scheduleMicrotask(() {
        bloc.callSink.add('aaa');
        bloc.dispose();
      });

      await expectLater(
          bloc.onRunning,
          emitsInOrder(<dynamic>[
            false,
            true,
            false,
          ]));
    });

    test('fire error', () async {
      final bloc = _initBloc();

      scheduleMicrotask(() {
        bloc.callSink.add('aaa');
        bloc.dispose();
      });

      await expectLater(
        bloc.onResult,
        emitsError(TypeMatcher<FormatException>()),
      );
    });
  });

  group('cached request bloc', () {
    CachedMockRequest _initBloc() => CachedMockRequest();

    test('update cached response', () async {
      final bloc = _initBloc();

      scheduleMicrotask(() async {
        bloc.callSink.add('10');

        await Future.delayed(const Duration(milliseconds: 500));

        bloc.callSink.add('10');
        bloc.dispose();
      });

      await expectLater(
          bloc.cachedResult,
          emitsInOrder(
            <dynamic>[10],
          ));
    });

    test('no loading if hit cache', () async {
      final bloc = _initBloc();

      scheduleMicrotask(() async {
        bloc.callSink.add('10');

        await Future.delayed(const Duration(milliseconds: 500));

        bloc.callSink.add('10');
        bloc.dispose();
      });

      await expectLater(
          bloc.onRunning,
          emitsInOrder(<dynamic>[
            false,
            true,
            false,
          ]));
    });

    test('1 response for 1 request', () async {
      final bloc = _initBloc();

      scheduleMicrotask(() async {
        bloc.callSink.add('10');

        await Future.delayed(const Duration(milliseconds: 500));

        bloc.callSink.add('10');
        bloc.dispose();
      });

      await expectLater(
          bloc.onResult,
          emitsInOrder(<dynamic>[
            10,
            10,
          ]));
    });

    test('hit cache if same request', () async {
      final bloc = _initBloc();

      scheduleMicrotask(() async {
        bloc.callSink.add('10');

        await Future.delayed(const Duration(milliseconds: 500));

        bloc.callSink.add('10');
        bloc.dispose();
      });

      await expectLater(bloc.hitRequest, emitsInOrder(<dynamic>[null]));
    });
  });
}
