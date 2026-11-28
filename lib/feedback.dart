enum FeedbackKind { issue, feature }

class FeedbackDraft {
  final FeedbackKind kind;
  final String title, details;
  final bool includeDiagnostics;
  const FeedbackDraft({
    this.kind = FeedbackKind.issue,
    this.title = '',
    this.details = '',
    this.includeDiagnostics = true,
  });
  factory FeedbackDraft.fromMap(Object? value) {
    if (value is! Map) return const FeedbackDraft();
    String text(String key, int limit) {
      final field = value[key];
      return field is String
          ? field.substring(0, field.length.clamp(0, limit))
          : '';
    }

    return FeedbackDraft(
      kind: value['kind'] == 'feature'
          ? FeedbackKind.feature
          : FeedbackKind.issue,
      title: text('title', 120),
      details: text('details', 4000),
      includeDiagnostics: value['includeDiagnostics'] != false,
    );
  }
  Map<String, Object> toMap() => {
    'kind': kind.name,
    'title': title,
    'details': details,
    'includeDiagnostics': includeDiagnostics,
  };
  String get kindLabel =>
      kind == FeedbackKind.issue ? 'Report an issue' : 'Suggest a feature';
  bool get ready => title.trim().isNotEmpty && details.trim().isNotEmpty;

  String report({required String build, required String platform}) => [
    'RenoImagineAI feedback',
    'Type: ${kind == FeedbackKind.issue ? 'Issue' : 'Feature request'}',
    'Title: ${title.trim()}',
    '',
    details.trim(),
    if (includeDiagnostics) ...['', 'App build: $build', 'Platform: $platform'],
  ].join('\n');
}

/// Public contact details only. Never default to the private source repository.
class FeedbackDestination {
  final Uri uri;
  final bool email;
  FeedbackDestination._(this.uri, this.email);
  static FeedbackDestination? parse({String email = '', String formUrl = ''}) {
    final address = email.trim();
    if (address.isNotEmpty) {
      if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
          .hasMatch(address)) {
        return null;
      }
      return FeedbackDestination._(Uri(scheme: 'mailto', path: address), true);
    }
    final form = Uri.tryParse(formUrl.trim());
    if (form == null ||
        form.scheme != 'https' ||
        form.host.isEmpty ||
        form.userInfo.isNotEmpty) {
      return null;
    }
    return FeedbackDestination._(form, false);
  }

  static FeedbackDestination? fromEnvironment() => parse(
    email: const String.fromEnvironment('RENOVISION_SUPPORT_EMAIL'),
    formUrl: const String.fromEnvironment('RENOVISION_FEEDBACK_URL'),
  );

  Uri forReport(FeedbackDraft draft, String report) => email
      ? uri.replace(
          query:
              'subject=${Uri.encodeComponent('RenoImagineAI ${draft.kind == FeedbackKind.issue ? 'issue' : 'feature'}: ${draft.title.trim()}')}&body=${Uri.encodeComponent(report)}',
        )
      : uri;
}
