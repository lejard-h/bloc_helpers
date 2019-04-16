import 'dart:async';

import 'package:rxdart/rxdart.dart';
import 'bloc.dart';

/// Bloc implementing a selection behavior
///
/// Unique value selector
/// ```dart
/// final selector = new SelectorBloc<String>();
///
/// selector.selected.first; // []
///
/// selector.selectSink.add('foo'); // ['foo']
/// selector.selectSink.add('foo'); // ['foo']
/// selector.selectAllSink.add(['foo', 'toto']); // ['foo', 'toto']
/// selector.selectSink.add('bar); // ['foo', 'toto', 'bar']
///
/// selector.unselect.add('foo'); // ['toto', 'bar']
/// selector.unselectAll.add(null); // []
///
/// or
///
/// ```dart
/// final selector = new SelectorBloc<String>(unique: false);
///
/// selector.selectSink.add('foo');
/// selector.selectSink.add('foo');
/// selector.selectSink.add('bar);
///
/// selector.selected.first; /// [ 'foo', 'foo', 'bar' ]
/// ```
class SelectorBloc<T> extends Bloc {
  final bool unique;

  final BehaviorSubject<Iterable<T>> _selectedBehavior;

  final _selectPublisher = PublishSubject<T>();
  final _selectAllPublisher = PublishSubject<Iterable<T>>();
  final _unselectPublisher = PublishSubject<T>();
  final _unselectAllPublisher = PublishSubject<Iterable<T>>();
  final _clearPublisher = PublishSubject<void>();

  SelectorBloc({List<T> seedValue})
      : unique = false,
        _selectedBehavior = BehaviorSubject<List<T>>.seeded(seedValue) {
    _initListeners();
  }

  SelectorBloc.unique({Set<T> seedValue})
      : unique = true,
        _selectedBehavior = BehaviorSubject<Set<T>>.seeded(seedValue) {
    _initListeners();
  }

  void _initListeners() {
    onSelect.listen((v) => _add([v]));
    onSelectAll.listen(_add);

    onUnselect.listen((v) => _remove([v]));
    onUnselectAll.listen(_remove);

    onClear.listen((_) => _remove(_selectedBehavior.value));
  }

  void _add(Iterable<T> values) {
    if (values == null || values == _selectedBehavior.value) return;

    if (unique) {
      final current = _selectedBehavior.value?.toSet() ?? Set<T>();
      _selectedBehavior.add(
        current..addAll(values),
      );
    } else {
      final current = _selectedBehavior.value?.toList() ?? List<T>();
      _selectedBehavior.add(
        current..addAll(values),
      );
    }
  }

  void _remove(Iterable<T> values) {
    if (values == null) return;

    if (unique) {
      final current = _selectedBehavior.value?.toSet() ?? Set<T>();
      _selectedBehavior.add(
        current.where((v) => !values.contains(v)).toSet(),
      );
    } else {
      final current = _selectedBehavior.value?.toList() ?? List<T>();
      _selectedBehavior.add(
        current.where((v) => !values.contains(v)).toList(),
      );
    }
  }

  @override
  Future<void> dispose() async {
    await _selectPublisher.close();
    await _unselectPublisher.close();
    await _unselectAllPublisher.close();
    await _selectAllPublisher.close();
    await _clearPublisher.close();
    await super.dispose();
  }

  /// Stream of selected item
  /// Emit the last value when listen
  ValueObservable<Iterable<T>> get selected => _selectedBehavior.stream;

  /// Emit event when [selectSink.add]
  Observable<T> get onSelect => _selectPublisher.stream;

  /// Emit event when [unselectSink.add]
  Observable<T> get onUnselect => _unselectPublisher.stream;

  /// Emit event when [selectAllSink.add]
  Observable<Iterable<T>> get onSelectAll => _selectAllPublisher.stream;

  /// Emit event when [unselectAllSink.add]t
  Observable<Iterable<T>> get onUnselectAll => _unselectAllPublisher.stream;

  Observable<void> get onClear => _clearPublisher.stream;

  /// Sink to unselect an item
  Sink<T> get unselectSink => _unselectPublisher.sink;

  /// Sink to select an item
  Sink<T> get selectSink => _selectPublisher.sink;

  /// Sink to select multiple item
  Sink<Iterable<T>> get selectAllSink => _selectAllPublisher.sink;

  /// Sink to unselect every item in the list
  Sink<Iterable<T>> get unselectAllSink => _unselectAllPublisher.sink;

  /// Sink to manually update the selected list
  Sink<Iterable<T>> get loadSink => _selectedBehavior.sink;

  Sink<void> get clearSink => _clearPublisher.sink;
}
