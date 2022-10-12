import 'dart:convert';

import 'package:http/http.dart' as http;

class Timing {
  final int surahId;
  final String reciter;

  Map<String, String> _reciters = {
    // 'saud_ash-shuraym': 'سعود الشريم',
    'hani_ar_rifai': '5',
    'abdul_baset': '2',
    'abdurrahmaan_as_sudais': '3',
    'abu_bakr_shatri': '4',
    'khalifah_taniji': '161',
    'khalil_al_husary': '6',
    'mishari_al_afasy': '7',
    'saud_ash-shuraym': '10',
    'siddiq_minshawi': '9',
  };

  // final int reciterId;
  Timing({
    required this.surahId,
    required this.reciter,
  });

  Future<List<int>> fetchTiming() async {
    String reciterId = _reciters[reciter] ?? '2';
    final url = 'https://api.qurancdn.com/api/qdc/audio/reciters/$reciterId/audio_files?chapter=$surahId&segments=true';
    final res = await http.get(Uri.parse(url));
    List data = jsonDecode(res.body)['audio_files'][0]['verse_timings'];
    // print(data.toString());
    List<int> timing = data.map((e) => e['timestamp_to'] as int).toList();

    print(timing);
    return [0, ...timing];
  }
}
