// Converts the authoring spreadsheets in content/source/ into the bundled
// app content at assets/content/course.json and assets/content/glossary.json,
// and validates them on the way.
//
// Usage:
//   dart run content/export_content.dart          # write the JSON files
//   dart run content/export_content.dart --check  # fail if out of date
import 'dart:convert';
import 'dart:io';

const _schemaVersion = 1;
const _sourceDir = 'content/source';
const _outputPath = 'assets/content/course.json';
const _glossaryOutputPath = 'assets/content/glossary.json';
const _types = {'mc', 'tf', 'match', 'zone', 'drag'};
const _tokens = {'S', 'OH1', 'OH2', 'MB1', 'MB2', 'OPP', 'L'};
const _backRow = {5, 6, 1};

void main(List<String> args) {
  final errors = <String>[];
  final units = _readCsv('$_sourceDir/units.csv');
  final lessons = _readCsv('$_sourceDir/lessons.csv');
  final cards = _readCsv('$_sourceDir/cards.csv');
  final questions = _readCsv('$_sourceDir/questions.csv');
  final glossaryFile = File('$_sourceDir/glossary.csv');
  final glossary = glossaryFile.existsSync()
      ? _readCsv(glossaryFile.path)
      : <Map<String, String>>[];

  final unitIds = <String>{};
  for (final u in units) {
    if (!unitIds.add(u['id']!)) errors.add('Duplicate unit id ${u['id']}');
  }
  final lessonIds = <String>{};
  for (final l in lessons) {
    if (!lessonIds.add(l['id']!)) errors.add('Duplicate lesson ${l['id']}');
    if (!unitIds.contains(l['unit'])) {
      errors.add('Lesson ${l['id']} points to missing unit ${l['unit']}');
    }
  }
  for (final c in cards) {
    if (!lessonIds.contains(c['lesson'])) {
      errors.add('Card "${c['title']}" points to missing lesson');
    }
  }

  final questionIds = <String>{};
  for (final q in questions) {
    final id = q['id']!;
    String where(String msg) => 'Question $id: $msg';
    if (!questionIds.add(id)) errors.add(where('duplicate id'));
    if (!lessonIds.contains(q['lesson'])) {
      errors.add(where('missing lesson ${q['lesson']}'));
    }
    final type = q['type']!;
    if (!_types.contains(type)) errors.add(where('unknown type "$type"'));
    if (q['prompt']!.isEmpty) errors.add(where('empty prompt'));
    if (q['explanation']!.isEmpty) errors.add(where('missing explanation'));
    if (q['concepts']!.isEmpty) errors.add(where('missing concept tag'));
    final options = _split(q['options']!);
    // Spreadsheet apps save true/false as TRUE/FALSE.
    final answer = type == 'tf' ? q['answer']!.toLowerCase() : q['answer']!;
    switch (type) {
      case 'mc':
        if (options.length < 2 || options.length > 4) {
          errors.add(where('needs 2 to 4 options'));
        }
        if (!options.contains(answer)) {
          errors.add(where('answer is not one of the options'));
        }
      case 'tf':
        if (answer != 'true' && answer != 'false') {
          errors.add(where('answer must be true or false'));
        }
      case 'zone':
        final zone = int.tryParse(answer);
        if (zone == null || zone < 1 || zone > 6) {
          errors.add(where('answer must be a zone from 1 to 6'));
        }
      case 'match':
        if (options.length < 3 || options.length > 5) {
          errors.add(where('needs 3 to 5 pairs'));
        }
        if (options.any((p) => p.split('=').length != 2)) {
          errors.add(where('each pair must look like Left=Right'));
        }
      case 'drag':
        // Options hold the answer key, one token per item: S=1|OH1=2|...
        // The tokens listed are the ones that appear in the tray.
        if (options.isEmpty || options.length > 6) {
          errors.add(where('needs 1 to 6 tokens, like S=1|OH1=2'));
        }
        final zonesUsed = <int>{};
        final tokensUsed = <String>{};
        for (final item in options) {
          final parts = item.split('=');
          final zone = parts.length == 2 ? int.tryParse(parts[1]) : null;
          if (parts.length != 2 || zone == null) {
            errors.add(where('"$item" must look like TOKEN=ZONE'));
            continue;
          }
          final token = parts[0];
          if (!_tokens.contains(token)) {
            errors.add(where('unknown token "$token"'));
          }
          if (!tokensUsed.add(token)) errors.add(where('token $token twice'));
          if (zone < 1 || zone > 6) {
            errors.add(where('$token must go in a zone from 1 to 6'));
          }
          if (!zonesUsed.add(zone)) {
            errors.add(where('two tokens share zone $zone'));
          }
          if (token == 'L' && !_backRow.contains(zone)) {
            errors.add(where('the libero may only be in zone 5, 6 or 1'));
          }
        }
        if (answer.isNotEmpty) {
          errors.add(where('leave answer empty; the key goes in options'));
        }
    }
  }
  for (final id in lessonIds) {
    if (!cards.any((c) => c['lesson'] == id)) {
      errors.add('Lesson $id has no teaching card');
    }
    if (!questions.any((q) => q['lesson'] == id)) {
      errors.add('Lesson $id has no questions');
    }
  }

  final termIds = {for (final g in glossary) g['id']!};
  final seenTerms = <String>{};
  for (final g in glossary) {
    final id = g['id']!;
    String where(String msg) => 'Glossary term $id: $msg';
    if (id.isEmpty) errors.add('Glossary term "${g['term']}" has no id');
    if (!seenTerms.add(id)) errors.add(where('duplicate id'));
    if (g['term']!.isEmpty) errors.add(where('empty term'));
    if (g['definition']!.isEmpty) errors.add(where('missing definition'));
    for (final r in _split(g['related']!)) {
      if (!termIds.contains(r)) errors.add(where('related "$r" not found'));
      if (r == id) errors.add(where('is related to itself'));
    }
    final unit = g['unit']!;
    if (unit.isNotEmpty && !unitIds.contains(unit)) {
      errors.add(where('points to missing unit $unit'));
    }
  }

  if (errors.isNotEmpty) {
    stderr.writeln('Content has ${errors.length} problem(s):');
    for (final e in errors) {
      stderr.writeln('  - $e');
    }
    exit(1);
  }

  final course = <String, Object?>{
    'schemaVersion': _schemaVersion,
    'units': [
      for (final u in units)
        {
          'id': u['id'],
          'title': u['title'],
          'description': u['description'],
          'lessons': [
            for (final l in lessons.where((l) => l['unit'] == u['id']))
              {
                'id': l['id'],
                'title': l['title'],
                'cards': [
                  for (final c in cards.where((c) => c['lesson'] == l['id']))
                    {'title': c['title'], 'body': c['body']},
                ],
                'questions': [
                  for (final q in questions.where(
                    (q) => q['lesson'] == l['id'],
                  ))
                    _question(q),
                ],
              },
          ],
        },
    ],
  };
  final glossaryJson = <String, Object?>{
    'schemaVersion': _schemaVersion,
    'terms': [
      for (final g in glossary)
        {
          'id': g['id'],
          'term': g['term'],
          'definition': g['definition'],
          if (g['example']!.isNotEmpty) 'example': g['example'],
          'related': _split(g['related']!),
          if (g['unit']!.isNotEmpty) 'unit': g['unit'],
        },
    ],
  };
  final outputs = {
    _outputPath: _encode(course),
    _glossaryOutputPath: _encode(glossaryJson),
  };

  if (args.contains('--check')) {
    var stale = false;
    for (final MapEntry(key: path, value: text) in outputs.entries) {
      final out = File(path);
      if (!out.existsSync() || out.readAsStringSync() != text) {
        stderr.writeln('$path is out of date.');
        stale = true;
      }
    }
    if (stale) {
      stderr.writeln('Run: dart run content/export_content.dart');
      exit(1);
    }
    stdout.writeln(
      'Content OK: ${questions.length} questions, '
      '${glossary.length} glossary terms.',
    );
    return;
  }
  for (final MapEntry(key: path, value: text) in outputs.entries) {
    File(path)
      ..createSync(recursive: true)
      ..writeAsStringSync(text);
  }
  stdout.writeln(
    'Wrote $_outputPath: ${units.length} units, ${lessons.length} lessons, '
    '${questions.length} questions.\n'
    'Wrote $_glossaryOutputPath: ${glossary.length} terms.',
  );
}

String _encode(Map<String, Object?> json) =>
    '${const JsonEncoder.withIndent('  ').convert(json)}\n';

Map<String, Object?> _question(Map<String, String> q) {
  final type = q['type']!;
  final options = _split(q['options']!);
  return {
    'id': q['id'],
    'type': type,
    'prompt': q['prompt'],
    if (type == 'mc') 'options': options,
    if (type == 'match')
      'pairs': [
        for (final p in options)
          {'left': p.split('=')[0], 'right': p.split('=')[1]},
      ],
    if (type == 'drag')
      'placements': {
        for (final p in options) p.split('=')[0]: int.parse(p.split('=')[1]),
      },
    if (type != 'match' && type != 'drag')
      'answer': type == 'tf' ? q['answer']!.toLowerCase() : q['answer'],
    'explanation': q['explanation'],
    'concepts': _split(q['concepts']!, ','),
    if (q['ruleRef']!.isNotEmpty) 'ruleRef': q['ruleRef'],
    if (q['leagueNote']!.isNotEmpty) 'leagueNote': q['leagueNote'],
    if (q['phase']!.isNotEmpty) 'phase': q['phase'],
  };
}

List<String> _split(String value, [String separator = '|']) => value.isEmpty
    ? const []
    : value.split(separator).map((s) => s.trim()).toList();

/// Reads a CSV file (with a header row) into a list of maps.
List<Map<String, String>> _readCsv(String path) {
  var text = File(path).readAsStringSync();
  // Excel can add a byte-order mark at the start of the file.
  if (text.startsWith('﻿')) text = text.substring(1);
  final rows = _parseCsv(text);
  final header = rows.first;
  return [
    for (final row in rows.skip(1))
      if (row.any((cell) => cell.isNotEmpty))
        {
          for (var i = 0; i < header.length; i++)
            header[i]: i < row.length ? row[i].trim() : '',
        },
  ];
}

/// A small CSV parser that handles quoted cells, doubled quotes and line
/// breaks inside quotes, which is what spreadsheet apps export.
List<List<String>> _parseCsv(String text) {
  final rows = <List<String>>[];
  var row = <String>[];
  final cell = StringBuffer();
  var inQuotes = false;
  for (var i = 0; i < text.length; i++) {
    final ch = text[i];
    if (inQuotes) {
      if (ch == '"') {
        if (i + 1 < text.length && text[i + 1] == '"') {
          cell.write('"');
          i++;
        } else {
          inQuotes = false;
        }
      } else {
        cell.write(ch);
      }
    } else if (ch == '"') {
      inQuotes = true;
    } else if (ch == ',') {
      row.add(cell.toString());
      cell.clear();
    } else if (ch == '\n' || ch == '\r') {
      if (ch == '\r' && i + 1 < text.length && text[i + 1] == '\n') i++;
      row.add(cell.toString());
      cell.clear();
      rows.add(row);
      row = <String>[];
    } else {
      cell.write(ch);
    }
  }
  if (cell.isNotEmpty || row.isNotEmpty) {
    row.add(cell.toString());
    rows.add(row);
  }
  return rows;
}
