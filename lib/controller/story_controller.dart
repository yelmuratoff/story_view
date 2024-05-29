import 'package:rxdart/rxdart.dart';

/// Enum to represent the different states of playback for the stories.
enum PlaybackState {
  /// State when the playback is paused.
  pause,

  /// State when the playback is playing.
  play,

  /// State when moving to the next story.
  next,

  /// State when moving to the previous story.
  previous,
}

/// Controller to sync playback between animated child (story) views. This
/// helps make sure when stories are paused, the animation (gifs/slides) are
/// also paused.
/// Another reason for using the controller is to place the stories on `paused`
/// state when a media is loading.
class StoryController {
  /// Stream that broadcasts the playback state of the stories.
  final playbackNotifier = BehaviorSubject<PlaybackState>();

  /// Notify listeners with a [PlaybackState.pause] state
  void pause() {
    playbackNotifier.add(PlaybackState.pause);
  }

  /// Notify listeners with a [PlaybackState.play] state
  void play() {
    playbackNotifier.add(PlaybackState.play);
  }

  /// Notify listeners with a [PlaybackState.next] state to move to the next story.
  void next() {
    playbackNotifier.add(PlaybackState.next);
  }

  /// Notify listeners with a [PlaybackState.previous] state to move to the previous story.
  void previous() {
    playbackNotifier.add(PlaybackState.previous);
  }

  /// Remember to call dispose when the story screen is disposed to close
  /// the notifier stream.
  void dispose() {
    playbackNotifier.close();
  }
}
