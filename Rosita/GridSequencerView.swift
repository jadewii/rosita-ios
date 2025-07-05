import SwiftUI

struct GridSequencerView: View {
    @EnvironmentObject var audioEngine: AudioEngine
    @State private var currentPlayingStep = -1
    
    // Track colors that match the instrument colors from the target image
    let trackColors: [Color] = [
        .orange,    // Track 0 (drums)
        .cyan,      // Track 1
        .green,     // Track 2
        .pink,      // Track 3
        .purple,    // Track 4
        .yellow,    // Track 5
        .mint,      // Track 6
        .blue       // Track 7
    ]
    
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
                                isActive: audioEngine.getGridCell(track: track, step: step),
                                isPlaying: audioEngine.isPlaying && step == currentPlayingStep,
                                color: trackColors[track]
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
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(hex: "ff8c99"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(hex: "d1477a"), lineWidth: 2)
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
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            RoundedRectangle(cornerRadius: 3)
                .fill(cellColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 3)
                        .stroke(Color.black, lineWidth: 1)
                )
                .overlay(
                    // Playing indicator
                    RoundedRectangle(cornerRadius: 3)
                        .stroke(isPlaying ? Color.white : Color.clear, lineWidth: 3)
                )
                .aspectRatio(1.2, contentMode: .fit)
                .scaleEffect(isPlaying ? 1.05 : 1.0)
                .animation(.easeInOut(duration: 0.1), value: isPlaying)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var cellColor: Color {
        // Track 4 (drums) has different colors per step, others have single track color
        if track == 3 { // Track 4 - Drums
            if isActive {
                // Different colors for different drum sounds
                switch step % 4 {
                case 0: return Color(hex: "FF4500") // Kick - Orange Red
                case 1: return Color(hex: "1E90FF") // Snare - Blue
                case 2: return Color(hex: "32CD32") // Hi-hat - Green
                case 3: return Color(hex: "FF1493") // Percussion - Pink
                default: return Color(hex: "FFD700")
                }
            } else {
                return Color(hex: "FFA500") // Orange background for drums
            }
        } else {
            // All other tracks have single color
            switch track {
            case 0: // Track 1 - Pink
                return isActive ? Color(hex: "FF1493") : Color(hex: "FFB6C1")
            case 1: // Track 2 - Blue
                return isActive ? Color(hex: "1E90FF") : Color(hex: "87CEEB")
            case 2: // Track 3 - Purple
                return isActive ? Color(hex: "9370DB") : Color(hex: "DDA0DD")
            case 4: // Track 5 - Green
                return isActive ? Color(hex: "32CD32") : Color(hex: "98FB98")
            case 5: // Track 6 - Orange
                return isActive ? Color(hex: "FF8C00") : Color(hex: "FFDAB9")
            case 6: // Track 7 - Cyan
                return isActive ? Color(hex: "00CED1") : Color(hex: "E0FFFF")
            case 7: // Track 8 - Red
                return isActive ? Color(hex: "DC143C") : Color(hex: "FFA0A0")
            default:
                return isActive ? Color.gray : Color.gray.opacity(0.3)
            }
        }
    }
}