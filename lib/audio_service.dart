import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';

enum AppBgm { home }

class AppAudioService {
  AppAudioService._();

  static final instance = AppAudioService._();
  static const homeBgmAsset = 'assets/audio/soft_rain_meditation.mp3';
  static const defaultBackgroundVolume = .50;

  final _bgmPlayer = AudioPlayer();
  final _brushPlayer = AudioPlayer();
  final _buttonPlayer = AudioPlayer();
  final _completePlayer = AudioPlayer();
  final _emotionPlayer = AudioPlayer();
  final _storyPlayer = AudioPlayer();

  StreamSubscription<AudioInterruptionEvent>? _interruptionSubscription;
  StreamSubscription<void>? _noisySubscription;
  AppBgm? _currentBgm;
  bool _resumeAfterInterruption = false;
  bool effectEnabled = true;
  bool backgroundEnabled = true;
  double effectVolume = .24;
  double backgroundVolume = defaultBackgroundVolume;

  Future<void> initialize() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());

    await Future.wait([
      _brushPlayer.setAsset('assets/audio/brush_soft_v6.mp3'),
      _buttonPlayer.setAsset('assets/audio/button_water_v6.mp3'),
      _completePlayer.setAsset('assets/audio/complete_bird_v6.mp3'),
      _emotionPlayer.setAsset('assets/audio/emotion_water_v6.mp3'),
      _storyPlayer.setAsset('assets/audio/story_page_v6.mp3'),
    ]);
    await _bgmPlayer.setLoopMode(LoopMode.one);
    await _bgmPlayer.setVolume(backgroundVolume);

    _interruptionSubscription = session.interruptionEventStream.listen((event) {
      if (event.begin) {
        _resumeAfterInterruption = _bgmPlayer.playing;
        unawaited(_bgmPlayer.pause());
      } else if (_resumeAfterInterruption &&
          backgroundEnabled &&
          _currentBgm != null) {
        _resumeAfterInterruption = false;
        unawaited(_bgmPlayer.play());
      }
    });
    _noisySubscription = session.becomingNoisyEventStream.listen((_) {
      _resumeAfterInterruption = false;
      unawaited(_bgmPlayer.pause());
    });
  }

  Future<void> setBgm(AppBgm? bgm) async {
    if (_currentBgm != bgm) {
      _currentBgm = bgm;
      if (bgm != null) {
        await _bgmPlayer.setAsset(homeBgmAsset);
        await _bgmPlayer.setLoopMode(LoopMode.one);
      }
    }
    if (bgm == null || !backgroundEnabled) {
      await _bgmPlayer.pause();
    } else {
      unawaited(_bgmPlayer.play());
    }
  }

  Future<void> setEffectEnabled(bool value) async {
    effectEnabled = value;
    if (!value) {
      await Future.wait([
        _brushPlayer.stop(),
        _buttonPlayer.stop(),
        _completePlayer.stop(),
        _emotionPlayer.stop(),
        _storyPlayer.stop(),
      ]);
    }
  }

  Future<void> setBackgroundEnabled(bool value) async {
    backgroundEnabled = value;
    if (value && _currentBgm != null) {
      unawaited(_bgmPlayer.play());
    } else {
      await _bgmPlayer.pause();
    }
  }

  Future<void> setEffectVolume(double value) async {
    effectVolume = value;
  }

  Future<void> setBackgroundVolume(double value) async {
    backgroundVolume = value;
    await _bgmPlayer.setVolume(value);
  }

  Future<void> playBrush() => _play(_brushPlayer, gain: .50);
  Future<void> playButton() => _play(_buttonPlayer, gain: .42);
  Future<void> playComplete() => _play(_completePlayer, gain: .62);
  Future<void> playEmotion() => _play(_emotionPlayer, gain: .48);
  Future<void> playStoryTransition() => _play(_storyPlayer, gain: .45);

  Future<void> _play(AudioPlayer player, {required double gain}) async {
    if (!effectEnabled) return;
    await player.setVolume((effectVolume * gain).clamp(0, 1));
    await player.seek(Duration.zero);
    await player.play();
  }

  Future<void> dispose() async {
    await _interruptionSubscription?.cancel();
    await _noisySubscription?.cancel();
    await Future.wait([
      _bgmPlayer.dispose(),
      _brushPlayer.dispose(),
      _buttonPlayer.dispose(),
      _completePlayer.dispose(),
      _emotionPlayer.dispose(),
      _storyPlayer.dispose(),
    ]);
  }
}
