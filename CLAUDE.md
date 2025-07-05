# ROSITA iOS - CLAUDE CODE CONTEXT

## QUICK ACCESS COMMAND
```bash
# Type this in terminal to open this project:
# claude "RositaIOS"
```

## PROJECT OVERVIEW
Beautiful iOS synthesizer app with retro aesthetic, piano keyboard, 8-track sequencer, ADSR controls, effects, and arpeggiator. Currently being refined with perfect layout and UI styling.

## PROJECT LOCATION
- **Path**: `/Users/jade/Wiistrument-Development/01-Active-Projects/Rosita-Project/source-code/wiistruments-center-clean/rosita-ios/RositaXcode/`
- **GitHub**: https://github.com/jadewii/rosita-ios
- **Branch**: main

## CURRENT STATUS ✅
- Beautiful retro UI with pink gradient background
- All layout issues resolved - no more overlapping!
- Custom retro buttons with 3D bevel effects
- Pattern buttons (1-8) and DUP button properly sized (56x56px)
- Instrument and Arpeggiator sections perfectly aligned
- Transport controls (PLAY-OCTAVE) show gray when inactive
- Audio engine working with lazy initialization
- ADSR and Effects properly positioned

## RECENT WORK (July 4, 2025)
- Fixed all overlapping UI elements
- Implemented proper spacing between sections
- Made all pattern buttons twice their original size
- Fixed button colors (gray when inactive, colored when active)
- Created beautiful horizontal layout for all controls
- Resolved instrument/arpeggiator positioning

## BUILD COMMANDS
```bash
# Build the iOS app (requires Xcode)
xcodebuild -quiet

# Quick check git status
git status

# Save all changes (use "SAVE" command)
git add -A && git commit -m "Your changes" && git push
```

## STREAMLINED WORKFLOW

### When user says "SAVE":
```bash
git add -A
git commit -m "UI improvements and layout fixes 🎹 Generated with Claude Code

Co-Authored-By: Claude <noreply@anthropic.com>"
git push origin main
```

### When user says "RositaIOS" in terminal:
- Navigate to this project directory
- Show current status
- Ready to continue development

## KEY FILES MODIFIED TODAY
- `Rosita/ContentView.swift` - Main layout container with perfect spacing
- `Rosita/ArpeggiatorView.swift` - Fixed to match instrument selector size
- `Rosita/PatternSlotsView.swift` - Made buttons 2x larger (56x56px)
- `Rosita/RetroButton.swift` - Pattern buttons sizing, colors
- `Rosita/TransportControlsView.swift` - Gray inactive button states
- `Rosita/InstrumentSelectorView.swift` - White background styling
- `Rosita/AudioEngine.swift` - Lazy initialization fix

## KNOWN WORKING FEATURES
- ✅ Audio synthesis and playback
- ✅ Piano keyboard with proper black key grouping
- ✅ 8-track sequencer grid
- ✅ 4 instruments (Synth, Bass, Keys, Drums)
- ✅ Pattern memory slots (1-8) + DUP
- ✅ Transport controls (PLAY, STOP, etc.)
- ✅ BPM display and control
- ✅ ADSR envelope controls
- ✅ Effects section
- ✅ Arpeggiator modes
- ✅ Beautiful retro UI styling

## UI LAYOUT STRUCTURE
```
Top Section:
[PLAY][STOP][RANDOM][CLEAR][CLR ALL][MIXER][ADSR][MAJOR][OCTAVE][BPM:120][INSTRUMENT 1234][ARPEGGIATOR 123]

Pattern Section:
                    [1][2][3][4][5][6][7][8][DUP]

Main Content:
[ADSR ENVELOPE]    [8x16 SEQUENCER GRID]
[EFFECTS      ]

Bottom:
                    [PIANO KEYBOARD]
```

## TROUBLESHOOTING
- If build fails: Check Xcode signing settings
- If audio doesn't work: Verify AVAudioSession permissions
- If UI overlaps: Check frame sizes and spacing values
- For any issues: Check git history for working versions

## NEXT POTENTIAL FEATURES
- Add more instrument types
- Implement effects parameters
- Add tempo sync options
- Create preset saving system
- Add MIDI export functionality

## EMERGENCY RECOVERY
```bash
git clone https://github.com/jadewii/rosita-ios
cd rosita-ios
# Open in Xcode and build
```

---
*Last updated: July 4, 2025*  
*Status: Beautiful, functional, ready for final testing*