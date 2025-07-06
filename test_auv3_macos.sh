#!/bin/bash

# Script to build and test the RositaAUv3 extension on macOS

echo "Building RositaAUv3 for macOS..."

# Clean build folder
rm -rf build/

# Build the AUv3 extension for macOS
xcodebuild -project Rosita.xcodeproj \
           -scheme RositaAUv3 \
           -configuration Debug \
           -destination 'platform=macOS' \
           -derivedDataPath ./build \
           build

if [ $? -eq 0 ]; then
    echo "Build successful!"
    echo ""
    echo "To test the AUv3 in a DAW:"
    echo "1. The extension should be automatically registered with the system"
    echo "2. Open Logic Pro, Ableton Live, or another AU host"
    echo "3. Look for 'Rosita' or 'RositaAUv3' in the Audio Units list"
    echo "4. The plugin should appear under: Manufacturer: JAde, Name: Jammin': RositaAUv3"
    echo ""
    echo "If the plugin doesn't appear:"
    echo "- Run: auval -a | grep -i rosita"
    echo "- Check Console.app for any AU validation errors"
    echo "- You may need to restart your DAW or run: killall -9 AudioComponentRegistrar"
else
    echo "Build failed!"
    exit 1
fi