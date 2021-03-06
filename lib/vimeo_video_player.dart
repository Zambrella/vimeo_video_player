library vimeo_video_player;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
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
    this.qualityData,
    this.videoPlayerController,
    this.selectedQuality,
    this.constructorType = _ConstructorType.regular,
  }) : super(key: key);

  /// Constructor to built a new instance of [VimeoVideoPlayer] with fullscreen parameters. Only to be used internally.
  const VimeoVideoPlayer.fullscreen({
    required String videoUrl,
    required List<VimeoQualityData> qualityData,
    required VideoPlayerController controller,
    required VimeoQualityData selectedQuality,
    required _ConstructorType constructorType,
    Key? key,
  }) : this(
          key: key,
          videoUrl: videoUrl,
          isFullScreen: true,
          qualityData: qualityData,
          videoPlayerController: controller,
          selectedQuality: selectedQuality,
          constructorType: _ConstructorType.fullscreen,
          autoPlay: true,
        );

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

  // Inline fullscreen variables
  final List<VimeoQualityData>? qualityData;
  final VimeoQualityData? selectedQuality;
  final VideoPlayerController? videoPlayerController;
  final _ConstructorType constructorType;

  @override
  State<VimeoVideoPlayer> createState() => _VimeoVideoPlayerState();
}

class _VimeoVideoPlayerState extends State<VimeoVideoPlayer> {
  // Video controlling variables
  late final List<VimeoQualityData> _qualityValues;
  late VideoPlayerController _controller;
  late VimeoQualityData _selectedQuality;
  Duration? _seekTo;

  // state variables to handle UI
  bool _isPlaying = false;
  bool _showOverlay = true;
  String? _errorMessage;

  Future<void>? initFuture;

  @override
  void initState() {
    super.initState();
    _initialiseVideo();
  }

  @override
  void dispose() {
    // Let the framework dispose of the controller if the widget was not built by the video player itself
    // if (widget.constructorType == _ConstructorType.regular) {
    _controller.pause();
    _controller.dispose();
    // }
    super.dispose();
  }

  void _customDispose() {
    _controller.pause();
    _controller.dispose();
  }

  Future<void> _initialiseVideo() async {
    try {
      _qualityValues = widget.qualityData ?? await _getQualities(widget.videoUrl);
      _selectedQuality = widget.selectedQuality ?? _qualityValues.first;
      _controller = widget.videoPlayerController ?? VideoPlayerController.network(_selectedQuality.url);
      _seekTo = _controller.value.position;
      _rotateScreen(_selectedQuality.width / _selectedQuality.height);
      if (widget.autoPlay) _playVideo();
      setState(() {
        initFuture = _controller.initialize();
      });
      return;
    } on PlatformException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    }
  }

  void _rotateScreen(double aspectRatio) {
    if (aspectRatio > 1 && widget.isFullScreen) {
      setState(() {
        SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
      });
    } else {
      setState(() {
        SystemChrome.setPreferredOrientations([DeviceOrientation.portraitDown, DeviceOrientation.portraitUp]);
      });
    }
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
    // Store the current position of video
    _seekTo = _controller.value.position;
    // Pause video
    _pauseVideo();
    await _controller.dispose();
    // Update selected quality
    _selectedQuality = vimeoQualityData;
    // Update video controller with new URL
    _controller = VideoPlayerController.network(_selectedQuality.url);
    // Initialise
    setState(() {
      initFuture = _controller.initialize();
    });
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
    _controller.pause(); //? Is this needed
    setState(() {
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitDown, DeviceOrientation.portraitUp]);
    });
    Navigator.of(context).pop(_controller);
  }

  void _fullScreenPressed() async {
    if (widget.isFullScreen) {
      _closePressed();
    } else {
      _controller.pause();
      _controller = await Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute(
          settings: const RouteSettings(name: 'Vimeo Full Screen Player'),
          builder: (context) => VimeoVideoPlayer.fullscreen(
            videoUrl: widget.videoUrl,
            qualityData: _qualityValues,
            controller: _controller,
            selectedQuality: _selectedQuality,
            constructorType: _ConstructorType.fullscreen,
          ),
        ),
      );
      setState(() {});
    }
  }

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
          future: initFuture,
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
              // Seeking only works once initialised has completed
              if (_seekTo != null) {
                _controller.seekTo(_seekTo!);
                _seekTo = null;
              }

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
                          //* Video
                          Center(
                            child: VideoPlayer(_controller),
                          ),
                          //* Darken overlay
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
                                  isFullscreen: widget.isFullScreen,
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
      // Map response data to objects then sort by highest resolution first
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

enum _ConstructorType { regular, fullscreen }

enum Orientation { landscape, portrait }

extension GetRotation on Orientation {}
