/// LCOV parsing and threshold rules for the coverage gates.
library;

/// Totals read from an LCOV report.
class CoverageSummary {
  /// Creates a summary.
  const CoverageSummary({
    required this.linesFound,
    required this.linesHit,
    required this.branchesFound,
    required this.branchesHit,
  });

  /// Instrumented lines.
  final int linesFound;

  /// Lines executed at least once.
  final int linesHit;

  /// Instrumented branches.
  final int branchesFound;

  /// Branches taken at least once.
  final int branchesHit;

  /// Line coverage in percent (100 when nothing is instrumented).
  double get linePercent => linesFound == 0 ? 100 : linesHit * 100 / linesFound;

  /// Branch coverage in percent (100 when nothing is instrumented).
  double get branchPercent =>
      branchesFound == 0 ? 100 : branchesHit * 100 / branchesFound;
}

/// Parses the text of an `lcov.info` file.
CoverageSummary parseLcov(String lcov) {
  var linesFound = 0;
  var linesHit = 0;
  var branchesFound = 0;
  var branchesHit = 0;
  for (final line in lcov.split('\n')) {
    if (line.startsWith('DA:')) {
      linesFound++;
      final hits = int.tryParse(line.split(',').last.trim()) ?? 0;
      if (hits > 0) linesHit++;
    } else if (line.startsWith('BRDA:')) {
      branchesFound++;
      final taken = line.split(',').last.trim();
      if (taken != '-' && (int.tryParse(taken) ?? 0) > 0) branchesHit++;
    }
  }
  return CoverageSummary(
    linesFound: linesFound,
    linesHit: linesHit,
    branchesFound: branchesFound,
    branchesHit: branchesHit,
  );
}

/// Minimum coverage a package must reach.
class CoverageRule {
  /// Creates a rule. [minBranch] is only checked when given.
  const CoverageRule({required this.minLine, this.minBranch});

  /// Minimum line coverage in percent.
  final double minLine;

  /// Minimum branch coverage in percent, or null to not check it.
  final double? minBranch;

  /// Human-readable failures; empty when the rule is met.
  List<String> check(CoverageSummary s) => [
    if (s.linePercent < minLine)
      'line coverage ${s.linePercent.toStringAsFixed(1)}% < $minLine%',
    if (minBranch != null && s.branchPercent < minBranch!)
      'branch coverage ${s.branchPercent.toStringAsFixed(1)}% < $minBranch%',
  ];
}
