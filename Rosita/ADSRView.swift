import SwiftUI

struct ADSRView: View {
    @EnvironmentObject var audioEngine: AudioEngine
    
    var body: some View {
        VStack(spacing: 8) {
            // Title
            Text("ADSR Envelope")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.black)
            
            // ADSR Sliders - beautiful custom sliders like original
            VStack(spacing: 8) {
                CustomSlider(value: $audioEngine.attack, range: 0...2, trackColor: Color(hex: "FFB6C1"), label: "A:")
                CustomSlider(value: $audioEngine.decay, range: 0...2, trackColor: Color(hex: "FFB6C1"), label: "D:")
                CustomSlider(value: $audioEngine.sustain, range: 0...1, trackColor: Color(hex: "FF69B4"), label: "S:")
                CustomSlider(value: $audioEngine.release, range: 0...5, trackColor: Color(hex: "FFB6C1"), label: "R:")
            }
            .onChange(of: audioEngine.attack) { _ in audioEngine.updateADSR() }
            .onChange(of: audioEngine.decay) { _ in audioEngine.updateADSR() }
            .onChange(of: audioEngine.sustain) { _ in audioEngine.updateADSR() }
            .onChange(of: audioEngine.release) { _ in audioEngine.updateADSR() }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.8))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.black, lineWidth: 2)
                )
        )
    }
}

