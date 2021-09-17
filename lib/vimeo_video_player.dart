library vimeo_video_player;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';

class VimeoVideoPlayer extends StatefulWidget {
  const VimeoVideoPlayer({
    Key? key,
    required this.videoUrl,
    this.loadingIndicator = const CircularProgressIndicator(),
    this.backgroundColor = Colors.black,
    this.loadingIndicatorSize = 0.1,
  }) : super(key: key);

  /// Vimeo link
  final String videoUrl;

  /// Widget that is displayed in the middle of the widget while the video loads.
  final Widget loadingIndicator;

  /// Background color of canvas for video. Only displays while the video is loading.
  final Color backgroundColor;

  /// Ratio to the width of video.
  final double loadingIndicatorSize;

  @override
  State<VimeoVideoPlayer> createState() => _VimeoVideoPlayerState();
}

class _VimeoVideoPlayerState extends State<VimeoVideoPlayer> {
  bool isLoading = true;
  bool hasError = false;

  late final VideoPlayerController _controller;
  late final List<VimeoQualityData> _qualityValues;
  late VimeoQualityData _selectedQuality;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  Future<void> initialiseVideo() async {
    _qualityValues = await _getQualities(widget.videoUrl);
    _selectedQuality = _qualityValues.last;
    _controller = VideoPlayerController.network(_selectedQuality.url);
    _controller.initialize();
    // _controller.play();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            fit: StackFit.expand,
            alignment: Alignment.center,
            children: [
              FutureBuilder(
                future: initialiseVideo(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    return SizedBox(width: 200, height: 200, child: VideoPlayer(_controller));
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
              ),
              // Overlay
            ],
          );
        },
      ),
    );
  }
}

Future<List<VimeoQualityData>> _getQualities(String videoUrl) async {
  try {
    final videoId = videoUrl.substring(videoUrl.lastIndexOf('/') + 1, videoUrl.length).trim();
    // Get data about the video's settings
    final response = await http.get(Uri.parse('https://player.vimeo.com/video/$videoId/config'));
    // Convert response to a json object
    final Iterable data = jsonDecode(response.body)['request']['files']['progressive'];
    // Todo: Improve this by creating a quality object
    List<VimeoQualityData> qualities = data.map((item) => VimeoQualityData.fromMap(item)).toList();
    return qualities;
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
