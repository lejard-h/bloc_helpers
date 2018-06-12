import 'dart:async';

import 'package:rxdart/rxdart.dart';
import 'bloc.dart';

class SelectorBloc<T> implements Bloc {
  final bool unique;

  final _selectedBehavior = new BehaviorSubject<List<T>>();

  final _selectPublisher = new PublishSubject<T>();
  final _selectAllPublisher = new PublishSubject<List<T>>();
  final _unselectPublisher = new PublishSubject<T>();
  final _unselectAllPublisher = new PublishSubject<void>();

  SelectorBloc({this.unique: true}) {
    onSelect.listen((v) => _add([v]));
    onSelectAll.listen(_add);

    onUnselect.listen((v) => _remove([v]));
    onUnselectAll.listen((_) => _remove(_selectedBehavior.value));
  }

  void _add(List<T> values) {
    final toAdd = unique
        ? values.where((v) => !_selectedBehavior.value.contains(v))
        : values;

    _selectedBehavior.add(
      _selectedBehavior.value.toList()..addAll(toAdd),
    );
  }

  void _remove(List<T> values) {
    _selectedBehavior.add(
      _selectedBehavior.value.where((v) => !values.contains(v)),
    );
  }

  @override
  void dispose() {
    _selectedBehavior.close();
    _selectPublisher.close();
    _unselectPublisher.close();
    _unselectAllPublisher.close();
    _selectAllPublisher.close();
  }

  Stream<List<T>> get selected => _selectedBehavior;

  Stream<T> get onSelect => _selectPublisher.stream;

  Stream<T> get onUnselect => _unselectPublisher.stream;

  Stream<List<T>> get onSelectAll => _selectAllPublisher.stream;

  Stream<void> get onUnselectAll => _unselectAllPublisher.stream;

  Sink<T> get unselectSink => _unselectPublisher.sink;

  Sink<T> get selectSink => _selectPublisher.sink;

  Sink<List<T>> get selectAllSink => _selectAllPublisher.sink;

  Sink<void> get unselectAllSink => _unselectAllPublisher.sink;
}
