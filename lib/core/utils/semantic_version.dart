class SemanticVersion implements Comparable<SemanticVersion> {
  const SemanticVersion({
    required this.major,
    required this.minor,
    required this.patch,
    this.preRelease = const [],
  });

  factory SemanticVersion.parse(String input) {
    final normalized = input.trim().replaceFirst(RegExp('^v'), '');
    final withoutBuild = normalized.split('+').first;
    final dashIndex = withoutBuild.indexOf('-');
    final parts = dashIndex < 0
        ? [withoutBuild]
        : [
            withoutBuild.substring(0, dashIndex),
            withoutBuild.substring(dashIndex + 1),
          ];
    final core = parts.first.split('.');
    if (core.length < 3) {
      throw FormatException('Version must use major.minor.patch: $input');
    }

    return SemanticVersion(
      major: int.parse(core[0]),
      minor: int.parse(core[1]),
      patch: int.parse(core[2]),
      preRelease: parts.length > 1 ? parts[1].split('.') : const [],
    );
  }

  final int major;
  final int minor;
  final int patch;
  final List<String> preRelease;

  bool get isPreRelease => preRelease.isNotEmpty;

  @override
  int compareTo(SemanticVersion other) {
    final core = major.compareTo(other.major);
    if (core != 0) return core;
    final minorResult = minor.compareTo(other.minor);
    if (minorResult != 0) return minorResult;
    final patchResult = patch.compareTo(other.patch);
    if (patchResult != 0) return patchResult;

    if (preRelease.isEmpty && other.preRelease.isEmpty) return 0;
    if (preRelease.isEmpty) return 1;
    if (other.preRelease.isEmpty) return -1;

    final length = preRelease.length > other.preRelease.length
        ? preRelease.length
        : other.preRelease.length;
    for (var index = 0; index < length; index++) {
      if (index >= preRelease.length) return -1;
      if (index >= other.preRelease.length) return 1;

      final left = preRelease[index];
      final right = other.preRelease[index];
      final leftNumber = int.tryParse(left);
      final rightNumber = int.tryParse(right);
      if (leftNumber != null && rightNumber != null) {
        final result = leftNumber.compareTo(rightNumber);
        if (result != 0) return result;
      } else if (leftNumber != null) {
        return -1;
      } else if (rightNumber != null) {
        return 1;
      } else {
        final result = left.compareTo(right);
        if (result != 0) return result;
      }
    }

    return 0;
  }

  @override
  String toString() {
    final suffix = preRelease.isEmpty ? '' : '-${preRelease.join('.')}';
    return '$major.$minor.$patch$suffix';
  }
}
