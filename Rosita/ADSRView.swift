import SwiftUI

struct ADSRView: View {
    @EnvironmentObject var audioEngine: AudioEngine
    @State private var attack: Double = 0.01
    @State private var decay: Double = 0.1
    @State private var sustain: Double = 0.8
    @State private var release: Double = 0.3
    
    var body: some View {
        VStack(spacing: 8) {
            // Title with selected track indicator
            Text("ADSR (TRACK \(audioEngine.selectedInstrument + 1))")
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(.black)
            
            // ADSR Sliders - beautiful custom sliders like original
            VStack(spacing: 8) {
                CustomSlider(value: $attack, range: 0...2, trackColor: Color(hex: "FFB6C1"), label: "A:")
                CustomSlider(value: $decay, range: 0...2, trackColor: Color(hex: "FFB6C1"), label: "D:")
                CustomSlider(value: $sustain, range: 0...1, trackColor: Color(hex: "FF69B4"), label: "S:")
                CustomSlider(value: $release, range: 0...5, trackColor: Color(hex: "FFB6C1"), label: "R:")
            }
            .onChange(of: attack) { newValue in 
                audioEngine.updateTrackADSR(track: audioEngine.selectedInstrument, attack: newValue, decay: decay, sustain: sustain, release: release)
            }
            .onChange(of: decay) { newValue in 
                audioEngine.updateTrackADSR(track: audioEngine.selectedInstrument, attack: attack, decay: newValue, sustain: sustain, release: release)
            }
            .onChange(of: sustain) { newValue in 
                audioEngine.updateTrackADSR(track: audioEngine.selectedInstrument, attack: attack, decay: decay, sustain: newValue, release: release)
            }
            .onChange(of: release) { newValue in 
                audioEngine.updateTrackADSR(track: audioEngine.selectedInstrument, attack: attack, decay: decay, sustain: sustain, release: newValue)
            }
            .onChange(of: audioEngine.selectedInstrument) { _ in
                // Load ADSR values for the newly selected track
                let trackADSR = audioEngine.getTrackADSR(track: audioEngine.selectedInstrument)
                attack = trackADSR[0]
                decay = trackADSR[1]
                sustain = trackADSR[2]
                release = trackADSR[3]
            }
            .onAppear {
                // Initialize with current track's ADSR values
                let trackADSR = audioEngine.getTrackADSR(track: audioEngine.selectedInstrument)
                attack = trackADSR[0]
                decay = trackADSR[1]
                sustain = trackADSR[2]
                release = trackADSR[3]
            }
        }
        .padding()
        .background(
            Rectangle()
                .fill(Color.white.opacity(0.8))
                .overlay(
                    Rectangle()
                        .stroke(Color.black, lineWidth: 3)
                )
        )
    }
}