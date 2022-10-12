import 'package:ayat/pages/svg_page.dart';
import 'package:ayat/pages/tts_page.dart';
import 'package:ayat/providers/prevs.dart';
import 'package:flutter/material.dart';
import './pages/home_page.dart';
import 'package:provider/provider.dart';
import 'package:just_audio_background/just_audio_background.dart';

Future<void> main() async {
  // runApp(const MyApp());
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.ryanheise.bg_demo.channel.audio',
    androidNotificationChannelName: 'Audio playback',
    androidNotificationOngoing: true,
  );
  runApp(
    ChangeNotifierProvider(
      create: ((context) => Prevs()),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(),
      // home: TtsPage(),
      // home: SvgPage(),
    );
  }
}
