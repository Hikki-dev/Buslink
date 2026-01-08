#!/bin/bash

echo "------------------------------------------"
echo "   Installing Flutter for Vercel Build     "
echo "------------------------------------------"

# 1. Install Flutter
if [ -d "flutter" ]; then
    echo "Flutter already installed."
else
    echo "Cloning Flutter repository..."
    git clone https://github.com/flutter/flutter.git -b stable --depth 1
fi

# 2. Add Flutter to Path
export PATH="$PATH:`pwd`/flutter/bin"

# 3. Check Installation
echo "Flutter version:"
flutter --version

# 4. Enable Web
flutter config --enable-web

# 5. Build Project
echo "Building Flutter Web App..."

# Generate firebase_options.dart from template with Secrets
echo "Generating firebase_options.dart..."
# Use sed to replace placeholders with environment variable values
sed -e "s/__API_KEY_WEB__/$FIREBASE_API_KEY_WEB/g" \
    -e "s/__APP_ID_WEB__/$FIREBASE_APP_ID_WEB/g" \
    -e "s/__MESSAGING_SENDER_ID__/$FIREBASE_MESSAGING_SENDER_ID/g" \
    -e "s/__PROJECT_ID__/$FIREBASE_PROJECT_ID/g" \
    -e "s/__AUTH_DOMAIN__/$FIREBASE_AUTH_DOMAIN/g" \
    -e "s/__STORAGE_BUCKET__/$FIREBASE_STORAGE_BUCKET/g" \
    -e "s/__MEASUREMENT_ID__/$FIREBASE_MEASUREMENT_ID/g" \
    lib/firebase_options_template.dart > lib/firebase_options.dart

flutter build web --release

echo "------------------------------------------"
echo "  Build Complete!                         "
echo "------------------------------------------"
