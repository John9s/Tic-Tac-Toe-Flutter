import 'package:hive/hive.dart';

class Boxes {
  static Box<List<dynamic>> getMatrix() =>
      Hive.box<List<dynamic>>('matrixstate');

      static Box<String> getValues() =>
      Hive.box<String>('values');
}
