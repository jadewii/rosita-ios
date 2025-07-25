import SwiftUI

struct TransportControlsView: View {
    @EnvironmentObject var audioEngine: AudioEngine
    @State private var bpmText = "120"
    
    var body: some View {
        VStack(spacing: 8) {
            // Top row: Transport buttons with retro style
            HStack(spacing: 6) {
                // Play/Pause button
                RetroButton(
                    title: audioEngine.isPlaying ? "II" : "PLAY",
                    color: audioEngine.isPlaying ? Color(hex: "9370DB") : Color(hex: "00FF00"),
                    textColor: audioEngine.isPlaying ? .white : .black,
                    action: {
                        audioEngine.togglePlayback()
                    },
                    width: 84,
                    height: 42,
                    fontSize: audioEngine.isPlaying ? 16 : 13
                )
                
                // Stop button
                RetroButton(
                    title: "STOP",
                    color: Color(hex: "FF0000"),
                    textColor: .white,
                    action: {
                        audioEngine.stop()
                    },
                    width: 84,
                    height: 42,
                    fontSize: 13
                )
                
                // REC button - changes appearance based on mode
                RetroButton(
                    title: audioEngine.recordingMode == .trStyle ? "TR" : "REC",
                    color: audioEngine.isRecording ? 
                        (audioEngine.recordingMode == .trStyle ? Color(hex: "8B0000") : Color(hex: "FF0000")) : 
                        Color.gray,
                    textColor: audioEngine.isRecording ? .white : .white,
                    action: {
                        audioEngine.toggleRecording()
                    },
                    width: 76,
                    height: 42,
                    fontSize: 13
                )
                .onLongPressGesture {
                    audioEngine.toggleRecordingMode()
                }
                
                // Random button
                RetroButton(
                    title: "RANDOM",
                    color: false ? Color(hex: "FFFF00") : Color.gray, // Always inactive for now
                    textColor: false ? .black : .white,
                    action: {
                        audioEngine.randomizePattern()
                    },
                    width: 100,
                    height: 42,
                    fontSize: 11
                )
                
                // Clear button
                RetroButton(
                    title: "CLEAR",
                    color: false ? Color(hex: "00FFFF") : Color.gray, // Always inactive for now
                    textColor: false ? .black : .white,
                    action: {
                        audioEngine.clearPattern()
                    },
                    width: 90,
                    height: 42,
                    fontSize: 12
                )
                
                // Clear All button
                RetroButton(
                    title: "CLR ALL",
                    color: false ? Color(hex: "FF0000") : Color.gray, // Always inactive for now
                    textColor: false ? .white : .white,
                    action: {
                        audioEngine.clearAllPatterns()
                    },
                    width: 100,
                    height: 42,
                    fontSize: 11
                )
                
                // Mixer button
                RetroButton(
                    title: "MIXER",
                    color: false ? Color(hex: "FF00FF") : Color.gray, // Always inactive for now
                    textColor: false ? .black : .white,
                    action: {
                        // Mixer functionality
                    },
                    width: 90,
                    height: 42,
                    fontSize: 12
                )
                
                // ADSR button
                RetroButton(
                    title: "ADSR",
                    color: Color(hex: "00FFFF"),
                    textColor: .black,
                    action: {},
                    width: 84,
                    height: 42,
                    fontSize: 12
                )
                
                // MAJOR button
                RetroButton(
                    title: "MAJOR",
                    color: Color(hex: "FFFF00"),
                    textColor: .black,
                    action: {},
                    width: 84,
                    height: 42,
                    fontSize: 12
                )
                
                // OCTAVE button
                RetroButton(
                    title: "OCTAVE",
                    color: Color(hex: "9370DB"),
                    textColor: .black,
                    action: {},
                    width: 90,
                    height: 42,
                    fontSize: 11
                )
                
                // Grid octave - button
                RetroButton(
                    title: "-",
                    color: Color(hex: "87CEEB"),
                    textColor: .black,
                    action: {
                        if audioEngine.gridTranspose > -24 {
                            audioEngine.gridTranspose -= 12
                        }
                    },
                    width: 52,
                    height: 36,
                    fontSize: 16
                )
                
                // Grid octave + button
                RetroButton(
                    title: "+",
                    color: Color(hex: "87CEEB"),
                    textColor: .black,
                    action: {
                        if audioEngine.gridTranspose < 24 {
                            audioEngine.gridTranspose += 12
                        }
                    },
                    width: 52,
                    height: 36,
                    fontSize: 16
                )
            }
        }
    }
}