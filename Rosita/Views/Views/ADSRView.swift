import SwiftUI

struct ADSRView: View {
    @EnvironmentObject var audioEngine: AudioEngine
    
    var body: some View {
        VStack(spacing: 16) {
            // Title
            Text("ADSR Envelope")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.black)
            
            // ADSR Sliders
            VStack(spacing: 12) {
                ADSRSlider(label: "A:", value: $audioEngine.attack, range: 0...2, color: .pink)
                ADSRSlider(label: "D:", value: $audioEngine.decay, range: 0...2, color: .pink)
                ADSRSlider(label: "S:", value: $audioEngine.sustain, range: 0...1, color: .pink)
                ADSRSlider(label: "R:", value: $audioEngine.release, range: 0...5, color: .pink)
            }
            .onChange(of: audioEngine.attack) { _ in audioEngine.updateADSR() }
            .onChange(of: audioEngine.decay) { _ in audioEngine.updateADSR() }
            .onChange(of: audioEngine.sustain) { _ in audioEngine.updateADSR() }
            .onChange(of: audioEngine.release) { _ in audioEngine.updateADSR() }
            
            // Bottom buttons
            HStack(spacing: 12) {
                Button(action: {
                    // ADSR action
                }) {
                    Text("ADSR")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.black)
                        .frame(width: 60, height: 30)
                        .background(Color.white)
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.black, lineWidth: 1)
                        )
                }
                
                Button(action: {
                    // Scale action
                }) {
                    Text("Major")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.black)
                        .frame(width: 60, height: 30)
                        .background(Color.white)
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.black, lineWidth: 1)
                        )
                }
                
                Button(action: {
                    // Octave action
                }) {
                    Text("Octave")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.black)
                        .frame(width: 60, height: 30)
                        .background(Color.white)
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.black, lineWidth: 1)
                        )
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

struct ADSRSlider: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
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
                        .frame(width: geometry.size.width * CGFloat((value - range.lowerBound) / (range.upperBound - range.lowerBound)), height: 20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.black, lineWidth: 1)
                        )
                    
                    // Custom slider knob
                    HStack {
                        Spacer()
                            .frame(width: geometry.size.width * CGFloat((value - range.lowerBound) / (range.upperBound - range.lowerBound)))
                        
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
                            let newValue = Double(gesture.location.x / geometry.size.width) * (range.upperBound - range.lowerBound) + range.lowerBound
                            value = min(max(newValue, range.lowerBound), range.upperBound)
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }
                )
            }
            .frame(height: 24)
        }
    }
}

struct ScaleButton: View {
    let title: String
    
    var body: some View {
        Button(action: {
            // Scale functionality would go here
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.2))
                .cornerRadius(8)
        }
    }
}