import 'package:flutter_test/flutter_test.dart';
import 'package:six_on_six/core/domain/avatar.dart';

void main() {
  test('there are 50 different ready-made avatars', () {
    expect(avatarPresets, hasLength(50));
    expect(avatarPresets.toSet(), hasLength(50));
  });

  test('every hair style and jersey colour appears in the presets', () {
    expect(avatarPresets.map((a) => a.hair).toSet(), HairStyle.values.toSet());
    expect(
      avatarPresets.map((a) => a.jersey).toSet(),
      hasLength(AvatarOptions.jerseyColors),
    );
  });

  test('an avatar survives a save and load', () {
    const avatar = Avatar(
      skin: 4,
      hair: HairStyle.afro,
      hairColor: 3,
      jersey: 5,
      number: 23,
      headband: true,
    );
    expect(avatarFromJson(avatar.toJson()), avatar);
  });

  test('damaged or out-of-range values fall back to the defaults', () {
    final avatar = avatarFromJson({
      'skin': 40,
      'hair': 'mohawk',
      'hairColor': -1,
      'jersey': 'red',
      'number': 150,
    });
    expect(avatar, const Avatar());
  });

  test('the jersey number stays between 1 and 99', () {
    expect(const Avatar(number: 99).copyWith(number: 100).number, 99);
    expect(const Avatar(number: 1).copyWith(number: 0).number, 1);
  });
}
