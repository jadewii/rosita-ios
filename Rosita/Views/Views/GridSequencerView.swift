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
        VStack(spacing: 8) {
            // Step number indicators
            HStack(spacing: 2) {
                ForEach(1...16, id: \.self) { step in
                    Text("\(step)")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 8)
            
            // Main sequencer grid
            VStack(spacing: 1) {
                ForEach(0..<8) { track in
                    HStack(spacing: 1) {
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
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.cyan.opacity(0.3))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.black, lineWidth: 2)
                    )
            )
            .onReceive(Timer.publish(every: 60.0 / audioEngine.bpm / 4.0, on: .main, in: .common).autoconnect()) { _ in
                if audioEngine.isPlaying {
                    currentPlayingStep = (currentPlayingStep + 1) % 16
                } else {
                    currentPlayingStep = -1
                }
            }
            
            // Volume controls at the bottom
            HStack(spacing: 12) {
                Spacer()
                
                Button(action: {
                    // Volume down
                }) {
                    Text("-")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.black)
                        .frame(width: 30, height: 24)
                        .background(Color.white)
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.black, lineWidth: 1)
                        )
                }
                
                Button(action: {
                    // Volume up
                }) {
                    Text("+")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.black)
                        .frame(width: 30, height: 24)
                        .background(Color.white)
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.black, lineWidth: 1)
                        )
                }
            }
            .padding(.top, 8)
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
                .frame(height: 24)
                .scaleEffect(isPlaying ? 1.05 : 1.0)
                .animation(.easeInOut(duration: 0.1), value: isPlaying)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var cellColor: Color {
        if isActive {
            return color
        } else {
            return Color.cyan.opacity(0.2)
        }
    }
}