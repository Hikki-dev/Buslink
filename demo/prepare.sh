#!/usr/bin/env bash
# Makes the two git-ignored files the app needs to build, filled with FAKE values, so the
# app can be built and run against the local Firebase emulators without a Firebase project.
# It never overwrites a file that already exists, so your real settings are safe.
set -euo pipefail
cd "$(dirname "$0")/.."

if [ ! -f lib/firebase_options.dart ]; then
  sed -e "s/__API_KEY_[A-Z]*__/demo-api-key/g" \
      -e "s/__APP_ID_[A-Z]*__/1:000000000000:web:demo/g" \
      -e "s/__MESSAGING_SENDER_ID__/000000000000/g" \
      -e "s/__PROJECT_ID__/demo-buslink/g" \
      -e "s/__AUTH_DOMAIN__/demo-buslink.firebaseapp.com/g" \
      -e "s/__STORAGE_BUCKET__/demo-buslink.appspot.com/g" \
      -e "s/__MEASUREMENT_ID__/G-DEMO/g" \
      -e "s/__[A-Z_]*__/demo/g" \
      lib/firebase_options_template.dart > lib/firebase_options.dart
  echo "made lib/firebase_options.dart (fake values)"
else
  echo "lib/firebase_options.dart already exists, left alone"
fi

if [ ! -f .env ]; then
  printf 'STRIPE_PUBLISHABLE_KEY=\nOPENWEATHER_API_KEY=\nFIREBASE_PROJECT_ID=demo-buslink\n' > .env
  echo "made .env (no keys: payments and weather are switched off)"
else
  echo ".env already exists, left alone"
fi
