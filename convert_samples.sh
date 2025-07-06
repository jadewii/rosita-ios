#!/bin/bash

echo "🎵 Converting WAV samples to M4A for Rosita"
echo "=========================================="

# Create output directory
mkdir -p Rosita/Samples_M4A

# Convert all WAV files to M4A
for wav in Rosita/Samples/*.wav; do
    filename=$(basename "$wav" .wav)
    echo "Converting $filename.wav → $filename.m4a"
    afconvert -f m4af -d aac "$wav" "Rosita/Samples_M4A/$filename.m4a"
done

echo ""
echo "✅ Conversion complete!"
echo "M4A files saved in: Rosita/Samples_M4A/"
echo ""
echo "Benefits of M4A:"
echo "- 10x smaller file size"
echo "- Better iOS/macOS performance"
echo "- Hardware accelerated playback"
echo "- Perfect for Mac App Store apps"