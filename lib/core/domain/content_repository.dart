import 'package:six_on_six/core/domain/course.dart';
import 'package:six_on_six/core/domain/glossary.dart';

/// Where the app gets its learning content. Screens never read asset files
/// directly; they ask this repository.
abstract interface class ContentRepository {
  Future<Course> loadCourse();

  Future<Glossary> loadGlossary();
}
