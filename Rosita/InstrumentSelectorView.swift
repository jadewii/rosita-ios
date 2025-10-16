import SwiftUI

struct InstrumentSelectorView: View {
    @EnvironmentObject var audioEngine: AudioEngine

    var body: some View {
        // Instrument selector with title
        VStack(spacing: 2) {
            // Title
            Text("ROSITA")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(.black)

            // Instrument buttons in a single row - retro style
            HStack(spacing: 4) {
                ForEach(0..<4) { index in
                    RetroInstrumentButton(
                        index: index,
                        isSelected: audioEngine.selectedInstrument == index && !audioEngine.isFXMode,
                        type: InstrumentType(rawValue: index) ?? .synth,
                        waveformIndex: audioEngine.instrumentWaveforms[index]
                    ) {
                        if audioEngine.selectedInstrument == index && !audioEngine.isFXMode {
                            // Already selected - cycle waveform
                            audioEngine.cycleInstrumentWaveform(index)
                        } else {
                            // Select this instrument and exit FX mode
                            audioEngine.selectedInstrument = index
                            audioEngine.isFXMode = false
                            audioEngine.isKitBrowserMode = false
                            audioEngine.isMixerMode = false
                        }
                    }
                }

                // FX button
                RetroFXButton(
                    isSelected: audioEngine.isFXMode
                ) {
                    // Select FX mode (like selecting a track)
                    audioEngine.isFXMode = true
                    audioEngine.isKitBrowserMode = false
                    audioEngine.isMixerMode = false
                }
            }
            .contentTransition(.identity)
            .transaction { $0.animation = nil }
        }
        .padding(4)
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

    @ViewBuilder
    func getWaveformShape() -> some View {
        if type != .drums {
            VStack(spacing: 4) {
                // Waveform icon on top
                switch waveformIndex {
                case 0: // Square
                    SquareWaveShape()
                        .stroke(isSelected ? Color.black.opacity(0.6) : Color.white, lineWidth: 2)
                        .frame(width: 42, height: 24)
                case 1: // Sawtooth
                    SawtoothWaveShape()
                        .stroke(isSelected ? Color.black.opacity(0.6) : Color.white, lineWidth: 2)
                        .frame(width: 42, height: 24)
                case 2: // Triangle
                    TriangleWaveShape()
                        .stroke(isSelected ? Color.black.opacity(0.6) : Color.white, lineWidth: 2)
                        .frame(width: 42, height: 24)
                case 3: // Sine
                    SineWaveShape()
                        .stroke(isSelected ? Color.black.opacity(0.6) : Color.white, lineWidth: 2)
                        .frame(width: 42, height: 24)
                case 4: // Reverse Sawtooth
                    ReverseSawWaveShape()
                        .stroke(isSelected ? Color.black.opacity(0.6) : Color.white, lineWidth: 2)
                        .frame(width: 42, height: 24)
                default:
                    EmptyView()
                }

                // Text label below
                Text(getWaveformLabel())
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(isSelected ? Color.black.opacity(0.7) : Color.white.opacity(0.9))
            }
            .frame(width: 56, height: 56)
        } else {
            // Show grid icon for percussion (track 4) or kit label for other drums
            if index == 3 {
                // Track 4 - show 4-square grid icon
                GridIconShape()
                    .fill(isSelected ? Color.black : Color.white)
                    .frame(width: 56, height: 56)
            } else {
                // Other drum tracks - show kit label
                VStack(spacing: 2) {
                    Text("KIT")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(isSelected ? .black : .white)
                    Text("\(waveformIndex + 1)")
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .foregroundColor(isSelected ? .black : .white)
                }
            }
        }
    }

    func getWaveformLabel() -> String {
        switch waveformIndex {
        case 0: return "SQR"
        case 1: return "SAW"
        case 2: return "TRI"
        case 3: return "SIN"
        case 4: return "RSAW"
        default: return ""
        }
    }

    var body: some View {
        ZStack {
            // Background
            Rectangle()
                .fill(isSelected ? getWaveformColor() : Color.black)
                .frame(width: 56, height: 56)
                .overlay(
                    ZStack {
                        // 3D bevel effect
                        VStack(spacing: 0) {
                            Rectangle()
                                .fill(Color.white.opacity(isSelected ? 0.4 : 0.0))
                                .frame(height: 2)
                            Spacer()
                        }

                        HStack(spacing: 0) {
                            Rectangle()
                                .fill(Color.white.opacity(isSelected ? 0.4 : 0.0))
                                .frame(width: 2)
                            Spacer()
                        }

                        VStack(spacing: 0) {
                            Spacer()
                            Rectangle()
                                .fill(Color.black.opacity(isSelected ? 0.6 : 0.0))
                                .frame(height: 2)
                        }

                        HStack(spacing: 0) {
                            Spacer()
                            Rectangle()
                                .fill(Color.black.opacity(isSelected ? 0.6 : 0.0))
                                .frame(width: 2)
                        }

                        Rectangle()
                            .stroke(isSelected ? Color.white : Color.gray, lineWidth: 2)
                    }
                )

            // Waveform shape in center
            getWaveformShape()
        }
        .contentShape(Rectangle())
        .onTapGesture {
            action()
        }
    }
}

struct OctaveButton: View {
    let symbol: String
    let instrumentType: InstrumentType
    let octaveOffset: Int
    let isUpperButton: Bool
    let action: () -> Void

    private func getButtonColor() -> Color {
        let baseColor = instrumentType.color

        // Determine if this button should be highlighted
        let shouldHighlight = (isUpperButton && octaveOffset > 0) || (!isUpperButton && octaveOffset < 0)

        if !shouldHighlight {
            return Color.black
        }

        // Calculate color based on octave offset
        // Higher octave = lighter, lower octave = darker
        let absOffset = abs(octaveOffset)

        if isUpperButton {
            // + button: lighter colors for higher octaves
            switch absOffset {
            case 1: return adjustBrightness(baseColor, by: 0.15)  // Slightly lighter
            case 2: return adjustBrightness(baseColor, by: 0.30)  // Much lighter
            default: return baseColor
            }
        } else {
            // - button: darker colors for lower octaves
            switch absOffset {
            case 1: return adjustBrightness(baseColor, by: -0.20) // Slightly darker
            case 2: return adjustBrightness(baseColor, by: -0.40) // Much darker
            default: return baseColor
            }
        }
    }

    private func adjustBrightness(_ color: Color, by amount: CGFloat) -> Color {
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0

        let uiColor = UIColor(color)
        uiColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)

        let newBrightness = max(0, min(1, brightness + amount))
        return Color(hue: Double(hue), saturation: Double(saturation), brightness: Double(newBrightness), opacity: Double(alpha))
    }

    var body: some View {
        ZStack {
            Rectangle()
                .fill(getButtonColor())
                .frame(width: 56, height: 35)
                .overlay(
                    ZStack {
                        // 3D bevel effect when active
                        if octaveOffset != 0 {
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
                        }

                        Rectangle()
                            .stroke(octaveOffset != 0 ? Color.white : Color.gray, lineWidth: 2)
                    }
                )

            Text(symbol)
                .font(.system(size: 16, weight: .bold, design: .monospaced))
                .foregroundColor(octaveOffset != 0 ? .black : .white)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            action()
        }
    }
}

// FX Button
struct RetroFXButton: View {
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        ZStack {
            Rectangle()
                .fill(isSelected ? Color(hex: "9370DB") : Color.black)
                .frame(width: 56, height: 56)
                .overlay(
                    ZStack {
                        // 3D bevel effect when selected
                        if isSelected {
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
                        }
                        Rectangle()
                            .stroke(isSelected ? Color.white : Color.gray, lineWidth: 2)
                    }
                )

            Text("FX")
                .font(.system(size: 16, weight: .bold, design: .monospaced))
                .foregroundColor(isSelected ? .black : .white)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            action()
        }
    }
}