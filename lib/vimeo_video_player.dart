library vimeo_video_player;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import 'package:async/async.dart';
import 'package:equatable/equatable.dart';

part 'src/video_slider.dart';

class VimeoVideoPlayer extends StatefulWidget {
  const VimeoVideoPlayer({
    Key? key,
    required this.videoUrl,
    this.loadingIndicator = const CircularProgressIndicator(),
    this.backgroundColor = Colors.green,
    this.loadingIndicatorSize = 30.0,
    this.autoPlay = false,
    this.iconSizes = 30.0,
    this.iconColor = Colors.white,
    this.iconMargin = 6.0,
    this.sliderColor = Colors.white,
    this.overlayCloseDelay = const Duration(seconds: 3),
    this.isFullScreen = false,
    this.overlayColor = Colors.black,
  }) : super(key: key);

  /// Vimeo link in format of "https://player.vimeo.com/video/$videoId".
  final String videoUrl;

  /// Widget that is displayed in the middle of the widget while the video loads.
  final Widget loadingIndicator;

  /// Background color of canvas for video. Only displays while the video is loading.
  final Color backgroundColor;

  /// Size, in pixels, of loading widget
  final double loadingIndicatorSize;

  /// Set to [true] to have video play as soon as the video is loaded. Defaults to [false].
  final bool autoPlay;

  // Size, in pixels, of overlay icons; play, pause, fullscreen, close
  final double iconSizes;

  // Color of overlay icons
  final Color iconColor;

  // Distance of icons from the edges of the video
  final double iconMargin;

  // Color of slider. Buffered and background color of slider will display with this color but with opacity.
  final Color sliderColor;

  // Time it takes for the overlay to close after pressing play
  final Duration overlayCloseDelay;

  // When the overlay is shown, this will cover the entire video. This video will be shown with an opacity of 0.2.
  final Color overlayColor;

  // Set to [true] if the video is the only widget on the page
  final bool isFullScreen;

  @override
  State<VimeoVideoPlayer> createState() => _VimeoVideoPlayerState();
}

class _VimeoVideoPlayerState extends State<VimeoVideoPlayer> {
  // Video controlling variables
  late final List<VimeoQualityData> _qualityValues;
  late VideoPlayerController _controller;
  late VimeoQualityData _selectedQuality;
  late final AsyncMemoizer _memoizer;

  // state variables to handle UI
  bool _isPlaying = false;
  bool _showOverlay = true;
  String? _errorMessage;

  Future<void>? initFuture;

  @override
  void initState() {
    super.initState();
    _memoizer = AsyncMemoizer();
  }

  @override
  void dispose() {
    super.dispose();
    _controller.pause();
    _controller.dispose();
  }

  Future<void> _initialiseVideo() {
    return _memoizer.runOnce(() async {
      try {
        _qualityValues = await _getQualities(widget.videoUrl);
        _selectedQuality = _qualityValues.first;
        _controller = VideoPlayerController.network(_selectedQuality.url);
        await _controller.initialize();
        if (widget.autoPlay) _playVideo();
        return;
      } on PlatformException catch (e) {
        setState(() {
          _errorMessage = e.message;
        });
      }
    });
  }

  void _playVideo() {
    _controller.play();
    setState(() => _isPlaying = true);
    Future.delayed(widget.overlayCloseDelay, () {
      if (_controller.value.isPlaying) {
        setState(() => _showOverlay = false);
      }
    });
  }

  void _pauseVideo() {
    _controller.pause();
    setState(() {
      _isPlaying = false;
    });
  }

  void _playPause() {
    if (_controller.value.isPlaying) {
      _pauseVideo();
    } else {
      _playVideo();
    }
  }

  void _updateSettings(VimeoQualityData vimeoQualityData) async {
    // Store if the video was playing
    final wasPlaying = _controller.value.isPlaying;
    // Pause video
    _pauseVideo();
    // Update selected quality
    _selectedQuality = vimeoQualityData;
    // Store the current position of video
    final currentPosition = _controller.value.position;
    // Update video controller with new URL
    _controller = VideoPlayerController.network(_selectedQuality.url);
    // Initialise
    await _controller.initialize();
    // Move position of video to where was left off
    _controller.seekTo(currentPosition);
    // Play video if it was playing when settings where changed
    if (wasPlaying) _playVideo();
  }

  void _settingsPressed() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Wrap(
          children: _qualityValues
              .map(
                (value) => ListTile(
                  title: Text('${value.quality} - ${value.fps} fps'),
                  trailing: value == _selectedQuality
                      ? const Icon(
                          Icons.check,
                          color: Colors.black,
                        )
                      : null,
                  onTap: () {
                    _updateSettings(value);
                    Navigator.pop(context);
                  },
                ),
              )
              .toList(),
        );
      },
    );
  }

  void _closePressed() {
    _controller.pause();
    Navigator.of(context).pop();
  }

  void _fullScreenPressed() {}

  void _toggleOverlay() {
    setState(() {
      _showOverlay = !_showOverlay;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: widget.isFullScreen ? Colors.black : Colors.transparent,
      child: Center(
        child: FutureBuilder(
          future: _initialiseVideo(),
          builder: (context, snapshot) {
            if (_errorMessage != null) {
              return Text(
                '$_errorMessage',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: widget.isFullScreen ? Colors.white : Colors.black,
                ),
              );
            } else if (snapshot.connectionState == ConnectionState.done) {
              return AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return GestureDetector(
                      onTap: _toggleOverlay,
                      child: Stack(
                        fit: StackFit.expand,
                        alignment: Alignment.center,
                        children: [
                          Center(
                            child: VideoPlayer(_controller),
                          ),
                          if (_showOverlay)
                            Container(
                              color: widget.overlayColor.withOpacity(0.3),
                            ),
                          //* Pause/Play
                          if (_showOverlay)
                            Align(
                              alignment: Alignment.center,
                              child: IconButton(
                                onPressed: _playPause,
                                iconSize: widget.iconSizes * 1.5,
                                icon: Icon(
                                  _isPlaying ? Icons.pause : Icons.play_arrow,
                                  color: widget.iconColor,
                                ),
                              ),
                            ),
                          //* Settings
                          if (_showOverlay)
                            Positioned(
                              top: widget.iconMargin,
                              right: widget.iconMargin,
                              child: IconButton(
                                onPressed: _settingsPressed,
                                iconSize: widget.iconSizes,
                                icon: Icon(
                                  Icons.settings,
                                  color: widget.iconColor,
                                ),
                              ),
                            ),
                          //* Close
                          if (_showOverlay && widget.isFullScreen)
                            Positioned(
                              top: widget.iconMargin,
                              left: widget.iconMargin,
                              child: IconButton(
                                onPressed: _closePressed,
                                iconSize: widget.iconSizes,
                                icon: Icon(
                                  Icons.close,
                                  color: widget.iconColor,
                                ),
                              ),
                            ),
                          //* Slider
                          if (_showOverlay)
                            Positioned(
                              bottom: widget.iconMargin,
                              child: SizedBox(
                                width: constraints.maxWidth,
                                child: VideoSlider(
                                  _controller,
                                  iconSize: widget.iconSizes,
                                  isFullscreen: false,
                                  fullScreenPress: _fullScreenPressed,
                                  iconColor: widget.iconColor,
                                  sliderColor: widget.sliderColor,
                                  iconMargin: widget.iconMargin,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              );
            } else {
              //* Background
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.transparent,
                ),
                //* Loading indicator
                child: Center(
                  child: SizedBox(
                    height: widget.loadingIndicatorSize,
                    width: widget.loadingIndicatorSize,
                    child: widget.loadingIndicator,
                  ),
                ),
              );
            }
          },
        ),
      ),
    );
  }
}

Future<List<VimeoQualityData>> _getQualities(String videoUrl) async {
  assert(videoUrl.contains('vimeo'), 'Video url is not a vimeo link');
  try {
    final videoId = videoUrl.substring(videoUrl.lastIndexOf('/') + 1, videoUrl.length).trim();
    // Get data about the video's settings
    final response = await http.get(Uri.parse('https://player.vimeo.com/video/$videoId/config'));
    if (response.statusCode != 200) {
      throw Exception('Error getting video data');
    } else {
      // Convert response to a json object
      final Iterable data = jsonDecode(response.body)['request']['files']['progressive'];
      List<VimeoQualityData> qualities = data.map((item) => VimeoQualityData.fromMap(item)).toList()
        ..sort((b, a) => a.width.compareTo(b.width));
      return qualities;
    }
  } catch (e) {
    throw Exception('Error fetching video data');
  }
}

class VimeoQualityData extends Equatable {
  const VimeoQualityData({required this.width, required this.height, required this.fps, required this.quality, required this.url});

  final int width;
  final int height;
  final int fps;
  final String quality;
  final String url;

  Map<String, dynamic> toMap() {
    return {
      'width': width,
      'height': height,
      'fps': fps,
      'quality': quality,
      'url': url,
    };
  }

  factory VimeoQualityData.fromMap(Map<String, dynamic> map) {
    return VimeoQualityData(
      width: map['width'],
      height: map['height'],
      fps: map['fps'],
      quality: map['quality'],
      url: map['url'],
    );
  }

  String toJson() => json.encode(toMap());

  factory VimeoQualityData.fromJson(String source) => VimeoQualityData.fromMap(json.decode(source));

  @override
  String toString() {
    return 'VimeoQualityData(width: $width, height: $height, fps: $fps, quality: $quality, url: $url)';
  }

  @override
  List<Object?> get props => [width, height, fps, quality, url];
}
