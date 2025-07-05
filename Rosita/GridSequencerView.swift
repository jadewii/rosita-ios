import SwiftUI

struct GridSequencerView: View {
    @EnvironmentObject var audioEngine: AudioEngine
    @State private var currentPlayingStep = -1
    
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
    
    var body: some View {
        VStack(spacing: 4) {
            // Step numbers like the web version
            HStack(spacing: 2) {
                ForEach(1...16, id: \.self) { step in
                    Text("\(step)")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity, minHeight: 16)
                        .background(
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.white.opacity(0.8))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 2)
                                        .stroke(Color.black, lineWidth: 0.5)
                                )
                        )
                }
            }
            .padding(.horizontal, 8)
            
            // Main sequencer grid - 8 tracks x 16 steps
            VStack(spacing: 2) {
                ForEach(0..<8) { track in
                    HStack(spacing: 2) {
                        ForEach(0..<16) { step in
                            GridCell(
                                track: track,
                                step: step,
                                isActive: audioEngine.getGridCellForCurrentInstrument(track: track, step: step),
                                isPlaying: audioEngine.isPlaying && step == currentPlayingStep,
                                selectedInstrument: audioEngine.selectedInstrument,
                                instrumentColor: getInstrumentColor(for: audioEngine.selectedInstrument),
                                darkerColor: getDarkerShade(of: getInstrumentColor(for: audioEngine.selectedInstrument))
                            ) {
                                audioEngine.toggleGridCell(track: track, step: step)
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
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
            .onReceive(Timer.publish(every: 60.0 / audioEngine.bpm / 4.0, on: .main, in: .common).autoconnect()) { _ in
                if audioEngine.isPlaying {
                    currentPlayingStep = (currentPlayingStep + 1) % 16
                } else {
                    currentPlayingStep = -1
                }
            }
        }
    }
}

struct GridCell: View {
    let track: Int
    let step: Int
    let isActive: Bool
    let isPlaying: Bool
    let selectedInstrument: Int
    let instrumentColor: Color
    let darkerColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Rectangle()
                .fill(cellColor)
                .overlay(
                    Rectangle()
                        .stroke(Color.gray.opacity(0.6), lineWidth: 0.5)
                )
                .overlay(
                    // Darker outline for active steps (like your reference images)
                    Rectangle()
                        .stroke(isActive ? darkerColor : Color.clear, lineWidth: 3)
                )
                .overlay(
                    // Playing indicator - clean white border
                    Rectangle()
                        .stroke(isPlaying ? Color.white : Color.clear, lineWidth: 2)
                )
                .aspectRatio(1.2, contentMode: .fit)
                .scaleEffect(isPlaying ? 1.02 : 1.0)
                .animation(.easeInOut(duration: 0.1), value: isPlaying)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var cellColor: Color {
        // Special handling for drums (instrument 4 = index 3)
        if selectedInstrument == 3 { // Drums
            if isActive {
                // Different colors for different drum sounds based on track
                switch track {
                case 0: return Color(hex: "FF4500") // Kick - Orange Red
                case 1: return Color(hex: "1E90FF") // Snare - Blue
                case 2: return Color(hex: "32CD32") // Hi-hat - Green
                case 3: return Color(hex: "FF1493") // Percussion - Pink
                default: return darkerColor
                }
            } else {
                // Lighter shade of the current instrument color for inactive drum cells
                return instrumentColor.opacity(0.3)
            }
        } else {
            // All other instruments: use the selected instrument's color scheme
            return isActive ? darkerColor : instrumentColor.opacity(0.3)
        }
    }
}