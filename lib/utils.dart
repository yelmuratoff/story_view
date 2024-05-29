/// Enum representing the possible states of loading.
enum LoadState {
  /// Indicates that the content is currently loading.
  loading,

  /// Indicates that the content has successfully loaded.
  success,

  /// Indicates that loading the content has failed.
  failure
}

/// Enum representing the possible directions of movement.
enum Direction {
  /// Represents the upward direction.
  up,

  /// Represents the downward direction.
  down,

  /// Represents the leftward direction.
  left,

  /// Represents the rightward direction.
  right
}

/// Class to handle information about vertical drag events.
class VerticalDragInfo {
  /// Indicates if the drag event should be canceled.
  bool cancel = false;

  /// The direction of the drag event.
  Direction? direction;

  /// Updates the direction of the drag event based on the primaryDelta.
  ///
  /// If the primaryDelta is positive, the direction is set to [Direction.down].
  /// If the primaryDelta is negative, the direction is set to [Direction.up].
  /// If the new direction differs from the current direction, the cancel flag is set to true.
  ///
  /// [primaryDelta] The change in the primary axis (vertical) drag distance.
  void update(double primaryDelta) {
    Direction tmpDirection;

    if (primaryDelta > 0) {
      tmpDirection = Direction.down;
    } else {
      tmpDirection = Direction.up;
    }

    if (direction != null && tmpDirection != direction) {
      cancel = true;
    }

    direction = tmpDirection;
  }
}
