import SwiftUI

struct EffectsView: View {
    @EnvironmentObject var audioEngine: AudioEngine
    
    let effectNames = ["A", "B", "C", "D"]
    let effectFullNames = ["Delay", "Reverb", "Distortion", "Chorus"]
    
    var body: some View {
        VStack(spacing: 8) {
            titleView
            effectControlsView
        }
        .padding()
        .background(backgroundView)
    }
    
    private var titleView: some View {
        Text("Effects")
            .font(.system(size: 14, weight: .bold))
            .foregroundColor(.black)
    }
    
    private var effectControlsView: some View {
        VStack(spacing: 8) {
            ForEach(0..<4) { index in
                effectSlider(for: index)
            }
        }
    }
    
    private func effectSlider(for index: Int) -> some View {
        CustomEffectSlider(
            value: $audioEngine.effectAmounts[index],
            isEnabled: $audioEngine.effectsEnabled[index],
            trackColor: Color(hex: "E6E6FA"),
            label: effectNames[index] + ":"
        )
        .onChange(of: audioEngine.effectAmounts[index]) { _ in
            audioEngine.updateEffects()
        }
        .onChange(of: audioEngine.effectsEnabled[index]) { _ in
            audioEngine.updateEffects()
        }
    }
    
    private var backgroundView: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.white.opacity(0.8))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.black, lineWidth: 2)
            )
    }
}

