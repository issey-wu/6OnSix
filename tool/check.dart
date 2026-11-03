// Runs every project check in order and writes the output to
// build/check.log. Works on macOS and Windows.
//
// Usage (from the project root):
//   dart run tool/check.dart            # all checks
//   dart run tool/check.dart --screens  # also render app screenshots
import 'dart:io';

Future<void> main(List<String> args) async {
  final log = File('build/check.log')..createSync(recursive: true);
  final sink = log.openWrite();
  final flutter = _flutterExecutable();
  final dart = Platform.resolvedExecutable;

  final steps = <(String, String, List<String>)>[
    ('Get packages', flutter, ['pub', 'get']),
    (
      'Generate database code',
      dart,
      ['run', 'build_runner', 'build', '--delete-conflicting-outputs'],
    ),
    ('Export content', dart, ['run', 'content/export_content.dart']),
    ('Format', dart, ['format', '.']),
    ('Analyze', flutter, ['analyze']),
    ('Test', flutter, ['test']),
    if (args.contains('--screens'))
      (
        'Screenshots',
        flutter,
        ['test', 'tool/screenshots/capture_test.dart', '--update-goldens'],
      ),
  ];

  final results = <String>[];
  for (final (name, exe, stepArgs) in steps) {
    stdout.writeln('==> $name');
    sink.writeln('\n===== $name: $exe ${stepArgs.join(' ')}');
    final result = await Process.run(
      exe,
      stepArgs,
      runInShell: Platform.isWindows,
    );
    sink
      ..write(result.stdout)
      ..write(result.stderr);
    final ok = result.exitCode == 0;
    results.add('${ok ? 'PASS' : 'FAIL'}  $name');
    stdout.writeln(ok ? '    passed' : '    FAILED (see build/check.log)');
  }

  sink
    ..writeln('\n===== Summary')
    ..writeln(results.join('\n'))
    ..writeln('ALLDONE');
  await sink.close();
  stdout
    ..writeln('\nSummary')
    ..writeln(results.join('\n'));
}

/// The flutter tool next to the Dart SDK running this script, so the
/// pinned version is used even when flutter is not on PATH.
String _flutterExecutable() {
  // .../flutter/bin/cache/dart-sdk/bin/dart -> .../flutter
  var dir = File(Platform.resolvedExecutable).parent;
  for (var i = 0; i < 4; i++) {
    dir = dir.parent;
  }
  final name = Platform.isWindows ? 'flutter.bat' : 'flutter';
  final candidate = File('${dir.path}/bin/$name');
  return candidate.existsSync() ? candidate.path : name;
}
