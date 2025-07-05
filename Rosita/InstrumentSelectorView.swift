import SwiftUI

struct InstrumentSelectorView: View {
    @EnvironmentObject var audioEngine: AudioEngine
    
    var body: some View {
        VStack(spacing: 4) {
            // Title
            Text("Instrument")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white)
            
            // Instrument buttons in a single row
            HStack(spacing: 6) {
                ForEach(0..<4) { index in
                    InstrumentButton(
                        index: index,
                        isSelected: audioEngine.selectedInstrument == index,
                        type: InstrumentType(rawValue: index) ?? .synth
                    ) {
                        audioEngine.selectedInstrument = index
                    }
                }
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

struct InstrumentButton: View {
    let index: Int
    let isSelected: Bool
    let type: InstrumentType
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                action()
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
        }) {
            Text(type.displayNumber)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 36, height: 36)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isSelected ? type.color.opacity(0.8) : Color.white.opacity(0.2))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.white, lineWidth: isSelected ? 2 : 1)
                        )
                        .shadow(color: isSelected ? type.color.opacity(0.6) : Color.clear, radius: 8)
                )
                .scaleEffect(isSelected ? 1.1 : 1.0)
        }
    }
}