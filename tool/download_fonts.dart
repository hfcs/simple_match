// Downloads NotoSansTC-Regular.ttf from Google Fonts and saves it to assets/fonts/.
// Usage: dart tool/download_fonts.dart
import 'dart:io';
import 'package:http/http.dart' as http;

Future<void> main() async {
  const url = 'https://github.com/googlefonts/noto-cjk/raw/main/Sans/TTF/TraditionalChineseHK/NotoSansTC-Regular.ttf';
  const outPath = 'assets/fonts/NotoSansTC-Regular.ttf';

  final outFile = File(outPath);
  if (await outFile.exists()) {
    print('Font already exists at $outPath. Skipping download.');
    return;
  }

  print('Downloading NotoSansTC-Regular.ttf...');
  final response = await http.get(Uri.parse(url));
  if (response.statusCode == 200) {
    await outFile.create(recursive: true);
    await outFile.writeAsBytes(response.bodyBytes);
    print('Font downloaded to $outPath');
  } else {
    print('Failed to download font. Status: ${response.statusCode}');
    exit(1);
  }
}
