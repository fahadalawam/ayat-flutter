import 'dart:async';
import 'package:ayat/models/clip.dart';
import 'package:ayat/providers/prevs.dart';
import 'package:ayat/utils/timing.dart';

import 'package:flutter/gestures.dart';

import 'package:flutter/material.dart';

import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
// import 'package:audioplayers/audioplayers.dart';
import 'package:quran/quran.dart' as quran;
import 'package:wakelock/wakelock.dart';

import 'package:provider/provider.dart';

import '../widgets/quran_text.dart';
import '../widgets/clip_button.dart';

import 'package:flutter/services.dart' show rootBundle;
import 'package:xml/xml.dart';
import 'package:text_to_speech/text_to_speech.dart';
import 'package:flutter_tts/flutter_tts.dart';
// import 'package:just_audio_background/just_audio_background.dart';

// import 'package:shared_preferences/shared_preferences.dart';

enum SelectionMode { start, end }

class PlayerPage extends StatefulWidget {
  static const PAGE_NAME = 'player-page/';

  int start;
  int end;
  int surahNumber;
  String reciterKey;
  PlayerPage({
    Key? key,
    required this.surahNumber,
    required this.start,
    required this.end,
    required this.reciterKey,
  }) : super(key: key);

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  late AudioPlayer _player;
  late AudioPlayer _clip;
  // late int? _duration;
  late int _surahNumber;
  late int _start;
  late int _end;
  late int _tempStart;
  late int _tempEnd;
  late int _currentVerse;
  late ScrollController _controller;
// TODO: get times from API.
  late List<int> _positions;
  bool _isLoading = true;

  late Timer _timer;

  int? isolatedVers;
  SelectionMode? _selectionMode;
  List<String> _trnaslation = [];
  late TextToSpeech _tts;
  late FlutterTts flutterTts;

  Map<String, String> _reciters = {
    // 'saud_ash-shuraym': 'سعود الشريم',
    'hani_ar_rifai': 'هاني الرفاعي',
    'abdul_baset': 'عبد الباسط عبد الصمد',
    'abdurrahmaan_as_sudais': 'عبدالرحمن السديدس',
    'abu_bakr_shatri': 'ابوبكر الشاطري',
    'khalifah_taniji': 'خليفة تانيجي',
    'khalil_al_husary': 'خليل الحصري',
    'mishari_al_afasy': 'مشاري العفاسي',
    'saud_ash-shuraym': 'سعود الشريم',
    'siddiq_minshawi': 'صادق المنشاوي',
  };

  late String _selectedReciterKey;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    Wakelock.toggle(enable: true);
    _surahNumber = widget.surahNumber;
    _start = widget.start;
    _currentVerse = _start;
    _end = widget.end;
    _player = AudioPlayer();

    _controller = ScrollController();

    _tts = TextToSpeech();

    _selectedReciterKey = widget.reciterKey;
    flutterTts = FlutterTts();
    flutterTts.getLanguages.then((value) => print(value));
    flutterTts.getVoices.then((value) => print(value));
    //tr-TR
    //hi-IN
    flutterTts.setLanguage('tr-TR');
    print('language ========');
    print(flutterTts.getLanguages);
  }

  @override
  void dispose() {
    // TODO: implement dispose
    print('dispos...');
    Wakelock.toggle(enable: false);
    _player.stop();
    _player.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();

    print(await _tts.getLanguages());
    print('tts language ========');

    int _tick = 50;
    await _updateReciter();
    await flutterTts.setSharedInstance(true);

    Provider.of<Prevs>(context, listen: false).saveLatest(Clip(surahNumber: _surahNumber, start: _start, end: _end, reciterKey: _selectedReciterKey));

    _timer = Timer.periodic(Duration(milliseconds: _tick), (Timer t) async {
      if (!_player.playing) return;
      final position = _player.position;

      if (isolatedVers != null) {
        if (position.inMilliseconds > _positions[isolatedVers!]) {
          await _player.seek(Duration(milliseconds: _positions[isolatedVers! - 1]));
        }
        return;
      }

      if (position.inMilliseconds >= _positions[_currentVerse]) {
        // print('pos to stop => ${_positions[_currentVerse]}');
        setState(() {
          _player.pause();
        });
        print('diff => ${position.inMilliseconds - _positions[_currentVerse]}');
        await Future.delayed(Duration(milliseconds: 500));
        // _tts.speak(_trnaslation[_currentVerse - 1]);
        // await Future.delayed(Duration(milliseconds: 2000));
        await flutterTts.awaitSpeakCompletion(true);
        await flutterTts.speak(_trnaslation[_currentVerse - 1]);
        await Future.delayed(Duration(milliseconds: 500));
        // _tts.stop();

        setState(() {
          _currentVerse++;
        });
        _player.play();
      }

      if (position.inMilliseconds > _positions[_end]) {
        _player.seek(Duration(milliseconds: _positions[_start - 1]));
        setState(() {
          _currentVerse = _start;
          _player.pause();
          _isLoading = true;
        });
        await Future.delayed(const Duration(seconds: 2));
        setState(() {
          _isLoading = false;
          _player.play();
        });
      }
    });

    // final file = await rootBundle.loadString('assets/translations/en_ahmedali.xml');
    // final file = await rootBundle.loadString('assets/translations/tr.bulac.xml');
    final file = await rootBundle.loadString('assets/translations/tr.bulac.xml');
    final document = XmlDocument.parse(file);
    final _suraXml = document.getElement('quran')!.findElements('sura').toList()[_surahNumber - 1];
    setState(() {
      _trnaslation = _suraXml.findElements('aya').map((a) => a.getAttribute('text')!).toList();
    });
    print(_trnaslation);
  }

  Future<void> _updateReciter() async {
    //saud_ash-shuraym 10
    //abu_bakr_shatri 4
    //https://download.quranicaudio.com/qdc/saud_ash-shuraym/murattal/067.mp3
    // String s = _surahNumber.toString().padLeft(3, '0');
    String s = _selectedReciterKey == 'saud_ash-shuraym' ? _surahNumber.toString().padLeft(3, '0') : _surahNumber.toString();
    // _selectedReciter = _reciters.keys.toList()[0];
    // _player = AudioPlayer(mode: PlayerMode.MEDIA_PLAYER);
    // _player.setAudioSource(source)
    // await _player.setUrl('https://download.quranicaudio.com/qdc/$_selectedReciterKey/murattal/$s.mp3');
    // final _audio = AudioSource.uri(uri);
    final audiodSourse = AudioSource.uri(
      Uri.parse('https://download.quranicaudio.com/qdc/$_selectedReciterKey/murattal/$s.mp3'),
      tag: MediaItem(
        // Specify a unique ID for each media item:
        id: '1',
        // Metadata to display in the notification:
        album: "test Album",
        title: "test title",
        // artUri: Uri.parse('https://example.com/albumart.jpg'),
      ),
    );
    await _player.setAudioSource(audiodSourse);

    // _duration = await _player.getDuration();

    // _duration = await _player.setUrl(
    //     'https://download.quranicaudio.com/qdc/saud_ash-shuraym/murattal/$s.mp3');
    // _duration = await _player.load();

    await Timing(surahId: _surahNumber, reciter: _selectedReciterKey).fetchTiming().then((value) {
      setState(() {
        print('timimng => $value');
        _positions = value;
        _isLoading = false;
        _player.seek(Duration(milliseconds: _positions[_start - 1]));
      });
    });
    _save();
    await _player.seek(Duration(milliseconds: _positions[_currentVerse - 1]));

    setState(() {
      _isLoading = false;
      _player.play();
    });
  }

  void onTxtTap(int verse) async {
    if (_selectionMode != null) {
      if (_selectionMode == SelectionMode.start) {
        if (verse > _tempEnd) _tempEnd = verse;
        setState(() {
          _selectionMode = null;

          _start = verse;
          _end = _tempEnd;
          if (_start > _currentVerse) _currentVerse = _start;
        });

        // if (_start > _currentVerse)
        await _player.seek(Duration(milliseconds: _positions[_currentVerse - 1]));
      }

      if (_selectionMode == SelectionMode.end) {
        if (verse < _tempStart) _tempStart = verse;
        setState(() {
          _selectionMode = null;

          _end = verse;
          _start = _tempStart;
          if (_end < _currentVerse) _currentVerse = _start;
        });
        // if (_end < _currentVerse)
        await _player.seek(Duration(milliseconds: _positions[_currentVerse - 1]));
      }

      _save();
      _player.play();
      return;
    }

    if (isolatedVers != null) {
      setState(() {
        isolatedVers = null;
      });
      return;
    }

    if (verse == _currentVerse) {
      print('** ACTIVATER ISOLAITION MODE for vers $verse');
      setState(() {
        isolatedVers = verse;
      });
      return;
    }

    setState(() {
      _currentVerse = verse;
    });
    await _player.seek(Duration(milliseconds: _positions[_currentVerse - 1]));
  }

  @override
  Widget build(BuildContext context) {
    //timer for updating the position

    return Scaffold(
      appBar: AppBar(
        title: const Text('Player'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          DropdownButton<String>(
              value: _selectedReciterKey,
              items: _reciters.keys
                  .map((key) => DropdownMenuItem<String>(
                        value: key,
                        child: Text(_reciters[key]!),
                        onTap: () {
                          setState(() {
                            _selectedReciterKey = key;
                            _updateReciter();
                          });
                        },
                      ))
                  .toList(),
              onChanged: (val) {}),
          if (_trnaslation.length > 0)
            Container(
              width: double.infinity,
              height: 100,
              margin: EdgeInsets.all(40),
              color: Color.fromARGB(255, 190, 215, 255),
              child: Center(
                child: Text(
                  _trnaslation[_currentVerse - 1],
                ),
              ),
            ),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                controller: _controller,
                child: GestureDetector(
                  // onVerticalDragEnd: (details) {
                  //   print('vel = ${details.primaryVelocity}');
                  //   if ((details.primaryVelocity ?? 0) > 0) {
                  //     // _prevBlock();
                  //   }
                  //   if ((details.primaryVelocity ?? 0) < 0) {
                  //     _nextBlock();
                  //   }
                  // },
                  child: QuranText(
                    surahNumber: _surahNumber,
                    start: _start,
                    end: _end,
                    current: _currentVerse,
                    tap: onTxtTap,
                    isSelecting: _selectionMode != null,
                    isolatedVers: isolatedVers,
                  ),
                ),
              ),
            ),
          ),
          if (_selectionMode == null)
            Padding(
              padding: EdgeInsets.all(10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: _prevBlock,
                    icon: Icon(Icons.move_up_rounded),
                    label: Text('تراجع'),
                  ),
                  SizedBox(width: 20),
                  ElevatedButton.icon(
                    onPressed: _nextBlock,
                    icon: Icon(Icons.move_down_rounded),
                    label: Text('تقدم'),
                  ),
                ],
              ),
            ),
          Container(
            height: 150,
            width: double.infinity,
            color: Colors.grey,
            child: _selectionMode != null
                ? _showSelectPanel()
                : _isLoading
                    ? Center(child: CircularProgressIndicator())
                    : Row(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          ClipButton(
                            onIncrement: incrementStart,
                            onDecrement: decrementStart,
                            onSelect: _selectStart,
                            aya: _start,
                          ),
                          IconButton(
                            onPressed: () => setState(() {
                              _player.playing ? _player.pause() : _player.play();
                            }),
                            padding: EdgeInsets.zero,
                            icon: Icon(
                              _player.playing ? Icons.pause : Icons.play_arrow,
                              size: 48,
                            ),
                          ),
                          ClipButton(
                            onIncrement: incrementEnd,
                            onDecrement: decrementEnd,
                            onSelect: _selectEnd,
                            aya: _end,
                          ),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  // void _nextBlock() async {
  //   int lastVerse = _positions.length - 1;
  //   if (_end >= lastVerse) return;

  //   int length = _end - _start + 1;
  //   if (_end + length > lastVerse) length = lastVerse - _end;
  //   print('length = $length');
  //   print('start = $_start');
  //   print('end = $_end');

  //   setState(() {
  //     _start = _end + 1;
  //     _end = _end + length;
  //     _currentVerse = _start;
  //   });
  //   await _player.seek(Duration(milliseconds: _positions[_currentVerse - 1]));

  //   _save();
  // }

  void _prevBlock() {
    int firstVerse = 1;
    if (_start <= firstVerse) return;

    setState(() {
      _start--;
      _end--;
      if (_currentVerse > _end) {
        _currentVerse = _start;
        _player.seek(Duration(milliseconds: _positions[_currentVerse - 1]));
      }
    });

    _save();
  }

  void _nextBlock() {
    int lastVerse = _positions.length - 1;
    if (_end >= lastVerse) return;

    // int length = _end - _start + 1;
    // if (_end + length > lastVerse) length = lastVerse - _end;
    // print('length = $length');
    // print('start = $_start');
    // print('end = $_end');

    setState(() {
      _start++;
      _end++;
      // if (_currentVerse < _start) _currentVerse = _start;
      if (_currentVerse < _start) {
        _currentVerse = _start;
        _player.seek(Duration(milliseconds: _positions[_currentVerse - 1]));
      }
    });

    _save();
  }

  // void _prevBlock() async {
  //   // int length = _end - _start + 1;
  //   int firstVerse = 1;
  //   if (_start <= firstVerse) return;

  //   int length = _end - _start + 1;
  //   if (_start - length < firstVerse) length = _start - firstVerse;

  //   print('length = $length');
  //   print('start = $_start');
  //   print('end = $_end');

  //   setState(() {
  //     _start = _start - length;
  //     _end = _start - 1;
  //     _currentVerse = _start;
  //   });
  //   await _player.seek(Duration(milliseconds: _positions[_currentVerse - 1]));

  //   _save();
  // }

  Widget _showSelectPanel() {
    return Column(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Text('select a verse.'),
        ElevatedButton(
            child: Text('Cancel'),
            onPressed: () {
              setState(() {
                _selectionMode = null;
                _start = _tempStart;
                _end = _tempEnd;
              });
              // _player.play();
            }),
      ],
    );
  }

  void _save() {
    Provider.of<Prevs>(context, listen: false).saveLatest(Clip(
      surahNumber: _surahNumber,
      start: _start,
      end: _end,
      reciterKey: _selectedReciterKey,
    ));
  }

  void incrementStart() async {
    if (_start >= _positions.length - 1) return;

    setState(() {
      _start++;
      if (_start > _end) _end++;
    });

    if (_start <= _currentVerse) return;
    _currentVerse = _start;
    await _player.seek(Duration(milliseconds: _positions[_currentVerse - 1]));

    _save();
  }

  void decrementStart() async {
    if (_start <= 1) return;
    setState(() {
      _start = _start - 1;
    });

    _save();
  }

  void incrementEnd() async {
    if (_end >= _positions.length - 1) return;
    setState(() {
      _end = _end + 1;
    });

    _save();
  }

  void decrementEnd() async {
    if (_end <= 1) return;
    setState(() {
      _end--;
      if (_end <= _start) _start = _end;
      if (_end < _currentVerse) {
        _currentVerse = _start;
        _player.seek(Duration(milliseconds: _positions[_start - 1]));
      }
    });
    _save();
  }

  void _selectStart() async {
    _player.pause();
    setState(() {
      _selectionMode = SelectionMode.start;

      _tempStart = _start;
      _tempEnd = _end;
      _start = 1;
      _end = _positions.length - 1;
    });
    print(_selectionMode);

    // await _player.seek(Duration(milliseconds: _positions[_currentVerse - 1]));

    // _save();
  }

  void _selectEnd() {
    _player.pause();
    setState(() {
      _selectionMode = SelectionMode.end;

      _tempStart = _start;
      _tempEnd = _end;
      _start = 1;
      _end = _positions.length - 1;
    });
    print(_selectionMode);
  }
}
