import SwiftUI

struct EffectsView: View {
    @EnvironmentObject var audioEngine: AudioEngine
    @State private var effectAmounts: [Double] = [0.3, 0.3, 0.2, 0.3]
    @State private var effectsEnabled: [Bool] = [true, true, true, true]
    
    let effectNames = ["A", "B", "C", "D"]
    let effectFullNames = ["Echo", "Space", "Warmth", "Phase"]
    
    var body: some View {
        VStack(spacing: 4) {
            titleView
            effectControlsView
        }
        .padding(8)
        .background(backgroundView)
        .onChange(of: audioEngine.selectedInstrument) { _ in
            // Load effects for the newly selected track
            loadEffectsForCurrentTrack()
        }
        .onAppear {
            // Initialize with current track's effects
            loadEffectsForCurrentTrack()
        }
    }
    
    private var titleView: some View {
        Text("EFFECTS (TRACK \(audioEngine.selectedInstrument + 1))")
            .font(.system(size: 12, weight: .bold, design: .monospaced))
            .foregroundColor(.black)
    }
    
    private var effectControlsView: some View {
        VStack(spacing: 4) {
            ForEach(0..<4) { index in
                effectSlider(for: index)
            }
        }
    }
    
    private func effectSlider(for index: Int) -> some View {
        CustomEffectSlider(
            value: Binding(
                get: { effectAmounts[index] },
                set: { newValue in
                    effectAmounts[index] = newValue
                    audioEngine.updateTrackEffect(track: audioEngine.selectedInstrument, effect: index, enabled: effectsEnabled[index], amount: newValue)
                }
            ),
            isEnabled: Binding(
                get: { effectsEnabled[index] },
                set: { newValue in
                    effectsEnabled[index] = newValue
                    audioEngine.updateTrackEffect(track: audioEngine.selectedInstrument, effect: index, enabled: newValue, amount: effectAmounts[index])
                }
            ),
            trackColor: Color(hex: "E6E6FA"),
            label: effectNames[index] + ":"
        )
    }
    
    private func loadEffectsForCurrentTrack() {
        let track = audioEngine.selectedInstrument
        if track >= 0 && track < audioEngine.trackEffectsEnabled.count {
            effectsEnabled = audioEngine.trackEffectsEnabled[track]
            effectAmounts = audioEngine.trackEffectAmounts[track]
        }
    }
    
    private var backgroundView: some View {
        Rectangle()
            .fill(Color.white.opacity(0.8))
            .overlay(
                Rectangle()
                    .stroke(Color.black, lineWidth: 3)
            )
    }
}