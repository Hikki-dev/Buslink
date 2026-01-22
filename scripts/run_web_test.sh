#!/bin/bash

# Kill any existing chromedriver instances
pkill chromedriver

# Start ChromeDriver in background
echo "🚀 Starting ChromeDriver..."
if [ -f "./node_modules/.bin/chromedriver" ]; then
    echo "Using local chromedriver..."
    ./node_modules/.bin/chromedriver --port=4444 &
elif command -v chromedriver &> /dev/null; then
    echo "Using system chromedriver..."
    chromedriver --port=4444 &
else
    echo "⚠️ 'chromedriver' not found. Trying 'npx chromedriver'..."
    npx chromedriver --port=4444 &
fi

PID=$!

# Wait for ChromeDriver to be ready (Loop up to 30s)
echo "⏳ Waiting for ChromeDriver to start on port 4444..."
counter=0
while ! nc -z localhost 4444; do   
  sleep 1
  counter=$((counter+1))
  if [ $counter -ge 30 ]; then
      echo "❌ ChromeDriver failed to start after 30 seconds."
      kill $PID
      exit 1
  fi
done
echo "✅ ChromeDriver is ready!"

# Run the test
echo "🧪 Running Web Integration Test..."
flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/app_test.dart \
  -d chrome

# Cleanup
echo "🧹 Cleaning up..."
kill $PID
