// Increments the build number in pubspec.yaml (the integer after '+').
// Usage: dart tool/bump_build.dart
import 'dart:io';

void main() {
  final file = File('pubspec.yaml');
  final lines = file.readAsLinesSync();
  final updated = lines.map((line) {
    if (!line.startsWith('version:')) return line;
    final match = RegExp(r'^(version:\s*)(\d+\.\d+\.\d+)\+(\d+)$').firstMatch(line);
    if (match == null) return line;
    final semver = match.group(2)!;
    final build = int.parse(match.group(3)!) + 1;
    print('Version: $semver+$build');
    return '${match.group(1)}$semver+$build';
  }).toList();
  file.writeAsStringSync(updated.join('\n') + '\n');
}
