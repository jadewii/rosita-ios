import SwiftUI

struct InstrumentSelectorView: View {
    @EnvironmentObject var audioEngine: AudioEngine
    @State private var animatingIndex: Int? = nil
    
    var body: some View {
        VStack(spacing: 2) {
            // Title
            Text("INSTRUMENT")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(.black)
            
            // Instrument buttons in a single row - retro style
            HStack(spacing: 4) {
                ForEach(0..<4) { index in
                    RetroInstrumentButton(
                        index: index,
                        isSelected: audioEngine.selectedInstrument == index,
                        type: InstrumentType(rawValue: index) ?? .synth,
                        waveformIndex: audioEngine.instrumentWaveforms[index],
                        isAnimating: animatingIndex == index
                    ) {
                        if audioEngine.selectedInstrument == index {
                            // Already selected - cycle waveform
                            audioEngine.cycleInstrumentWaveform(index)
                            // Haptic feedback for waveform change
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            
                            // Trigger animation
                            withAnimation(.easeInOut(duration: 0.2)) {
                                animatingIndex = index
                            }
                            // Reset animation state
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                animatingIndex = nil
                            }
                        } else {
                            // Select this instrument
                            audioEngine.selectedInstrument = index
                        }
                    }
                }
            }
        }
        .padding(6)
        .background(
            Rectangle()
                .fill(Color.white)
                .overlay(
                    Rectangle()
                        .stroke(Color.black, lineWidth: 2)
                )
        )
    }
}

struct RetroInstrumentButton: View {
    let index: Int
    let isSelected: Bool
    let type: InstrumentType
    let waveformIndex: Int
    let isAnimating: Bool
    let action: () -> Void
    
    func getWaveformColor() -> Color {
        // Colors based on waveform type (consistent across all instruments)
        if type == .drums {
            // Drums keep kit-based colors
            switch waveformIndex {
            case 0: return Color(hex: "FFD700") // Gold - kit 1
            case 1: return Color(hex: "FFA500") // Orange - kit 2
            case 2: return Color(hex: "FF8C00") // Dark orange - kit 3
            case 3: return Color(hex: "FF6347") // Tomato - kit 4
            default: return type.color
            }
        } else {
            // All melodic instruments use the same color per waveform
            switch waveformIndex {
            case 0: return Color(hex: "FF69B4") // Hot pink - square
            case 1: return Color(hex: "32CD32") // Lime green - sawtooth
            case 2: return Color(hex: "1E90FF") // Dodger blue - triangle
            case 3: return Color(hex: "FFD700") // Gold - sine
            case 4: return Color(hex: "FF4500") // Orange red - reverse saw
            default: return type.color
            }
        }
    }
    
    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.1)) {
                action()
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
        }) {
            Text(type.displayNumber)
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(isSelected ? .black : .white)
                .frame(width: 28, height: 28)
                .scaleEffect(isAnimating ? 1.2 : 1.0)
                .background(
                    Rectangle()
                        .fill(isSelected ? getWaveformColor() : Color.black)
                        .overlay(
                            ZStack {
                                // 3D bevel effect
                                if isSelected {
                                    // Top and left highlight
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
                                    
                                    // Bottom and right shadow
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
                                }
                                
                                Rectangle()
                                    .stroke(isSelected ? Color.white : Color.gray, lineWidth: 2)
                            }
                        )
                )
        }
    }
}