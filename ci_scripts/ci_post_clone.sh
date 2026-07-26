#!/bin/sh
# Prepares a Flutter workspace in Xcode Cloud after the repository is cloned.
# Keep Flutter pinned so Cloud builds use the same framework version as this app.
set -eu

FLUTTER_VERSION="3.32.8"
FLUTTER_HOME="$HOME/flutter"
WORKSPACE="${CI_PRIMARY_REPOSITORY_PATH:-$PWD}"

git clone --depth 1 --branch "$FLUTTER_VERSION" \
  https://github.com/flutter/flutter.git "$FLUTTER_HOME"
export PATH="$FLUTTER_HOME/bin:$PATH"

cd "$WORKSPACE"
flutter config --no-analytics
flutter precache --ios
flutter pub get

# App Store Connect requires every uploaded archive to have a new build number.
# CI_BUILD_NUMBER is assigned by Xcode Cloud for each workflow run.
if [ -n "${CI_BUILD_NUMBER:-}" ]; then
  sed -i '' "s/^FLUTTER_BUILD_NUMBER=.*/FLUTTER_BUILD_NUMBER=${CI_BUILD_NUMBER}/" \
    ios/Flutter/Generated.xcconfig
  sed -i '' "s/^export FLUTTER_BUILD_NUMBER=.*/export FLUTTER_BUILD_NUMBER=${CI_BUILD_NUMBER}/" \
    ios/Flutter/flutter_export_environment.sh
fi

cd ios
pod install
