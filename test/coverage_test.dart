import 'package:test/test.dart';

import '../tool/src/coverage.dart';

const _lcov = '''
SF:lib/a.dart
DA:1,1
DA:2,0
DA:3,4
BRDA:3,0,0,1
BRDA:3,0,1,0
end_of_record
SF:lib/b.dart
DA:1,1
DA:2,1
end_of_record
''';

void main() {
  test('line coverage counts executed lines over instrumented lines', () {
    final s = parseLcov(_lcov);
    expect(s.linesFound, 5);
    expect(s.linesHit, 4);
    expect(s.linePercent, closeTo(80, 1e-9));
  });

  test('branch coverage counts taken branches', () {
    final s = parseLcov(_lcov);
    expect(s.branchesFound, 2);
    expect(s.branchesHit, 1);
    expect(s.branchPercent, closeTo(50, 1e-9));
  });

  test('no instrumented lines or branches count as fully covered', () {
    final s = parseLcov('');
    expect(s.linePercent, 100);
    expect(s.branchPercent, 100);
  });

  test('a branch that was never reached (-) is not taken', () {
    final s = parseLcov('SF:x\nBRDA:1,0,0,-\nBRDA:1,0,1,2\nend_of_record\n');
    expect(s.branchesFound, 2);
    expect(s.branchesHit, 1);
  });

  test('rules: line threshold and optional branch threshold', () {
    final s = parseLcov(_lcov);
    expect(const CoverageRule(minLine: 80).check(s), isEmpty);
    expect(const CoverageRule(minLine: 90).check(s), hasLength(1));
    expect(
      const CoverageRule(minLine: 0, minBranch: 100).check(s),
      hasLength(1),
    );
    expect(
      const CoverageRule(minLine: 90, minBranch: 100).check(s),
      hasLength(2),
    );
  });
}
