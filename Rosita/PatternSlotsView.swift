import SwiftUI

// Pattern 1-8 buttons only
struct Pattern8Buttons: View {
    @EnvironmentObject var audioEngine: AudioEngine

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<8) { slot in
                RetroPatternButton(
                    number: slot + 1,
                    isSelected: audioEngine.isStepEditMode ? (trackLengthForSlot(slot) == audioEngine.trackLengths[audioEngine.selectedInstrument]) : (audioEngine.currentPatternSlot == slot),
                    isDupTarget: audioEngine.isDupMode && !audioEngine.isStepEditMode,
                    action: {
                        if audioEngine.isStepEditMode {
                            // In STEP EDIT mode, set track length
                            let length = trackLengthForSlot(slot)
                            audioEngine.setTrackLength(track: audioEngine.selectedInstrument, length: length)
                        } else {
                            // Normal mode, select pattern
                            audioEngine.selectPattern(slot)
                        }
                    }
                )
            }
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
                color: Color(hex: "9370DB"),
                textColor: .black,
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