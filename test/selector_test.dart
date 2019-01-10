import 'dart:async';

import 'package:test/test.dart';
import 'package:bloc_helpers/bloc_helpers.dart';

void main() {
  group('selector bloc not unique', () {
    SelectorBloc _initBloc() => SelectorBloc<String>(
          seedValue: ['foo', 'foo', 'bar'],
        );

    test('seed', () async {
      final bloc = _initBloc();

      await expectLater(bloc.selected, emits(['foo', 'foo', 'bar']));

      bloc.dispose();
    });

    test('select', () async {
      final bloc = SelectorBloc<String>();

      scheduleMicrotask(() {
        bloc.selectSink.add('foo');
        bloc.selectSink.add('foo');
        bloc.selectSink.add('bar');
        bloc.dispose();
      });

      await expectLater(
          bloc.selected,
          emitsInOrder(<dynamic>[
            ['foo'],
            ['foo', 'foo'],
            ['foo', 'foo', 'bar'],
          ]));
    });
    test('unselect', () async {
      final bloc = _initBloc();

      scheduleMicrotask(() {
        bloc.unselectSink.add('bar');
        bloc.dispose();
      });

      await expectLater(
          bloc.selected,
          emitsInOrder(<dynamic>[
            ['foo', 'foo', 'bar'],
            ['foo', 'foo']
          ]));
    });
    test('selectAll', () async {
      final bloc = _initBloc();

      scheduleMicrotask(() {
        bloc.selectAllSink.add(<String>['42', '1337']);
        bloc.dispose();
      });

      await expectLater(
          bloc.selected,
          emitsInOrder(<dynamic>[
            ['foo', 'foo', 'bar'],
            [
              'foo',
              'foo',
              'bar',
              '42',
              '1337',
            ]
          ]));
    });
    test('unselectAll', () async {
      final bloc = _initBloc();

      scheduleMicrotask(() {
        bloc.unselectAllSink.add(<String>['foo', 'bar']);
        bloc.dispose();
      });

      await expectLater(
        bloc.selected,
        emitsInOrder(<dynamic>[
          ['foo', 'foo', 'bar'],
          []
        ]),
      );
    });
    test('clear', () async {
      final bloc = _initBloc();

      scheduleMicrotask(() {
        bloc.clearSink.add(null);
        bloc.dispose();
      });

      await expectLater(
        bloc.selected,
        emitsInOrder(<dynamic>[
          ['foo', 'foo', 'bar'],
          []
        ]),
      );
    });
  });

  group('selector bloc unique', () {
    SelectorBloc _initBloc() => SelectorBloc<String>.unique(
          seedValue: Set.from(['foo', 'foo', 'bar']),
        );

    test('seed', () async {
      final bloc = _initBloc();

      await expectLater(bloc.selected, emits(['foo', 'bar']));

      bloc.dispose();
    });

    test('select', () async {
      final bloc = SelectorBloc<String>.unique();

      scheduleMicrotask(() {
        bloc.selectSink.add('foo');
        bloc.selectSink.add('foo');
        bloc.selectSink.add('bar');
        bloc.dispose();
      });

      await expectLater(
          bloc.selected,
          emitsInOrder(<dynamic>[
            ['foo'],
            ['foo'],
            ['foo','bar'],
          ]));
    });
    test('unselect', () async {
      final bloc = _initBloc();

      scheduleMicrotask(() {
        bloc.unselectSink.add('bar');
        bloc.dispose();
      });

      await expectLater(
          bloc.selected,
          emitsInOrder(<dynamic>[
            ['foo','bar'],
            ['foo']
          ]));
    });
    test('selectAll', () async {
      final bloc = _initBloc();

      scheduleMicrotask(() {
        bloc.selectAllSink.add(<String>['42', '42', '1337']);
        bloc.dispose();
      });

      await expectLater(
          bloc.selected,
          emitsInOrder(<dynamic>[
            ['foo',  'bar'],
            [
              'foo',
              'bar',
              '42',
              '1337',
            ]
          ]));
    });
    test('unselectAll', () async {
      final bloc = _initBloc();

      scheduleMicrotask(() {
        bloc.unselectAllSink.add(<String>['foo', 'bar']);
        bloc.dispose();
      });

      await expectLater(
        bloc.selected,
        emitsInOrder(<dynamic>[
          ['foo', 'bar'],
          []
        ]),
      );
    });
    test('clear', () async {
      final bloc = _initBloc();

      scheduleMicrotask(() {
        bloc.clearSink.add(null);
        bloc.dispose();
      });

      await expectLater(
        bloc.selected,
        emitsInOrder(<dynamic>[
          ['foo', 'bar'],
          []
        ]),
      );
    });
  });
}
