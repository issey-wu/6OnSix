import 'package:flutter/material.dart';
import 'package:six_on_six/app/theme.dart';
import 'package:six_on_six/core/domain/course.dart';
import 'package:six_on_six/core/ui/court_lineup.dart';
import 'package:six_on_six/core/ui/court_view.dart';
import 'package:six_on_six/core/ui/player_token.dart';

/// The explanation for [question] broken into short steps, for the
/// "Show me how" panel. Court questions get a step per player or zone, built
/// from the answer itself, so no extra content has to be written.
List<String> howToSteps(Question question) {
  final sentences = question.explanation
      .split(RegExp(r'(?<=[.!?])\s+(?=[A-Z0-9])'))
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty);
  final fromAnswer = switch (question.type) {
    QuestionType.dragDrop => [
      for (final MapEntry(key: token, value: zone)
          in question.placements.entries)
        _placeStep(token, zone),
    ],
    QuestionType.tapZone => [
      if (int.tryParse(question.answer) case final zone?)
        'Zone $zone is ${courtZoneNames[zone]}.',
    ],
    QuestionType.matching => [
      for (final pair in question.pairs) '${pair.left}: ${pair.right}.',
    ],
    QuestionType.multipleChoice || QuestionType.trueFalse => <String>[],
  };
  return [...fromAnswer, ...sentences];
}

String _placeStep(String token, int zone) {
  final role = playerRoleName(token);
  final where = courtZoneNames[zone];
  return '$role ($token) goes in zone $zone, $where.';
}

/// Opens the "Show me how" panel for [question].
Future<void> showMeHow(
  BuildContext context, {
  required Question question,
  required Course course,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  useSafeArea: true,
  builder: (context) => ShowMeHowSheet(question: question, course: course),
);

/// Walks through why an answer is right: the answer, a court picture for
/// court questions, the explanation as steps, the rule and words to know.
class ShowMeHowSheet extends StatefulWidget {
  const new({required this.question, required this.course, super.key});

  final Question question;
  final Course course;

  @override
  State<ShowMeHowSheet> createState() => _ShowMeHowSheetState();
}

class _ShowMeHowSheetState extends State<ShowMeHowSheet> {
  int _runId = 0;

  @override
  Widget build(BuildContext context) {
    final q = widget.question;
    final text = Theme.of(context).textTheme;
    final tokens = AppTokens.of(context);
    final steps = howToSteps(q);
    final terms = widget.course.termsFor(q, '${q.prompt} ${q.explanation}');
    final ruleRef = q.ruleRef;
    final note = q.leagueNote;

    Widget heading(String label) => Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Semantics(
        header: true,
        child: Text(
          label,
          style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
      ),
    );

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        children: [
          Semantics(
            header: true,
            child: Text(
              'How it works',
              style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          if (q.type != QuestionType.matching) ...[
            const SizedBox(height: 4),
            Text(
              'Answer: ${q.answerLabel}',
              style: text.titleSmall?.copyWith(color: tokens.textSecondary),
            ),
          ],
          if (q.type == QuestionType.dragDrop) ...[
            const SizedBox(height: 16),
            Center(
              child: SizedBox(
                width: 240,
                child: AnimatedLineup(
                  placements: q.placements,
                  order: q.tokens,
                  runId: _runId,
                ),
              ),
            ),
            Center(
              child: TextButton.icon(
                onPressed: () => setState(() => _runId++),
                icon: const Icon(Icons.replay),
                label: const Text('Play again'),
              ),
            ),
          ],
          if (q.type == QuestionType.tapZone) ...[
            const SizedBox(height: 16),
            Center(
              child: SizedBox(
                width: 240,
                child: CourtView(
                  selectedZone: int.tryParse(q.answer),
                  revealZoneNumbers: true,
                ),
              ),
            ),
          ],
          heading('Step by step'),
          for (final (i, step) in steps.indexed)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: tokens.brandOrange,
                    child: Text(
                      '${i + 1}',
                      style: text.labelMedium?.copyWith(
                        color: tokens.onYellowOrange,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(step, style: text.bodyLarge)),
                ],
              ),
            ),
          if (ruleRef != null) ...[
            heading('The rule'),
            Text('Rulebook: $ruleRef', style: text.bodyMedium),
          ],
          if (note != null) ...[
            const SizedBox(height: 8),
            Text('League note: $note', style: text.bodyMedium),
          ],
          if (terms.isNotEmpty) ...[
            heading('Words to know'),
            for (final term in terms)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '${term.term}: ',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      TextSpan(text: term.definition),
                    ],
                  ),
                  style: text.bodyMedium,
                ),
              ),
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}
