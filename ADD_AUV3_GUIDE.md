# 🎛️ Adding AUv3 to Rosita iOS

## Making Rosita a Professional Audio Unit Plugin

### What is AUv3?
- Audio Unit v3 - Apple's plugin format
- Run inside GarageBand, Logic Pro, Cubasis, AUM
- Users can use multiple instances
- Professional music production workflow

### Steps to Add AUv3:

#### 1. Add AUv3 App Extension Target
In Xcode:
- File → New → Target
- iOS → Audio Unit Extension
- Name: "RositaAUv3"
- Language: Swift
- Include UI: YES ✅

#### 2. Configure Info.plist for AUv3
```xml
<key>NSExtension</key>
<dict>
    <key>NSExtensionAttributes</key>
    <dict>
        <key>AudioComponents</key>
        <array>
            <dict>
                <key>description</key>
                <string>Rosita Drum Machine</string>
                <key>manufacturer</key>
                <string>Wiis</string>
                <key>name</key>
                <string>Wiistrument: Rosita</string>
                <key>subtype</key>
                <string>rsit</string>
                <key>type</key>
                <string>aumu</string>
                <key>version</key>
                <integer>1</integer>
            </dict>
        </array>
    </dict>
    <key>NSExtensionPointIdentifier</key>
    <string>com.apple.AudioUnit-UI</string>
</dict>
```

#### 3. Share Audio Engine
Move your AudioEngine to a shared framework both app and AUv3 can use.

#### 4. Create AUv3 Audio Unit Class
```swift
import AudioToolbox
import AVFoundation
import RositaCore

public class RositaAudioUnit: AUAudioUnit {
    private var _currentMIDIVelocity: UInt8 = 127
    private var audioEngine: AudioEngine!
    
    // Your existing audio processing here
}
```

### Why This Is The Way:
- ✅ Users buy once, use everywhere
- ✅ Professional workflow
- ✅ Works in all iOS DAWs
- ✅ Multiple instances
- ✅ MIDI support
- ✅ Parameter automation

### Testing Your AUv3:
1. Build and run on device
2. Open GarageBand
3. Add Audio Unit instrument
4. Find "Wiistrument: Rosita"
5. Your full UI appears!

### Revenue Model:
- Sell as "Rosita Pro" with AUv3
- Premium price ($14.99-$29.99)
- Professional musicians pay for quality
- Works on iPhone AND iPad

This is how Korg, Moog, and Arturia do it!