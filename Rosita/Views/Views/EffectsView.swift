import SwiftUI

struct EffectsView: View {
    @EnvironmentObject var audioEngine: AudioEngine
    
    let effectNames = ["A", "B", "C", "D"]
    let effectFullNames = ["Delay", "Reverb", "Distortion", "Chorus"]
    
    var body: some View {
        VStack(spacing: 16) {
            // Title
            Text("Effects")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.black)
            
            // Effect Controls
            VStack(spacing: 12) {
                ForEach(0..<4) { index in
                    EffectSlider(
                        label: effectNames[index] + ":",
                        fullName: effectFullNames[index],
                        value: $audioEngine.effectAmounts[index],
                        isEnabled: $audioEngine.effectsEnabled[index],
                        color: .blue
                    )
                    .onChange(of: audioEngine.effectAmounts[index]) { _ in
                        audioEngine.updateEffects()
                    }
                    .onChange(of: audioEngine.effectsEnabled[index]) { _ in
                        audioEngine.updateEffects()
                    }
                }
            }
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

struct EffectSlider: View {
    let label: String
    let fullName: String
    @Binding var value: Double
    @Binding var isEnabled: Bool
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Text(label)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.black)
                .frame(width: 25)
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.black, lineWidth: 1)
                        )
                    
                    // Fill
                    RoundedRectangle(cornerRadius: 6)
                        .fill(color)
                        .frame(width: geometry.size.width * CGFloat(value), height: 20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.black, lineWidth: 1)
                        )
                    
                    // Custom slider knob
                    HStack {
                        Spacer()
                            .frame(width: geometry.size.width * CGFloat(value))
                        
                        Circle()
                            .fill(Color.white)
                            .frame(width: 24, height: 24)
                            .overlay(
                                Circle()
                                    .stroke(Color.black, lineWidth: 2)
                            )
                            .offset(x: -12)
                    }
                }
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { gesture in
                            let newValue = Double(gesture.location.x / geometry.size.width)
                            value = min(max(newValue, 0), 1)
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }
                )
            }
            .frame(height: 24)
            
            // Enable/disable checkbox
            Button(action: {
                isEnabled.toggle()
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(isEnabled ? color : Color.gray.opacity(0.3))
                    .frame(width: 20, height: 20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color.black, lineWidth: 1)
                    )
                    .overlay(
                        Text(isEnabled ? "✓" : "")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    )
            }
        }
    }
}