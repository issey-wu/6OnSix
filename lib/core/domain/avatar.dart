import 'package:meta/meta.dart';

/// Hair styles for the avatar builder.
enum HairStyle {
  none('None'),
  buzz('Buzz'),
  short('Short'),
  curly('Curly'),
  afro('Afro'),
  ponytail('Ponytail'),
  bun('Bun'),
  long('Long');

  new(this.label);

  final String label;
}

/// How many choices each part of the avatar has. The colours themselves live
/// in the UI (lib/core/ui/avatar_view.dart).
abstract final class AvatarOptions {
  static const skinTones = 6;
  static const hairColors = 6;
  static const jerseyColors = 8;
  static const minNumber = 1;
  static const maxNumber = 99;
}

/// The learner's player avatar: a volleyball player in a jersey.
@immutable
class Avatar {
  const new({
    this.skin = 2,
    this.hair = HairStyle.short,
    this.hairColor = 1,
    this.jersey = 0,
    this.number = 6,
    this.headband = false,
  });

  /// Index into the skin tones, 0 to [AvatarOptions.skinTones] - 1.
  final int skin;
  final HairStyle hair;

  /// Index into the hair colours.
  final int hairColor;

  /// Index into the jersey colours.
  final int jersey;

  /// Jersey number, 1 to 99.
  final int number;
  final bool headband;

  Avatar copyWith({
    int? skin,
    HairStyle? hair,
    int? hairColor,
    int? jersey,
    int? number,
    bool? headband,
  }) => Avatar(
    skin: skin ?? this.skin,
    hair: hair ?? this.hair,
    hairColor: hairColor ?? this.hairColor,
    jersey: jersey ?? this.jersey,
    number: (number ?? this.number).clamp(
      AvatarOptions.minNumber,
      AvatarOptions.maxNumber,
    ),
    headband: headband ?? this.headband,
  );

  Map<String, Object?> toJson() => {
    'skin': skin,
    'hair': hair.name,
    'hairColor': hairColor,
    'jersey': jersey,
    'number': number,
    'headband': headband,
  };

  @override
  bool operator ==(Object other) =>
      other is Avatar &&
      other.skin == skin &&
      other.hair == hair &&
      other.hairColor == hairColor &&
      other.jersey == jersey &&
      other.number == number &&
      other.headband == headband;

  @override
  int get hashCode =>
      Object.hash(skin, hair, hairColor, jersey, number, headband);
}

/// Reads an avatar saved with [Avatar.toJson]. Unknown or out-of-range
/// values fall back to the defaults, so an old or damaged save still loads.
Avatar avatarFromJson(Map<String, Object?> json) {
  int pick(String key, int count, int fallback) {
    final value = json[key];
    return value is int && value >= 0 && value < count ? value : fallback;
  }

  const defaults = Avatar();
  final number = json['number'];
  return Avatar(
    skin: pick('skin', AvatarOptions.skinTones, defaults.skin),
    hair: HairStyle.values.firstWhere(
      (h) => h.name == json['hair'],
      orElse: () => defaults.hair,
    ),
    hairColor: pick('hairColor', AvatarOptions.hairColors, defaults.hairColor),
    jersey: pick('jersey', AvatarOptions.jerseyColors, defaults.jersey),
    number:
        number is int &&
            number >= AvatarOptions.minNumber &&
            number <= AvatarOptions.maxNumber
        ? number
        : defaults.number,
    headband: json['headband'] == true,
  );
}

/// The 50 ready-made avatars, a varied spread of every option. The list is
/// fixed, so a preset looks the same on every device.
final List<Avatar> avatarPresets = List.unmodifiable(_buildPresets());

List<Avatar> _buildPresets() {
  const numbers = [
    1,
    2,
    3,
    4,
    5,
    6,
    7,
    8,
    9,
    10,
    11,
    12,
    13,
    14,
    17,
    19,
    21,
    22,
    23,
    24,
    27,
    33,
    44,
    77,
    99,
  ];
  final presets = <Avatar>[];
  final seen = <Avatar>{};
  var i = 0;
  while (presets.length < 50) {
    final avatar = Avatar(
      skin: (i * 5 + 1) % AvatarOptions.skinTones,
      hair: HairStyle.values[(i * 3 + 1) % HairStyle.values.length],
      hairColor: (i * 7 + i ~/ 6 + 2) % AvatarOptions.hairColors,
      jersey:
          (i + i ~/ AvatarOptions.jerseyColors) % AvatarOptions.jerseyColors,
      number: numbers[(i * 11) % numbers.length],
      headband: i % 4 == 3,
    );
    if (seen.add(avatar)) presets.add(avatar);
    i++;
  }
  return presets;
}
