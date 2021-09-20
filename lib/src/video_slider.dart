part of vimeo_video_player;

class VideoSlider extends StatelessWidget {
  const VideoSlider(
    this._controller, {
    Key? key,
    required this.iconSize,
    required this.fullScreenPress,
    required this.isFullscreen,
    required this.iconColor,
    required this.sliderColor,
  }) : super(key: key);

  final VideoPlayerController _controller;
  final double iconSize;
  final VoidCallback fullScreenPress;
  final bool isFullscreen;
  final Color iconColor;
  final Color sliderColor;

  @override
  Widget build(BuildContext context) {
    // Similar to adding a listener to the controller
    return ValueListenableBuilder(
      valueListenable: _controller,
      builder: (context, VideoPlayerValue value, child) {
        return Row(
          children: [
            SizedBox(
              width: 50,
              child: Center(
                child: Text(
                  '${value.position.inMinutes}:${(value.position.inSeconds - value.position.inMinutes * 60).toString().padLeft(2, '0')}',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
            Expanded(
              child: SizedBox(
                height: iconSize,
                child: Center(
                  child: VideoProgressIndicator(
                    _controller,
                    allowScrubbing: true,
                    padding: const EdgeInsets.all(0),
                    colors: VideoProgressColors(
                      playedColor: sliderColor,
                      backgroundColor: sliderColor.withOpacity(0.3),
                      bufferedColor: sliderColor.withOpacity(0.6),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(
              width: 50,
              child: Center(
                child: Text(
                  '${value.duration.inMinutes}:${(value.duration.inSeconds - value.duration.inMinutes * 60).toString().padLeft(2, '0')}',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
            IconButton(
              onPressed: fullScreenPress,
              iconSize: iconSize,
              icon: Icon(
                isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
                color: iconColor,
              ),
            ),
          ],
        );
      },
    );
  }
}
