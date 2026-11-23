import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:six_on_six/app/providers.dart';
import 'package:six_on_six/app/theme.dart';
import 'package:six_on_six/core/domain/avatar.dart';
import 'package:six_on_six/core/ui/avatar_view.dart';

/// Pick one of 50 ready-made avatars, or build one: skin tone, hair, hair
/// colour, jersey colour and number, and a headband.
class AvatarScreen extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<AvatarScreen> createState() => _AvatarScreenState();
}

class _AvatarScreenState extends ConsumerState<AvatarScreen> {
  late Avatar _avatar;

  @override
  void initState() {
    super.initState();
    _avatar = ref.read(avatarProvider) ?? avatarPresets.first;
  }

  void _change(Avatar next) => setState(() => _avatar = next);

  void _save() {
    ref.read(avatarProvider.notifier).set(_avatar);
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/profile');
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Your avatar')),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 12),
              child: AnimatedSwitcher(
                duration: motion(context, const Duration(milliseconds: 220)),
                switchInCurve: Curves.easeOutBack,
                transitionBuilder: (child, animation) =>
                    ScaleTransition(scale: animation, child: child),
                child: AvatarView(
                  key: ValueKey(_avatar),
                  avatar: _avatar,
                  size: 140,
                ),
              ),
            ),
            TabBar(
              labelColor: tokens.brandOrange,
              unselectedLabelColor: tokens.textSecondary,
              indicatorColor: tokens.brandOrange,
              indicatorWeight: 4,
              labelStyle: text.titleSmall?.copyWith(
                fontWeight: FontWeight.w900,
              ),
              tabs: const [
                Tab(text: 'Ready-made'),
                Tab(text: 'Build your own'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _Presets(selected: _avatar, onPick: _change),
                  _Builder(avatar: _avatar, onChange: _change),
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton(
                  key: const ValueKey('save-avatar'),
                  onPressed: _save,
                  child: const Text('Save avatar'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Presets extends StatelessWidget {
  const new({required this.selected, required this.onPick});

  final Avatar selected;
  final ValueChanged<Avatar> onPick;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 76,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
      ),
      itemCount: avatarPresets.length,
      itemBuilder: (context, i) {
        final avatar = avatarPresets[i];
        final isSelected = avatar == selected;
        return Semantics(
          button: true,
          selected: isSelected,
          label: 'Ready-made avatar ${i + 1}',
          excludeSemantics: true,
          child: InkResponse(
            key: ValueKey('preset-$i'),
            onTap: () => onPick(avatar),
            containedInkWell: true,
            customBorder: const CircleBorder(),
            child: AnimatedContainer(
              duration: motion(context, const Duration(milliseconds: 150)),
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? tokens.choice : Colors.transparent,
                  width: 3,
                ),
              ),
              child: FittedBox(child: AvatarView(avatar: avatar)),
            ),
          ),
        );
      },
    );
  }
}

class _Builder extends StatelessWidget {
  const new({required this.avatar, required this.onChange});

  final Avatar avatar;
  final ValueChanged<Avatar> onChange;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    Widget label(String title) => Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 8),
      child: Semantics(
        header: true,
        child: Text(
          title,
          style: text.titleSmall?.copyWith(fontWeight: FontWeight.w900),
        ),
      ),
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        label('Skin tone'),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final (i, color) in AvatarPalette.skinTones.indexed)
              _Swatch(
                key: ValueKey('skin-$i'),
                color: color,
                label: 'Skin tone ${i + 1}',
                selected: avatar.skin == i,
                onTap: () => onChange(avatar.copyWith(skin: i)),
              ),
          ],
        ),
        label('Hair'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final style in HairStyle.values)
              ChoiceChip(
                key: ValueKey('hair-${style.name}'),
                label: Text(style.label),
                selected: avatar.hair == style,
                onSelected: (_) => onChange(avatar.copyWith(hair: style)),
              ),
          ],
        ),
        label('Hair colour'),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final (i, color) in AvatarPalette.hairColors.indexed)
              _Swatch(
                key: ValueKey('hair-color-$i'),
                color: color,
                label: AvatarPalette.hairColorNames[i],
                selected: avatar.hairColor == i,
                onTap: () => onChange(avatar.copyWith(hairColor: i)),
              ),
          ],
        ),
        label('Jersey'),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final (i, (color, _)) in AvatarPalette.jerseys.indexed)
              _Swatch(
                key: ValueKey('jersey-$i'),
                color: color,
                label: '${AvatarPalette.jerseyNames[i]} jersey',
                selected: avatar.jersey == i,
                onTap: () => onChange(avatar.copyWith(jersey: i)),
              ),
          ],
        ),
        label('Jersey number'),
        Row(
          children: [
            IconButton.filledTonal(
              key: const ValueKey('number-down'),
              tooltip: 'Lower number',
              onPressed: avatar.number > AvatarOptions.minNumber
                  ? () => onChange(avatar.copyWith(number: avatar.number - 1))
                  : null,
              icon: const Icon(Icons.remove_rounded),
            ),
            SizedBox(
              width: 64,
              child: Text(
                '${avatar.number}',
                textAlign: TextAlign.center,
                style: text.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            IconButton.filledTonal(
              key: const ValueKey('number-up'),
              tooltip: 'Raise number',
              onPressed: avatar.number < AvatarOptions.maxNumber
                  ? () => onChange(avatar.copyWith(number: avatar.number + 1))
                  : null,
              icon: const Icon(Icons.add_rounded),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          key: const ValueKey('headband'),
          contentPadding: EdgeInsets.zero,
          title: Text(
            'Headband',
            style: text.titleSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          value: avatar.headband,
          onChanged: (on) => onChange(avatar.copyWith(headband: on)),
        ),
      ],
    );
  }
}

/// A round colour choice with a tick when picked.
class _Swatch extends StatelessWidget {
  const new({
    required this.color,
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final Color color;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    final light = color.computeLuminance() > 0.5;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: InkResponse(
        onTap: onTap,
        radius: 26,
        child: AnimatedContainer(
          duration: motion(context, const Duration(milliseconds: 150)),
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? tokens.choice : tokens.surfaceMuted,
              width: selected ? 4 : 2,
            ),
          ),
          child: selected
              ? Icon(
                  Icons.check_rounded,
                  color: light ? Colors.black87 : Colors.white,
                )
              : null,
        ),
      ),
    );
  }
}
