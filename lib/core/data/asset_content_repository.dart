import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:six_on_six/core/data/course_parser.dart';
import 'package:six_on_six/core/domain/content_repository.dart';
import 'package:six_on_six/core/domain/course.dart';
import 'package:six_on_six/core/domain/glossary.dart';

/// Reads the content bundled with the app: assets/content/course.json and
/// assets/content/glossary.json.
class AssetContentRepository implements ContentRepository {
  new({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  static const path = 'assets/content/course.json';
  static const glossaryPath = 'assets/content/glossary.json';

  final AssetBundle _bundle;
  Course? _cached;
  Glossary? _cachedGlossary;

  @override
  Future<Course> loadCourse() async {
    final cached = _cached;
    if (cached != null) return cached;
    return _cached = parseCourse(await _readJson(path));
  }

  @override
  Future<Glossary> loadGlossary() async {
    final cached = _cachedGlossary;
    if (cached != null) return cached;
    return _cachedGlossary = parseGlossary(await _readJson(glossaryPath));
  }

  Future<Map<String, Object?>> _readJson(String assetPath) async {
    // Read bytes and decode here rather than loadString, which hands large
    // files to a background isolate.
    final data = await _bundle.load(assetPath);
    final text = utf8.decode(data.buffer.asUint8List());
    final json = jsonDecode(text);
    if (json is! Map<String, Object?>) {
      throw ContentFormatException('$assetPath is not an object');
    }
    return json;
  }
}
