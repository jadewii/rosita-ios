import SwiftUI

struct TransportControlsView: View {
    @EnvironmentObject var audioEngine: AudioEngine
    @State private var bpmText = "120"
    
    var body: some View {
        VStack(spacing: 8) {
            // Top row: Transport buttons
            HStack(spacing: 12) {
                // Play button
                Button(action: {
                    audioEngine.togglePlayback()
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                }) {
                    Image(systemName: audioEngine.isPlaying ? "stop.fill" : "play.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                        .frame(width: 40, height: 32)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(audioEngine.isPlaying ? Color.red : Color.green)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color.black, lineWidth: 1)
                                )
                        )
                }
                
                // Stop button
                Button(action: {
                    audioEngine.stop()
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                }) {
                    Text("Stop")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.black)
                        .frame(width: 50, height: 32)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color.black, lineWidth: 1)
                                )
                        )
                }
                
                // Random button
                Button(action: {
                    audioEngine.randomizePattern()
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                }) {
                    Text("Random")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.black)
                        .frame(width: 60, height: 32)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.orange)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color.black, lineWidth: 1)
                                )
                        )
                }
                
                // Clear button
                Button(action: {
                    audioEngine.clearPattern()
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                }) {
                    Text("Clear")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.black)
                        .frame(width: 50, height: 32)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.blue)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color.black, lineWidth: 1)
                                )
                        )
                }
                
                // Clear All button
                Button(action: {
                    audioEngine.clearAllPatterns()
                    UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                }) {
                    Text("Clear All")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.black)
                        .frame(width: 70, height: 32)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.red)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color.black, lineWidth: 1)
                                )
                        )
                }
                
                // Mixer button
                Button(action: {
                    // Mixer functionality
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                }) {
                    Text("Mixer")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.black)
                        .frame(width: 50, height: 32)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color.black, lineWidth: 1)
                                )
                        )
                }
            }
        }
    }
}