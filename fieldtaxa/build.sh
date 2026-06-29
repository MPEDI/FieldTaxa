#!/usr/bin/env bash
set -euo pipefail

echo "==> Bumping build number…"
dart tool/bump_build.dart

echo "==> flutter clean…"
flutter clean

echo "==> flutter pub get…"
flutter pub get

echo "==> flutter gen-l10n…"
flutter gen-l10n

echo "==> flutter build ipa --release…"
flutter build ipa --release

echo ""
echo "✓ Build complete."
