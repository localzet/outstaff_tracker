import 'dart:convert';

List<String> parseTags(Object? value) {
  final seen = <String>{};
  final result = <String>[];

  void add(String? tag) {
    final normalized = tag?.trim();
    if (normalized == null || normalized.isEmpty) {
      return;
    }
    final key = normalized.toLowerCase();
    if (seen.add(key)) {
      result.add(normalized);
    }
  }

  void read(Object? source) {
    if (source == null) {
      return;
    }
    if (source is String) {
      final trimmed = source.trim();
      if (trimmed.isEmpty) {
        return;
      }
      if (trimmed.startsWith('[')) {
        try {
          read(jsonDecode(trimmed));
          return;
        } on FormatException {
          // Keep parsing as a plain delimited string.
        }
      }
      for (final tag in trimmed.split(RegExp(r'[,;]'))) {
        add(tag);
      }
      return;
    }
    if (source is Iterable) {
      for (final item in source) {
        if (item is Map) {
          add(_firstString(item, const ['name', 'tag', 'value', 'label']));
        } else {
          read(item);
        }
      }
      return;
    }
    if (source is Map) {
      for (final key in const ['tags', 'tagNames', 'tag']) {
        if (source.containsKey(key)) {
          read(source[key]);
        }
      }
      add(_firstString(source, const ['name', 'value', 'label']));
    }
  }

  read(value);

  return result;
}

String? formatTags(Iterable<String> tags) {
  final normalized = parseTags(tags.toList(growable: false));

  return normalized.isEmpty ? null : normalized.join(', ');
}

String formatTagsForDisplay(Object? value) {
  return parseTags(value).join(', ');
}

bool tagsContain(Object? value, String query) {
  final normalizedQuery = query.trim().toLowerCase();
  if (normalizedQuery.isEmpty) {
    return true;
  }

  return parseTags(value).any(
    (tag) => tag.toLowerCase().contains(normalizedQuery),
  );
}

String? _firstString(Map<Object?, Object?> source, List<String> keys) {
  for (final key in keys) {
    final value = source[key];
    if (value is String && value.trim().isNotEmpty) {
      return value;
    }
  }

  return null;
}
