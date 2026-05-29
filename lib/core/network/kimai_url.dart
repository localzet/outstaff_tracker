String normalizeKimaiBaseUrl(String input) {
  final trimmed = input.trim();
  if (trimmed.isEmpty) {
    return '';
  }

  final uri = Uri.parse(trimmed);
  final normalizedPath = _normalizePath(uri.path);

  return uri.replace(path: normalizedPath).removeFragment().toString();
}

String? validateKimaiHostUrl(String input) {
  final raw = input.trim();
  final uri = Uri.tryParse(raw);
  if (raw.isEmpty ||
      uri == null ||
      !uri.hasScheme ||
      uri.host.isEmpty ||
      (uri.scheme != 'http' && uri.scheme != 'https')) {
    return 'Enter a valid Kimai URL.';
  }

  return null;
}

String _normalizePath(String path) {
  final cleaned = path.trim().replaceAll(RegExp(r'/+$'), '');
  if (cleaned.isEmpty || cleaned == '/') {
    return '/api';
  }

  final withoutDuplicateApi = cleaned.replaceFirst(RegExp(r'(/api)+$'), '/api');
  if (withoutDuplicateApi.endsWith('/api')) {
    return withoutDuplicateApi;
  }

  return '$withoutDuplicateApi/api';
}
