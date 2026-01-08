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
flutter build web --release

echo "------------------------------------------"
echo "  Build Complete!                         "
echo "------------------------------------------"
