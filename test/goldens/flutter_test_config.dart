import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Golden tests render with the font files in [fonts/], not with whatever the
/// host or the Flutter SDK cache happens to have installed.
///
/// Roboto and Material Icons are the Flutter 3.47.7 SDK copies (Apache-2.0,
/// see the license files beside them). Noto Sans Arabic is OFL
/// (fonts/NotoSansArabic-LICENSE.txt). CI pins that same Flutter version, and
/// the phone surface is fixed in the golden test, so a missing font fails the
/// run instead of painting the Ahem fallback and diffing every image.
///
/// Pixels still differ slightly between machines, so a comparison passes
/// within [_tolerance] of the pixels.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await _loadFonts();
  final current = goldenFileComparator;
  if (current is LocalFileComparator) {
    goldenFileComparator = _TolerantComparator(
      current.basedir.resolve('showcase_golden_test.dart'),
    );
  }
  await testMain();
}

const double _tolerance = 0.005;

String _fontsDirectory() {
  final candidates = <String>[
    '${File.fromUri(Platform.script).parent.path}/fonts',
    '${Directory.current.path}/test/goldens/fonts',
  ];
  for (final path in candidates) {
    if (File('$path/Roboto-Regular.ttf').existsSync()) return path;
  }
  throw StateError(
    'Golden fonts are missing. Looked for Roboto-Regular.ttf in: '
    '${candidates.join(', ')}.',
  );
}

Future<void> _loadFonts() async {
  final fonts = _fontsDirectory();
  final roboto = <String>[
    '$fonts/Roboto-Light.ttf',
    '$fonts/Roboto-Regular.ttf',
    '$fonts/Roboto-Medium.ttf',
    '$fonts/Roboto-Bold.ttf',
  ];
  await _family('Roboto', roboto);
  // Stand-ins for the Apple system fonts a CupertinoApp asks for.
  for (final family in ['CupertinoSystemText', 'CupertinoSystemDisplay']) {
    await _family(family, [
      '$fonts/Roboto-Regular.ttf',
      '$fonts/Roboto-Medium.ttf',
      '$fonts/Roboto-Bold.ttf',
    ]);
  }
  await _family('MaterialIcons', ['$fonts/MaterialIcons-Regular.otf']);
  await _family('Noto Sans Arabic', [
    '$fonts/NotoSansArabic-Regular.ttf',
    '$fonts/NotoSansArabic-Bold.ttf',
  ]);
}

Future<void> _family(String family, List<String> paths) async {
  final loader = FontLoader(family);
  for (final path in paths) {
    final file = File(path);
    if (!file.existsSync()) {
      throw StateError('Golden font file is missing for $family: $path');
    }
    loader.addFont(
        file.readAsBytes().then((bytes) => ByteData.sublistView(bytes)));
  }
  await loader.load();
}

class _TolerantComparator extends LocalFileComparator {
  _TolerantComparator(super.testFile);

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final result = await GoldenFileComparator.compareLists(
      imageBytes,
      await getGoldenBytes(golden),
    );
    if (result.passed || result.diffPercent <= _tolerance) {
      result.dispose();
      return true;
    }
    final error = await generateFailureOutput(result, golden, basedir);
    result.dispose();
    throw FlutterError(error);
  }
}
