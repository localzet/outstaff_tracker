String normalizeKimaiBaseUrl(
  String input, {
  bool allowInsecureHttp = false,
}) {
  var raw = input.trim();
  if (raw.isEmpty) {
    return '';
  }

  if (!raw.contains(RegExp(r'^[a-zA-Z][a-zA-Z0-9+\-.]*://'))) {
    raw = 'https://$raw';
  }

  var uri = Uri.parse(raw);
  var scheme = uri.scheme.toLowerCase();
  if (scheme == 'http' && !allowInsecureHttp) {
    scheme = 'https';
  }

  final normalizedPath = _normalizePath(uri.path);
  uri = uri.replace(
    scheme: scheme,
    path: normalizedPath,
    queryParameters: uri.queryParameters.isEmpty ? null : uri.queryParameters,
    fragment: null,
  );

  return uri.toString();
}

String? validateKimaiHostUrl(
  String input, {
  bool allowInsecureHttp = false,
}) {
  final normalized = normalizeKimaiBaseUrl(
    input,
    allowInsecureHttp: allowInsecureHttp,
  );
  final uri = Uri.tryParse(normalized);
  if (normalized.isEmpty ||
      uri == null ||
      !uri.hasScheme ||
      uri.host.isEmpty ||
      (uri.scheme != 'http' && uri.scheme != 'https')) {
    return 'Введите корректный адрес Kimai.';
  }

  if (uri.scheme == 'http' && !allowInsecureHttp) {
    return 'HTTP без шифрования отключён.';
  }

  return null;
}

String _normalizePath(String path) {
  final segments = path
      .split('/')
      .where((segment) => segment.trim().isNotEmpty)
      .map((segment) => segment.trim())
      .toList();

  while (segments.isNotEmpty && segments.last.toLowerCase() == 'api') {
    segments.removeLast();
  }

  segments.add('api');
  return '/${segments.join('/')}';
}
