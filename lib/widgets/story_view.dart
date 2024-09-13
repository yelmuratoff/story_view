// ignore_for_file: avoid_bool_literals_in_conditional_expressions, prefer_constructors_over_static_methods, avoid_classes_with_only_static_members

import 'dart:async';
import 'dart:developer';
import 'dart:math' as math;

import 'package:collection/collection.dart' show IterableExtension;
import 'package:flutter/material.dart';

import 'package:story_view/controller/story_controller.dart';
import 'package:story_view/utils.dart';
import 'package:story_view/widgets/story_image.dart';
import 'package:story_view/widgets/story_video.dart';

/// Enum to indicate where the progress indicators should be placed.
enum ProgressPosition {
  /// Indicates that the progress indicators should be placed at the top.
  top,

  /// Indicates that the progress indicators should be placed at the bottom.
  bottom,

  /// Indicates that no progress indicators should be placed.
  none
}

/// Enum to specify the height of the progress indicator.
/// Inline stories should use [small].
enum IndicatorHeight {
  /// Indicates a small height for the progress indicator.
  small,

  /// Indicates a medium height for the progress indicator.
  medium,

  /// Indicates a large height for the progress indicator.
  large
}

/// This is a representation of a story item (or page).
class StoryItem {
  /// Specifies how long the page should be displayed. It should be a reasonable
  /// amount of time greater than 0 milliseconds.
  final Duration duration;

  /// Has this page been shown already? This is used to indicate that the page
  /// has been displayed. If some pages are supposed to be skipped in a story,
  /// mark them as shown `shown = true`.
  ///
  /// However, during initialization of the story view, all pages after the
  /// last unshown page will have their `shown` attribute altered to false. This
  /// is because the next item to be displayed is taken by the last unshown
  /// story item.
  bool shown;

  /// The page content
  final Widget view;

  ///
  StoryItem(
    this.view, {
    required this.duration,
    this.shown = false,
  });

  /// Short hand to create text-only page.
  ///
  /// [title] is the text to be displayed on [backgroundColor]. The text color
  /// alternates between [Colors.black] and [Colors.white] depending on the
  /// calculated contrast. This is to ensure readability of text.
  ///
  /// Works for inline and full-page stories. See [StoryView.inline] for more on
  /// what inline/full-page means.
  static StoryItem text({
    required String title,
    required Color backgroundColor,
    Key? key,
    TextStyle? textStyle,
    bool shown = false,
    bool roundedTop = false,
    bool roundedBottom = false,
    EdgeInsetsGeometry? textOuterPadding,
    Duration? duration,
  }) {
    final double contrast = _ContrastHelper.contrast([
      backgroundColor.red,
      backgroundColor.green,
      backgroundColor.blue,
    ], [
      255,
      255,
      255,
    ] /** white text */);

    return StoryItem(
      Container(
        key: key,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(roundedTop ? 8 : 0),
            bottom: Radius.circular(roundedBottom ? 8 : 0),
          ),
        ),
        padding: textOuterPadding ??
            const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 16,
            ),
        child: Center(
          child: Text(
            title,
            style: textStyle?.copyWith(
                  color: contrast > 1.8 ? Colors.white : Colors.black,
                ) ??
                TextStyle(
                  color: contrast > 1.8 ? Colors.white : Colors.black,
                  fontSize: 18,
                ),
            textAlign: TextAlign.center,
          ),
        ),
        //color: backgroundColor,
      ),
      shown: shown,
      duration: duration ?? const Duration(seconds: 3),
    );
  }

  /// Factory constructor for page images. [controller] should be same instance as
  /// one passed to the `StoryView`
  factory StoryItem.pageImage({
    required String url,
    required StoryController controller,
    Key? key,
    BoxFit imageFit = BoxFit.fitWidth,
    Text? caption,
    bool shown = false,
    Map<String, dynamic>? requestHeaders,
    Widget? loadingWidget,
    Widget? errorWidget,
    EdgeInsetsGeometry? captionOuterPadding,
    Duration? duration,
  }) {
    return StoryItem(
      ColoredBox(
        key: key,
        color: Colors.black,
        child: Stack(
          children: <Widget>[
            StoryImage.url(
              url,
              controller: controller,
              fit: imageFit,
              requestHeaders: requestHeaders,
              loadingWidget: loadingWidget,
              errorWidget: errorWidget,
            ),
            SafeArea(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(
                    bottom: 24,
                  ),
                  padding: captionOuterPadding ??
                      const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 8,
                      ),
                  color: caption != null ? Colors.black54 : Colors.transparent,
                  child: caption ?? const SizedBox.shrink(),
                ),
              ),
            ),
          ],
        ),
      ),
      shown: shown,
      duration: duration ?? const Duration(seconds: 3),
    );
  }

  /// Shorthand for creating inline image. [controller] should be same instance as
  /// one passed to the `StoryView`
  factory StoryItem.inlineImage({
    required String url,
    Text? caption,
    required StoryController controller,
    Key? key,
    BoxFit imageFit = BoxFit.cover,
    Map<String, dynamic>? requestHeaders,
    bool shown = false,
    bool roundedTop = true,
    bool roundedBottom = false,
    Widget? loadingWidget,
    Widget? errorWidget,
    EdgeInsetsGeometry? captionOuterPadding,
    Duration? duration,
  }) {
    return StoryItem(
      ClipRRect(
        key: key,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(roundedTop ? 8 : 0),
          bottom: Radius.circular(roundedBottom ? 8 : 0),
        ),
        child: Container(
          color: Colors.grey[100],
          child: ColoredBox(
            color: Colors.black,
            child: Stack(
              children: <Widget>[
                StoryImage.url(
                  url,
                  controller: controller,
                  fit: imageFit,
                  requestHeaders: requestHeaders,
                  loadingWidget: loadingWidget,
                  errorWidget: errorWidget,
                ),
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: captionOuterPadding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: SizedBox(
                      width: double.infinity,
                      child: caption ?? const SizedBox.shrink(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      shown: shown,
      duration: duration ?? const Duration(seconds: 3),
    );
  }

  /// Shorthand for creating page video. [controller] should be same instance as
  /// one passed to the `StoryView`
  factory StoryItem.pageVideo(
    String url, {
    required StoryController controller,
    Key? key,
    Duration? duration,
    Widget? caption,
    bool shown = false,
    Map<String, dynamic>? requestHeaders,
    Widget? loadingWidget,
    Widget? errorWidget,
  }) {
    return StoryItem(
      ColoredBox(
        key: key,
        color: Colors.black,
        child: Stack(
          children: <Widget>[
            StoryVideo.url(
              url,
              controller: controller,
              requestHeaders: requestHeaders,
              loadingWidget: loadingWidget,
              errorWidget: errorWidget,
            ),
            SafeArea(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 24),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  color: caption != null ? Colors.black54 : Colors.transparent,
                  child: caption ?? const SizedBox.shrink(),
                ),
              ),
            ),
          ],
        ),
      ),
      shown: shown,
      duration: duration ?? const Duration(seconds: 10),
    );
  }

  /// Shorthand for creating a story item from an image provider such as `AssetImage`
  /// or `NetworkImage`. However, the story continues to play while the image loads
  /// up.
  factory StoryItem.pageProviderImage(
    ImageProvider image, {
    Key? key,
    BoxFit imageFit = BoxFit.fitWidth,
    String? caption,
    bool shown = false,
    Duration? duration,
  }) {
    return StoryItem(
      ColoredBox(
        key: key,
        color: Colors.black,
        child: Stack(
          children: <Widget>[
            Center(
              child: Image(
                image: image,
                height: double.infinity,
                width: double.infinity,
                fit: imageFit,
              ),
            ),
            SafeArea(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(
                    bottom: 24,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 8,
                  ),
                  color: caption != null ? Colors.black54 : Colors.transparent,
                  child: caption != null
                      ? Text(
                          caption,
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        )
                      : const SizedBox(),
                ),
              ),
            ),
          ],
        ),
      ),
      shown: shown,
      duration: duration ?? const Duration(seconds: 3),
    );
  }

  /// Shorthand for creating an inline story item from an image provider such as `AssetImage`
  /// or `NetworkImage`. However, the story continues to play while the image loads
  /// up.
  factory StoryItem.inlineProviderImage(
    ImageProvider image, {
    Key? key,
    Text? caption,
    bool shown = false,
    bool roundedTop = true,
    bool roundedBottom = false,
    Duration? duration,
  }) {
    return StoryItem(
      Container(
        key: key,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(roundedTop ? 8 : 0),
            bottom: Radius.circular(roundedBottom ? 8 : 0),
          ),
          image: DecorationImage(
            image: image,
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          margin: const EdgeInsets.only(
            bottom: 16,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 8,
          ),
          child: Align(
            alignment: Alignment.bottomLeft,
            child: SizedBox(
              width: double.infinity,
              child: caption ?? const SizedBox(),
            ),
          ),
        ),
      ),
      shown: shown,
      duration: duration ?? const Duration(seconds: 3),
    );
  }
}

/// Widget to display stories just like Whatsapp and Instagram. Can also be used
/// inline/inside [ListView] or [Column] just like Google News app. Comes with
/// gestures to pause, forward and go to previous page.
class StoryView extends StatefulWidget {
  /// The pages to displayed.
  final List<StoryItem?> storyItems;

  /// Callback for when a full cycle of story is shown. This will be called
  /// each time the full story completes when [repeat] is set to `true`.
  final VoidCallback? onComplete;

  /// Callback for when a vertical swipe gesture is detected. If you do not
  /// want to listen to such event, do not provide it. For instance,
  /// for inline stories inside ListViews, it is preferrable to not to
  /// provide this callback so as to enable scroll events on the list view.
  final Function(Direction?)? onVerticalSwipeComplete;

  /// Callback for when a horizontal swipe gesture is detected. If you do not
  /// want to listen to such event, do not provide it.
  /// This is useful for paginating the story items.
  /// The [Direction] parameter will be either [Direction.left] or [Direction.right].
  final Function(Direction?)? onHorizontalSwipeComplete;

  /// Callback for when a story and it index is currently being shown.
  final void Function(StoryItem storyItem, int index)? onStoryShow;

  /// Callback for when the next page is tapped.
  final void Function(StoryItem storyItem, int index)? onTapNext;

  /// Callback for when the previous page is tapped.
  final void Function(StoryItem storyItem, int index, bool isHasPreviousStories)? onTapPrevious;

  /// Where the progress indicator should be placed.
  final ProgressPosition progressPosition;

  /// Should the story be repeated forever?
  final bool repeat;

  /// If you would like to display the story as full-page, then set this to
  /// `false`. But in case you would display this as part of a page (eg. in
  /// a [ListView] or [Column]) then set this to `true`.
  final bool inline;

  /// Controls the playback of the stories
  final StoryController controller;

  /// Indicator Color
  final Color? indicatorColor;

  /// Indicator Foreground Color
  final Color? indicatorForegroundColor;

  /// Determine the height of the indicator
  final IndicatorHeight indicatorHeight;

  /// Use this if you want to give outer padding to the indicator
  final EdgeInsetsGeometry indicatorOuterPadding;

  /// background color
  final Color backgroundColor;

  /// Top layer stack widgets
  final List<Widget> topLayerStackWidgets;

  ///
  final Widget? lastPageLayerStackWidget;

  ///
  const StoryView({
    required this.storyItems,
    required this.controller,
    this.onComplete,
    this.onStoryShow,
    this.progressPosition = ProgressPosition.top,
    this.repeat = false,
    this.inline = false,
    this.onVerticalSwipeComplete,
    this.onHorizontalSwipeComplete,
    this.indicatorColor,
    this.indicatorForegroundColor,
    this.indicatorHeight = IndicatorHeight.large,
    this.indicatorOuterPadding = const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 8,
    ),
    this.backgroundColor = Colors.white,
    this.topLayerStackWidgets = const [],
    this.lastPageLayerStackWidget,
    this.onTapNext,
    this.onTapPrevious,
  });

  @override
  State<StatefulWidget> createState() {
    return StoryViewState();
  }
}

///
class StoryViewState extends State<StoryView> with TickerProviderStateMixin {
  AnimationController? _animationController;
  Animation<double>? _currentAnimation;
  Timer? _nextDebouncer;

  StreamSubscription<PlaybackState>? _playbackSubscription;

  ///
  VerticalDragInfo? verticalDragInfo;

  ///
  HorizontalDragInfo? horizontalDragInfo;

  StoryItem? get _currentStory {
    return widget.storyItems.firstWhereOrNull((it) => !it!.shown);
  }

  Widget get _currentView {
    var item = widget.storyItems.firstWhereOrNull((it) => !it!.shown);
    item ??= widget.storyItems.last;
    return item?.view ?? Container();
  }

  @override
  void initState() {
    super.initState();

    // All pages after the first unshown page should have their shown value as
    // false
    final firstPage = widget.storyItems.firstWhereOrNull((it) => !it!.shown);
    if (firstPage == null) {
      for (final it2 in widget.storyItems) {
        it2!.shown = false;
      }
    } else {
      final lastShownPos = widget.storyItems.indexOf(firstPage);
      widget.storyItems.sublist(lastShownPos).forEach((it) {
        it!.shown = false;
      });
    }

    _playbackSubscription = widget.controller.playbackNotifier.listen((playbackStatus) {
      switch (playbackStatus) {
        case PlaybackState.play:
          _removeNextHold();
          _animationController?.forward();
          break;

        case PlaybackState.pause:
          _holdNext(); // then pause animation
          _animationController?.stop(canceled: false);
          break;

        case PlaybackState.next:
          _removeNextHold();
          _goForward();
          break;

        case PlaybackState.previous:
          _removeNextHold();
          _goBack();
          break;
      }
    });

    _play();
  }

  @override
  void dispose() {
    _clearDebouncer();

    _animationController?.dispose();
    _playbackSubscription?.cancel();

    super.dispose();
  }

  @override
  void setState(void Function() fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  void _play() {
    _animationController?.dispose();
    // get the next playing page
    final storyItem = widget.storyItems.firstWhere((it) {
      return !it!.shown;
    })!;

    final storyItemIndex = widget.storyItems.indexOf(storyItem);

    if (widget.onStoryShow != null) {
      widget.onStoryShow?.call(storyItem, storyItemIndex);
    }

    _animationController = AnimationController(duration: storyItem.duration, vsync: this);

    _animationController!.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        storyItem.shown = true;
        if (widget.storyItems.last != storyItem) {
          _beginPlay();
        } else {
          // done playing
          _onComplete();
        }
      }
    });

    _currentAnimation = Tween(begin: 0.0, end: 1.0).animate(_animationController!);

    widget.controller.play();
  }

  void _beginPlay() {
    setState(() {});
    _play();
  }

  void _onComplete() {
    if (widget.onComplete != null) {
      widget.controller.pause();
      widget.onComplete!();
    }

    if (widget.repeat) {
      for (final it in widget.storyItems) {
        it!.shown = false;
      }

      _beginPlay();
    }
  }

  void _goBack() {
    _animationController!.stop();

    if (_currentStory == null) {
      widget.storyItems.last!.shown = false;
    }

    if (_currentStory == widget.storyItems.first) {
      _beginPlay();
    } else {
      _currentStory!.shown = false;
      final int lastPos = widget.storyItems.indexOf(_currentStory);
      final previous = widget.storyItems[lastPos - 1]!;

      previous.shown = false;

      _beginPlay();
    }
  }

  void _goForward() {
    if (_currentStory != widget.storyItems.last) {
      _animationController!.stop();

      // get last showing
      final last = _currentStory;

      if (last != null) {
        last.shown = true;
        if (last != widget.storyItems.last) {
          _beginPlay();
        }
      }
    } else {
      // this is the last page, progress animation should skip to end
      _animationController!.animateTo(1.0, duration: const Duration(milliseconds: 10));
    }
  }

  void _clearDebouncer() {
    _nextDebouncer?.cancel();
    _nextDebouncer = null;
  }

  void _removeNextHold() {
    _nextDebouncer?.cancel();
    _nextDebouncer = null;
  }

  void _holdNext() {
    _nextDebouncer?.cancel();
    _nextDebouncer = Timer(const Duration(milliseconds: 500), () {});
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: widget.backgroundColor,
      child: Stack(
        children: <Widget>[
          _currentView,
          Visibility(
            visible: widget.progressPosition != ProgressPosition.none,
            child: Align(
              alignment: widget.progressPosition == ProgressPosition.top ? Alignment.topCenter : Alignment.bottomCenter,
              child: SafeArea(
                bottom: widget.inline ? false : true,
                // we use SafeArea here for notched and bezeles phones
                child: Container(
                  padding: widget.indicatorOuterPadding,
                  child: PageBar(
                    widget.storyItems.map((it) => PageData(it!.duration, it.shown)).toList(),
                    _currentAnimation,
                    key: UniqueKey(),
                    indicatorHeight: widget.indicatorHeight,
                    indicatorColor: widget.indicatorColor,
                    indicatorForegroundColor: widget.indicatorForegroundColor,
                  ),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            heightFactor: 1,
            child: GestureDetector(
              onTapDown: (details) {
                widget.controller.pause();
              },
              onTapCancel: () {
                widget.controller.play();
              },
              onTapUp: (details) {
                // if debounce timed out (not active) then continue anim
                if (_nextDebouncer?.isActive == false) {
                  widget.controller.play();
                } else {
                  if (_currentStory != null) {
                    widget.onTapNext?.call(_currentStory!, widget.storyItems.indexOf(_currentStory));
                  }
                  widget.controller.next();
                }
              },
              onVerticalDragStart: widget.onVerticalSwipeComplete == null
                  ? null
                  : (details) {
                      widget.controller.pause();
                    },
              onVerticalDragCancel: widget.onVerticalSwipeComplete == null
                  ? null
                  : () {
                      widget.controller.play();
                    },
              onVerticalDragUpdate: widget.onVerticalSwipeComplete == null
                  ? null
                  : (details) {
                      verticalDragInfo ??= VerticalDragInfo();

                      verticalDragInfo!.update(details.primaryDelta!);

                      // TODO: provide callback interface for animation purposes
                    },
              onHorizontalDragUpdate: widget.onHorizontalSwipeComplete == null
                  ? null
                  : (details) {
                      horizontalDragInfo ??= HorizontalDragInfo();
                      log('Horizontal Drag Update: ${details.primaryDelta}');
                      horizontalDragInfo!.update(details.primaryDelta!);
                    },
              onVerticalDragEnd: widget.onVerticalSwipeComplete == null
                  ? null
                  : (details) {
                      widget.controller.play();
                      // finish up drag cycle
                      if (!verticalDragInfo!.cancel && widget.onVerticalSwipeComplete != null) {
                        widget.onVerticalSwipeComplete!(
                          verticalDragInfo!.direction,
                        );
                      }

                      verticalDragInfo = null;
                    },
              onHorizontalDragEnd: widget.onHorizontalSwipeComplete == null
                  ? null
                  : (details) {
                      // finish up drag cycle
                      if (widget.onHorizontalSwipeComplete != null) {
                        // ignore: prefer_null_aware_method_calls
                        widget.onHorizontalSwipeComplete!(
                          horizontalDragInfo!.direction,
                        );
                      }
                    },
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            heightFactor: 1,
            child: SizedBox(
              width: 70,
              child: GestureDetector(
                onTap: () {
                  if (_currentStory != null) {
                    widget.onTapPrevious?.call(
                      _currentStory!,
                      widget.storyItems.indexOf(_currentStory),
                      widget.storyItems.indexOf(_currentStory) > 0,
                    );
                  }
                  widget.controller.previous();
                },
              ),
            ),
          ),
          if (widget.topLayerStackWidgets.isNotEmpty) ...widget.topLayerStackWidgets,
          if (widget.lastPageLayerStackWidget != null &&
              widget.storyItems.firstWhereOrNull((it) => it?.shown == false) == widget.storyItems.last)
            widget.lastPageLayerStackWidget!,
        ],
      ),
    );
  }
}

/// Capsule holding the duration and shown property of each story. Passed down
/// to the pages bar to render the page indicators.
class PageData {
  ///
  Duration duration;

  ///
  bool shown;

  ///
  PageData(this.duration, this.shown);
}

/// Horizontal bar displaying a row of [StoryProgressIndicator] based on the
/// [pages] provided.
class PageBar extends StatefulWidget {
  ///
  final List<PageData> pages;

  ///
  final Animation<double>? animation;

  ///
  final IndicatorHeight indicatorHeight;

  ///
  final Color? indicatorColor;

  ///
  final Color? indicatorForegroundColor;

  ///
  const PageBar(
    this.pages,
    this.animation, {
    this.indicatorHeight = IndicatorHeight.large,
    this.indicatorColor,
    this.indicatorForegroundColor,
    Key? key,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return PageBarState();
  }
}

///
class PageBarState extends State<PageBar> {
  ///
  double spacing = 4;

  @override
  void initState() {
    super.initState();

    final int count = widget.pages.length;
    spacing = (count > 15) ? 2 : ((count > 10) ? 3 : 4);

    widget.animation!.addListener(() {
      setState(() {});
    });
  }

  @override
  void setState(void Function() fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  ///
  bool isPlaying(PageData page) {
    return widget.pages.firstWhereOrNull((it) => !it.shown) == page;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: widget.pages.map((it) {
        return Expanded(
          child: Container(
            padding: EdgeInsets.only(
              right: widget.pages.last == it ? 0 : spacing,
            ),
            child: StoryProgressIndicator(
              isPlaying(it) ? widget.animation!.value : (it.shown ? 1 : 0),
              indicatorHeight: widget.indicatorHeight == IndicatorHeight.large
                  ? 5
                  : widget.indicatorHeight == IndicatorHeight.medium
                      ? 3
                      : 2,
              indicatorColor: widget.indicatorColor,
              indicatorForegroundColor: widget.indicatorForegroundColor,
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// Custom progress bar. Supposed to be lighter than the
/// original [ProgressIndicator], and rounded at the sides.
class StoryProgressIndicator extends StatelessWidget {
  /// From `0.0` to `1.0`, determines the progress of the indicator
  final double value;

  ///
  final double indicatorHeight;

  ///
  final Color? indicatorColor;

  ///
  final Color? indicatorForegroundColor;

  ///
  const StoryProgressIndicator(
    this.value, {
    this.indicatorHeight = 5,
    this.indicatorColor,
    this.indicatorForegroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.fromHeight(
        indicatorHeight,
      ),
      foregroundPainter: IndicatorOval(
        indicatorForegroundColor ?? Colors.white.withOpacity(0.8),
        value,
      ),
      painter: IndicatorOval(
        indicatorColor ?? Colors.white.withOpacity(0.4),
        1.0,
      ),
    );
  }
}

///
class IndicatorOval extends CustomPainter {
  ///
  final Color color;

  ///
  final double widthFactor;

  ///
  const IndicatorOval(this.color, this.widthFactor);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width * widthFactor, size.height),
        const Radius.circular(3),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}

/// Concept source: https://stackoverflow.com/a/9733420
class _ContrastHelper {
  _ContrastHelper();

  static double luminance(int? r, int? g, int? b) {
    final a = [r, g, b].map((it) {
      final double value = it!.toDouble() / 255.0;
      return value <= 0.03928 ? value / 12.92 : math.pow((value + 0.055) / 1.055, 2.4);
    }).toList();

    return a[0] * 0.2126 + a[1] * 0.7152 + a[2] * 0.0722;
  }

  static double contrast(List<int> rgb1, List<int> rgb2) {
    return luminance(rgb2[0], rgb2[1], rgb2[2]) / luminance(rgb1[0], rgb1[1], rgb1[2]);
  }
}
