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
        body: const VimeoVideoPlayer(
          loadingIndicator: CircularProgressIndicator(),
          backgroundColor: Colors.purple,
        ),
      ),
    );
  }
}
