library vimeo_video_player;

import 'package:flutter/material.dart';

class VimeoVideoPlayer extends StatefulWidget {
  const VimeoVideoPlayer({
    Key? key,
    this.loadingIndicator = const CircularProgressIndicator(),
    this.backgroundColor = Colors.black,
    this.loadingIndicatorSize = 0.1,
  }) : super(key: key);

  /// Widget that is displayed in the middle of the widget while the video loads.
  final Widget loadingIndicator;

  /// Background color of canvas for video. Only displays while the video is loading.
  final Color backgroundColor;

  /// Ratio of the width of video.
  final double loadingIndicatorSize;

  @override
  State<VimeoVideoPlayer> createState() => _VimeoVideoPlayerState();
}

class _VimeoVideoPlayerState extends State<VimeoVideoPlayer> {
  double? videoWidth;
  double? videoHeight;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Temporary
    videoHeight = MediaQuery.of(context).size.height;
    videoWidth = MediaQuery.of(context).size.width;
    return Center(
      child: SizedBox(
        width: videoHeight,
        height: videoHeight,
        child: Stack(
          fit: StackFit.expand,
          children: [
            //* Background
            Container(
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
            ),
            // Video
            // Overlay
          ],
        ),
      ),
    );
  }
}
