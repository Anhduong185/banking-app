#!/bin/bash

echo "🚀 Building iOS app for internal distribution..."

# Clean build
echo "🧹 Cleaning previous builds..."
flutter clean
flutter pub get

# Build iOS app
echo "📱 Building iOS app..."
flutter build ios --release --no-codesign

# Check if build was successful
if [ $? -eq 0 ]; then
    echo "✅ Build successful!"
    echo "📁 App location: build/ios/iphoneos/Runner.app"
    echo ""
    echo "📋 Next steps:"
    echo "1. Open Xcode"
    echo "2. Open ios/Runner.xcworkspace"
    echo "3. Select your team in Signing & Capabilities"
    echo "4. Archive and distribute via:"
    echo "   - TestFlight (recommended)"
    echo "   - Ad Hoc (for specific devices)"
    echo "   - Enterprise (for company internal)"
else
    echo "❌ Build failed!"
    exit 1
fi 