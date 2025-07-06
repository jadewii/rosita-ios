import SwiftUI

struct GridSequencerView: View {
    @EnvironmentObject var audioEngine: AudioEngine
    
    // Get instrument colors from InstrumentType
    private func getInstrumentColor(for instrumentIndex: Int) -> Color {
        guard let instrumentType = InstrumentType(rawValue: instrumentIndex) else {
            return Color.gray
        }
        return instrumentType.color
    }
    
    // Get darker shade for active steps
    private func getDarkerShade(of color: Color) -> Color {
        // Convert to darker version for active steps
        switch color {
        case Color(hex: "FFB6C1"): return Color(hex: "FF1493") // Pink -> Deep Pink
        case Color(hex: "87CEEB"): return Color(hex: "1E90FF") // Sky Blue -> Dodger Blue
        case Color(hex: "DDA0DD"): return Color(hex: "9370DB") // Plum -> Medium Purple
        case Color(hex: "FFD700"): return Color(hex: "FFA500") // Gold -> Orange
        default: return color.opacity(0.7)
        }
    }
    
    // Get even darker shade for outlines
    private func getOutlineColor(for color: Color) -> Color {
        switch color {
        case Color(hex: "FFB6C1"): return Color(hex: "C71585") // Pink -> Medium Violet Red
        case Color(hex: "87CEEB"): return Color(hex: "4682B4") // Sky Blue -> Steel Blue
        case Color(hex: "DDA0DD"): return Color(hex: "6A0DAD") // Plum -> Dark Purple
        case Color(hex: "FFD700"): return Color(hex: "FF8C00") // Gold -> Dark Orange
        default: return color.opacity(0.5)
        }
    }
    
    var body: some View {
        VStack(spacing: 4) {
            // Main sequencer grid - 8 tracks x 16 steps
            VStack(spacing: 2) {
                    ForEach(0..<8) { track in
                        HStack(spacing: 2) {
                            ForEach(0..<16) { step in
                                let isBeatMarker = (step % 4 == 0)
                                GridCell(
                                    row: track,
                                    col: step,
                                    isActive: audioEngine.getGridCell(row: track, col: step),
                                    isPlaying: audioEngine.isPlaying && step == audioEngine.currentPlayingStep,
                                    selectedInstrument: audioEngine.selectedInstrument,
                                    instrumentColor: getInstrumentColor(for: audioEngine.selectedInstrument),
                                    darkerColor: getDarkerShade(of: getInstrumentColor(for: audioEngine.selectedInstrument)),
                                    octave: audioEngine.getGridCellOctave(row: track, col: step),
                                    velocity: audioEngine.getGridCellVelocity(row: track, col: step),
                                    isBeatMarker: isBeatMarker
                                ) {
                                    audioEngine.toggleGridCell(row: track, col: step)
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                } longPressAction: {
                                    audioEngine.showVelocityEditor(row: track, col: step)
                                }
                            }
                        }
                    }
                }
            .padding(8)
            .background(
                Rectangle()
                    .fill(getInstrumentColor(for: audioEngine.selectedInstrument))
                    .overlay(
                        Rectangle()
                            .stroke(getDarkerShade(of: getInstrumentColor(for: audioEngine.selectedInstrument)), lineWidth: 1)
                    )
            )
        }
    }
}

struct GridCell: View {
    let row: Int
    let col: Int
    let isActive: Bool
    let isPlaying: Bool
    let selectedInstrument: Int
    let instrumentColor: Color
    let darkerColor: Color
    let octave: Int
    let velocity: Float
    var isBeatMarker: Bool = false
    let action: () -> Void
    let longPressAction: () -> Void
    
    var body: some View {
        Button(action: action) {
            Rectangle()
                .fill(cellColor)
                .overlay(
                    Rectangle()
                        .stroke(isActive ? getActiveOutlineColor() : darkerColor.opacity(0.4), lineWidth: isActive ? 3 : 1)
                )
                .overlay(
                    // Velocity indicator - gradient based on velocity
                    GeometryReader { geometry in
                        if isActive {
                            VStack {
                                Spacer()
                                Rectangle()
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [darkerColor.opacity(0.9), darkerColor.opacity(0.4)]),
                                            startPoint: .bottom,
                                            endPoint: .top
                                        )
                                    )
                                    .frame(height: geometry.size.height * CGFloat(velocity))
                            }
                        }
                    }
                )
                .overlay(
                    // Playing indicator - clean white border with pulse
                    Rectangle()
                        .stroke(isPlaying ? Color.white : Color.clear, lineWidth: 2)
                        .scaleEffect(isPlaying ? 1.05 : 1.0)
                        .opacity(isPlaying ? 1.0 : 0.0)
                )
                .aspectRatio(1.0, contentMode: .fit)
                .scaleEffect(isPlaying ? 1.08 : 1.0)
                .animation(.easeInOut(duration: 0.08), value: isPlaying)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isActive)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0.5) {
            longPressAction()
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
    }
    
    private func getActiveOutlineColor() -> Color {
        // Return an even darker shade than the cell color for better contrast
        switch instrumentColor {
        case Color(hex: "FFB6C1"): return Color(hex: "C71585") // Pink -> Medium Violet Red
        case Color(hex: "87CEEB"): return Color(hex: "4682B4") // Sky Blue -> Steel Blue
        case Color(hex: "DDA0DD"): return Color(hex: "6A0DAD") // Plum -> Dark Purple
        case Color(hex: "FFD700"): return Color(hex: "FF8C00") // Gold -> Dark Orange
        default: return darkerColor.opacity(0.8)
        }
    }
    
    private var cellColor: Color {
        // Special handling for drums (instrument 4 = index 3)
        if selectedInstrument == 3 { // Drums
            if isActive {
                // Different colors for different drum sounds based on row
                switch row {
                case 0: return Color(hex: "FF4500") // Kick - Orange Red
                case 1: return Color(hex: "1E90FF") // Snare - Blue  
                case 2: return Color(hex: "32CD32") // Hi-hat - Green
                case 3: return Color(hex: "FF1493") // Percussion - Pink
                default: return darkerColor
                }
            } else {
                // Show drum row colors faintly when inactive for drums
                if row < 4 {
                    switch row {
                    case 0: return Color(hex: "FF4500").opacity(0.2) // Kick
                    case 1: return Color(hex: "1E90FF").opacity(0.2) // Snare
                    case 2: return Color(hex: "32CD32").opacity(0.2) // Hi-hat
                    case 3: return Color(hex: "FF1493").opacity(0.2) // Percussion
                    default: return instrumentColor.opacity(0.3)
                    }
                } else {
                    return Color.gray.opacity(0.1) // Empty rows for drums
                }
            }
        } else {
            // All other instruments: use the selected instrument's color scheme with octave shading
            if isActive {
                // Adjust color brightness based on octave
                switch octave {
                case -2: return darkerColor.opacity(0.5)  // Very low octave
                case -1: return darkerColor.opacity(0.7)  // Low octave
                case 0: return darkerColor                 // Base octave
                case 1: return instrumentColor.opacity(0.9)   // High octave - use base color lighter
                case 2: return instrumentColor.opacity(0.8)   // Very high octave - even lighter base
                default: return darkerColor
                }
            } else {
                // For beat markers (steps 4, 8, 12), use darker shade of instrument color
                if isBeatMarker {
                    return darkerColor.opacity(0.15)
                } else {
                    return instrumentColor.opacity(0.3)
                }
            }
        }
    }
}