library vimeo_video_player;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';

part 'src/video_overlay.dart';

class VimeoVideoPlayer extends StatefulWidget {
  const VimeoVideoPlayer({
    Key? key,
    required this.videoUrl,
    this.loadingIndicator = const CircularProgressIndicator(),
    this.backgroundColor = Colors.green,
    this.loadingIndicatorSize = 0.1,
    this.autoPlay = false,
  }) : super(key: key);

  /// Vimeo link in format of "https://player.vimeo.com/video/$videoId".
  final String videoUrl;

  /// Widget that is displayed in the middle of the widget while the video loads.
  final Widget loadingIndicator;

  /// Background color of canvas for video. Only displays while the video is loading.
  final Color backgroundColor;

  /// Ratio to the width of video.
  final double loadingIndicatorSize;

  /// Set to [true] to have video play as soon as the video is loaded. Defaults to [false].
  final bool autoPlay;

  @override
  State<VimeoVideoPlayer> createState() => _VimeoVideoPlayerState();
}

class _VimeoVideoPlayerState extends State<VimeoVideoPlayer> {
  bool isLoading = true;
  bool hasError = false;

  late final VideoPlayerController _controller;
  late final List<VimeoQualityData> _qualityValues;
  late VimeoQualityData _selectedQuality;

  Future<void>? initFuture;

  @override
  void initState() {
    super.initState();
    _initialiseVideo();
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  Future<void> _initialiseVideo() async {
    _qualityValues = await _getQualities(widget.videoUrl);
    _selectedQuality = _qualityValues.last;
    _controller = VideoPlayerController.network(_selectedQuality.url);
    initFuture = _controller.initialize();
    setState(() {});
    if (widget.autoPlay) _controller.play();
  }

  void _playVideo() {
    _controller.play();
    setState(() {});
  }

  void _pauseVideo() {
    _controller.pause();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final totalWidth = constraints.maxWidth;
          final totalHeight = constraints.maxHeight;
          print('Total Width: $totalWidth, Total Height: $totalHeight');
          return FutureBuilder(
            // [initFuture] is assigned only once the video data has been collected so that the future doesn't change and cause a rebuild when calling setstate because in this case the value of the future doesn't change once the video data has loaded
            future: initFuture,
            builder: (context, snapshot) {
              print(snapshot.connectionState);
              if (snapshot.connectionState == ConnectionState.done) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    AspectRatio(
                      aspectRatio: _controller.value.aspectRatio,
                      child: Center(
                        child: VideoPlayer(_controller),
                      ),
                    ),
                    Align(
                      alignment: Alignment.center,
                      child: IconButton(
                        onPressed: () {
                          if (_controller.value.isPlaying) {
                            _pauseVideo();
                          } else {
                            _playVideo();
                          }
                        },
                        icon: Icon(
                          _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                        ),
                      ),
                    )
                  ],
                );
              } else if (snapshot.hasError) {
                return Text('Error');
              } else {
                //* Background
                return Container(
                  decoration: BoxDecoration(
                    color: widget.backgroundColor,
                  ),
                  //* Loading indicator
                  child: Center(
                    child: FractionallySizedBox(
                      widthFactor: widget.loadingIndicatorSize,
                      child: AspectRatio(
                        aspectRatio: 1.0,
                        child: isLoading ? widget.loadingIndicator : const SizedBox.shrink(),
                      ),
                    ),
                  ),
                );
              }
            },
          );
        },
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
      List<VimeoQualityData> qualities = data.map((item) => VimeoQualityData.fromMap(item)).toList();
      return qualities;
    }
  } catch (e) {
    throw Exception('Error fetching video data');
  }
}

class VimeoQualityData {
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
}
