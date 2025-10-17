import SwiftUI

// Pattern 1-8 buttons only
struct Pattern8Buttons: View {
    @EnvironmentObject var audioEngine: AudioEngine

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<8) { slot in
                if audioEngine.isMixerMode {
                    // MIXER MODE - 8 mute buttons
                    MuteButton(
                        trackIndex: slot
                    )
                } else if audioEngine.isScaleSelectionMode {
                    // All 8 buttons show scale names in SCALE SELECTION mode
                    ScaleButton(
                        scaleIndex: slot,
                        isSelected: audioEngine.currentScale == slot,
                        action: {
                            audioEngine.changeScale(to: slot)
                            // Only close scale selection if not locked
                            if !audioEngine.isScaleSelectionLocked {
                                audioEngine.isScaleSelectionMode = false
                            }
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }
                    )
                } else if audioEngine.isStepEditMode && slot < 4 {
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
                        isSelected: audioEngine.isScaleSelectionMode ? false : (audioEngine.isStepEditMode ? false : (audioEngine.currentPatternSlot == slot)),
                        isDupTarget: audioEngine.isDupMode && !audioEngine.isStepEditMode && !audioEngine.isScaleSelectionMode,
                        action: {
                            // Exit solo mode if active
                            if audioEngine.soloedTrack != nil {
                                audioEngine.soloedTrack = nil
                            }

                            if audioEngine.isScaleSelectionMode {
                                // In SCALE SELECTION mode, all 8 buttons show scales
                                return
                            } else if audioEngine.isStepEditMode {
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

// Mute Button for mixer mode
struct MuteButton: View {
    let trackIndex: Int
    @EnvironmentObject var audioEngine: AudioEngine

    @State private var longPressTimer: Timer?
    @State private var isLongPressing = false

    var body: some View {
        let isMuted = getMuteState()
        let isSoloed = (audioEngine.soloedTrack == trackIndex)
        let label = getLabel()
        let fontSize = trackIndex == 7 ? 10 : 12

        ZStack {
            Rectangle()
                .fill(isSoloed ? Color(hex: "FFD700") : (isMuted ? Color(hex: "FF9999") : Color(hex: "32CD32")))
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
                            .stroke(Color.black, lineWidth: 2)
                    }
                )

            // Label
            Text(label)
                .font(.system(size: CGFloat(fontSize), weight: .bold, design: .monospaced))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if !isLongPressing {
                // If solo mode is active, exit it
                if audioEngine.soloedTrack != nil {
                    audioEngine.soloedTrack = nil
                } else {
                    // Normal tap - toggle mute
                    toggleMute()
                }
            }
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if longPressTimer == nil {
                        // Start timer on press
                        longPressTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
                            // Long press detected - activate solo
                            isLongPressing = true
                            audioEngine.soloedTrack = trackIndex
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        }
                    }
                }
                .onEnded { _ in
                    // Cancel timer and reset
                    longPressTimer?.invalidate()
                    longPressTimer = nil

                    // Reset long press flag after a short delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        isLongPressing = false
                    }
                }
        )
    }

    private func getMuteState() -> Bool {
        switch trackIndex {
        case 0...2:
            // Melodic tracks
            return audioEngine.trackMuted[trackIndex]
        case 3...6:
            // Individual drum rows
            let drumRow = trackIndex - 3
            return audioEngine.drumRowsMuted[drumRow]
        case 7:
            // All drums
            return audioEngine.allDrumsMuted
        default:
            return false
        }
    }

    private func toggleMute() {
        switch trackIndex {
        case 0...2:
            // Toggle melodic track mute
            audioEngine.trackMuted[trackIndex].toggle()
        case 3...6:
            // Toggle individual drum row mute
            let drumRow = trackIndex - 3
            audioEngine.drumRowsMuted[drumRow].toggle()
        case 7:
            // Toggle all drums mute
            audioEngine.allDrumsMuted.toggle()
        default:
            break
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func getLabel() -> String {
        switch trackIndex {
        case 0: return "TRK\n1"
        case 1: return "TRK\n2"
        case 2: return "TRK\n3"
        case 3: return "KICK"
        case 4: return "SNARE"
        case 5: return "HAT"
        case 6: return "PERC"
        case 7: return "ALL\nDRUMS"
        default: return ""
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
                            .stroke(Color.black, lineWidth: 2)
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
                            .stroke(Color.black, lineWidth: 2)
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

// Scale selection button
struct ScaleButton: View {
    let scaleIndex: Int
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        ZStack {
            Rectangle()
                .fill(getScaleColor())
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
                            .stroke(isSelected ? Color.white : Color.black, lineWidth: isSelected ? 3 : 2)
                    }
                )

            // Scale name
            Text(getScaleName())
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(isSelected ? .white : .black)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            action()
        }
    }

    private func getScaleName() -> String {
        switch scaleIndex {
        case 0: return "MAJ"
        case 1: return "MIN"
        case 2: return "PENT"
        case 3: return "BLUE"
        case 4: return "CHRO"
        case 5: return "DOR"
        case 6: return "MIX"
        case 7: return "H-MIN"
        default: return ""
        }
    }

    private func getScaleColor() -> Color {
        switch scaleIndex {
        case 0: return Color(hex: "FF69B4") // Major - Hot Pink
        case 1: return Color(hex: "9370DB") // Minor - Purple
        case 2: return Color(hex: "32CD32") // Pentatonic - Lime Green
        case 3: return Color(hex: "1E90FF") // Blues - Dodger Blue
        case 4: return Color(hex: "FFD700") // Chromatic - Gold
        case 5: return Color(hex: "FF6347") // Dorian - Tomato
        case 6: return Color(hex: "FF8C00") // Mixolydian - Dark Orange
        case 7: return Color(hex: "8A2BE2") // Harmonic Minor - Blue Violet
        default: return Color.gray
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