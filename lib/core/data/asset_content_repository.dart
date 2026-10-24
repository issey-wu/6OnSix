import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:six_on_six/core/data/course_parser.dart';
import 'package:six_on_six/core/domain/content_repository.dart';
import 'package:six_on_six/core/domain/course.dart';

/// Reads the course bundled with the app at assets/content/course.json.
class AssetContentRepository implements ContentRepository {
  new({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  static const path = 'assets/content/course.json';

  final AssetBundle _bundle;
  Course? _cached;

  @override
  Future<Course> loadCourse() async {
    final cached = _cached;
    if (cached != null) return cached;
    // Read bytes and decode here rather than loadString, which hands large
    // files to a background isolate.
    final data = await _bundle.load(path);
    final text = utf8.decode(data.buffer.asUint8List());
    final json = jsonDecode(text);
    if (json is! Map<String, Object?>) {
      throw const ContentFormatException('course.json is not an object');
    }
    return _cached = parseCourse(json);
  }
}
