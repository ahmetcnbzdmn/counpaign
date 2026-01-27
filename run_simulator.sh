#!/bin/bash

# Configuration
SIMULATOR_NAME="iPhone 15 Fresh"
BUNDLE_ID="com.ahmetcan.counpaign"
APP_PATH="build/ios/iphonesimulator/Runner.app"

echo "🚀 Starting Manual Build & Run Sequence..."

# 1. Build using Flutter (targeting simulator)
echo "📦 Building iOS app for simulator..."
export PATH=$PATH:/opt/homebrew/bin
export LANG=en_US.UTF-8
flutter build ios --simulator --debug

if [ $? -ne 0 ]; then
    echo "❌ Build failed!"
    exit 1
fi

echo "✅ Build successful!"

# 2. Boot simulator if needed
echo "📱 Checking simulator status..."
BOOTED=$(xcrun simctl list devices | grep "$SIMULATOR_NAME" | grep "Booted")
if [ -z "$BOOTED" ]; then
    echo "booting $SIMULATOR_NAME..."
    xcrun simctl boot "$SIMULATOR_NAME"
fi

# 3. Install App
echo "md Installing app..."
xcrun simctl install booted "$APP_PATH"

# 4. Launch App
echo "🚀 Launching app..."
xcrun simctl launch booted "$BUNDLE_ID"

echo "🎉 Done! App should be running on the simulator."
