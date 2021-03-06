import 'dart:async';

import 'package:build_test/build_test.dart';
import 'package:admin_template_analyzer_plugin/src/checker.dart';
import 'package:test/test.dart';

/// Applies fixes from the plugin to [src], and compares the result to
/// [expectedFixedSource].
Future expectCorrection(String src, String expectedFixedSource) async {
  final checker = Checker();

  // We need a library name to use `findLibraryByName` from `build_test`.
  // It would must be in library `admin_template` so that the fake annotation
  // symbol matchs with the real one in `admin_template` package.
  final srcPrefix = 'library admin_template;';

  // Supply anything else we expect to need to resolve the source.
  final srcSuffix = '''
  class AgFormTemplate {
    final Type modelType;
    const AgFormTemplate({this.modelType})
  };
  ''';

  // The source that the [Checker] will run on.
  final totalSrc = '$srcPrefix$src$srcSuffix';

  // Resolve the source and run the [Checker].
  final element = await resolveSource(
      totalSrc, (resolver) => resolver.findLibraryByName('admin_template'));
  final checkResults = checker.check(element);

  // Apply the fixes to the source.
  //
  // Plugin must output edits sorted descending by offset, so we can apply them
  // one after the other without them clashing.
  var fixedSrc = totalSrc;
  final edits = checkResults.values
      .expand((correction) =>
          correction.change.edits.expand((edits) => edits.edits))
      .toList();
  for (var edit in edits) {
    fixedSrc = fixedSrc.replaceRange(
        edit.offset, edit.offset + edit.length, edit.replacement);
  }

  // Strip off the prefix and suffix that were added to the source so we can
  // compare what changed.
  expect(fixedSrc, startsWith(srcPrefix));
  fixedSrc = fixedSrc.substring(srcPrefix.length);
  expect(fixedSrc, endsWith(srcSuffix));
  fixedSrc = fixedSrc.substring(0, fixedSrc.length - srcSuffix.length);

  // Finally, check the result against the expectation.
  expect(fixedSrc, expectedFixedSource);
}

/// Check that the plugin will not modify [src].
Future expectNoCorrection(String src) async {
  final checker = Checker();
  final srcPrefix = '''
  library admin_template;
  class AgFormTemplate {
    final Type modelType;
    const AgFormTemplate({this.modelType})
  };
  ''';
  final totalSrc = '$srcPrefix$src';

  final element = await resolveSource(
      totalSrc, (resolver) => resolver.findLibraryByName('admin_template'));

  expect(
      checker.check(element).values.expand((correction) =>
          correction.change.edits.expand((edits) => edits.edits)),
      isEmpty);
}
