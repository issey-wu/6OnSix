import 'package:flutter/material.dart';
import 'package:six_on_six/app/theme.dart';
import 'package:six_on_six/core/ui/motion.dart';

/// Asks the learner to confirm something, in a sheet that rises from the
/// bottom in the app's style. The safe choice is the big button; the
/// [action] (such as Quit or Reset) is the smaller one below it, in red when
/// [destructive]. Returns true only when the learner picks [action].
Future<bool> confirmSheet(
  BuildContext context, {
  required String title,
  required String message,
  required String action,
  String stay = 'Cancel',
  IconData icon = Icons.help_outline_rounded,
  bool destructive = true,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    useSafeArea: true,
    builder: (context) {
      final tokens = AppTokens.of(context);
      final text = Theme.of(context).textTheme;
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PopIn(scale: true, offset: 0, child: _Badge(icon: icon)),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: text.bodyLarge?.copyWith(color: tokens.textSecondary),
            ),
            const SizedBox(height: 24),
            FilledButton(
              key: const ValueKey('sheet-stay'),
              onPressed: () => Navigator.pop(context, false),
              child: Text(stay),
            ),
            const SizedBox(height: 8),
            TextButton(
              key: const ValueKey('sheet-action'),
              style: TextButton.styleFrom(
                foregroundColor: destructive ? tokens.error : null,
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: () => Navigator.pop(context, true),
              child: Text(action),
            ),
          ],
        ),
      );
    },
  );
  return result ?? false;
}

/// Asks for a short piece of text, such as the learner's name, in a sheet
/// that rises above the keyboard. Returns null when the learner backs out.
Future<String?> textSheet(
  BuildContext context, {
  required String title,
  String initial = '',
  String hint = '',
  String save = 'Save',
  int maxLength = 30,
  IconData icon = Icons.edit_rounded,
}) => showModalBottomSheet<String>(
  context: context,
  useSafeArea: true,
  isScrollControlled: true,
  builder: (context) => _TextSheet(
    title: title,
    initial: initial,
    hint: hint,
    save: save,
    maxLength: maxLength,
    icon: icon,
  ),
);

class _TextSheet extends StatefulWidget {
  const new({
    required this.title,
    required this.initial,
    required this.hint,
    required this.save,
    required this.maxLength,
    required this.icon,
  });

  final String title;
  final String initial;
  final String hint;
  final String save;
  final int maxLength;
  final IconData icon;

  @override
  State<_TextSheet> createState() => _TextSheetState();
}

class _TextSheetState extends State<_TextSheet> {
  // Owned by the sheet, so it lives until the sheet has fully closed.
  late final TextEditingController _controller = TextEditingController(
    text: widget.initial,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      // Keep the sheet above the keyboard.
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Badge(icon: widget.icon),
            const SizedBox(height: 16),
            Text(
              widget.title,
              textAlign: TextAlign.center,
              style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 20),
            TextField(
              key: const ValueKey('sheet-field'),
              controller: _controller,
              autofocus: true,
              maxLength: widget.maxLength,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.done,
              style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              decoration: InputDecoration(hintText: widget.hint),
              onSubmitted: (value) => Navigator.pop(context, value),
            ),
            const SizedBox(height: 12),
            FilledButton(
              key: const ValueKey('sheet-save'),
              onPressed: () => Navigator.pop(context, _controller.text),
              child: Text(widget.save),
            ),
            const SizedBox(height: 8),
            TextButton(
              style: TextButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}

/// A round icon on a chunky yellow badge, at the top of a sheet.
class _Badge extends StatelessWidget {
  const new({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    return Center(
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: tokens.brandYellow,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Color.lerp(tokens.brandYellow, Colors.black, 0.25)!,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Icon(icon, size: 38, color: tokens.brandRed),
      ),
    );
  }
}
