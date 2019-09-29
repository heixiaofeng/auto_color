import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('test i18n', () async {
    var fileEntityList = Directory('localization/').listSync().where((f) => f.path.endsWith('.json'));
    Map benchmark;
    for (final fileEntity in fileEntityList) {
      Map json = jsonDecode(await File(fileEntity.path).readAsString());
      benchmark = benchmark ?? json;
      for (final entry in benchmark.entries) {
        expect(json.containsKey(entry.key), isTrue, reason: '${fileEntity.path} ${entry.key}');
      }
      expect(json.length, benchmark.length, reason: '${fileEntity.path}');
    }
  });
}
