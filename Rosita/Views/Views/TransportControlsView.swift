import SwiftUI

struct TransportControlsView: View {
    @EnvironmentObject var audioEngine: AudioEngine
    @State private var bpmText = "120"
    
    var body: some View {
        HStack(spacing: 16) {
            // Play/Stop button
            Button(action: {
                audioEngine.togglePlayback()
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            }) {
                Image(systemName: audioEngine.isPlaying ? "stop.fill" : "play.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                    .frame(width: 50, height: 50)
                    .background(
                        Circle()
                            .fill(audioEngine.isPlaying ? Color.red : Color.green)
                            .shadow(radius: 4)
                    )
            }
            
            // Random button
            Button(action: {
                audioEngine.randomizePattern()
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            }) {
                Text("Random")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.orange)
                            .shadow(radius: 2)
                    )
            }
            
            // Clear button
            Button(action: {
                audioEngine.clearPattern()
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            }) {
                Text("Clear")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.blue)
                            .shadow(radius: 2)
                    )
            }
            
            // Clear All button
            Button(action: {
                audioEngine.clearAllPatterns()
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            }) {
                Text("Clear All")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.red)
                            .shadow(radius: 2)
                    )
            }
            
            Spacer()
            
            // BPM control
            HStack(spacing: 8) {
                Text("BPM:")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                
                TextField("BPM", text: $bpmText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 60)
                    .keyboardType(.numberPad)
                    .onChange(of: bpmText) { newValue in
                        if let bpm = Double(newValue), bpm >= 60, bpm <= 200 {
                            audioEngine.bpm = bpm
                        }
                    }
                    .onAppear {
                        bpmText = String(Int(audioEngine.bpm))
                    }
                
                VStack(spacing: 4) {
                    Button(action: {
                        audioEngine.bpm = min(audioEngine.bpm + 1, 200)
                        bpmText = String(Int(audioEngine.bpm))
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }) {
                        Image(systemName: "chevron.up")
                            .font(.system(size: 12))
                            .foregroundColor(.white)
                    }
                    
                    Button(action: {
                        audioEngine.bpm = max(audioEngine.bpm - 1, 60)
                        bpmText = String(Int(audioEngine.bpm))
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }) {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 12))
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .padding(.horizontal)
        .frame(height: 60)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.1))
                .shadow(radius: 4)
        )
    }
}