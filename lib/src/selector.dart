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

  final _selectPublisher = new PublishSubject<T>();
  final _selectAllPublisher = new PublishSubject<Iterable<T>>();
  final _unselectPublisher = new PublishSubject<T>();
  final _unselectAllPublisher = new PublishSubject<void>();

  SelectorBloc({this.unique: true, Iterable<T> seedValue: const []})
      : _selectedBehavior = new BehaviorSubject<Iterable<T>>(
            seedValue: unique
                ? new Set<T>.from(seedValue)
                : new List<T>.from(seedValue)) {
    onSelect.listen((v) => _add([v]));
    onSelectAll.listen(_add);

    onUnselect.listen((v) => _remove([v]));
    onUnselectAll.listen((_) => _remove(_selectedBehavior.value));
  }

  void _add(Iterable<T> values) {
    if (values == null || values == _selectedBehavior.value) return;

    if (unique) {
      _selectedBehavior.add(
        _selectedBehavior.value.toSet()..addAll(values),
      );
    } else {
      _selectedBehavior.add(
        _selectedBehavior.value.toList()..addAll(values),
      );
    }
  }

  void _remove(Iterable<T> values) {
    if (values == null) return;

    if (unique) {
      _selectedBehavior.add(
        _selectedBehavior.value.where((v) => !values.contains(v)).toSet(),
      );
    } else {
      _selectedBehavior.add(
        _selectedBehavior.value.where((v) => !values.contains(v)).toList(),
      );
    }
  }

  @override
  void dispose() {
    _selectPublisher.close();
    _unselectPublisher.close();
    _unselectAllPublisher.close();
    _selectAllPublisher.close();

    super.dispose();
  }

  /// Stream of selected item
  /// Emit the last value when listen
  Stream<Iterable<T>> get selected => _selectedBehavior;

  /// Emit event when [selectSink.add]
  Stream<T> get onSelect => _selectPublisher.stream;

  /// Emit event when [unselectSink.add]
  Stream<T> get onUnselect => _unselectPublisher.stream;

  /// Emit event when [selectAllSink.add]
  Stream<Iterable<T>> get onSelectAll => _selectAllPublisher.stream;

  /// Emit event when [unselectAllSink.add]t
  Stream<void> get onUnselectAll => _unselectAllPublisher.stream;

  /// Sink to unselect an item
  Sink<T> get unselectSink => _unselectPublisher.sink;

  /// Sink to select an item
  Sink<T> get selectSink => _selectPublisher.sink;

  /// Sink to select multiple item
  Sink<Iterable<T>> get selectAllSink => _selectAllPublisher.sink;

  /// Sink to unselect every item in the list
  Sink<void> get unselectAllSink => _unselectAllPublisher.sink;

  /// Sink to manually update the selected list
  Sink<Iterable<T>> get loadSink => _selectedBehavior.sink;
}
