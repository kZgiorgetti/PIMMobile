import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Override with --dart-define=PIM_API_URL=http://host:5000
const apiBaseUrl = String.fromEnvironment(
  'PIM_API_URL',
  defaultValue: 'http://localhost:5000',
);
final apiUrlProvider = Provider<String>((_) => apiBaseUrl);
