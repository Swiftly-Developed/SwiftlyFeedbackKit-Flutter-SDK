import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Golden tests render with real fonts so the images can be reviewed: Roboto
/// and Material Icons from the Flutter SDK's cache, and Noto Sans Arabic
/// (OFL, see fonts/NotoSansArabic-LICENSE.txt) from this directory.
///
/// Pixels still differ slightly between machines, so a comparison passes
/// within [_tolerance] of the pixels.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await _loadFonts();
  final current = goldenFileComparator;
  if (current is LocalFileComparator) {
    goldenFileComparator = _TolerantComparator(
        current.basedir.resolve('showcase_golden_test.dart'),);
  }
  await testMain();
}

const double _tolerance = 0.005;

Future<void> _loadFonts() async {
  final flutterRoot = Platform.environment['FLUTTER_ROOT'];
  if (flutterRoot == null) return;
  final material = '$flutterRoot/bin/cache/artifacts/material_fonts';
  await _family('Roboto', [
    for (final weight in ['Light', 'Regular', 'Medium', 'Bold'])
      '$material/Roboto-$weight.ttf',
  ]);
  // Stand-ins for the Apple system fonts a CupertinoApp asks for.
  for (final family in ['CupertinoSystemText', 'CupertinoSystemDisplay']) {
    await _family(family, [
      '$material/Roboto-Regular.ttf',
      '$material/Roboto-Medium.ttf',
      '$material/Roboto-Bold.ttf',
    ]);
  }
  await _family('MaterialIcons', ['$material/MaterialIcons-Regular.otf']);
  final here = File.fromUri(Platform.script).parent.path;
  final fonts = Directory('$here/fonts').existsSync()
      ? '$here/fonts'
      : '${Directory.current.path}/test/goldens/fonts';
  await _family('Noto Sans Arabic', [
    '$fonts/NotoSansArabic-Regular.ttf',
    '$fonts/NotoSansArabic-Bold.ttf',
  ]);
}

Future<void> _family(String family, List<String> paths) async {
  final loader = FontLoader(family);
  var any = false;
  for (final path in paths) {
    final file = File(path);
    if (!file.existsSync()) continue;
    any = true;
    loader.addFont(file.readAsBytes().then((b) => ByteData.sublistView(b)));
  }
  if (any) await loader.load();
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
