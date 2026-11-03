import 'package:meta/meta.dart';

/// The learner's theme choice in Settings. System follows the phone.
enum ThemeChoice { system, light, dark }

/// The learner's name and settings. Held in memory for now, like
/// progress; saving to the on-device database comes with drift.
@immutable
class Preferences {
  const new({
    this.name = '',
    this.theme = ThemeChoice.system,
    this.sound = true,
    this.haptics = true,
    this.welcomeSeen = false,
  });

  /// Optional display name. Empty until the learner adds one in Profile.
  final String name;
  final ThemeChoice theme;
  final bool sound;
  final bool haptics;

  /// Set once the learner taps Get started on the welcome screen.
  final bool welcomeSeen;

  /// The name to show: "Player" until one is set.
  String get displayName => name.trim().isEmpty ? 'Player' : name.trim();

  bool get hasName => name.trim().isNotEmpty;

  Preferences copyWith({
    String? name,
    ThemeChoice? theme,
    bool? sound,
    bool? haptics,
    bool? welcomeSeen,
  }) => Preferences(
    name: name ?? this.name,
    theme: theme ?? this.theme,
    sound: sound ?? this.sound,
    haptics: haptics ?? this.haptics,
    welcomeSeen: welcomeSeen ?? this.welcomeSeen,
  );

  @override
  bool operator ==(Object other) =>
      other is Preferences &&
      other.name == name &&
      other.theme == theme &&
      other.sound == sound &&
      other.haptics == haptics &&
      other.welcomeSeen == welcomeSeen;

  @override
  int get hashCode => Object.hash(name, theme, sound, haptics, welcomeSeen);
}
