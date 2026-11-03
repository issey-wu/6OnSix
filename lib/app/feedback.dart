import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:six_on_six/app/logger.dart';
import 'package:six_on_six/app/providers.dart';

const _logger = AppLogger('feedback');

/// The moments that get a sound and a haptic (docs/design.md, section 9).
enum FeedbackEvent { correct, incorrect, pairMatched, tokenSnapped, complete }

/// Plays sounds and haptics for key moments, following the learner's
/// sound and haptics settings. Regular button taps get neither.
class FeedbackService {
  new(this._ref, {this.playSounds = true});

  final Ref _ref;

  /// False in widget tests, where there is no audio plugin.
  final bool playSounds;

  AudioPlayer? _player;

  static const Map<FeedbackEvent, String> _files = {
    FeedbackEvent.correct: 'sounds/correct.wav',
    FeedbackEvent.incorrect: 'sounds/incorrect.wav',
    FeedbackEvent.pairMatched: 'sounds/match_pop.wav',
    FeedbackEvent.tokenSnapped: 'sounds/token_snap.wav',
    FeedbackEvent.complete: 'sounds/lesson_complete.wav',
  };

  void play(FeedbackEvent event) {
    final settings = _ref.read(settingsProvider);
    if (settings.hapticsOn) unawaited(_haptic(event));
    if (settings.soundOn && playSounds) unawaited(_sound(event));
  }

  Future<void> _haptic(FeedbackEvent event) async {
    switch (event) {
      case FeedbackEvent.correct:
      case FeedbackEvent.pairMatched:
        await HapticFeedback.lightImpact();
      case FeedbackEvent.tokenSnapped:
        await HapticFeedback.selectionClick();
      case FeedbackEvent.incorrect:
        await HapticFeedback.mediumImpact();
      case FeedbackEvent.complete:
        await HapticFeedback.heavyImpact();
    }
  }

  Future<void> _sound(FeedbackEvent event) async {
    try {
      final player = _player ??= await _createPlayer();
      await player.stop();
      await player.play(AssetSource(_files[event]!));
    } on Object catch (error, stackTrace) {
      _logger.warning(
        'Could not play sound',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<AudioPlayer> _createPlayer() async {
    // Ambient audio: mixes with other apps and respects the silent switch.
    await AudioPlayer.global.setAudioContext(
      AudioContextConfig(respectSilence: true).build(),
    );
    final player = AudioPlayer();
    await player.setReleaseMode(ReleaseMode.stop);
    return player;
  }
}

final feedbackProvider = Provider<FeedbackService>(
  (ref) => FeedbackService(
    ref,
    playSounds: !Platform.environment.containsKey('FLUTTER_TEST'),
  ),
);
