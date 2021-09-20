import 'package:flutter/material.dart';
import 'package:vimeo_video_player/vimeo_video_player.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Vimeo Video Demo'),
        ),
        body: const HomePage(),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          ElevatedButton(
            onPressed: () {},
            child: const Text('Play video'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context, rootNavigator: false).push(
                MaterialPageRoute(
                  builder: (context) => const VimeoVideoPlayer(
                    videoUrl: 'https://player.vimeo.com/video/606395365',
                    // videoUrl: 'https://player.vimeo.com/video/596474336',
                    loadingIndicator: CircularProgressIndicator(),
                    backgroundColor: Colors.purple,
                    autoPlay: true,
                    isFullScreen: true,
                  ),
                ),
              );
            },
            child: const Text('Full Screen Video'),
          ),
          const VideoContainer(),
        ],
      ),
    );
  }
}

class VideoContainer extends StatelessWidget {
  const VideoContainer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width - 20,
      height: MediaQuery.of(context).size.height - 300,
      child: const VimeoVideoPlayer(
        videoUrl: 'https://player.vimeo.com/video/606395365',
        // videoUrl: 'https://player.vimeo.com/video/596474336',
        loadingIndicator: CircularProgressIndicator(),
        backgroundColor: Colors.purple,
        autoPlay: false,
      ),
    );
  }
}
