#!/bin/bash

# 🚀 BusLink Automated Test Suite (Total Isolation Mode - V13)

echo "🧹 Cleanup: Killing existing chromedriver, chrome, and flutter/dart processes..."

# Mac-specific aggressive cleanup
pkill -9 chromedriver 2>/dev/null
pkill -9 -f "Google Chrome" 2>/dev/null
pkill -9 -f "flutter_tools" 2>/dev/null
pkill -9 -f "dart" 2>/dev/null

# Extra cleanup for Mac to avoid "Multiple applications open" error
ps aux | grep -i "Google Chrome" | grep -v grep | awk '{print $2}' | xargs kill -9 2>/dev/null
ps aux | grep -i "chromedriver" | grep -v grep | awk '{print $2}' | xargs kill -9 2>/dev/null

sleep 2

# 🌐 Flags for Absolute Isolation
# We use a broad set of flags to suppress any possible user-facing UI
FLAGS=(
  "--disable-notifications"
  "--disable-geolocation"
  "--use-fake-ui-for-media-stream"
  "--use-fake-device-for-media-stream"
  "--disable-popup-blocking"
  "--disable-infobars"
  "--no-first-run"
  "--disable-extensions"
  "--disable-default-apps"
  "--disable-background-networking"
  "--disable-sync"
  "--disable-translate"
  "--mute-audio"
  "--no-default-browser-check"
  "--window-size=1280,1024"
)

export CHROMEDRIVER_ARGS="${FLAGS[*]}"

# 🌐 Start Chromedriver
echo "🌐 Starting Chromedriver on port 4444..."
chromedriver --port=4444 &
CHROMEDRIVER_PID=$!
sleep 3

# 🧪 Run Integration Test
echo "🧪 Running Stabilized Full System Test with IS_TESTING isolation..."

# Construct flags for flutter drive
DRIVE_FLAGS=()
for flag in "${FLAGS[@]}"; do
  DRIVE_FLAGS+=("--web-browser-flag=$flag")
done

flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/full_system_test.dart \
  -d chrome \
  --browser-name=chrome \
  --no-headless \
  --dart-define=IS_TESTING=true \
  "${DRIVE_FLAGS[@]}"

TEST_EXIT_CODE=$?

# 🛑 Final Cleanup
echo "🛑 Cleaning up..."
kill -9 $CHROMEDRIVER_PID 2>/dev/null
pkill -9 -f "Google Chrome" 2>/dev/null

if [ $TEST_EXIT_CODE -eq 0 ]; then
  echo "✅ SUCCESS: All tests passed!"
else
  echo "❌ FAILURE: Test exited with code $TEST_EXIT_CODE"
fi

exit $TEST_EXIT_CODE
