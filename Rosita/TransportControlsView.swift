import SwiftUI

struct TransportControlsView: View {
    @EnvironmentObject var audioEngine: AudioEngine
    @State private var bpmText = "120"
    
    var body: some View {
        VStack(spacing: 8) {
            // Top row: Transport buttons with retro style
            HStack(spacing: 12) {
                // Play button
                RetroButton(
                    title: audioEngine.isPlaying ? "STOP" : "PLAY",
                    color: audioEngine.isPlaying ? Color(hex: "FF0000") : Color(hex: "00FF00"),
                    textColor: .black,
                    action: {
                        audioEngine.togglePlayback()
                    },
                    width: 65,
                    height: 42,
                    fontSize: 14
                )
                
                // Stop button
                RetroButton(
                    title: "STOP",
                    color: audioEngine.isPlaying ? Color(hex: "808080") : Color.gray,
                    textColor: .white,
                    action: {
                        audioEngine.stop()
                    },
                    width: 65,
                    height: 42,
                    fontSize: 14
                )
                
                // Random button
                RetroButton(
                    title: "RANDOM",
                    color: false ? Color(hex: "FFFF00") : Color.gray, // Always inactive for now
                    textColor: false ? .black : .white,
                    action: {
                        audioEngine.randomizePattern()
                    },
                    width: 75,
                    height: 42,
                    fontSize: 13
                )
                
                // Clear button
                RetroButton(
                    title: "CLEAR",
                    color: false ? Color(hex: "00FFFF") : Color.gray, // Always inactive for now
                    textColor: false ? .black : .white,
                    action: {
                        audioEngine.clearPattern()
                    },
                    width: 65,
                    height: 42,
                    fontSize: 14
                )
                
                // Clear All button
                RetroButton(
                    title: "CLR ALL",
                    color: false ? Color(hex: "FF0000") : Color.gray, // Always inactive for now
                    textColor: false ? .white : .white,
                    action: {
                        audioEngine.clearAllPatterns()
                    },
                    width: 75,
                    height: 42,
                    fontSize: 13
                )
                
                // Mixer button
                RetroButton(
                    title: "MIXER",
                    color: false ? Color(hex: "FF00FF") : Color.gray, // Always inactive for now
                    textColor: false ? .black : .white,
                    action: {
                        // Mixer functionality
                    },
                    width: 65,
                    height: 42,
                    fontSize: 14
                )
            }
        }
    }
}