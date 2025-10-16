import SwiftUI

// Pattern 1-8 buttons only
struct Pattern8Buttons: View {
    @EnvironmentObject var audioEngine: AudioEngine

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<8) { slot in
                if audioEngine.isStepEditMode && slot < 4 {
                    // First 4 buttons become sequence direction icon buttons in STEP EDIT mode
                    SequenceDirectionButton(
                        direction: slot,
                        color: getSequenceDirectionColor(slot),
                        iconColor: audioEngine.sequenceDirections[audioEngine.selectedInstrument] == slot ? .white : .black,
                        action: {
                            print("🎯 Setting direction for instrument \(audioEngine.selectedInstrument) to \(slot)")
                            audioEngine.sequenceDirections[audioEngine.selectedInstrument] = slot
                            print("🎯 Directions array is now: \(audioEngine.sequenceDirections)")
                        }
                    )
                } else if audioEngine.isStepEditMode && slot >= 4 && slot < 8 {
                    // Buttons 5-8 (slots 4-7) become track speed buttons in STEP EDIT mode
                    let speedIndex = slot - 4  // Map to 0-3
                    TrackSpeedButton(
                        speedIndex: speedIndex,
                        color: getTrackSpeedColor(speedIndex),
                        textColor: audioEngine.trackSpeeds[audioEngine.selectedInstrument] == speedIndex ? .white : .black,
                        action: {
                            print("🎯 Setting track speed for instrument \(audioEngine.selectedInstrument) to \(speedIndex)")
                            audioEngine.trackSpeeds[audioEngine.selectedInstrument] = speedIndex
                            print("🎯 Track speeds array is now: \(audioEngine.trackSpeeds)")
                        }
                    )
                } else {
                    RetroPatternButton(
                        number: slot + 1,
                        isSelected: audioEngine.isStepEditMode ? false : (audioEngine.currentPatternSlot == slot),
                        isDupTarget: audioEngine.isDupMode && !audioEngine.isStepEditMode,
                        action: {
                            if audioEngine.isStepEditMode {
                                // In STEP EDIT mode, buttons 1-4 are direction, 5-8 are speed, no pattern selection
                                return
                            } else {
                                // Normal mode, select pattern
                                audioEngine.selectPattern(slot)
                            }
                        }
                    )
                }
            }
        }
    }

    // Get sequence direction color
    private func getSequenceDirectionColor(_ direction: Int) -> Color {
        let currentDirection = audioEngine.sequenceDirections[audioEngine.selectedInstrument]
        if currentDirection == direction {
            // Active colors
            switch direction {
            case 0: return Color(hex: "32CD32")  // Forward - Green
            case 1: return Color(hex: "FF6347")  // Backward - Tomato Red
            case 2: return Color(hex: "FFD700")  // Pendulum - Gold
            case 3: return Color(hex: "9370DB")  // Random - Purple
            default: return Color.white
            }
        } else {
            return Color.white
        }
    }

    // Get track speed color
    private func getTrackSpeedColor(_ speedIndex: Int) -> Color {
        let currentSpeed = audioEngine.trackSpeeds[audioEngine.selectedInstrument]
        if currentSpeed == speedIndex {
            // Active colors
            switch speedIndex {
            case 0: return Color(hex: "FF6347")  // 1/2x - Tomato Red (slower)
            case 1: return Color(hex: "32CD32")  // 1x - Green (normal)
            case 2: return Color(hex: "FFD700")  // 2x - Gold (faster)
            case 3: return Color(hex: "FF4500")  // 4x - Orange Red (fastest)
            default: return Color.white
            }
        } else {
            return Color.white
        }
    }

    // Map slot (0-7) to track length (2-16)
    private func trackLengthForSlot(_ slot: Int) -> Int {
        return (slot + 1) * 2  // 1→2, 2→4, 3→6, 4→8, 5→10, 6→12, 7→14, 8→16
    }
}

// DUP button separately - becomes RETRIG in STEP EDIT mode
struct DupButton: View {
    @EnvironmentObject var audioEngine: AudioEngine

    var body: some View {
        if audioEngine.isStepEditMode {
            // RETRIG button in STEP EDIT mode
            RetroButton(
                title: "RETRIG\n\(audioEngine.currentRetrigCount)x",
                color: getRetrigColor(),
                textColor: audioEngine.currentRetrigCount > 1 ? .white : .black,
                action: {
                    audioEngine.cycleRetrigCount()

                    // Apply retrig count to currently selected step
                    if let step = audioEngine.editingStep {
                        // Melodic tracks
                        audioEngine.setRetrigCount(row: step.row, col: step.col, instrument: audioEngine.selectedInstrument, count: audioEngine.currentRetrigCount)
                    } else if let step = audioEngine.editingDrumStep {
                        // Drum tracks
                        audioEngine.setRetrigCount(row: step.row, col: step.col, instrument: audioEngine.selectedInstrument, count: audioEngine.currentRetrigCount)
                    }
                },
                width: 56,
                height: 56,
                fontSize: 10
            )
        } else {
            // DUP button in normal mode
            RetroButton(
                title: "DUP",
                color: audioEngine.isDupMode ? Color.white : Color(hex: "9370DB"),
                textColor: audioEngine.isDupMode ? .black : .black,
                action: {
                    audioEngine.duplicatePattern()
                },
                width: 56,
                height: 56,
                fontSize: 12
            )
        }
    }

    private func getRetrigColor() -> Color {
        switch audioEngine.currentRetrigCount {
        case 1: return Color.white
        case 2: return Color(hex: "32CD32")  // Green for 2x
        case 3: return Color(hex: "FF8C00")  // Orange for 3x
        default: return Color.white
        }
    }
}

// Sequence Direction Button with icon
struct SequenceDirectionButton: View {
    let direction: Int
    let color: Color
    let iconColor: Color
    let action: () -> Void

    var body: some View {
        ZStack {
            Rectangle()
                .fill(color)
                .frame(width: 56, height: 56)
                .overlay(
                    ZStack {
                        // 3D bevel effect
                        VStack(spacing: 0) {
                            Rectangle()
                                .fill(Color.white.opacity(0.4))
                                .frame(height: 2)
                            Spacer()
                        }
                        HStack(spacing: 0) {
                            Rectangle()
                                .fill(Color.white.opacity(0.4))
                                .frame(width: 2)
                            Spacer()
                        }
                        VStack(spacing: 0) {
                            Spacer()
                            Rectangle()
                                .fill(Color.black.opacity(0.6))
                                .frame(height: 2)
                        }
                        HStack(spacing: 0) {
                            Spacer()
                            Rectangle()
                                .fill(Color.black.opacity(0.6))
                                .frame(width: 2)
                        }
                        Rectangle()
                            .stroke(Color.white, lineWidth: 2)
                    }
                )

            // Icon
            getDirectionIcon()
                .frame(width: 40, height: 40)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            action()
        }
    }

    @ViewBuilder
    private func getDirectionIcon() -> some View {
        switch direction {
        case 0:
            Text("→")  // Forward
                .font(.system(size: 28))
                .foregroundColor(iconColor)
        case 1:
            Text("←")  // Backward
                .font(.system(size: 28))
                .foregroundColor(iconColor)
        case 2:
            Text("⟷")  // Pendulum
                .font(.system(size: 28))
                .foregroundColor(iconColor)
        case 3:
            Text("🎲")  // Random
                .font(.system(size: 28))
                .foregroundColor(iconColor)
        default:
            Text("→")
                .font(.system(size: 28))
                .foregroundColor(iconColor)
        }
    }
}

// Track Speed Button with label
struct TrackSpeedButton: View {
    let speedIndex: Int
    let color: Color
    let textColor: Color
    let action: () -> Void

    var body: some View {
        ZStack {
            Rectangle()
                .fill(color)
                .frame(width: 56, height: 56)
                .overlay(
                    ZStack {
                        // 3D bevel effect
                        VStack(spacing: 0) {
                            Rectangle()
                                .fill(Color.white.opacity(0.4))
                                .frame(height: 2)
                            Spacer()
                        }
                        HStack(spacing: 0) {
                            Rectangle()
                                .fill(Color.white.opacity(0.4))
                                .frame(width: 2)
                            Spacer()
                        }
                        VStack(spacing: 0) {
                            Spacer()
                            Rectangle()
                                .fill(Color.black.opacity(0.6))
                                .frame(height: 2)
                        }
                        HStack(spacing: 0) {
                            Spacer()
                            Rectangle()
                                .fill(Color.black.opacity(0.6))
                                .frame(width: 2)
                        }
                        Rectangle()
                            .stroke(Color.white, lineWidth: 2)
                    }
                )

            // Speed label
            Text(getSpeedLabel())
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(textColor)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            action()
        }
    }

    private func getSpeedLabel() -> String {
        switch speedIndex {
        case 0: return "1/2x"
        case 1: return "1x"
        case 2: return "2x"
        case 3: return "4x"
        default: return "1x"
        }
    }
}

// Combined view for backward compatibility
struct PatternSlotsView: View {
    var body: some View {
        HStack(spacing: 6) {
            Pattern8Buttons()

            Spacer()
                .frame(width: 6)  // Same spacing as between other buttons

            DupButton()
        }
    }
}