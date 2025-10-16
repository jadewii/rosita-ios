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
                            audioEngine.sequenceDirections[audioEngine.selectedInstrument] = slot
                        }
                    )
                } else {
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

// Sequence Direction Button with icon
struct SequenceDirectionButton: View {
    let direction: Int
    let color: Color
    let iconColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
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
        }
        .buttonStyle(PlainButtonStyle())
    }

    @ViewBuilder
    private func getDirectionIcon() -> some View {
        switch direction {
        case 0: ArrowRightShape().fill(iconColor)
        case 1: ArrowLeftShape().fill(iconColor)
        case 2: ArrowPendulumShape().fill(iconColor)
        case 3: RandomIconShape().fill(iconColor)
        default: ArrowRightShape().fill(iconColor)
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

// MARK: - Arrow Shapes for Sequence Direction

struct ArrowRightShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height

        // Right arrow (for Forward)
        path.move(to: CGPoint(x: width * 0.75, y: height * 0.5))
        path.addLine(to: CGPoint(x: width * 0.5, y: height * 0.75))
        path.addLine(to: CGPoint(x: width * 0.5, y: height * 0.6))
        path.addLine(to: CGPoint(x: width * 0.25, y: height * 0.6))
        path.addLine(to: CGPoint(x: width * 0.25, y: height * 0.4))
        path.addLine(to: CGPoint(x: width * 0.5, y: height * 0.4))
        path.addLine(to: CGPoint(x: width * 0.5, y: height * 0.25))
        path.closeSubpath()

        return path
    }
}

struct ArrowLeftShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height

        // Left arrow (for Backward)
        path.move(to: CGPoint(x: width * 0.25, y: height * 0.5))
        path.addLine(to: CGPoint(x: width * 0.5, y: height * 0.75))
        path.addLine(to: CGPoint(x: width * 0.5, y: height * 0.6))
        path.addLine(to: CGPoint(x: width * 0.75, y: height * 0.6))
        path.addLine(to: CGPoint(x: width * 0.75, y: height * 0.4))
        path.addLine(to: CGPoint(x: width * 0.5, y: height * 0.4))
        path.addLine(to: CGPoint(x: width * 0.5, y: height * 0.25))
        path.closeSubpath()

        return path
    }
}

struct ArrowPendulumShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height

        // Double arrow (left and right for Pendulum)
        path.move(to: CGPoint(x: width * 0.2, y: height * 0.5))
        path.addLine(to: CGPoint(x: width * 0.35, y: height * 0.35))
        path.addLine(to: CGPoint(x: width * 0.35, y: height * 0.45))
        path.addLine(to: CGPoint(x: width * 0.65, y: height * 0.45))
        path.addLine(to: CGPoint(x: width * 0.65, y: height * 0.35))
        path.addLine(to: CGPoint(x: width * 0.8, y: height * 0.5))
        path.addLine(to: CGPoint(x: width * 0.65, y: height * 0.65))
        path.addLine(to: CGPoint(x: width * 0.65, y: height * 0.55))
        path.addLine(to: CGPoint(x: width * 0.35, y: height * 0.55))
        path.addLine(to: CGPoint(x: width * 0.35, y: height * 0.65))
        path.closeSubpath()

        return path
    }
}