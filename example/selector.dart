import 'package:bloc_helpers/bloc_helpers.dart';

main() {
  final selector = SelectorBloc<String>();

  selector.selected.listen((selected) => print(selected));

  selector.selectSink.add('foo');
  selector.unselectSink.add('foo');

  selector.selectAllSink.add(['foo', 'bar']);
}
