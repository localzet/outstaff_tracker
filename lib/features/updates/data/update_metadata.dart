import '../../../core/utils/semantic_version.dart';

class ReleaseAsset {
  const ReleaseAsset({
    required this.name,
    required this.url,
    this.sha256,
    this.size,
  });

  factory ReleaseAsset.fromJson(Map<String, Object?> json) {
    final name = json['name'];
    final url = json['url'] ?? json['browser_download_url'];
    if (name is! String || name.isEmpty) {
      throw const FormatException('Release asset name is missing.');
    }
    if (url is! String || url.isEmpty) {
      throw const FormatException('Release asset URL is missing.');
    }

    return ReleaseAsset(
      name: name,
      url: url,
      sha256: json['sha256'] as String?,
      size: json['size'] is int ? json['size'] as int : null,
    );
  }

  final String name;
  final String url;
  final String? sha256;
  final int? size;
}

class UpdateMetadata {
  const UpdateMetadata({
    required this.tag,
    required this.version,
    required this.releaseNotesUrl,
    required this.windowsInstaller,
    required this.prerelease,
    this.pubspecVersion,
    this.publishedAt,
  });

  factory UpdateMetadata.fromJson(Map<String, Object?> json) {
    final tag = json['tag'];
    final version = json['version'];
    final releaseNotesUrl = json['releaseNotesUrl'];
    final assets = json['assets'];
    if (tag is! String || tag.isEmpty) {
      throw const FormatException('Update tag is missing.');
    }
    if (version is! String || version.isEmpty) {
      throw const FormatException('Update version is missing.');
    }
    if (releaseNotesUrl is! String || releaseNotesUrl.isEmpty) {
      throw const FormatException('Release notes URL is missing.');
    }
    if (assets is! Map) {
      throw const FormatException('Update assets are missing.');
    }

    final windowsInstallerJson = assets['windowsInstaller'];
    if (windowsInstallerJson is! Map) {
      throw const FormatException('Windows installer asset is missing.');
    }

    return UpdateMetadata(
      tag: tag,
      version: version,
      pubspecVersion: json['pubspecVersion'] as String?,
      publishedAt: DateTime.tryParse((json['publishedAt'] ?? '').toString()),
      releaseNotesUrl: releaseNotesUrl,
      prerelease: json['prerelease'] == true,
      windowsInstaller: ReleaseAsset.fromJson(
        Map<String, Object?>.from(windowsInstallerJson),
      ),
    );
  }

  factory UpdateMetadata.fromGitHubReleaseJson(Map<String, Object?> json) {
    final tag = json['tag_name'];
    final releaseNotesUrl = json['html_url'];
    final assetsJson = json['assets'];
    if (tag is! String || tag.isEmpty) {
      throw const FormatException('GitHub release tag is missing.');
    }
    if (releaseNotesUrl is! String || releaseNotesUrl.isEmpty) {
      throw const FormatException('GitHub release URL is missing.');
    }
    if (assetsJson is! List) {
      throw const FormatException('GitHub release assets are missing.');
    }

    final version = tag.replaceFirst(RegExp('^v'), '');
    final assets = assetsJson
        .whereType<Map>()
        .map((item) => ReleaseAsset.fromJson(Map<String, Object?>.from(item)))
        .toList();

    return UpdateMetadata(
      tag: tag,
      version: version,
      publishedAt: DateTime.tryParse((json['published_at'] ?? '').toString()),
      releaseNotesUrl: releaseNotesUrl,
      prerelease: json['prerelease'] == true,
      windowsInstaller: chooseWindowsInstallerAsset(assets),
    );
  }

  final String tag;
  final String version;
  final String? pubspecVersion;
  final DateTime? publishedAt;
  final String releaseNotesUrl;
  final ReleaseAsset windowsInstaller;
  final bool prerelease;

  SemanticVersion get semanticVersion => SemanticVersion.parse(version);
}

ReleaseAsset chooseWindowsInstallerAsset(List<ReleaseAsset> assets) {
  final candidates = assets.where((asset) {
    final name = asset.name.toLowerCase();
    return name.startsWith('outstaff_tracker-setup-') &&
        name.endsWith('.exe') &&
        !name.contains('portable');
  }).toList();

  if (candidates.isEmpty) {
    throw const FormatException('Windows installer asset was not found.');
  }

  candidates.sort((left, right) => left.name.compareTo(right.name));
  return candidates.last;
}

enum UpdateDecisionStatus {
  available,
  current,
  ignoredPrerelease,
}

class UpdateDecision {
  const UpdateDecision({
    required this.status,
    required this.currentVersion,
    required this.latestVersion,
  });

  final UpdateDecisionStatus status;
  final SemanticVersion currentVersion;
  final SemanticVersion latestVersion;

  bool get isAvailable => status == UpdateDecisionStatus.available;
}

UpdateDecision decideUpdate({
  required String currentVersion,
  required UpdateMetadata metadata,
  required bool includePrerelease,
}) {
  final current = SemanticVersion.parse(currentVersion);
  final latest = metadata.semanticVersion;
  if (metadata.prerelease && !includePrerelease) {
    return UpdateDecision(
      status: UpdateDecisionStatus.ignoredPrerelease,
      currentVersion: current,
      latestVersion: latest,
    );
  }

  return UpdateDecision(
    status: latest.compareTo(current) > 0
        ? UpdateDecisionStatus.available
        : UpdateDecisionStatus.current,
    currentVersion: current,
    latestVersion: latest,
  );
}
