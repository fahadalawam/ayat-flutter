import 'package:flutter/material.dart';

import 'package:text_to_speech/text_to_speech.dart';

class TtsPage extends StatelessWidget {
  late TextToSpeech tts;

  @override
  Widget build(BuildContext context) {
    tts = TextToSpeech();
    double volume = 1.0;
    tts.setVolume(volume);

    return Scaffold(
      appBar: AppBar(title: Text('TTS page')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              child: Text("أهلا وسهلا"),
              onPressed: () async {
                tts.setLanguage('ar-SA');
                String text = 'بِسْمِ اللهِ الرَّحْمنِ الرَّحِيمِِ';
                tts.speak(text);
              },
            ),
            ElevatedButton(
              child: Text('hindi'),
              onPressed: () async {
                tts.setLanguage('hi-IN');
                String text = 'सूरए फातेहा मक्का में नाजि़ल हुआ और इस की 7 आयते हैं';
                tts.speak(text);
              },
            ),
            ElevatedButton(
              child: Text('spain'),
              onPressed: () async {
                tts.setLanguage('es-ES');
                String text = 'Alabado sea Alá, Señor del universo';
                tts.speak(text);
              },
            ),
            ElevatedButton(
              child: Text('turkish'),
              onPressed: () async {
                tts.setLanguage('tr-TR');
                String text = "Yalnız sana ibadet ederiz ve yalnız senden yardım dileriz";
                tts.speak(text);
              },
            ),
            ElevatedButton(
              child: Text('french'),
              onPressed: () async {
                tts.setLanguage('fr-FR');
                String text = 'Louange à Allah, Seigneur de l’Univers.';
                tts.speak(text);
              },
            ),
            ElevatedButton(
              child: Text('english'),
              onPressed: () async {
                tts.setLanguage('en-US');
                String text = 'All praise is for Allah—Lord of all worlds';
                tts.speak(text);
              },
            ),
          ],
        ),
      ),
    );
  }

  // hi-IN
  // es-ES
}
