// Runs the pure Dart packages with coverage and enforces the gates:
// core and engine packages >= 90% line coverage; engine_safety additionally
// 100% branch coverage. Usage: dart run tool/check_coverage.dart
import 'dart:io';

import 'src/coverage.dart';

const _rules = <String, CoverageRule>{
  'core_common': CoverageRule(minLine: 90),
  'core_model': CoverageRule(minLine: 90),
  'core_ports': CoverageRule(minLine: 90),
  'testing': CoverageRule(minLine: 90),
  // Engines are added as they are built, e.g.:
  // 'engine_safety': CoverageRule(minLine: 90, minBranch: 100),
};

Future<void> main() async {
  var failed = false;
  for (final entry in _rules.entries) {
    final dir = 'packages/${entry.key}';
    if (!Directory(dir).existsSync()) continue;
    final run = await Process.run(
      'dart',
      ['run', 'coverage:test_with_coverage', '--branch-coverage'],
      workingDirectory: dir,
    );
    final lcov = File('$dir/coverage/lcov.info');
    if (run.exitCode != 0 || !lcov.existsSync()) {
      stderr
        ..writeln('${entry.key}: tests or coverage failed')
        ..writeln(run.stdout)
        ..writeln(run.stderr);
      failed = true;
      continue;
    }
    final summary = parseLcov(lcov.readAsStringSync());
    final problems = entry.value.check(summary);
    stdout.writeln(
      '${entry.key}: lines ${summary.linePercent.toStringAsFixed(1)}%'
      ' branches ${summary.branchPercent.toStringAsFixed(1)}%'
      '${problems.isEmpty ? '' : '  FAIL: ${problems.join('; ')}'}',
    );
    if (problems.isNotEmpty) failed = true;
  }
  exit(failed ? 1 : 0);
}
